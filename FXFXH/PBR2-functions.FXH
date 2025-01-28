//all the helper functions



//#include "PBR1-constants.FXH"  //shader通用的

#include "PBR1-maxui.FXH"  //可调的材质 


//常用常量，与确定的风格参数===================
//并非所有都有用


/*  
=======================================



=============================
*/

//VS==================================

// 通过四元数来计算旋转的函数，来自 CNC3 的 Skinning.fxh
float3 QuaternionRotate(float4 rotation, float3 position) 
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
}; 

float3x3 Quaternion2Matrix(float4 Quaternion)
{
    float3 basisX = QuaternionRotate(Quaternion, float3(1,0,0));
    float3 basisY = QuaternionRotate(Quaternion, float3(0,1,0));
    float3 basisZ = QuaternionRotate(Quaternion, float3(0,0,1));
    return float3x3(basisX, basisY, basisZ);
}


//直接在PS里算的VIEW
float3 hp_ps_getViewVector(float3 WorldPosition) 
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
float3 getShadowMapUV(float4 WorldPosition) 
{
    if(! HasShadow){return float3(0,0,-1);};

    float4 shadowMapCoordinates = mul(WorldPosition, ShadowMapWorldToShadow);
    shadowMapCoordinates.xyz /= shadowMapCoordinates.w;
    // shadowMapCoordinates.z -= 1.0/256 ; // BIAS moved to PS function
    return shadowMapCoordinates.xyz;
};



float3 intersectOnHorizon(float3 pointA, float3 pointB, float planeheight)
{
    float slope = (planeheight - pointA.z) / (pointB.z - pointA.z);
    float3 intersectXYZ = pointA + slope * (pointB - pointA);
    return intersectXYZ;
}




float avoidzero(float inputfloat)
{    return max(inputfloat, (1.0/4096.0));};


//灯光闪烁
float hp_secondpulse()
{
    return abs( frac(Time) * 2 -1) ;
};


float hp_ReverseLerp(float sidemin, float sidemax, float invalue)
{
    float lerpw = (invalue - sidemin)/(sidemax - sidemin) ;
    return saturate(lerpw) ;
};

float hp_cubic_hermit(float invalue)
{
    float inx = invalue ; // saturate(invalue); no saturate!
    return ( (3.0 - 2 * inx) * inx * inx );
};

float hp_steep_transition( float invalue, float centerpoint, float margin)
{
    float inx = invalue - centerpoint ;
    inx = inx / margin * 0.5 + 0.5 ;
    return saturate(inx) ;
};

float hp_round_transition( float invalue, float centerpoint, float margin)
{
    float edges = (invalue < centerpoint)? 0 : 1 ;
    float lerpw = saturate( abs(invalue - centerpoint) / margin ) ;
    return lerp(invalue , edges , lerpw ) ;
}




//PS===================================

//柔和阴影


float hp_invshadow_bilinear ( float3 SMUV, float sun_tilt ) 
{ 
    if(sun_tilt <= 0) {return 0;};
    if(! HasShadow)   {return 1;}; 

    float2 SM01T = float2(0, Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w);
    float2 UVlerpw = frac(SMUV.xy / SM01T.y);
    float object_depth = SMUV.z - SM01T.y * 2;//(3- 2* sun_tilt) ; //  1.0 / 512.0 ;
    //tbd : use suntilt to fix side offset

    float4 fourSamples = float4(   //四个角的阴影图深度
        tex2D(ShadowMapSampler, (SMUV.xy + SM01T.xx)).x ,
        tex2D(ShadowMapSampler, (SMUV.xy + SM01T.xy)).x ,
        tex2D(ShadowMapSampler, (SMUV.xy + SM01T.yx)).x ,
        tex2D(ShadowMapSampler, (SMUV.xy + SM01T.yy)).x 
    );  // LU,LD,RU,RD (00,01,10,11) 
    bool4 fourTests = (fourSamples > object_depth) ; //阴影比物体离阳光更远，则有阳光
    fourSamples = (float4)fourTests ;
    //双线性插值
    float2 bilinearLR = lerp(fourSamples.xy , fourSamples.zw , UVlerpw.x);
    float  bilinearUD = lerp(bilinearLR.x   , bilinearLR.y   , UVlerpw.y);
    float lightmid = hp_cubic_hermit(bilinearUD) ; //* bilinearUD;

    return lightmid ;
}

