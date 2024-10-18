//all the helper functions




#include "PBR1-constants.FXH"  //shader通用的



//常用常量，与确定的风格参数===================
//并非所有都有用

// const float PIE = radians(180) ; //圆周率，目前弃用

const bool  base_texture_gamma = true ; //是否对主贴图进行gamma修正
const bool  double_hc_bright = false ; //像原版一样翻倍阵营色亮度
const bool  final_output_gamma = false ;

const float FresnelF0 = 0.125 ; //绝缘体菲涅尔效应F0，即反射角为0时高光亮度
const float FresnelMetalF0 = 0.875 ; //金属的菲涅尔F0

const float ambient_diff_multiply =  1 ; //环境光与天空盒diffuse
const float ambient_spec_multiply =  1 ; //环境光与天空盒specular

const float pointlight_multiply =  2 ; //点光源整体亮度
const float sunlight_multiply =  1 ; //阳光亮度
const float diffuse_multiply =  1 ; //漫反射亮度，影响阳光与点光源
const float specbase_multiply =  0.5 ; //高光在最大粗糙度金属下的基础峰值亮度，影响阳光与点光源


#if defined(_3DSMAX_) //IN PREVIEW

const bool  HasCloud = false ; //允许动态云影响阳光亮度
const bool  HasWarfog = false ; //允许接受战争迷雾（大多数单位直接会消失所以没必要）

#else  //IN GAME

const bool  HasCloud = true ; //允许动态云影响阳光亮度
const bool  HasWarfog = true ; //允许接受战争迷雾（大多数单位直接会消失所以没必要）

#endif


/*  =======================================

const int   calculate_diffuse_type = 2 ; //是否直射光漫反射要被菲涅尔修正，及其精确度
const bool  difcolor_F0_loss = true ; //对垂直入射光线依然分走能量（如果已经烘焙到base图或F0极小就关闭）
const float ambient_reflectivity_loss =  0.4 ; //环境光被菲涅尔效应分走的能量比例（算下半球体积分?）
const float direct_reflectivity_loss =  0.75 ; //直射光被菲涅尔效应分走的能量比例（type2）
const float direct_fresnel_cutoff =  1.75 ; //拟合上面那个用的，1-2之间越小越显著（type1）
const int   ShadowPCFlevel = 2 ; //柔和阴影的十字采样数量是这个乘4

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

=============================
*/

//VS==================================

// 通过四元数来计算旋转的函数，来自 CNC3 的 Skinning.fxh
float3 Quaternion_R(float4 rotation, float3 position) 
{
	float4 a
	= rotation.wwwx * position.xyzx 
    + rotation.yzxy * position.zxyy;
	a.w = -a.w;
	a -= rotation.zxyz * position.yzxz;
    float3 finalvector 
    = rotation.www * a.xyz 
    - rotation.xyz * a.www 
    + rotation.yzx * a.zxy 
    - rotation.zxy * a.yzx;
	return finalvector;
}; //非常巧妙，把一个3X3矩阵省略到float4


//直接在PS里算的VIEW
float3 helper_ps_getViewVector(float3 WorldPosition) 
{   
    float3 camera_in_world = EyePosition ;
    #ifdef _3DSMAX_  //MAX自己的视角位置覆盖
    camera_in_world = ViewI[3].xyz ;
    #endif
    float3 viewvector = normalize(camera_in_world - WorldPosition);  
    return viewvector ;
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
    float shadowBias =  1/256 ; //阴影偏移，防止给自己投影

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

    const int ShadowPCFlevel = 2 ;
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

    float2 ThisShiftUV; float ShadowDepth ; float ShadowDensity ; float countSAMPLES ;

    for(int sc = 0; sc <= 4; sc++) //这个用来调采样数
    {
        ThisShiftUV = float2(texelX[sc], texelY[sc]) * 1.25
        * Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w + ShadowProjection.xy ;

        ShadowDepth = tex2Dlod(ShadowMapSampler, float4(ThisShiftUV, 0, 0) );
        ShadowDensity += (ShadowDepth < ShadowProjection.z) ? 1 : 0 ;
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



float3 getSKYBOXcolor (float3 reflectedView, float roughness, float glossiness, float AOchannel) 
{

    float  mirAO = saturate(AOchannel * glossiness);  //天空盒镜面反射的AO
    // float  lod_before_log = pow(2, max_skybox_mip_level);
    float max_skybox_miplevel_exp2 = 64 ; //最大粗糙度时使用的天空盒mipmap偏移

    float  skybox_lodbias = log2(roughness * max_skybox_miplevel_exp2) ; // max 0 ? log2 ?
    float4 skyboxUV = float4(reflectedView , skybox_lodbias); //根据粗糙度的对数算mipmap偏移数
    float3 skybox_color = texCUBElod(EnvironmentTextureSampler, skyboxUV);
    // texCUBEbias ? texCUBElod 

    return skybox_color * mirAO;
}


float3 getIRRADIANCEcolor (float3 N, float AOchannel) 
{
    float difAO = AOchannel * AOchannel ;

    if(use_irradiance_box)
    { return 
    texCUBE(IrradianceTextureSampler, N) * difAO ;
    };

    //没有辐照贴图就拟合一个
    float3 nomap_irradiance = AmbientLightColor ;
    #ifdef _3DSMAX_
    nomap_irradiance = PV_AmbientLight ;
    #endif

    float downwarddecay = saturate(N.z + 1.25) ;
    nomap_irradiance *= min(difAO , downwarddecay) ; //真的要么
    return nomap_irradiance;
}


//高光分布
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

float helper_lambertian(float dotLN) 
{
    return saturate(dotLN) * diffuse_multiply ;
}




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
float helper_timepulse()
{
    if(GlowPeriod <= 0){return 1;};

    float phase = frac( Time / GlowPeriod ) ; // 保留小数部分， mod 1
    phase = abs(phase *2 -1) ;//或者平方？
    return phase ;
};


// smoothstep(min, max, x)  for point light range compute


/*
废弃代码


const float ambient_SKY_multiply =  1 ; //拟合天空盒的天空色亮度
const float ambient_GROUND_multiply =  0.75 ; //拟合天空盒的地面色亮度

const bool  skybox_lod_absolute = true ; //用绝对lod而非相对lod bias采样模糊天空盒
const bool  skybox_lod_logarithmic = true ; //是否根据粗糙度的log2修正天空盒mipmap偏移

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


//带有菲涅尔修正的漫反射，有四种算式可选
float helper_newdiffuse(float dotLN, float Reflectivity) 
{
    float lambertian = saturate(dotLN) ;
    float newlambertian = lambertian ;

    const int calculate_diffuse_type = 2 ; //是否直射光漫反射要被菲涅尔修正，及其精确度

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
};  //这个废弃了

*/