//下面是一堆全局MACRO控制。用于条件编译取舍功能

// #define _3DSMAX_ 
//编译给3DSMAX预览专用版时开启。
//请注意 如果你直接把源码给MAX读 是不需要上面这个的。 MAX会自己加
//你可以编译一个FXO然后后缀改成FX 给MAX读。
//只有装了W3X插件才能读取
//因为MAX 默认只能用FX源码。不能读编译后的
//但如果给游戏用的 就不要启用。否则游戏直接崩

// #define FORBID_PIPELINE_CONSTANT //
// #define FORCE_ENABLE_TEXTURE_CLIP //强制开启主贴图的ALPHA镂空。无论有没有ALPHATEST。不影响半透明

// 上面的最好别乱动 dont change any above 

// #define FORBID_FACTION_COLOR //中立单位要禁止阵营色 generic on
// #define DYNAMIC_CLOUD_REF //允许动态云背景反射。对金属和玻璃质感很重要 on for all
// #define ALLOW_STEALTH //允许隐身时有特殊的全息投影特效, player object only ! building off
// #define ALLOW_CLIP_TEXTURE_ALPHA //允许贴图alpha镂空。on for all
// #define RENDER_BACKFACE //only for tengu, objectsjapan

//下面三个互相冲突的功能只能选一个
// #define ALLOW_CLIP_VERTEX_ALPHA //允许骨骼透明度隐藏零件。building不要。objects ? 
// #define IS_BUILDNG //仅building要。这是损伤破洞功能。与上下两者冲突 不可同时用
// #define IS_NANO_BUILDUP  //启用帝国建筑的建造动画。 与上两者冲突 不可同时用


/*
fxc.exe /O2 /T fx_2_0 /Fo   objectsgeneric.fxo   PBR5-10-objects-ARPBR.FX
fxc.exe /O2 /T fx_2_0 /Fo   buildingsgeneric.fxo   PBR5-10-objects-ARPBR.FX

fxc.exe /O2 /T fx_2_0 /Fo   buildingsjapanbuildup.fxo   PBR5-10-objects-ARPBR.FX

fxc.exe /O2 /T fx_2_0 /Fo   buildingsallied.fxo   PBR5-10-objects-ARPBR.FX
fxc.exe /O2 /T fx_2_0 /Fo   buildingsjapan.fxo   PBR5-10-objects-ARPBR.FX
fxc.exe /O2 /T fx_2_0 /Fo   buildingssoviet.fxo   PBR5-10-objects-ARPBR.FX

fxc.exe /O2 /T fx_2_0 /Fo   objectsallied.fxo   PBR5-10-objects-ARPBR.FX
fxc.exe /O2 /T fx_2_0 /Fo   objectsjapan.fxo   PBR5-10-objects-ARPBR.FX
fxc.exe /O2 /T fx_2_0 /Fo   objectssoviet.fxo   PBR5-10-objects-ARPBR.FX

fxc.exe /O2 /T fx_2_0 /Fo   objectsallied3DSMAX.fxo   PBR5-10-objects-ARPBR.FX

*/
//#pragma warning(disable: 3206)



#include "head3-vsps.FXH" //WILL INCLUDE EVERYTHING


float4 SPM_threshold //SPM的界限
<   string UIName = "SPM_threshold"; 	string UIWidget = "Color";
> ={ 0.75, 0.125, 0.125, 1 }; //分别是：红色金属阈值，绿色金属阈值，蓝色阵营色阈值，发光倍数

float MinRoughness //最低粗糙度（要用倒数更精确吗？）
<   string UIName = "MinRoughness"; //MAXglossiness
    float UIMax = 0.5; float UIMin = 0.005; float UIStep = 0.005; 
> ={ 0.125 }; 

bool InfantrySkin //当作步兵  允许软绑定  同时关闭法线图
<    string UIName = "InfantrySkin";> = 0;

/*
float MaxRoughness //最大粗糙度
<   string UIName = "MaxRoughness"; 
    float UIMax = 1.0 ; float UIMin = 0.5; float UIStep = 0.05; 
> ={ 1.0 }; 
*/


