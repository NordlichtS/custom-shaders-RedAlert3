//all the helper functions
#include "PBR1-c-maxui.FXH"    //最先加载max可调的参数
#include "PBR1-a-constants.FXH"  //shader通用的
#include "PBR1-b-styles.FXH"  //都是静态常量


/*
struct VSOutputLanyi
{
    float4 Position : POSITION;
    float2 TexCoord : TEXCOORD0;
    float3 TangentSpaceToWorldX : TEXCOORD1_centroid;
    float3 TangentSpaceToWorldY : TEXCOORD2_centroid;
    float3 TangentSpaceToWorldZ : TEXCOORD3_centroid;
    float3 WorldPosition  : TEXCOORD4;
    float4 ShadowMapCoord : TEXCOORD5;
    float4 ShroudAndCloud : TEXCOORD6;
    float4 VertexColor : COLOR0;
};
*/

//VS==================================

// 通过四元数来计算旋转的函数，来自 CNC3 的 Skinning.fxh
float3 Quaternion_R(float4 rotation, float3 position) 
{
	float4 a;
	a = rotation.wwwx * position.xyzx + rotation.yzxy * position.zxyy;
	a.w = -a.w;
	a -= rotation.zxyz * position.yzxz;
    float3 finalvector 
    = rotation.www * a.xyz - rotation.xyz * a.www + rotation.yzx * a.zxy - rotation.zxy * a.yzx;
	return finalvector;
}; //非常巧妙，把一个3X3矩阵省略到float4

/*
// 摄像机相对位置与距离 (这个不能用了)
float4 helper_eye_relative(float3 WorldPosition) 
{
    float3 V = (EyePosition.xyz - WorldPosition);
    #if defined(_3DSMAX_)  //MAX自己的视角位置覆盖
        V = (ViewI[3].xyz - WorldPosition);
    #endif
    float distance_eye_vertex = length(V);
    return  float4(V.xyz, distance_eye_vertex );
};  //然后在PS里 XYZ/W 就能获得normalized后的view vector
*/

//直接在PS里算的VIEW
float3 helper_ps_getViewVector(float3 WorldPosition) 
{   
    float3 camera_in_world = EyePosition ;
    #if defined(_3DSMAX_)  //MAX自己的视角位置覆盖
        camera_in_world = ViewI[3].xyz ;
    #endif
    return normalize(camera_in_world - WorldPosition);   
};


// 计算战争迷雾贴图的 UV 坐标
float2 getWarfogUV(float4 WorldPosition) 
{
    return (WorldPosition.xy + Shroud.ScaleUV_OffsetUV.zw) * Shroud.ScaleUV_OffsetUV.xy;
};
// 计算云的贴图的 UV 坐标
float2 getCloudUV(float4 WorldPosition) 
{
    float4 multipliedCloudUV = WorldPosition.xyzz * Cloud.WorldPositionMultiplier_XYZZ;
    return multipliedCloudUV.xy - multipliedCloudUV.zw + Cloud.CurrentOffsetUV;
};
//xy warfog , zw cloud 


// 计算阴影贴图的 UV 坐标和深度
float4 getShadowMapUV(float4 WorldPosition) 
{
    float4 shadowMapCoordinates = mul(WorldPosition, ShadowMapWorldToShadow);
    shadowMapCoordinates.xyz /= shadowMapCoordinates.w;
    shadowMapCoordinates.z -= shadowBias;
    return shadowMapCoordinates;
};


float avoidzero(float inputfloat)
{    return max(inputfloat, 1/4096);};










//PS===================================

