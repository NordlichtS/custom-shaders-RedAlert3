//#define _3DSMAX_
#pragma warning(disable: 3206)

#include "PBR3-vsps.FXH" //WILL INCLUDE EVERYTHING

float3 ground_color
< 
	string UIName = "PV_ground_color";
	string UIWidget = "Color";
	bool ExportValue = false;
> = { 0.3, 0.2, 0.1 };

float3 sky_color 
< 
	string UIName = "PV_sky_color";
	string UIWidget = "Color";
	bool ExportValue = false;
> = { 0.8, 0.9, 1.0 };

float METALthreshold255
<
    string UIName = "MetalThreshold255"; 
    float UIMax = 256; float UIMin = 0; float UIStep = 0.5; 
> = 20 ;


float3 MetalAlbedo 
< 
	string UIName = "MetalAlbedo";
	string UIWidget = "Color";
> = float3( 0.75, 0.75, 0.75 );

float MinRoughness
<
    string UIName = "MinRoughness"; 
    float UIMax = 1; float UIMin = 0.1; //float UIStep = 0.05; 
> = 0.33 ;


// #define BUILDING_DAMAGE 
// const bool building_damage = 0 ; 
//用这个控制编译时是否需要建筑损伤？

struct PS_H_input
{
    //float4 Position : POSITION;   //VS一定要输出的clip space渲染坐标
    float4 VertexColor : COLOR0;  //顶点颜色
    float4 MainTexUV  : TEXCOORD0; //XY是主帖图UV,ZW是建筑损伤图UV
    float3 ShadowPROJ : TEXCOORD1; //XYZ阴影空间投影, W弃用
    float4 FogCloudUV : TEXCOORD2; //迷雾和云的UV
    float3 WorldP : TEXCOORD3;  //世界空间位置
    float3 WorldN : TEXCOORD4_centroid; //世界法线Z
    float3 WorldT : TEXCOORD5_centroid; //世界切线Y
    float3 WorldB : TEXCOORD6_centroid; //世界切线X
};

