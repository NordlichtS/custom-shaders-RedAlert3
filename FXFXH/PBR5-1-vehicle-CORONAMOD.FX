//这个文件是用来编译的，包含了高画质的PIXEL SHADER 和technique部分
//  #pragma warning(disable: 3206)

#define ENV_CUSTOM
//#define USE_IRRADIANCE_BOX

#include "head3-vsps.FXH"



float MinRoughness //最低粗糙度（要用倒数更精确吗？）
<   string UIName = "MinRoughness"; //MAXglossiness
    float UIMax = 0.50; float UIMin = 0.005; float UIStep = 0.005; 
> ={ 0.125 }; 

float reflectivity_cutoff //非金属反射度的梯度，生效范围阈值为此值倒数
<   string UIName = "reflectivity_cutoff"; 
    float UIMax = 8; float UIMin = 0; float UIStep = 0.25; 
> = { 2 }  ; //小于1则对所有非金属生效，大于1则仅对很粗糙部位生效。此值越大，生效范围越窄

float GlowAmplitude //最大发光倍数，(如果写负数会怎样?)
<   string UIName = "GlowAmplitude"; 
    float UIMax = 8; float UIMin = 0; float UIStep = 0.25; 
> = 3 ; 


/*
// MAIN PBR PIXEL SHADER with tangent frame support
支持法线图，物理渲染，阴影柔和，8点光源全BRDF，天空盒，MAX预览
岚依的源码看懂了一部分，不过里面留下的教程链接还是很好的，我重写吧
参考教程：
freya holmer
acerola
知乎 
油管
*/

struct PS_H_input
{
    //float4 Position : POSITION;   //VS一定要输出的clip space渲染坐标
    float4 VertexColor : COLOR0;  //顶点颜色
    float4 MainTexUV  : TEXCOORD0; //XY是主帖图UV,ZW是建筑损伤图UV
    float4 ShadowCS : TEXCOORD1; //XYZ阴影空间投影, W弃用
    float4 FogCloudUV : TEXCOORD2; //迷雾和云的UV
    float3 WorldP : TEXCOORD3;  //世界空间位置
    float3 WorldN : TEXCOORD4_centroid; //世界法线Z
    float3 WorldT : TEXCOORD5_centroid; //世界切线Y
    float3 WorldB : TEXCOORD6_centroid; //世界切线X
};