//柔和阴影
float helper_invert_shadow_density_cross ( float3 ShadowProjection, float sun_tilt )  
{
    if(sun_tilt <= 0) {return 0;};
    if(! HasShadow)   {return 1;}; 

    static const int ShadowPCFlevel = 2 ;
    float ShadowDensity = 0; int countSAMPLES = 0; //int? float?
    float ShadowDepth; float2 ThisShiftUV; float ShiftTexel ; 
    for (float countSHIFT = 0.5- ShadowPCFlevel; countSHIFT < ShadowPCFlevel; countSHIFT += 1 )
    {
        ShiftTexel = countSHIFT * Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w ;

        ThisShiftUV = ShadowProjection.xy + float2 (ShiftTexel , 0); //LEFT TO RIGHT
        ShadowDepth = tex2D(ShadowMapSampler, ThisShiftUV);
        ShadowDensity += (ShadowDepth < ShadowProjection.z) ? +1 : +0 ;

        ThisShiftUV = ShadowProjection.xy + float2 (0 , ShiftTexel); //UP TO DOWN
        ShadowDepth = tex2D(ShadowMapSampler, ThisShiftUV);
        ShadowDensity += (ShadowDepth < ShadowProjection.z) ? +1 : +0 ;

        countSAMPLES +=2 ;
    }
    ShadowDensity /= countSAMPLES ; //need saturate?
    return 1- ShadowDensity;
};

float helper_invert_shadow_density_array ( float3 ShadowProjection, float sun_tilt )  
{
    if(sun_tilt <= 0) {return 0;};
    if(! HasShadow)   {return 1;}; 

    float texelX[9] = {0, -1, +1,  0,  0, -1, +1, -1, +1} ;
    float texelY[9] = {0,  0,  0, -1, +1, -1, -1, +1, +1} ;

    float2 ThisShiftUV; float ShadowDepth ; float ShadowDensity ; int countSAMPLES ;

    for(int sc = 0; sc <= 4; sc++) //这个用来调采样数
    {
        ThisShiftUV = float2(texelX[sc], texelY[sc]) * 1.25
        * Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w + ShadowProjection.xy ;

        ShadowDepth = tex2D(ShadowMapSampler, ThisShiftUV);
        ShadowDensity += (ShadowDepth < ShadowProjection.z) ? +1 : +0 ;
        countSAMPLES +=1 ;
    };
    ShadowDensity /= countSAMPLES ; //need saturate?
    return 1- ShadowDensity;
}


float3 mixHC (float3 basetex , float HCweighht)
{

    float3 actualHC = RecolorColor ;
    #if defined(_3DSMAX_)  // MAX永远有阵营色
    actualHC = PV_FactionColor ;
    #endif
    float3 aftermix = basetex ;
    if(double_hc_bright)   
    {aftermix = saturate(basetex * 2) ;}; //模仿原版双倍亮度
    aftermix *= actualHC ;
    return lerp(basetex, aftermix, HCweighht) ;
}



float3 getSKYBOXcolor (float3 R, float roughness) 
{
    float  skybox_lodbias =  log2(roughness * max_skybox_lod_bias) ; // max 0 ?
    float4 skyboxUV = float4(R.xyz , skybox_lodbias); //根据粗糙度的对数算mipmap偏移数
    float3 skybox_color = texCUBEbias(EnvironmentTextureSampler, skyboxUV);

    return skybox_color;
}


float3 getIRRADIANCEcolor (float3 N) 
{
    if(use_irradiance_box){
    float3 irradianceBOX = texCUBE(IrradianceTextureSampler, N);
    return irradianceBOX ;}

    float3 nomap_irradiance = AmbientLightColor ;
    nomap_irradiance *= saturate(N.z +1);
    return nomap_irradiance;
}

//高光的分布
/*
float helper_specdist_new(float OOA, float specpeak, float3 R, float3 L)
{
    //float specpeak = glossiness * specbase_multiply;
    float cosRL = dot(R,L);
    cosRL = saturate(cosRL);
    //float OOA = glossiness * glossiness ; //one over alpha
    //square curve is similar to cosine within half period
    float specdist = cosRL * OOA - OOA +1 ;
    specdist = saturate(specdist);
    specdist = pow(specdist , 2 ); //smooth tails
    //float peakbrightness = glossiness * specbase_multiply ; 
    //specdist *= peakbrightness ;
    return specdist  ;
};
*/