float4 PS_H_GEN2MOD_SKETCH (PS_H_input i) : COLOR 
{
  float4 OUTCOLOR = i.VertexColor; //安全起见先initialize

  //风格常数，编译前确定

    const float ambient_diff_mult =  0.32 ; //环境光与天空盒diffuse
    const float ambient_spec_mult =  0.32 ; //环境光与天空盒specular

    const float pointlight_mult =  1 ; //点光源整体亮度
    const float sunlight_mult =  1 ; //阳光亮度
    const float diffuse_mult =  0.8 ; //漫反射亮度，影响阳光与点光源
    const float specbase_mult =  0.4 ; //高光在最大粗糙度金属下的基础峰值亮度，影响阳光与点光源

    const float GLASSthreshold255 = 12 ;
    const float FresnelF0 = 0.125 ;


  //拿出主贴图 (GEN 2 MOD )
    float4 dif = tex2D(DiffuseTextureSampler,  i.MainTexUV.xy );
    float4 nrm = tex2D(NormalMapSampler,       i.MainTexUV.xy );
    float4 spm = tex2D(SpecMapSampler,         i.MainTexUV.xy );

  //初步整理下信息 (GEN 2 MOD )
    // if(AlphaTestEnable) { clip(dif.w - 0.5);  clip(i.VertexColor.w - 0.25); }; 
    clip(dif.w - 0.5); 
    float  HCchannel = (HasRecolorColors)? spm.b : 0 ;
    dif.xyz *= lerp(dif.xyz , RecolorColor , HCchannel); //gamma修正的同时混合阵营色
    float4 colortone = hp_saturation_luminance(dif.xyz, 0.04);
 
    //float metalness = smoothstep(0.5 , 0.75 , spm.x) ;
    bool ismetal = bool(spm.x > (METALthreshold255 / 256) );
    bool isglass = bool(spm.y > (GLASSthreshold255 / 256) );
    //ismetal = (isglass)? false : ismetal ;
    
    float glossgradient = hp_ReverseLerp(0, METALthreshold255 , (spm.x * 256) ) ; 
    float roughness = lerp( 1, MinRoughness , glossgradient );
    roughness = (isglass)? 0.125 : roughness ;
    float  glossiness = (1 / roughness) ; //OOA? SPECPEAK?

    float3 difcolor = (ismetal || isglass)? 0 : dif.xyz ;
    difcolor *= dif.w * dif.w;
    float3 speccolor = (ismetal)? float3(1,1,1) : MetalAlbedo ;
    speccolor = (isglass)? colortone.xyz : speccolor ;
    float F0 = (ismetal)? 1 : FresnelF0 ;
    F0 = (isglass)? colortone.w : F0 ;

    float3 GlowMapRGB = dif.xyz * spm.y * spm.y ; 
    //发光图层，发光梯度为平方


  //世界法线
    float3 N = i.WorldN ;
    //if(tangent_xy_mult != 0) {
    N.xyz = hp_normalmapper(nrm.xy) ;
    float3x3 TangentSpaceToWorldMatrix = float3x3(i.WorldT, i.WorldB, i.WorldN) ;
    N = mul(N, TangentSpaceToWorldMatrix) ;
    //};
    N = normalize(N); //长度单位化，这一步很重要

  //世界空间的view vector，与目光反射
    float3 V = hp_ps_getViewVector(i.WorldP) ;
    //float  EYEtilt = dot(V , N) ; //1= perpendicular view, 0= side view , -1=back
    float3 R = reflect(-V , N) ; //input light vector is towards fragment!
    //if(EYEtilt <0) {R = -V ;} ; //SHOULD I FIX IT ?
    float3 Lsun     = DirectionalLight[0].Direction.xyz ;
    float3 SUNcolor = DirectionalLight[0].Color.xyz ;
    #if defined(_3DSMAX_)  //MAX预览阳光方向与颜色覆盖
    Lsun     = PV_SunlightDirection ; 
    SUNcolor = PV_SunlightColor ;
    #endif


  //环境光相关 
    float3 groundcolor = min(AmbientLightColor, min(DirectionalLight[1].Color , DirectionalLight[2].Color));
    float3 skyupcolor  = max(AmbientLightColor, max(DirectionalLight[1].Color , DirectionalLight[2].Color));
    skyupcolor *= hp_dynamic_cloud_reflection(i.FogCloudUV.zw ,  R,  Lsun);

    #if defined(_3DSMAX_)
    groundcolor = ground_color ; 
    skyupcolor = sky_color ;    
    #endif

    //float env_fresnel_term = pow( saturate(1 - EYEtilt) , 4 );
    //env_fresnel_term = (ismetal)? 1 : env_fresnel_term ;
    //float env_reflectivity =  glossgradient ; //修正环境光的反射度，其实相当于G term了
    //com f0 :  dielec=0.12, metal = 1 , glass = lumine
    //env f0 :  dielec = 0,  metal = 1 , glass = 0
    //float env_f0 = (ismetal )? 1 : 0 ; // turn 1 for metal only. glass still use 0
    
    float env_f0 = (ismetal || isglass )? F0 : 0 ;
    float env_f_term = hp_fresnel(R, V, env_f0) * glossgradient; 

    float3 skybox_color = hp_fake_skybox(groundcolor , skyupcolor , R.z , glossiness) ;
    float3 irradiance_color = hp_fake_irradiance(groundcolor, skyupcolor , N.z);

    float3 ambientALL = float3(0,0,0) ; //环境光BRDF
    //ambient DIFF
    ambientALL += irradiance_color * difcolor * ambient_diff_mult ; 
    //ambient SPEC
    ambientALL += skybox_color * speccolor * ambient_spec_mult * env_f_term ; 

  //阳光相关  

    SUNcolor *= sunlight_mult ;
    float  sun_tilt  = dot(N,Lsun) ;
    SUNcolor *= hp_invshadow_bilinear(i.ShadowPROJ.xyz , sun_tilt);
    //shadow helper also return 0 for backface, 1 for no shadow
    #ifndef _3DSMAX_ //高画质都有云，但预览没有
    SUNcolor *= tex2D(CloudTextureSampler, i.FogCloudUV.zw);
    #endif

    float3 sunALL = float3(0,0,0) ;  //阳光BRDF
    //sun diff
    sunALL += difcolor * sun_tilt * diffuse_mult ;
    //sun spec
    sunALL += speccolor * hp_specdist(glossiness, R, Lsun) * hp_fresnel(Lsun, V, F0) * specbase_mult;
    sunALL *= SUNcolor ;

  //点光源BRDF
    float3 PLtotal = float3(0,0,0) ;

    for (int itpl = 0; itpl < 8 && itpl < NumPointLights; itpl++ ) 
    {
      //if(itpl >= NumPointLights ){break;};

      float3 PLpos = PointLight[itpl].Position - i.WorldP ;
      float3 PLcolor = PointLight[itpl].Color ;
      float  PLrangeMAX = PointLight[itpl].Range_Inner_Outer.y * 2 ;
      float  PLrangeMIN = PointLight[itpl].Range_Inner_Outer.x ;

      #ifdef _3DSMAX_ //读取预览点光源数据
      PLpos = PV_pointlightPOS - i.WorldP; // relative!
      PLcolor = PV_pointlightCOLOR ; 
      PLrangeMAX = PV_pointlightRANGE ;
      PLrangeMIN = 0 ;
      #endif

      if(PLrangeMAX < 1) {continue;}; //排除无用的点光源
      float  PLdist = length(PLpos) ;
      if(PLdist >= PLrangeMAX) {continue;}; //排除太远的点光源
      float3 PLL = PLpos / PLdist ; //normalized light vector
      float  PLtilt = dot(PLL, N) ;
      if(PLtilt <= 0) {continue;}; //排除背光面

      float decaymult = (PLdist - PLrangeMAX) / (PLrangeMIN - PLrangeMAX);
      decaymult = saturate(decaymult * decaymult); //平方衰减看起来更自然

      float3 thisBRDF = float3(0,0,0) ;
      //pl diff
      thisBRDF += difcolor * PLtilt * diffuse_mult ; 
      //pl spec
      thisBRDF += speccolor * hp_specdist(glossiness, R, PLL) * hp_fresnel(PLL, V, F0) * specbase_mult ;
      //pl color
      thisBRDF *= PLcolor * decaymult;

      PLtotal += thisBRDF ; //叠加所有点光源
    };
    PLtotal *= pointlight_mult ;


  //最终混色
    OUTCOLOR.xyz = ambientALL + sunALL + PLtotal ; //BRDF
    //OUTCOLOR.xyz *= CAVITYchannel ;
    #ifndef _3DSMAX_ //预览没有迷雾
    OUTCOLOR.xyz *= tex2D(ShroudTextureSampler, i.FogCloudUV.xy) ;
    #endif
    OUTCOLOR.xyz += GlowMapRGB *  GlowAmplitude ; 
    OUTCOLOR.xyz *= TintColor ;

    OUTCOLOR.w *= OpacityOverride * dif.w ;

    return OUTCOLOR;
};

