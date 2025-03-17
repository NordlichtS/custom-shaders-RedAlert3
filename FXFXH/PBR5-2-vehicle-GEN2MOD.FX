//#define _3DSMAX_
#define IS_BUILDNG
//#define PULSE_GLOW
//#define HAS_GLOW  //FORBID THIS ALSO REMOVE GLASS
//#define IGNORE_NRM
/*
fxc.exe /O2 /T fx_2_0 /Fo   BUILDING.fxo   PBR5-2-vehicle-GEN2MOD.FX
*/
#pragma warning(disable: 3206)

#include "head3-vsps.FXH" //WILL INCLUDE EVERYTHING

/*
float maxgloss // one over min roughness
<
    string UIName = "maxgloss"; 
    float UIMax = 16; float UIMin = 1; float UIStep = 0.25; 
> = 8 ;

float maxglow // one over min roughness
<
    string UIName = "maxglow"; 
    float UIMax = 5; float UIMin = 0; float UIStep = 0.25; 
> = 4 ;
*/

// #define BUILDING_DAMAGE
// const bool building_damage = 0 ; 
//用这个控制编译时是否需要建筑损伤？

struct PS_H_input
{
    float2 vpos : VPOS ; //screen pixel 
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

    const float ambient_diff_mult =  0.5 ; //环境光与天空盒diffuse
    const float ambient_spec_mult =  1 ; //环境光与天空盒specular
    const float tangent_mult = -2 ; 
    const float maxglow = 4 ;

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
    clip(dif.w - 0.5); 
    #ifdef IGNORE_NRM
    nrm = float4(0,0,1,1);
    #endif

  //兼容原版

    #ifndef HAS_GLOW //G2MOD
    spm.g = 0 ;
    #endif


    float4 buildingDMG = float4(0,0,1,1);
    #ifdef IS_BUILDNG //建筑损伤
    buildingDMG = hp_new_damage_mix(i.MainTexUV.zw , i.VertexColor.w );
    #endif

  //有用的向量
    float3 N = float3(0,0,1); //i.WorldN ;
    N.xy = (nrm.xy * 2 - 1 ) * tangent_mult ;
    float3x3 TangentSpaceToWorldMatrix = float3x3(i.WorldB, i.WorldT, i.WorldN) ; //T B exchanged!
    N = mul(N, TangentSpaceToWorldMatrix) ;
    N = normalize(N); //长度单位化，这一步很重要
    #ifdef IGNORE_NRM
    N = normalize(i.WorldN);
    #endif

    float3 V = hp_ps_getViewVector(i.WorldP) ;
    float3 R = reflect(-V , N) ; //input light vector is towards fragment!
    float  EYEtilt = dot(V , N) ;
    if(EYEtilt <0) {R = -V ;} ;


  //初步整理下信息 (GEN 2 MOD )
    float HCchannel = (HasRecolorColors)? spm.b : 0 ;
    float3 hcmask = lerp( float3(1,1,1), RecolorColor, HCchannel);
    dif.xyz *= lerp(dif.xyz , 1 , HCchannel); //gamma without hc
    dif.xyz *= hcmask ;//* hcmask ; //squared hc mix

    //if(OpacityOverride < 0.985) //stealth
    //{return hp_stealthVFX(EYEtilt, dif.xyz , 1, i.vpos.y, realHC);}; 

    float4 colortone = hp_saturation_luminance(dif.xyz, 1.0/16 );

    
    float glossgradient = spm.r * 6;
    float specbase_mult =  1.0 / 6 ; 
    float spmLowPart = min(1, glossgradient) ; //saturate(glossgradient); 
    float glossiness = max(1, glossgradient) ; // clamp(glossgradient, 1, 6) ;
    

    /*
    float spmLowPart = saturate(spm.r * 4);
    //spmLowPart = lerp(temp1, 1, temp1) ;
    float glossiness = spm.r * spm.r * 8 + 1  ; // spm0.25 -> 1/16*8+1 = 1.5
    float specbase_mult = 1.0 / 8 ;
    */

    float glassness = min(1, spm.g * 16);
    float metalness = smoothstep(0.25 , 0.75 , spm.r) ;
    metalness = max(glassness, metalness) ; //?

    float3 diffcolor = dif.xyz * (1 - metalness);
    float3 speccolor = lerp(1, colortone.rgb, metalness ); //?
    float3 glowmapRGB = dif.xyz * spm.g * spm.g * maxglow ;

  //阳光相关  
    float3 Lsun     = DirectionalLight[0].Direction.xyz ;
    float3 SUNcolor = DirectionalLight[0].Color.xyz ;
    #ifdef _3DSMAX_  //MAX预览阳光方向与颜色覆盖
    Lsun     = PV_SunlightDirection ; 
    SUNcolor = PV_SunlightColor ;
    #endif

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
    sunALL += speccolor * hp_specdist(glossiness, R, Lsun) * hp_fresnel(Lsun, V, spmLowPart, 6) * specbase_mult;
    sunALL *= SUNcolor ; //*= sunlight_mult ;

  //环境光相关 
    float3 cloudReflectionMultipler = hp_dynamic_cloud_reflection(i.FogCloudUV.zw, R, Lsun)  ; //需要阳光信息
    cloudReflectionMultipler = lerp(1 , cloudReflectionMultipler, saturate(spm.r *2 -1) ) ;