struct PS_H_input
{
    float vface : VFACE ; // + facing camera, - backface ?
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

float4 PS_H_ARPBR (PS_H_input i) : COLOR 
{
  float4 OUTCOLOR = float4(0,0,0,1); //安全起见先initialize
  

  //风格常数，编译前确定


  //拿出主贴图 (GEN 2 MOD )
    float4 dif = tex2D(DiffuseTextureSampler,  i.MainTexUV.xy );
    float4 spm = tex2D(SpecMapSampler,         i.MainTexUV.xy );
    float4 nrm = tex2D(NormalMapSampler,       i.MainTexUV.xy );



  //有用的向量
    float3 albedo = dif.xyz ;
    float3 N = i.WorldN;
  #ifdef RENDER_BACKFACE
    N = (i.vface > 0)? -N : N ; //BACKFACE NRM CORRECTION
  #endif
    if(! InfantrySkin) { 
      nrm.xy = nrm.xy * 2 - 1  ;
      nrm.xy *= -BumpScale ;
      N += nrm.x * i.WorldB + nrm.y * i.WorldT ;
    };  //利用世界空间的切线去拉扯法线
    N = normalize(N); 
    //float3x3 TangentSpaceToWorldMatrix = float3x3(i.WorldB, i.WorldT, i.WorldN) ; //T B exchanged!
    //N = mul( float3(nrm.xy, 1), TangentSpaceToWorldMatrix) ;
    
    float3 V = hp_ps_getViewVector(i.WorldP) ;
    float3 R = reflect(-V , N) ; //input light vector is towards fragment!
    float  EYEtilt = dot(V , N) ;
    R = (EYEtilt <0) ? -V : R ;
    EYEtilt = saturate(EYEtilt);

    float3 Lsun     = DirectionalLight[0].Direction.xyz ;
    float3 SUNcolor = DirectionalLight[0].Color.xyz ;
  #ifdef _3DSMAX_  //MAX预览阳光方向与颜色覆盖
    Lsun     = PV_SunlightDirection ; 
    SUNcolor = PV_SunlightColor ;
  #endif


  //条件编译功能
    float3 extra_glow = 0 ; //add
    float3 extra_cavity = 1 ; //mult


    float3 realHC = 1 ;
  #ifndef FORBID_FACTION_COLOR
    realHC = (HasRecolorColors)? RecolorColor : realHC ;
    float whiteHCpart = dot(albedo.rgb, 0.375) ;//max(max(albedo.r, albedo.g), albedo.b);
    albedo = lerp((albedo * albedo) , whiteHCpart.xxx , spm.b); 
    //gamma only for no hc part
    spm.b = (spm.b > SPM_threshold.b)? spm.b : 0 ;
    albedo *= lerp(1, (realHC * realHC), spm.b);
  #else
    albedo *= albedo ;
  #endif


    //这段是ALPHA相关！
    //clipping affected ! ===========

    //if(AlphaTestEnable) 
  #ifdef FORCE_ENABLE_TEXTURE_CLIP
    clip(dif.w - 0.5); 
  #endif

  #ifdef ALLOW_CLIP_TEXTURE_ALPHA
    dif.w = (dif.w < 0.5)? 0 : dif.w ;
    OUTCOLOR.w *= dif.w ;
  #endif

  #ifdef ALLOW_CLIP_VERTEX_ALPHA
    OUTCOLOR.w *= i.VertexColor.w ;
  #endif

  #ifdef IS_BUILDNG //建筑损伤
    float4 buildingDMG = hp_new_damage_mix(i.MainTexUV.zw , i.VertexColor.w );
    OUTCOLOR.w *= buildingDMG.w ;
    extra_glow.rg += buildingDMG.rg ;
    extra_cavity *= buildingDMG.b ;
    spm.r *= buildingDMG.b ;
  #endif

  #ifdef IS_NANO_BUILDUP
    float2 nanobuildupMASK_alpha_glow = hp_nano_build(i.VertexColor.w, i.MainTexUV.xy);
    clip(nanobuildupMASK_alpha_glow.x - 0.375); 
    extra_glow += realHC * nanobuildupMASK_alpha_glow.y ;
    extra_cavity *= 1- nanobuildupMASK_alpha_glow.y;
  #endif


  //还原通道信息 ========================
    float blacklineavoid = saturate(dot(dif.xyz, 1) + dot(spm.rg, 2));
    
    float roughness = lerp(1, MinRoughness, spm.r) ;
    float glossiness = 1 / roughness ; //
    float specbase_mult = 0.25; 

    bool ismetal = (spm.r > SPM_threshold.r) || (spm.g > SPM_threshold.g)  ;

    float3 diffcolor = (ismetal)? 0 : albedo ;
    //diffcolor *= buildingDMG.b ; //haha

    float3 speccolor = (ismetal)? albedo : 0 ;
    float4 colortone = hp_saturation_luminance(speccolor, 0.0625 );
    speccolor = colortone.rgb ; //?
    speccolor *= blacklineavoid ;

    float f0_dir = (ismetal)? 1 : (1- colortone.w) ;
    float f0_env = (ismetal)? colortone.w : 0 ;

    //float  cavitymap = spm.w ;
    extra_cavity *= spm.w ;
    float glowchannel = saturate( SPM_threshold.w - spm.w);
    //float3 glowmapRGB = albedo * glowchannel * 4 ;
    extra_glow += albedo * glowchannel ;


  //BRDF=========================================

  //环境光相关 

    float3 irradi_color = hp_fake_irradiance(0, i.VertexColor.rgb , N.z) ; //already /2 in vs
    float3 skybox_color = hp_fake_skybox(0 , i.VertexColor.rgb , R.z , (glossiness * 0.5)) ; // hp_getAccentLight(R)
    skybox_color *= (ismetal)? 1 : (spm.r * spm.r)  ;
  #ifdef DYNAMIC_CLOUD_REF
    float3 cloudReflectionMultipler = hp_dynamic_cloud_reflection(i.FogCloudUV.zw, R, Lsun, (roughness *4))  ; 
    skybox_color *= cloudReflectionMultipler ;
  #endif
    irradi_color += AmbientLightColor;
    skybox_color += AmbientLightColor;
 
    float3 ambientALL = float3(0,0,0) ; //环境光BRDF
    ambientALL += irradi_color * diffcolor  ; 
    ambientALL += skybox_color * speccolor * hp_fresnel(R, V, f0_env, 8); 

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
    sunALL += diffcolor * sun_tilt ; //* diffuse_mult ;
    sunALL += speccolor * hp_specdist(glossiness, R, Lsun) * specbase_mult * hp_fresnel(Lsun, V, f0_dir, 4);
    sunALL *= SUNcolor ; //*= sunlight_mult ;


  //点光源BRDF
    float3 PLtotal = float3(0,0,0) ;
    for (int itpl = 0; itpl < min(8, NumPointLights); itpl++ ) //itpl < min(8, NumPointLights)
    {
      //if(itpl >= NumPointLights ){break;};

      float3 PLpos = PointLight[itpl].Position - i.WorldP ;
      float3 PLcolor = PointLight[itpl].Color ;
      float  PLrangeMAX = PointLight[itpl].Range_Inner_Outer.y * 2 ;
      float  PLrangeMIN = PointLight[itpl].Range_Inner_Outer.x ;//+ 1 ;

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
      thisBRDF += speccolor * hp_specdist(glossiness, R, PLL) * specbase_mult  ;
      //pl color
      thisBRDF *= PLcolor * PLdecayfactor(PLrangeMIN, PLrangeMAX, PLdist, 3);

      PLtotal += thisBRDF ; //叠加所有点光源
    };
    PLtotal *= 1 ;



  //最终混色
    OUTCOLOR.xyz += ambientALL + sunALL + PLtotal; //BRDF
    OUTCOLOR.xyz *= extra_cavity ; //
    OUTCOLOR.xyz += extra_glow * 5; //all glow
    OUTCOLOR.xyz *= TintColor ;

  #ifndef _3DSMAX_ //预览没有迷雾
    OUTCOLOR.xyz *= tex2D(ShroudTextureSampler, i.FogCloudUV.xy) ;
  #endif

    //alpha clipping is in macro function stage

  #ifdef _3DSMAX_
    if(AlphaTestEnable)  clip(OUTCOLOR.w - 0.375) ; 
    if(PV_SRGB) OUTCOLOR.xyz = sqrt(OUTCOLOR.xyz); //linear to srgb
  #endif

  #ifdef ALLOW_STEALTH
    if(OpacityOverride < 0.985) //stealth
    {OUTCOLOR = hp_stealthVFX(EYEtilt, albedo , 1, i.vpos.y, realHC);};
  #else
    OUTCOLOR.w *= OpacityOverride ;
  #endif

    return OUTCOLOR;
};

//高画质PBR pixel shader结束====================

int VSchooserExpr() 
{ 
  int max_allowed_bone = (InfantrySkin)? 2 : 1 ;
  return clamp(NumJointsPerVertex, 0, max_allowed_bone) ; 
}

VertexShader VS_H_Array[3] = {
    compile vs_3_0 VS_H_00skin(), 
    compile vs_3_0 VS_H_11skin(), 
    compile vs_3_0 VS_L_22skin(), //disable nrm for soft skin
};

VertexShader VS_L_Array[3] = {
    compile vs_3_0 VS_L_00skin(), 
    compile vs_3_0 VS_L_11skin(), 
    compile vs_3_0 VS_L_22skin(), 
};

VertexShader VS_Shadow_Array[3] = {
    compile vs_2_0 VS_ShadowMaker_00skin(), 
    compile vs_2_0 VS_ShadowMaker_11skin(), 
    compile vs_2_0 VS_ShadowMaker_22skin(), 
};

PixelShader PS_Shadow_Array[2] = {
  compile ps_2_0 PS_ShadowMaker_NoAlphaTest(),
  compile ps_2_0 PS_ShadowMaker_AlphaTest(),
};


#ifdef _3DSMAX_ //预览
technique MAXPREV
{    pass p0 
    {
        VertexShader = compile vs_3_0 VSforMAX(); 
        PixelShader = compile ps_3_0 PS_H_ARPBR();
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        AlphaBlendEnable = 0 ;
        AlphaTestEnable = 0 ;
    }
}

#else  //================= ingame


technique Default
{    pass p0 
  #ifndef IS_BUILDNG
  <string ExpressionEvaluator = "Objects";>
  #endif
  {
    VertexShader = VS_H_Array[ VSchooserExpr() ]; 
    PixelShader  = compile ps_3_0 PS_H_ARPBR(); 
    ZEnable = 1;
    ZFunc = 4;
    ZWriteEnable = 1;
  #ifdef RENDER_BACKFACE
    CullMode = 1;
  #else
    CullMode = 2;
  #endif
    AlphaFunc = 7;
    AlphaRef = 95; //95<0.375<96
    AlphaBlendEnable = 0;
    AlphaTestEnable = 1;
  } 
}


technique Default_M 
{    pass p0
  {
    VertexShader = VS_L_Array[ VSchooserExpr() ]; 
    PixelShader  = compile ps_3_0 PS_LOW_INFANTRY(); 
    ZEnable = 1;
    ZFunc = 4;
    ZWriteEnable = 1;
    CullMode = 2;
    AlphaFunc = 7;
    AlphaRef = 96;
    AlphaBlendEnable = 0;
    AlphaTestEnable = 0;
    //DepthBias = -1.0f / 4096 ;

  } 
}


technique _CreateShadowMap
{    pass p0    
  {
    VertexShader = VS_Shadow_Array[ VSchooserExpr()  ]; 
    PixelShader = PS_Shadow_Array[ int(AlphaTestEnable) ];
    ZEnable = 1;
    ZFunc = 4;
    ZWriteEnable = 1;
    CullMode = 2; //3
    AlphaBlendEnable = 0;
    AlphaTestEnable = 0;
  } 
}

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