//高画质PBR pixel shader结束====================



#ifdef _3DSMAX_ //预览
technique GEN2max
{
    pass p0 <string ExpressionEvaluator = "Objects";>
    {
        VertexShader = compile vs_3_0 VSforMAX(); 
        PixelShader  = compile ps_3_0 PS_H_GEN2MOD_SKETCH();    
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        AlphaBlendEnable = 0 ;
        AlphaTestEnable = 0 ;
    }
}

#else

int VSchooserExpr() 
{    return clamp(NumJointsPerVertex, 0, 1) ; }


VertexShader VS_H_Array[2] = {
    compile vs_3_0 VS_H_00skin(), 
    compile vs_3_0 VS_H_11skin(), 
    //compile vs_3_0 VS_H_22skin(), 
};

technique Default
{    pass p0 <string ExpressionEvaluator = "Objects";>
  {
    VertexShader = VS_H_Array[ VSchooserExpr()  ]; 
    PixelShader = compile ps_3_0 PS_H_GEN2MOD_SKETCH(); 
    ZEnable = 1;
    ZFunc = 4;
    ZWriteEnable = 1;
    CullMode = 2;
    AlphaFunc = 7;
    AlphaRef = 32;
    //AlphaBlendEnable = (AlphaBlendEnable);
    AlphaTestEnable = 0;
  } 
}

technique Default_M
{    pass p0 <string ExpressionEvaluator = "Objects";>
  {
    VertexShader = VS_H_Array[ VSchooserExpr()  ]; 
    PixelShader = compile ps_3_0 PS_H_GEN2MOD_SKETCH(); 
    ZEnable = 1;
    ZFunc = 4;
    ZWriteEnable = 1;
    CullMode = 2;
    AlphaFunc = 7;
    AlphaRef = 32;
    //AlphaBlendEnable = (AlphaBlendEnable);
    AlphaTestEnable = 0;
  } 
}