float hp_invshadow_underground ( float3 SMUV, float sun_tilt, float MicroShadowBias , bool welledgeNoSunlight ) 
{ 
    if(welledgeNoSunlight) {return 0;};
    if(sun_tilt <= 0) {return 0;};
    if(! HasShadow)   {return 1;}; 

    float2 SM01T = float2(0, Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w);
    float2 UVlerpw = frac(SMUV.xy / SM01T.y);
    float object_depth = SMUV.z + MicroShadowBias ;
    //tbd : use suntilt to fix side offset

    float4 fourSamples = float4(   //四个角的阴影图深度
        tex2D(ShadowMapSampler, (SMUV.xy + SM01T.xx)).x ,
        tex2D(ShadowMapSampler, (SMUV.xy + SM01T.xy)).x ,
        tex2D(ShadowMapSampler, (SMUV.xy + SM01T.yx)).x ,
        tex2D(ShadowMapSampler, (SMUV.xy + SM01T.yy)).x 
    );  // LU,LD,RU,RD (00,01,10,11) 
    bool4 fourTests = (fourSamples > object_depth) ; //阴影比物体离阳光更远，则有阳光
    fourSamples = (float4)fourTests ;
    //双线性插值
    float2 bilinearLR = lerp(fourSamples.xy , fourSamples.zw , UVlerpw.x);
    float  bilinearUD = lerp(bilinearLR.x   , bilinearLR.y   , UVlerpw.y);
    float lightmid = hp_cubic_hermit(bilinearUD) ; //* bilinearUD;

    return lightmid ;
}


float hp_invshadow_single ( float3 ShadowProjection, float sun_tilt )  
{
    if(sun_tilt <= 0) {return 0;};
    if(! HasShadow)   {return 1;}; 

    float3 realShadowUV = float3(0.5, 0.5, -2) 
    * Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w 
    + ShadowProjection.xyz ;
    float ShadowDepth = tex2D(ShadowMapSamplerLinear, realShadowUV.xy);
    //tex2D(ShadowMapSampler, ShadowProjection.xy);
    //tex2Dlod(ShadowMapSampler, float4(ShadowProjection.xy, 0, 0) );
    float NOTshadow = (ShadowDepth < realShadowUV.z) ? 0 : 1 ;

    return NOTshadow ;
}

float hp_invshadow_easy ( float3 ShadowProjection )  
{
    float3 realShadowUV = float3(0.5, 0.5, -4) 
    * Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w 
    + ShadowProjection.xyz ;
    float ShadowDepth = tex2D(ShadowMapSamplerLinear, realShadowUV.xy);
    float NOTshadow = (ShadowDepth < realShadowUV.z) ? 0 : 1 ;

    return NOTshadow ;
}


float3 hp_dynamic_cloud_reflection(float2 pixelcloudUV, float3 R, float3 Lsun)
{
  #ifdef _3DSMAX_
    return float3(1,1,1);
  #endif
    float2 UVbias = R.xy / R.z -  Lsun.xy / Lsun.z ;
    UVbias += pixelcloudUV ;
    float3 cloudcolor = tex2D(CloudTextureSampler, UVbias);
    float3 skycolor_multplier = lerp( 1, cloudcolor, saturate(R.z) );
    skycolor_multplier *= skycolor_multplier ; //gamma
    return skycolor_multplier ;
}


//#ifdef ENV_CUSTOM
float3 getSKYBOXcolor (float3 reflectedView, float roughness, float AOchannel) 
{
    // float  mirAO = saturate(AOchannel * glossiness);  //天空盒镜面反射的AO
    // float  lod_before_log = pow(2, max_skybox_mip_level);
    //float max_skybox_miplevel_exp2 = 64 ; //最大粗糙度时使用的天空盒mipmap偏移

    float  skybox_lodbias = log2(roughness * 64) ; // max 0 ? log2 ?
    float4 skyboxUV = float4(reflectedView , skybox_lodbias); //根据粗糙度的对数算mipmap偏移数
    float3 skybox_color = texCUBElod(EnvironmentTextureSampler, skyboxUV); 
    // texCUBEbias ? texCUBElod 

    return skybox_color * AOchannel;
}
//#endif