float4 PS_H_PBR_CORONA (PS_H_input i) : COLOR 
{
  float4 OUTCOLOR = i.VertexColor; //安全起见先initialize

  //风格常数，编译前确定
    const float FresnelF0 = 0.125 ; //绝缘体菲涅尔效应F0，即反射角为0时高光亮度
    const float FresnelMetalF0 = 0.875 ; //金属的菲涅尔F0
    const float metalalbedo_mult = 1.25 ; //金属的反光亮度

    const float ambient_diff_mult =  1 ; //环境光与天空盒diffuse
    const float ambient_spec_mult =  1 ; //环境光与天空盒specular

    const float pointlight_mult =  1 ; //点光源整体亮度
    const float sunlight_mult =  1 ; //阳光亮度
    const float diffuse_mult =  1 ; //漫反射亮度，影响阳光与点光源
    const float specbase_mult =  0.5 ; //高光在最大粗糙度金属下的基础峰值亮度，影响阳光与点光源
    const bool  base_texture_gamma = true ; //是否对主贴图进行gamma修正



  //拿出主贴图
    float4 dif = tex2D(DiffuseTextureSampler,  i.MainTexUV.xy );
    float4 nrm = tex2D(NormalMapSampler,       i.MainTexUV.xy );
    float4 spm = tex2D(SpecMapSampler,         i.MainTexUV.xy );

  //初步整理下信息
    if(AlphaTestEnable) { clip(dif.w - 0.5);  clip(i.VertexColor.w - 0.25); };    
    float  HCchannel = (HasRecolorColors)? spm.b : 0 ;
    dif.xyz *= lerp(dif.xyz , RecolorColor , HCchannel);
 
    float  metalness = spm.y ;
    
    float  roughness = lerp(1, MinRoughness , spm.x ) ; //  (1 / MAXglossiness)  //MinRoughness
    float  glossiness = (1 / roughness) ; //OOA? SPECPEAK?

    float  dielectric_reflectivity = saturate(spm.x * reflectivity_cutoff) ;
    
    float3 speccolor = lerp( dielectric_reflectivity.xxx, (dif.xyz * metalalbedo_mult) , metalness);
    float  F0 = lerp(FresnelF0 , FresnelMetalF0, metalness);
    float3 difcolor = dif.xyz * (1 - metalness) ;

    float  AOchannel = nrm.w ;
    float  GLOWchannel = spm.w ; 
    float  CAVITYchannel = 1 ;
    // if(GlowAmplitude != 0)
    //GLOWchannel = (GlowAmplitude > 0)? spm.w : (1- spm.w) ;
    //CAVITYchannel = 1 - GLOWchannel ;
    float3 glowmapRGB = dif.xyz * GLOWchannel ; //发光图层，可能要加个闪烁. abs(GlowAmplitude) 


  //世界法线
    float3 N = i.WorldN ;
    //if(tangent_xy_mult != 0) { //是否从nrm贴图获取
    N.xyz = hp_normalmapper(nrm.xy, (-BumpScale)) ;
    float3x3 TangentSpaceToWorldMatrix = float3x3(i.WorldB, i.WorldT, i.WorldN) ;
    N = mul(N, TangentSpaceToWorldMatrix) ;
    //};
    N = normalize(N); //长度单位化，这一步很重要

  //世界空间的view vector，与目光反射
    float3 V = hp_ps_getViewVector(i.WorldP) ;
    float  EYEtilt = dot(V , N) ; //1= perpendicular view, 0= side view , -1=back
    float3 R = reflect(-V , N) ; //input light vector is towards fragment!
    //if(EYEtilt <0) {R = -V ;} ; //SHOULD I FIX IT ?

  //环境光相关 
    float3 skybox_color = getSKYBOXcolor(R, roughness, AOchannel);
    float3 irradiance_color = AmbientLightColor * AOchannel * AOchannel ; 
    //getIRRADIANCEcolor(N, AOchannel);

    float3 ambientALL = float3(0,0,0) ; //环境光BRDF
    //ambient DIFF
    ambientALL += irradiance_color * difcolor * ambient_diff_mult ; 
    //ambient SPEC
    ambientALL += skybox_color * speccolor * ambient_spec_mult * hp_fresnel(R, V, F0, 6); 

  //阳光相关  
    float3 Lsun     = DirectionalLight[0].Direction.xyz ;
    float3 SUNcolor = DirectionalLight[0].Color.xyz ;
    #if defined(_3DSMAX_)  //MAX预览阳光方向与颜色覆盖
    Lsun     = PV_SunlightDirection ; 
    SUNcolor = PV_SunlightColor ;
    #endif

    SUNcolor *= sunlight_mult ;
    float  sun_tilt  = dot(N,Lsun) ;
    SUNcolor *= hp_invshadow_single((i.ShadowCS.xyz / i.ShadowCS.w) , sun_tilt);
    //shadow helper also return 0 for backface, 1 for no shadow
    #ifndef _3DSMAX_ //高画质都有云和影子，但预览没有
    float3 cloudcolor = tex2D(CloudTextureSampler, i.FogCloudUV.zw);
    SUNcolor *= cloudcolor * cloudcolor ;
    #endif

    float3 sunALL = float3(0,0,0) ;  //阳光BRDF
    //sun diff
    sunALL += difcolor * sun_tilt * diffuse_mult ;
    //sun spec
    sunALL += speccolor * hp_specdist(glossiness, R, Lsun) * hp_fresnel(Lsun, V, F0, 4) * specbase_mult;
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
      //pl spec    // * hp_fresnel(PLL, V, F0, 2)
      thisBRDF += speccolor * hp_specdist(glossiness, R, PLL)  * specbase_mult ; 
      //pl color
      thisBRDF *= PLcolor * decaymult;

      PLtotal += thisBRDF ; //叠加所有点光源
    };
    PLtotal *= pointlight_mult ;


  //最终混色
    OUTCOLOR.xyz = ambientALL + sunALL + PLtotal ; //BRDF
    OUTCOLOR.xyz *= CAVITYchannel ;
    #ifndef _3DSMAX_ //预览没有迷雾
    OUTCOLOR.xyz *= tex2D(ShroudTextureSampler, i.FogCloudUV.xy).x ;
    #endif
    OUTCOLOR.xyz += glowmapRGB  * GlowAmplitude ; //* hp_timepulse()
    OUTCOLOR.xyz *= TintColor ;

    OUTCOLOR.w *= OpacityOverride * dif.w ;

    return OUTCOLOR;
};

//高画质PBR pixel shader结束====================

//start techniques=========================

#if defined(_3DSMAX_) //预览===========
technique MAX_PV_CORONA
{
    pass p0 // <string ExpressionEvaluator = "Objects";>
    {
        VertexShader = compile vs_3_0 VSforMAX(); 
        PixelShader  = compile ps_3_0 PS_H_PBR_CORONA();    
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
    }
}
#endif //预览结束==================

int VSchooserExpr() 
{    return clamp(NumJointsPerVertex, 0, 1) ; }

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

/*

typedef enum D3D BLEND 
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



*/