/*
VertexShader VS_L_Array[2] = {
    compile vs_2_0 VS_L_00skin(), 
    compile vs_2_0 VS_L_11skin(), 
};



PixelShader PS_LM_Array[2] = {
  compile ps_2_0 PS_Objects_Low(false), //0 NO SHADOW
  compile ps_2_0 PS_Objects_Low(true),  //1 have 
};

technique Default_M
{    pass p0 <string ExpressionEvaluator = "Objects";>
  {
    VertexShader = VS_L_Array[ VSchooserExpr()  ]; 
    PixelShader  = PS_LM_Array[ int(HasShadow) ]; 
    ZEnable = 1;
    ZFunc = 4;
    ZWriteEnable = 1;
    CullMode = 2;
    AlphaFunc = 7;
    AlphaRef = 32;
    AlphaTestEnable = 0;
  } 
}

technique Default_L
{    pass p0 <string ExpressionEvaluator = "Objects";>
  {
    VertexShader = VS_L_Array[ VSchooserExpr()  ]; 
    PixelShader  = PS_LM_Array[ 0 ]; 
    ZEnable = 1;
    ZFunc = 4;
    ZWriteEnable = 1;
    CullMode = 2;
    AlphaFunc = 7;
    AlphaRef = 32;
    AlphaTestEnable = 0;
  } 
}
*/

VertexShader VS_Shadow_Array[2] = {
    compile vs_2_0 VS_ShadowMaker_00skin(), 
    compile vs_2_0 VS_ShadowMaker_11skin(), 
    //compile vs_2_0 VS_ShadowMaker_22skin(), 
};

technique _CreateShadowMap
{    pass p0    {
    VertexShader = VS_Shadow_Array[ VSchooserExpr()  ]; 
    PixelShader = compile ps_2_0 PS_ShadowMaker_Simple();
    ZEnable = 1;
    ZFunc = 4;
    ZWriteEnable = 1;
    CullMode = 2;
    AlphaBlendEnable = 0;
    AlphaTestEnable = 0;
} }

#endif

//
/*

typedef enum D3DBLEND 
  D3DBLEND_ZERO             = 1,
  D3DBLEND_ONE              = 2,
  D3DBLEND_SRCCOLOR         = 3,
  D3DBLEND_INVSRCCOLOR      = 4,
  D3DBLEND_SRCALPHA         = 5,
  D3DBLEND_INVSRCALPHA      = 6,
  D3DBLEND_DESTALPHA        = 7,
  D3DBLEND_INVDESTALPHA     = 8,
  D3DBLEND_DESTCOLOR        = 9,
  D3DBLEND_INVDESTCOLOR     = 10,
  D3DBLEND_SRCALPHASAT      = 11,
  D3DBLEND_BOTHSRCALPHA     = 12,
  D3DBLEND_BOTHINVSRCALPHA  = 13,
  D3DBLEND_BLENDFACTOR      = 14,
  D3DBLEND_INVBLENDFACTOR   = 15,
  D3DBLEND_SRCCOLOR2        = 16,
  D3DBLEND_INVSRCCOLOR2     = 17,
  D3DBLEND_FORCE_DWORD      = 0x7fffffff
source color is the color of the pixel that is being drawn,
destination color is the color of the pixel that was behind the one drawn.

typedef enum D3DCULL 
  D3DCULL_NONE         = 1, Do not cull back faces.
  D3DCULL_CW           = 2, Cull back faces with clockwise vertices.
  D3DCULL_CCW          = 3, Cull back faces with counterclockwise vertices.
default cullmode = 2

technique Default
{
    pass p0
    {
        VertexShader = VS_H_Array[Default_Expression27()]; 
        PixelShader = PS_H_Array[Default_Expression26()]; 
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        AlphaBlendEnable = 0;
        AlphaFunc = 7;
        AlphaRef = 96;
        AlphaTestEnable = 1;
    }
}
technique Default_M
{
    pass p0
    {
        VertexShader = VS_M_Array[Default_M_Expression25()]; 
        PixelShader = PS_M_Array[Default_M_Expression24()]; 
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        AlphaBlendEnable = 0;
        AlphaFunc = 7;
        AlphaRef = 96;
        AlphaTestEnable = 1;
    }
}
technique Default_L
{
    pass p0
    {
        VertexShader = VS_L_Array[Default_L_Expression23()]; 
        PixelShader = <PS_L_Array[0]>; 
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        AlphaBlendEnable = 0;
        AlphaFunc = 7;
        AlphaRef = 96;
        AlphaTestEnable = 1;
    }
}
technique _CreateShadowMap
{
    pass p0
    {
        VertexShader = VSCreateShadowMap_Array[_CreateShadowMap_Expression22()]; 
        PixelShader = PSCreateShadowMap_Array[_CreateShadowMap_Expression21()]; 
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        AlphaBlendEnable = 0;
        AlphaTestEnable = 0;
    }
}

*/