float3 getIRRADIANCEcolor (float3 N, float AOchannel) 
{
    float difAO = AOchannel * AOchannel ;

    //  if(use_irradiance_box)
    // { return     texCUBE(IrradianceTextureSampler, N) * difAO ;    };

    //没有辐照贴图就拟合一个
    float3 nomap_irradiance = AmbientLightColor ;

    float downwarddecay = saturate(N.z + 1.125) ;
    nomap_irradiance *= min(difAO , downwarddecay) ; //真的要么

    return nomap_irradiance;
}

float2 alignScreenTextureUV(float2 vpos, float2 texsize)
{    return (vpos + 0.5) / texsize ;}



//高光分布
float hp_specdist(float glossiness, float3 R, float3 L)
{
    float cosRL = dot(R,L) ;  //no need saturate
    //float OOA = glossiness * glossiness ; //one over alpha
    // cosRL * OOA - OOA +1 ;
    //square curve is similar to cosine within half period
    float specdist = (cosRL -1) * glossiness * glossiness + 1 ;
    specdist = saturate(specdist);
    specdist *= specdist ; //smooth tail
    specdist *= glossiness ; //concentraited brightness

    return  specdist ; //spec multiply is not here
}

float hp_specdist_patch(float glossiness, float3 R, float3 L) //glossiness as OOA
{
    float specdist = dot(R,L) * glossiness - glossiness + 1 ;
    specdist = saturate(specdist);
    specdist = pow(specdist, 2) ; //smooth tail
    specdist *= glossiness ; 
    return  specdist ; //spec multiply is not here
}

float hp_specdist_simple(float3 R, float3 L)
{
    float cosRL = dot(R,L) * 0.5 + 0.5 ;
    float specdist = pow(cosRL , 8) ;
    return specdist ;
}

float hp_specdist_power(int exponent, float3 R, float3 L)
{
    float cosRL = saturate(dot(R,L));
    float specdist = pow(cosRL , exponent) ;
    return specdist ;
}

//基于目光与光源，而不是半程向量的菲涅尔效应，曲线更柔和
float hp_fresnel(float3 L, float3 V, float F0, int exponent)
{
    float lerpw = dot( L , -V ) * 0.5 + 0.5 ;
    lerpw = pow (lerpw, exponent); //8 ? 6?
    float fresnelLV = lerp(F0, 1, lerpw);
    return fresnelLV ;
};



//用法线图XY算出Z向量
float3 hp_normalmapper(float2 TEXtangent, float tangent_xy_mult) 
{
    float3 nrm = float3(TEXtangent ,1 ) ;
    nrm.xy = nrm.xy * 2 -1 ;
    nrm.xy *= tangent_xy_mult ;
    //float tiltradius = dot(nrm.xy, nrm.xy);
    //nrm.z = saturate(2 - tiltradius ) ; 
    return nrm ;
};

float3 hp_getAccentLight ()
{
    float3 biggeraccent = max(DirectionalLight[1].Color , DirectionalLight[2].Color);
    #if defined(_3DSMAX_)
    biggeraccent = PV_accentlight ;
    #endif
    return biggeraccent ;
}


float3 hp_fake_irradiance( float3 groundcolor, float3 skycolor, float NZ)
{
    float lerpw = NZ * 0.5 + 0.5 ; // *0.5 ? 0.45 ?
    return lerp(groundcolor, skycolor, lerpw);
}

float3 hp_fake_skybox( float3 groundcolor, float3 skycolor, float RZ, float glossiness)
{
    float lerpw = saturate(RZ * glossiness  + 0.5 ); 
    return lerp(groundcolor, skycolor, lerpw);
}
    
    

