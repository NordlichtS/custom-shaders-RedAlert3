//#define _3DSMAX_
 #define DYNAMIC_CLOUD_REF
// #define IGNORE_NRM
// #define FORBID_PIPELINE_CONSTANT
// #define USE_ROUGHNESS_CURVE
// #define ALLOW_CLIP_TEXTURE_ALPHA //always on except nano buildup
// dont change any above

 #define ALLOW_CLIP_VERTEX_ALPHA //all objects shader
// #define IS_BUILDNG //only damage
// #define SPMG_GLOWPULSE
// #define CAN_HAVE_HC
// #define ALLOW_STEALTH
// #define IS_NANO_BUILDUP  


/*
fxc.exe /O2 /T fx_2_0 /Fo   objectsgeneric.fxo   PBR5-6-objects-PATCH.FX
fxc.exe /O2 /T fx_2_0 /Fo   buildingsgeneric.fxo   PBR5-6-objects-PATCH.FX

fxc.exe /O2 /T fx_2_0 /Fo   buildingsjapanbuildup.fxo   PBR5-6-objects-PATCH.FX

fxc.exe /O2 /T fx_2_0 /Fo   buildingsallied.fxo   PBR5-6-objects-PATCH.FX
fxc.exe /O2 /T fx_2_0 /Fo   buildingsjapan.fxo   PBR5-6-objects-PATCH.FX
fxc.exe /O2 /T fx_2_0 /Fo   buildingssoviet.fxo   PBR5-6-objects-PATCH.FX

fxc.exe /O2 /T fx_2_0 /Fo   objectsallied.fxo   PBR5-6-objects-PATCH.FX
fxc.exe /O2 /T fx_2_0 /Fo   objectsjapan.fxo   PBR5-6-objects-PATCH.FX
fxc.exe /O2 /T fx_2_0 /Fo   objectssoviet.fxo   PBR5-6-objects-PATCH.FX


*/
//#pragma warning(disable: 3206)

#include "PBR3-vsps.FXH" //WILL INCLUDE EVERYTHING


struct PS_H_input
{
    float2 vpos : VPOS ; //screen pixel 
    float4 VertexColor : COLOR0;  //顶点颜色
    float3 CoordOBJ  : COLOR1; 
    float4 MainTexUV  : TEXCOORD0; //XY是主帖图UV,ZW是建筑损伤图UV
    float3 ShadowPROJ : TEXCOORD1; //XYZ阴影空间投影, W弃用
    float4 FogCloudUV : TEXCOORD2; //迷雾和云的UV
    float3 WorldP : TEXCOORD3;  //世界空间位置
    float3 WorldN : TEXCOORD4_centroid; //世界法线Z
    float3 WorldT : TEXCOORD5_centroid; //世界切线Y
    float3 WorldB : TEXCOORD6_centroid; //世界切线X
};