float helper_specdist(float glossiness, float3 R, float3 L)
{
    float cosRL = saturate( dot(R,L) );
    float OOA = glossiness * glossiness ; //one over alpha
    //square curve is similar to cosine within half period
    float specdist = cosRL * OOA - OOA +1 ;
    specdist = saturate(specdist);
    specdist *= specdist ;

    return ( specdist * glossiness * specbase_multiply ) ;
};

//基于目光与光源，而不是半程向量的菲涅尔效应，虽然不写实但更有表现力，也省一次开方
float helper_fresnel(float3 L, float3 V, float F0)
{
    float lerpw = saturate(dot(L, -V)) ;
    float fresnelLV = lerp(F0, 1, lerpw * lerpw);
    return fresnelLV ;
};

//另一种菲涅尔计算方式，曲线应该和上面的很接近
float helper_fresnel_old(float3 L, float3 V, float F0)
{
    float cosRV = dot( L , V ) ;
    float lerpw = (1- cosRV)/2 ;
    lerpw = pow (lerpw, 8);
    float fresnelLV = lerp(F0, 1, lerpw);
    return fresnelLV ;
};

//带有菲涅尔修正的漫反射，有四种算式可选
float helper_newdiffuse(float dotLN, float Reflectivity) 
{
    float lambertian = saturate(dotLN) ;
    float newlambertian = lambertian ;

    static const int calculate_diffuse_type = 2 ; //是否直射光漫反射要被菲涅尔修正，及其精确度

    if(calculate_diffuse_type ==1) {
        newlambertian = lerp( lambertian , lambertian * lambertian , Reflectivity * 0.5 ) ;
    };

    if(calculate_diffuse_type ==2) {
        float lamb_after_fresnel = min(lambertian, (lambertian * lambertian * 1.44)); 
        newlambertian = lerp( lambertian , lamb_after_fresnel , Reflectivity ) ;
    };

    if(calculate_diffuse_type ==3) {
        float fresnel_loss = pow((1- lambertian * lambertian), 4) * Reflectivity ;
        newlambertian = lambertian * (1- fresnel_loss) ;
    };

    return newlambertian * diffuse_multiply; //最低精确度的
}; 



//用法线图XY算出Z向量
float3 helper_normalmapper(float2 TEXtangent) 
{
    // if(tangent_xy_multiply == 0 ){return float3(0,0,1);};
    float3 nrm = float3(TEXtangent ,1 ) ;
    nrm.xy = nrm.xy * 2 -1 ;
    nrm.xy *= tangent_xy_multiply ;//
    //nrm.z = sqrt(saturate(1 - dot(nrm.xy, nrm.xy))) ;//*2 ? //sqrt ?
    float tiltradius = dot(nrm.xy, nrm.xy);
    nrm.z = saturate(1 - tiltradius * tiltradius) ; 
    return nrm ;
};


//灯光闪烁
float helper_glowpulse()
{
    if(GlowPeriod ==0){return GlowAmplitude;};

    float phase = frac( Time / GlowPeriod ) ; // 保留小数部分， mod 1
    phase = abs(phase *2 -1) ;//或者平方？
    return phase * GlowAmplitude;
};


// smoothstep(min, max, x)  for point light range compute


/*
废弃代码

//通过粗糙度算更有用的光滑度
float helper_glossiness(float roughmap)
{
    float roughness ;
    if(SimpleRoughness)
    {roughness = max(MinRoughness, roughmap); }
    else
    {roughness = lerp(MinRoughness, 1, roughmap); };
    float glossiness = 1 / roughness ; //one over roughness, not alpha
    return glossiness ; //min 1 , max 10 (input 0.1)
};

//用VS算好阳光和三点光源 dot LN 给PS圆滑一下，不过可能还不如normalize好用
float4 helper_nosqrt_smooth_lambertian(float4 four_VS_dotLN)
{
    float4 temp = saturate(four_VS_dotLN);
    temp = 1 - temp ;
    temp *= temp;
    temp = 1 - temp ;
    return temp;
}

*/