float4 hp_new_damage_mix( float2 dmgUV, float bonealpha)
{
    //if(bonealpha > 0.5){return float4(0,0,1,1);};

    float4 dmgtex = 1;
  #ifdef IS_BUILDNG
    dmgtex = tex2D(DamagedTextureSampler , dmgUV);
  #endif
    dmgtex = (bonealpha < 0.375)? dmgtex : 1 ;

    float burnred = 1 - dmgtex.w  ; //max 0.625
    float burngreen = pow(burnred, 3) *2 ; 
    float darken = dmgtex.g ;//no square
    float alphamult = dmgtex.w ;//(dmgtex.w > 0.375)? 1 : dmgtex.w ;
    float4 alldmg = float4(burnred, burngreen, darken, alphamult);

    return alldmg ;
} //clip w-0.125  -> mult z  -> plus xy, 


float PLdecayfactor(float rangeMIN, float rangeMAX, float rangeTHIS )
{
    float dist_to_outer = rangeMAX - rangeTHIS ;
    float decayfull = dist_to_outer / rangeMAX ;
    float decayshort = dist_to_outer / (rangeMAX - rangeMIN) ;
    decayshort = pow( decayshort, 3);

    return min(decayfull, decayshort) ;
}

float4 hp_saturation_luminance(float3 inputcolor, float margin)
{   
    float3 colortone = inputcolor + margin ;
    float brightness = dot(colortone , 1) / 3;
    colortone /= brightness ;
    //brightness -= margin ;
    return float4(colortone, brightness);
}

float3 hp_getColorTone(float3 inputcolor)
{   
    float3 colortone = inputcolor + (8.0 / 256) ;
    float brightness = dot(colortone , 1) / 3;
    colortone /= brightness ;
    return colortone;
}



float4 hp_stealthVFX (float EYEtilt, float3 texcolor, float otheralpha, float vpos, float3 realHC)
{
    float fresnel = saturate(1- EYEtilt)  ;
    bool scanline = frac(vpos / 3 ) < 0.25; // + Time
    float3 edgemask = (scanline)? fresnel : pow(fresnel, 4) ;
    edgemask *= realHC ;

    float4 OUTCOLOR ;
    OUTCOLOR.xyz = texcolor * 0.5 + edgemask * (1.5 - OpacityOverride) ;
    OUTCOLOR.w = OpacityOverride;// * otheralpha ;
    return OUTCOLOR ;
}

half hp_nano_build(float bonealpha, half2 texUV)
{
    half2 gridint = abs(texUV) * 32 ;
    half2 gridfrac = frac(gridint);
    gridint -= gridfrac ;
    gridfrac = abs(gridfrac -0.5) ;

    float dist2grid = gridfrac.x + gridfrac.y ;
    float currentscan = (1- bonealpha) * 32 * 32;
    float lineup =  gridint.y * 32 + gridint.x + dist2grid * 16 ;
    float scanalpha = (lineup - currentscan) /16  ;
    //scanalpha = max(saturate(scanalpha), saturate(1 - dist2grid * 16));
    return saturate(scanalpha ) ;
}