float4 PS_H_PATCH (PS_H_input i) : COLOR 
{
  float4 OUTCOLOR = float4(0,0,0,1); //安全起见先initialize
  

  //风格常数，编译前确定

    const float ambient_diff_mult =  0.5 ; //环境光与天空盒diffuse
    const float ambient_spec_mult =  1 ; //环境光与天空盒specular

    float  temp1 ;
    float2 temp2 ;
    float3 temp3 ;
    float4 temp4 ;
    /*
    const float pointlight_mult =  1 ; //点光源整体亮度
    const float sunlight_mult =  1 ; //阳光亮度
    const float diffuse_mult =  1 ; //漫反射亮度，影响阳光与点光源
    */


  //拿出主贴图 (GEN 2 MOD )
    float4 dif = tex2D(DiffuseTextureSampler,  i.MainTexUV.xy );
    float4 nrm = tex2D(NormalMapSampler,       i.MainTexUV.xy );
    float4 spm = tex2D(SpecMapSampler,         i.MainTexUV.xy );
    //if(AlphaTestEnable) {clip(dif.w - 0.375); };


  //有用的向量
    float3 N = float3(0,0,1); 
  #ifdef IGNORE_NRM
    N = i.WorldN;
  #else
    N.xy = (nrm.xy * 2 - 1 )  ;
    N.xy *= -BumpScale ;
    float3x3 TangentSpaceToWorldMatrix = float3x3(i.WorldB, i.WorldT, i.WorldN) ; //T B exchanged!
    N = mul(N, TangentSpaceToWorldMatrix) ;
  #endif
    N = normalize(N); //长度单位化，这一步很重要

    float3 V = hp_ps_getViewVector(i.WorldP) ;
    float3 R = reflect(-V , N) ; //input light vector is towards fragment!
    float  EYEtilt = dot(V , N) ;
    R = (EYEtilt <0) ? -V : R ;
    //if(EYEtilt <0) {R = -V ;} ;

    float3 Lsun     = DirectionalLight[0].Direction.xyz ;
    float3 SUNcolor = DirectionalLight[0].Color.xyz ;
  #ifdef _3DSMAX_  //MAX预览阳光方向与颜色覆盖
    Lsun     = PV_SunlightDirection ; 
    SUNcolor = PV_SunlightColor ;
  #endif


  //条件编译功能
    float3 realHC = (HasRecolorColors)? RecolorColor : 1 ;
    float3 hcmask = 1 ;
  #ifdef CAN_HAVE_HC
    hcmask = lerp(1 , realHC, spm.b) ;
    dif.xyz *= lerp(dif.xyz , 1 , spm.b); //gamma without hc
    dif.xyz *= hcmask * hcmask;
  #else
    dif.xyz*= dif.xyz ;
  #endif

    float3 GlowMapRGB = 0 ;
  #ifdef SPMG_GLOWPULSE
    GlowMapRGB = RecolorColor * spm.g  ;
    GlowMapRGB *= (HasRecolorColors)? 2 : 0;
    float GlowAmplitude = Time /2 + i.MainTexUV.x ;//* dot(TintColor, 1) ;
    GlowAmplitude = abs(frac(GlowAmplitude) * 2 -1) ;
    GlowMapRGB *= saturate(GlowAmplitude *8 -7); //pow(GlowAmplitude, 8) ;
    GlowMapRGB *= dot(TintColor, TintColor);
  #endif

    //clipping affected ! ===========
  #ifndef IS_NANO_BUILDUP
  //#ifdef ALLOW_CLIP_VERTEX_ALPHA
    OUTCOLOR.w *= i.VertexColor.w ;
  #endif

  #ifdef ALLOW_CLIP_TEXTURE_ALPHA
    OUTCOLOR.w *= dif.w ;
  #endif

    float4 buildingDMG = float4(0,0,1,1);
  #ifdef IS_BUILDNG //建筑损伤
    buildingDMG = hp_new_damage_mix(i.MainTexUV.zw , i.VertexColor.w );
    OUTCOLOR.w *= buildingDMG.w ;
  #endif

  #ifdef ALLOW_STEALTH
    //float4 stealthoutput = hp_stealthVFX(EYEtilt, dif.xyz , 1, i.vpos.y, realHC);
    if(OpacityOverride < 0.985) //stealth
    {return hp_stealthVFX(EYEtilt, dif.xyz , 1, i.vpos.y, realHC);};
  #else
    OUTCOLOR.w *= OpacityOverride ;
  #endif

    half nanobuildupMASK = 1;
  #ifdef IS_NANO_BUILDUP
    nanobuildupMASK = hp_nano_build(i.VertexColor.w, i.MainTexUV.xy);
    clip(nanobuildupMASK - 0.375); 
  #else
    if(AlphaTestEnable){clip(OUTCOLOR.w - 0.375);}
  #endif


  //还原通道信息 ========================
    
    float glossiness = spm.r * 7 + 1  ; //
    float specbase_mult = 0.25; //1.5 * 0.125 ?
    float horizon_extra_sharp = 0.5 ;

    float metalness = smoothstep(0.5 , 0.75 , (spm.r + spm.g)) ;
    float4 colortone = hp_saturation_luminance(dif.xyz, 0.0625 );

    float3 diffcolor = dif.xyz * (1 - metalness);
    diffcolor *= buildingDMG.b ; //haha
    float3 speccolor = lerp(1, colortone.rgb, metalness )  ; //?

    float f0_dir = spm.r ;
    float f0_env = colortone.w * metalness ;

  #ifdef USE_ROUGHNESS_CURVE
    glossiness = 1/ saturate(1 - spm.r + 0.125) ; //one over roughness
    f0_dir = saturate(spm.r *1.5 + spm.g) ;
    horizon_extra_sharp = 0.75 ;
  #endif 

  //BRDF=========================================

  //环境光相关 
    float3 cloudReflectionMultipler = hp_dynamic_cloud_reflection(i.FogCloudUV.zw, R, Lsun)  ; //需要阳光信息
    cloudReflectionMultipler = lerp(1 , cloudReflectionMultipler, metalness ) ;

    //float3 groundcolor = AmbientLightColor;
    float3 skycolor  = hp_getAccentLight() ;

    float3 irradi_color = hp_fake_irradiance(0, skycolor , N.z) + AmbientLightColor ;
    float3 skybox_color = hp_fake_skybox(0 , skycolor , R.z , (glossiness * horizon_extra_sharp)) + AmbientLightColor ; 
  #ifdef DYNAMIC_CLOUD_REF
    skybox_color *= cloudReflectionMultipler ;
  #endif

    float env_f_term = hp_fresnel(R, V, f0_env, 6);  
 
    float3 ambientALL = float3(0,0,0) ; //环境光BRDF
    //ambient DIFF
    ambientALL += irradi_color * diffcolor * ambient_diff_mult ; 
    //ambient SPEC
    ambientALL += skybox_color * speccolor * ambient_spec_mult * env_f_term * max(spm.r, spm.g); 

  //阳光相关  

    float  sun_tilt  = dot(N,Lsun) ;
    SUNcolor *= hp_invshadow_bilinear(i.ShadowPROJ.xyz , sun_tilt) ;
    // hp_invshadow_dither(i.ShadowPROJ.xyz , sun_tilt, i.vpos);
    //shadow helper also return 0 for backface, 1 for no shadow
  #ifndef _3DSMAX_ //高画质都有云，但预览没有
    float3 cloudcolor = tex2D(CloudTextureSampler, i.FogCloudUV.zw);
    SUNcolor *= cloudcolor * cloudcolor ;
  #endif

    float3 sunALL = float3(0,0,0) ;  //阳光BRDF
    //sun diff
    sunALL += diffcolor * sun_tilt ; //* diffuse_mult ;
    //sun spec
    sunALL += speccolor * hp_specdist(glossiness, R, Lsun) * specbase_mult * hp_fresnel(Lsun, V, f0_dir, 4);
    sunALL *= SUNcolor ; //*= sunlight_mult ;


  //点光源BRDF
    float3 PLtotal = float3(0,0,0) ;
    for (int itpl = 0; (itpl < 8) && (itpl < NumPointLights); itpl++ ) 
    {
      //if(itpl >= NumPointLights ){break;};

      float3 PLpos = PointLight[itpl].Position - i.WorldP ;
      float3 PLcolor = PointLight[itpl].Color ;
      float  PLrangeMAX = PointLight[itpl].Range_Inner_Outer.y * 2 ;
      float  PLrangeMIN = PointLight[itpl].Range_Inner_Outer.x + 1 ;

    #ifdef _3DSMAX_ //读取预览点光源数据
      PLpos = PV_pointlightPOS - i.WorldP; // relative!
      PLcolor = PV_pointlightCOLOR ; 
      PLrangeMAX = PV_pointlightRANGE ;
      PLrangeMIN = 0 ;
    #endif

      if(PLrangeMAX < 1) {continue;}; //排除无用的点光源
      float  PLdist = length(PLpos) ;
      if(PLdist > PLrangeMAX) {continue;}; //排除太远的点光源
      float3 PLL = PLpos / PLdist ; //normalized light vector
      float  PLtilt = dot(PLL, N) ;
      if(PLtilt < 0) {continue;}; //排除背光面

      float3 thisBRDF = float3(0,0,0) ;
      //pl diff
      thisBRDF += diffcolor * PLtilt  ; 
      //pl spec  
      thisBRDF += speccolor * hp_specdist(glossiness, R, PLL) * specbase_mult * hp_fresnel(PLL, V, f0_dir, 2) ;
      //pl color
      thisBRDF *= PLcolor * PLdecayfactor(PLrangeMIN, PLrangeMAX, PLdist);

      PLtotal += thisBRDF ; //叠加所有点光源
    };
    PLtotal *= 1 ;


  //最终混色
    OUTCOLOR.xyz += ambientALL + sunALL ; //BRDF
    //OUTCOLOR.xyz *= hcmask ; //increase hc saturation
    OUTCOLOR.xyz *= buildingDMG.b ; //only half, other half in diffcolor
    OUTCOLOR.xy  += buildingDMG.rg ;
    OUTCOLOR.xyz *= TintColor ;
    OUTCOLOR.xyz += PLtotal ; //thus pl unaffected
    OUTCOLOR.xyz += GlowMapRGB ; //原版可能要删了这个

  #ifndef _3DSMAX_ //预览没有迷雾
    OUTCOLOR.xyz *= tex2D(ShroudTextureSampler, i.FogCloudUV.xy) ;
  #endif

    //alpha clipping is in macro function stage
    OUTCOLOR.w =1;

    return OUTCOLOR;
};