    //float3 groundcolor = AmbientLightColor;
    float3 skycolor_d  = hp_getAccentLight() ;
    float3 skycolor_s  = skycolor_d * cloudReflectionMultipler ;

    float3 irradi_color = hp_fake_irradiance(0, skycolor_d , N.z) + AmbientLightColor ;
    float3 skybox_color = hp_fake_skybox(0 , skycolor_s , R.z , glossiness) + AmbientLightColor ; 

    //skybox_color *= lerp( (1- diffcolor), 1, spmLowPart ) ; //saturation reduce

    float env_f_high = hp_fresnel(R, V, 0, 8); 
    float env_f_low = pow(saturate(1 - EYEtilt) , 4) ;
    float env_f0 = colortone.w * (metalness - glassness); //metal=0 -> f0=0, glass=1 -> f0=0
    float env_f_term = lerp(env_f0, 1, lerp(env_f_low, env_f_high, spmLowPart)) ;
 
    float3 ambientALL = float3(0,0,0) ; //环境光BRDF
    //ambient DIFF
    ambientALL += irradi_color * diffcolor * ambient_diff_mult * (1 - env_f_low); 
    //ambient SPEC
    ambientALL += skybox_color * speccolor * ambient_spec_mult * env_f_term ; 

  //点光源BRDF
    float3 PLtotal = float3(0,0,0) ;
    for (int itpl = 0; itpl < min(8, NumPointLights); itpl++ ) 
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
      if(PLdist >= PLrangeMAX) {continue;}; //排除太远的点光源
      float3 PLL = PLpos / PLdist ; //normalized light vector
      float  PLtilt = dot(PLL, N) ;
      if(PLtilt <= 0) {continue;}; //排除背光面

      float3 thisBRDF = float3(0,0,0) ;
      //pl diff
      thisBRDF += diffcolor * PLtilt  ; 
      //pl spec  
      thisBRDF += speccolor * hp_specdist(glossiness, R, PLL) * specbase_mult * hp_fresnel(PLL, V, spmLowPart, 4) ;
      //pl color
      thisBRDF *= PLcolor * PLdecayfactor(PLrangeMIN, PLrangeMAX, PLdist);

      PLtotal += thisBRDF ; //叠加所有点光源
    };
    PLtotal *= 1 ;


  //最终混色
    OUTCOLOR.xyz = ambientALL + sunALL + PLtotal ; //BRDF
    OUTCOLOR.xyz *= dif.w ; //make alpha edge darker
    OUTCOLOR.xyz *= buildingDMG.b ;
    OUTCOLOR.xy  += buildingDMG.xy ;
    OUTCOLOR.xyz *= TintColor ;

    #ifndef _3DSMAX_ //预览没有迷雾
    OUTCOLOR.xyz *= tex2D(ShroudTextureSampler, i.FogCloudUV.xy) ;
    #endif
    #ifdef HAS_GLOW
    OUTCOLOR.xyz += glowmapRGB ; //原版可能要删了这个
    #endif


    OUTCOLOR.w = 1 ; // i.VertexColor.w * OpacityOverride ;

    return OUTCOLOR;
};

//高画质PBR pixel shader结束====================

int VSchooserExpr() 
{ return clamp(NumJointsPerVertex, 0, 1) ; }

VertexShader VS_H_Array[2] = {
    compile vs_3_0 VS_H_00skin(), 
    compile vs_3_0 VS_H_11skin(), 
    //compile vs_3_0 VS_L_22skin(), //NO TGT
};

VertexShader VS_Shadow_Array[2] = {
    compile vs_2_0 VS_ShadowMaker_00skin(), 
    compile vs_2_0 VS_ShadowMaker_11skin(), 
    //compile vs_2_0 VS_ShadowMaker_22skin(), 
};

/*
int PSstealthExpr()
{  return (OpacityOverride < 0.985 )? 1 : 0 ; }

PixelShader PS_H_Array[2] = {
    compile ps_3_0 PS_H_GEN2MOD_SKETCH(),
    compile ps_3_0 PS_vfx_stealth(),
};
*/

#ifdef _3DSMAX_ //预览
technique GEN2max
{    pass p0 <string ExpressionEvaluator = "Objects";>
    {
        VertexShader = compile vs_3_0 VSforMAX(); 
        PixelShader = compile ps_3_0 PS_H_GEN2MOD_SKETCH();
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
    PixelShader  = compile ps_3_0 PS_H_GEN2MOD_SKETCH(); 
    ZEnable = 1;
    ZFunc = 4;
    ZWriteEnable = 1;
    CullMode = 2;
    AlphaFunc = 7;
    AlphaRef = 64;
    //AlphaBlendEnable = (AlphaBlendEnable);
    AlphaTestEnable = 0;
  } 
}

technique _CreateShadowMap
{    pass p0    {
    VertexShader = VS_Shadow_Array[ VSchooserExpr()  ]; 

    PixelShader = compile ps_2_0 PS_ShadowMaker_NoAlphaTest();

    ZEnable = 1;
    ZFunc = 4;
    ZWriteEnable = 1;
    CullMode = 3;
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