/* 
==================================
废弃代码===========================


float hp_invshadow_dither ( float3 ShadowProj, float sun_tilt, float2 vpos ) 
{
    if(sun_tilt <= 0) {return 0;};
    if(! HasShadow)   {return 1;}; 

    bool2 ditherblock = frac(vpos / 2) < 0.25 ;
    float2 SM01T = float2(0, Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w);
    float2 UVlerpw = frac(ShadowProj.xy / SM01T.y);
    float object_depth = ShadowProj.z - 1.0 / 512.0 ;
    float2 SMUV = (ditherblock)? +1 : -1 ;
    SMUV = SMUV * SM01T.y + ShadowProj.xy ;

    float4 fourSamples = float4(   //四个角的阴影图深度
        tex2D(ShadowMapSampler, (SMUV.xy + SM01T.xx)).x ,
        tex2D(ShadowMapSampler, (SMUV.xy + SM01T.xy)).x ,
        tex2D(ShadowMapSampler, (SMUV.xy + SM01T.yx)).x ,
        tex2D(ShadowMapSampler, (SMUV.xy + SM01T.yy)).x 
    );  // LU,LD,RU,RD (00,01,10,11) 
    bool4 fourTests = (fourSamples > object_depth) ; //阴影比物体离阳光更远，则有阳光
    fourSamples = (float4)fourTests ;
    //双线性插值
    float2 bilinearLR = lerp(fourSamples.xy , fourSamples.zw , UVlerpw.x);
    float  bilinearUD = lerp(bilinearLR.x   , bilinearLR.y   , UVlerpw.y);

    return bilinearUD ;
}


// static float phase = abs( frac(Time) *2 -1) ; //有用吗


// smoothstep(min, max, x)  for point light range compute

float smoothstep(float min, float max, float x) //需要把这个拆成两部分做成函数！
{
    // Clamp x to the [min, max] range
    x = saturate((x - min) / (max - min));

    // Apply cubic Hermite interpolation
    return x * x * (3.0 - 2.0 * x);
}

const float ambient_SKY_mult =  1 ; //拟合天空盒的天空色亮度
const float ambient_GROUND_mult =  0.75 ; //拟合天空盒的地面色亮度

const bool  skybox_lod_absolute = true ; //用绝对lod而非相对lod bias采样模糊天空盒
const bool  skybox_lod_logarithmic = true ; //是否根据粗糙度的log2修正天空盒mipmap偏移

float hp_invshadow_cross ( float3 ShadowProjection, float sun_tilt )  
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

float hp_invshadow_array ( float3 ShadowProjection, float sun_tilt )  
{
    if(sun_tilt <= 0) {return 0;};
    if(! HasShadow)   {return 1;}; 

    const float texelX[9] = {0, -1.2, +1.2,    0,    0, -0.8, +0.8, -0.8, +0.8} ;
    const float texelY[9] = {0,    0,    0, -1.2, +1.2, -0.8, -0.8, +0.8, +0.8} ;

    float2 ThisShiftUV; float ShadowDepth ; float ShadowDensity = 0 ; // int countSAMPLES ;

    for(int sc = 0; sc < 5; sc++) //这个用来调采样数
    {
        ThisShiftUV = float2(texelX[sc], texelY[sc]) 
        * Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w 
        + ShadowProjection.xy ;

        ShadowDepth = tex2Dlod(ShadowMapSamplerLinear, float4(ThisShiftUV, 0, 0) );
        // tex2D(ShadowMapSampler, ThisShiftUV);
        // tex2Dlod(ShadowMapSampler, float4(ThisShiftUV, 0, 0) );
        ShadowDensity += (ShadowDepth < ShadowProjection.z) ? 1 : 0 ;
    };
    ShadowDensity /= 5 ; //这个也是采样数
    return 1- ShadowDensity;
}



//通过粗糙度算更有用的光滑度
float hp_glossiness(float roughmap)
{
    float roughness ;
    if(SimpleRoughness)
    {roughness = max(MinRoughness, roughmap); }
    else
    {roughness = lerp(MinRoughness, 1, roughmap); };
    float glossiness = 1 / roughness ; //one over roughness, not alpha
    return glossiness ; //min 1 , max 10 (input 0.1)
};



float hp_specdist_new(float OOA, float specpeak, float3 R, float3 L)
{
    //float specpeak = glossiness * specbase_mult;
    float cosRL = dot(R,L);
    cosRL = saturate(cosRL);
    //float OOA = glossiness * glossiness ; //one over alpha
    //square curve is similar to cosine within half period
    float specdist = cosRL * OOA - OOA +1 ;
    specdist = saturate(specdist);
    specdist = pow(specdist , 2 ); //smooth tails
    //float peakbrightness = glossiness * specbase_mult ; 
    //specdist *= peakbrightness ;
    return specdist  ;
};


//带有菲涅尔修正的漫反射，有四种算式可选
float hp_newdiffuse(float dotLN, float Reflectivity) 
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

    return newlambertian * diffuse_mult; //最低精确度的
};  //这个废弃了

*/