//高画质PBR pixel shader结束====================

int VSchooserExpr() 
{ return clamp(NumJointsPerVertex, 0, 1) ; }

VertexShader VS_H_Array[2] = {
    compile vs_3_0 VS_H_00skin(), 
    compile vs_3_0 VS_H_11skin(), 
};

VertexShader VS_Shadow_Array[2] = {
    compile vs_2_0 VS_ShadowMaker_00skin(), 
    compile vs_2_0 VS_ShadowMaker_11skin(), 
};

PixelShader PS_Shadow_Array[2] = {
  compile ps_2_0 PS_ShadowMaker_NoAlphaTest(),
  compile ps_2_0 PS_ShadowMaker_AlphaTest(),
};


#ifdef _3DSMAX_ //预览
technique GEN2max
{    pass p0 <string ExpressionEvaluator = "Objects";>
    {
        VertexShader = compile vs_3_0 VSforMAX(); 
        PixelShader = compile ps_3_0 PS_H_PATCH();
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        AlphaBlendEnable = 0 ;
        AlphaTestEnable = 0 ;
    }
}
#endif

technique Default
{    pass p0 <string ExpressionEvaluator = "Objects";>
  {
    VertexShader = VS_H_Array[ VSchooserExpr() ]; 
    PixelShader  = compile ps_3_0 PS_H_PATCH(); 
    ZEnable = 1;
    ZFunc = 4;
    ZWriteEnable = 1;
    CullMode = 2;
    AlphaFunc = 7;
    AlphaRef = 64; //96
    AlphaBlendEnable = 0;
    AlphaTestEnable = 1;
    //DepthBias = -1.0f / 4096 ;

  } 
}

technique _CreateShadowMap
{    pass p0    {
    VertexShader = VS_Shadow_Array[ VSchooserExpr()  ]; 

  #ifdef IS_NANO_BUILDUP
    PixelShader = compile ps_2_0 PS_ShadowMaker_NoTexture() ;
  #else
    PixelShader = PS_Shadow_Array[ int(AlphaTestEnable) ];
  #endif

    ZEnable = 1;
    ZFunc = 4;
    ZWriteEnable = 1;
    CullMode = 2; //3
    AlphaBlendEnable = 0;
    AlphaTestEnable = 0;
} }



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

    pass p1 //outline
    {
        VertexShader = compile vs_3_0 VS_outline_3dsmax(); 
        PixelShader  = compile ps_3_0 PS_outline();    
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 0;
        CullMode = 3; // reverse
        AlphaBlendEnable = 1 ;
        AlphaTestEnable = 1 ;
    }


*/

