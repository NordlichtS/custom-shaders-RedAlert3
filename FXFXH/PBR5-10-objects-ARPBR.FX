//下面是一堆全局MACRO控制。用于条件编译取舍功能

// #define _3DSMAX_ 
//编译给3DSMAX预览专用版时开启。
//请注意 如果你直接把源码给MAX读 是不需要上面这个的。 MAX会自己加
//你可以编译一个FXO然后后缀改成FX 给MAX读。
//只有装了W3X插件才能读取
//因为MAX 默认只能用FX源码。不能读编译后的
//但如果给游戏用的 就不要启用。否则游戏直接崩

#define IS_OBJECT_BUILDING_SHADER

// #define FORBID_CLIPPING_CONSTANT //只有强制开 ALPHA TEST 的可以开
//  #define USE_ARPBR_W3X_CONSTANT
// #define REPLACE_DEFAULT_TECHNIQUE //only for objects terrain
// #define COMPILE_SOFTSKIN_VS //USUALLY OFF
// 上面的最好别乱动 dont change any above 

// #define FORBID_FACTION_COLOR //中立单位要禁止阵营色 generic on
// #define DYNAMIC_CLOUD_REF //允许动态云背景反射。对金属和玻璃质感很重要 仅玩家
// #define ALLOW_STEALTH //允许隐身时有特殊的全息投影特效, player object only ! 建筑和中立都关
// #define RENDER_BACKFACE //only for tengu, objectsjapan
// #define FORBID_SHADOW_ALPHATEST  //for terrain like stuff


// #define OPACITY_OVERRIDE_CLIP  //仅玩家的OBJECT开
// #define OPACITY_OVERRIDE_OUTPUT //玩家的OBJECT和BUILDING 开
// #define ALLOW_CLIP_TEXTURE_ALPHA //允许贴图alpha镂空。on for all
// #define FORCE_ENABLE_ALPHA_CLIP_BEFORE_RETURN //应该都关
// #define KEEP_ALPHA_TEXTURE_SAMPLER_SAME  //仅建筑
//  #define DAMAGE_BURNRED  //烧红效果看情况吧
// #define SHADOW_DITHER //just like terrain

//下面三个互相冲突的（顶点ALPHA功能）功能只能选一个
// #define ALLOW_CLIP_VERTEX_ALPHA //允许骨骼透明度隐藏零件。building不要。objects ? 
// #define IS_BUILDNG //仅building要。这是损伤破洞功能。与上下两者冲突 不可同时用
// #define IS_NANO_BUILDUP  //启用帝国建筑的建造动画。 与上两者冲突 不可同时用


/*

fxc.exe /O2 /T fx_2_0 /Fo   objectsARPBR.fxo   PBR5-10-objects-ARPBR.FX


*/
//#pragma warning(disable: 3206)



#include "head3-vsps.FXH" //WILL INCLUDE EVERYTHING


#ifdef USE_ARPBR_W3X_CONSTANT

float4 SPM_threshold //SPM的界限
<   string UIName = "SPM_threshold"; 	string UIWidget = "Color";
> ={ 2, 0.5, 0.25, 1 }; //分别是：红色金属阈值，绿色金属阈值，蓝色阵营色阈值，发光(<=1!)

float MinRoughness //最低粗糙度（要用倒数更精确吗？）
<   string UIName = "MinRoughness"; //MAXglossiness
    float UIMax = 0.5; float UIMin = 0.005; float UIStep = 0.005; 
> ={ 0.125 }; 

bool InfantrySkin //当作步兵  允许软绑定  同时关闭法线图
<    string UIName = "InfantrySkin";> = 0;

#else // USE_ARPBR_W3X_CONSTANT?

static const float4 SPM_threshold = { 0.75, 0.125, 0.125, 1 }; //careful gen evo values
static const float MinRoughness = 0.125 ;
static const bool InfantrySkin = 0 ;

#endif //USE_ARPBR_W3X_CONSTANT ?


struct PS_H_input
{
    float vface : VFACE ; // + facing camera, - backface ?
    float2 vpos : VPOS ; //screen pixel 
    float4 VertexColor : COLOR0;  //顶点颜色
    float3 CoordOBJ  : COLOR1; 
    float4 MainTexUV  : TEXCOORD0; //XY是主帖图UV,ZW是建筑损伤图UV
    float4 ShadowCS : TEXCOORD1; //XYZ阴影空间投影, W弃用
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

  #ifdef KEEP_ALPHA_TEXTURE_SAMPLER_SAME
    if(AlphaTestEnable)
    {dif.a = tex2D(DiffuseEasySampler,  i.MainTexUV.xy ).a;}
  #endif



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
    float fresnelbase = 1- EYEtilt;

    float3 Lsun     = DirectionalLight[0].Direction.xyz ;
    float3 SUNcolor = DirectionalLight[0].Color.xyz ;
  #ifdef _3DSMAX_  //MAX预览阳光方向与颜色覆盖
    Lsun     = PV_SunlightDirection ; 
    SUNcolor = PV_SunlightColor ;
  #endif

    //float4 ditherline = frac(i.vpos.yyyy / float4(1,2,4,8));
    bool2 dither2x2 = frac(i.vpos /2) < 0.375 ;
    bool alreadystealth = (OpacityOverride < 0.985) ;
    


  //条件编译功能
    float3 extra_glow = 0 ; //add
    float3 extra_cavity = 1 ; //mult

    // hc mixer and gamma
    float3 realHC = 1 ;
    float3 hcmask = 1 ;
  #ifndef FORBID_FACTION_COLOR
    realHC = (HasRecolorColors)? RecolorColor : realHC ;
    float whiteHCpart = dot(albedo.rgb, 0.375) ;//max(max(albedo.r, albedo.g), albedo.b);
    albedo = lerp((albedo * albedo) , whiteHCpart.xxx , spm.b); 
    //gamma only for no hc part
    spm.b = (spm.b > SPM_threshold.b)? spm.b : 0 ;
    hcmask = lerp(1,  realHC, spm.b);
    albedo *= hcmask ;
    #ifndef INCREASE_HC_SATURATION
    albedo *= hcmask ;
    #endif
  #else
    albedo *= albedo ;
  #endif

    //in case needed
  #ifdef SPECIAL_FUNCTION_A
    extra_glow += 0 ;
    extra_cavity *= 1 ;
  #endif


    //这段是ALPHA相关！
    //clipping affected ! ===========
    float extra_alpha = 1 ;


  #ifdef OPACITY_OVERRIDE_CLIP
    extra_alpha *= OpacityOverride ;
  #endif

  #ifdef ALLOW_CLIP_TEXTURE_ALPHA
    //dif.w = (dif.w < 0.5)? 0 : dif.w ;
    extra_alpha *= dif.w ;
  #endif

  #ifdef ALLOW_CLIP_VERTEX_ALPHA
    extra_alpha *= i.VertexColor.w ;
  #endif

  #ifdef IS_BUILDNG //建筑损伤
    float4 dmgtex = tex2D(DamagedTextureSampler , i.MainTexUV.zw);
    dmgtex = (i.VertexColor.w < 0.375)? dmgtex : 1 ;
    extra_alpha *= dmgtex.w ;
    #ifdef DAMAGE_BURNRED
      float burnred = 1 - dmgtex.w  ; //max 0.625
      extra_glow.r += pow(burnred, 2) ;
      extra_glow.g += pow(burnred, 4) ;
    #endif
    albedo.rgb *= dmgtex.rgb * dmgtex.a ;
    spm.r *= dmgtex.r * dmgtex.g * dmgtex.b ;
  #endif

  #ifdef IS_NANO_BUILDUP
    float2 nanobuildupMASK_alpha_glow = hp_nano_build(i.VertexColor.w, i.MainTexUV.xy);
    extra_alpha *= nanobuildupMASK_alpha_glow.x ;
    extra_glow += realHC * nanobuildupMASK_alpha_glow.y ;
    extra_cavity *= 1- nanobuildupMASK_alpha_glow.y;
  #endif


      
  //lets ignore the damn pass alpha test and do it here

  #ifdef FORCE_ENABLE_ALPHA_CLIP_BEFORE_RETURN
    clip(extra_alpha - 0.375) ;
  #else
    if(AlphaTestEnable) {clip(extra_alpha - 0.375) ; };
  #endif
  // EXTRA_ALPHA WILL NOT EXPORT TO OUTCOLOR



    //glow will x4 at the end
  #ifdef SUPPORT_LIGHTMAP
    extra_glow += getLightMap(i.MainTexUV.zw, Time) * albedo; 
  #endif
  #ifdef SUPPORT_TESLA
    extra_glow += getTeslaMap( i.vpos, Time, EYEtilt) ;
  #endif


    float4 stealthcolor = 1 ;
  #ifdef ALLOW_STEALTH
    stealthcolor.rgb = realHC ;
    stealthcolor.rgb *= fresnelbase * fresnelbase * (2 - OpacityOverride) ;
    stealthcolor.rgb += albedo ;
    stealthcolor.a = (dither2x2.y)? 1 : fresnelbase - 0.0625;
  #endif  
  //opacity is multiplied before, in both extra_alpha and OUTCOLOR
  //stealth alpha will be applied at shader end, not here




  //还原通道信息 ========================
    
    float roughness = lerp(1, MinRoughness, spm.r) ;
    float glossiness = 1 / roughness ; //
    float specbase_mult = 0.25; 

    bool ismetal = (spm.r > SPM_threshold.r) || (spm.g > SPM_threshold.g)  ;

    float4 colortone = hp_saturation_luminance(albedo, 0.0625 );
    float3 diffcolor = (ismetal)? 0 : albedo ;
    float3 speccolor = (ismetal)? colortone.rgb : 1 ;  ; //same beightness

    //float blacklineavoid = saturate(dot(dif.xyz, 1) + dot(spm.rg, 2));
    //speccolor *= blacklineavoid ;

    float f0_env = (ismetal)? colortone.w : 0 ;
    float f0_dir = (1 - colortone.w) * spm.r ;
    f0_dir = (ismetal)? 1 : f0_dir  ;

    extra_cavity *= spm.w ; //NO AFFECT WITH GLOW BRIGHTNESS
    float glowchannel = saturate( SPM_threshold.w - spm.w);
    extra_glow += albedo * glowchannel ;


  //BRDF=========================================

  //环境光相关 
    float3 upper_color = i.VertexColor.rgb + AmbientLightColor;  //already /2 in vs
    float3 lower_color = (ismetal)? (AmbientLightColor) : 0 ; //  0.5 ?
    float3 irradi_color = hp_fake_irradiance(0 , upper_color , N.z) ;
    float3 skybox_color = hp_fake_skybox(lower_color , upper_color , R.z , (glossiness * 0.5)) ; 
    skybox_color *= (ismetal)? 1 :  spm.r ;

  #ifdef DYNAMIC_CLOUD_REF
    float3 cloudReflectionMultipler = hp_dynamic_cloud_reflection(i.FogCloudUV.zw, R, Lsun, (roughness *4))  ; 
    skybox_color *= cloudReflectionMultipler ;
  #else
    //float3 noCloudSkyMultipler =
    skybox_color *= lerp(1, NoCloudMultiplier , saturate(R.z)); 
  #endif
 
    float3 ambientALL = float3(0,0,0) ; //环境光BRDF
    ambientALL += irradi_color * diffcolor  ; 
    ambientALL += skybox_color * speccolor * hp_fresnel(R, V, f0_env, 8); 

  //阳光相关  
    float vertex_suntilt = dot(i.WorldN, Lsun);

    float  sun_tilt  = dot(N,Lsun) ;
    SUNcolor *= (sun_tilt > 0 )? 1 : 0 ; 
    SUNcolor *= (vertex_suntilt > 0 )? 1 : 0 ; 

    //if(HasShadow){
    float3 ShadowMapUV = i.ShadowCS.xyz / i.ShadowCS.w ;
    float transition_range_mult = 2 - vertex_suntilt ;
    float transition_start_bias_mult = 1 ;
    #ifdef SHADOW_DITHER
      float2 smbias = float2(0, Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w);
      smbias = (dither2x2.x)? smbias.xy : smbias.yx ; //x to flip axis
      smbias = (dither2x2.y)? smbias    : - smbias  ; //y to flip direction     
      ShadowMapUV.xy += smbias * vertex_suntilt ;
      transition_range_mult = 1 ;
      transition_start_bias_mult = 1 ;
    #endif
    SUNcolor *= hp_invshadow_trilinear(ShadowMapUV, transition_range_mult, transition_start_bias_mult) ;
    //cubic hermit is in helper function, open when no dither
    //};


  #ifndef _3DSMAX_ //高画质都有云，但预览没有
    float3 cloudcolor = tex2D(CloudTextureSampler, i.FogCloudUV.zw).rgb;
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
      float  PLrangeMIN = PointLight[itpl].Range_Inner_Outer.x ;
      float  PLrangeMAX = PointLight[itpl].Range_Inner_Outer.y + PLrangeMIN ;

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
      if(PLtilt < 0) {PLcolor = 0 ;}; //排除背光面

      float3 thisBRDF = float3(0,0,0) ;
      thisBRDF += diffcolor * PLtilt  ; 
      thisBRDF += speccolor * hp_specdist(glossiness, R, PLL) * specbase_mult  ;
      thisBRDF *= PLcolor * PLdecayfactor(PLrangeMIN, PLrangeMAX, PLdist, 2);

      PLtotal += thisBRDF ; //叠加所有点光源
    };
    PLtotal *= 1 ;



  //最终混色
    OUTCOLOR.w = 1 ; //just in case
    OUTCOLOR.xyz += ambientALL + sunALL + PLtotal; //BRDF
    OUTCOLOR.xyz *= extra_cavity ; //
    OUTCOLOR.xyz += extra_glow * 4; //all glow

  #ifndef _3DSMAX_ //预览没有迷雾
    OUTCOLOR.xyz *= tex2D(ShroudTextureSampler, i.FogCloudUV.xy).rgb ;
  #endif

  #ifdef ALLOW_STEALTH
    OUTCOLOR = (alreadystealth)? stealthcolor : OUTCOLOR ;
    OUTCOLOR.rgb += PLtotal ;
  #endif

  #ifdef OPACITY_OVERRIDE_OUTPUT //no conflict with stealth
    OUTCOLOR.w *= OpacityOverride ;
  #else
    OUTCOLOR.w = 1 ;
  #endif

    OUTCOLOR.a = saturate(OUTCOLOR.a); //for safety
    OUTCOLOR.rgb *= TintColor ;
    #ifdef INCREASE_HC_SATURATION
    OUTCOLOR.rgb *= hcmask ;
    #endif

    //alpha clipping is in macro function stage
    //ONLY STEALTH AND OPACITY OVERRIDE AFFECT OUTCOLOR ALPHA

  #ifdef _3DSMAX_
    if(PV_SRGB) { OUTCOLOR.xyz = sqrt(OUTCOLOR.xyz) ; } //linear to srgb
  #endif

    return OUTCOLOR;
};

//高画质PBR pixel shader结束====================























//中低画质的PS ====================


float4 PS_LOW_ARPBR (PS_H_input i) : COLOR 
{
    float3 N = i.WorldN;
    float3 Lsun     = DirectionalLight[0].Direction.xyz ;
    float3 SUNcolor = DirectionalLight[0].Color.xyz * NoCloudMultiplier;
    float sun_tilt = dot(N, Lsun);
    float3 sundiffuselight = (sun_tilt > 0)? SUNcolor : 0 ;

    float3 ShadowMapUV = i.ShadowCS.xyz / i.ShadowCS.w ;
    ShadowMapUV.z -= (2 - sun_tilt) * Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w ;
    float shadowterm = hp_invshadow_trilinear(ShadowMapUV, 4, 1); //no shadow alt is inside
    shadowterm = saturate(shadowterm *2 -0.5);// hp_cubic_hermit(bUD) ; //* bUD;
    sundiffuselight *= shadowterm ;

    float3 albedocolor = 1 ;
    float  texalpha = 1 ;
    float  HCchannel = 0 ;

    float  extra_glow = 0 ; //add
    float3 extra_cavity = 1 ; //mult
    float  extra_alpha = 1 ; //

    //conditioanl functions, affect clipping

    #ifdef OPACITY_OVERRIDE_CLIP
    extra_alpha *= OpacityOverride ;
    #endif

    #ifdef ALLOW_CLIP_VERTEX_ALPHA
    extra_alpha *= i.VertexColor.w ; //ALLOW_CLIP_VERTEX_ALPHA
    #endif

    #ifdef ALLOW_CLIP_TEXTURE_ALPHA
    extra_alpha *= texalpha ;
    #endif

    #ifdef IS_BUILDNG
    float4 dmgtex = tex2D(DamagedTextureSampler , i.MainTexUV.zw) ;
    dmgtex = (i.VertexColor.w < 0.375)? dmgtex : 1;
    extra_cavity *= dmgtex.rgb ;
    extra_alpha *= dmgtex.w ;
    //clip(dmgtex.w - 0.375) ;
    #endif 

    #ifdef IS_NANO_BUILDUP
    float2 nanobuildupMASK_alpha_glow = hp_nano_build(i.VertexColor.w, i.MainTexUV.xy);
    extra_alpha *= nanobuildupMASK_alpha_glow.x ;
    extra_glow +=  nanobuildupMASK_alpha_glow.y ;
    HCchannel += nanobuildupMASK_alpha_glow.y * 2 ;
    //clip(nanobuildupMASK_alpha_glow.x - 0.375) ; 
    #endif




  #ifdef SUPPORT_LIGHTMAP
    //extra_glow += getLightMap(i.MainTexUV.zw, 0) ; 
  #endif
  #ifdef SUPPORT_TESLA
    extra_glow += abs( frac(Time + N.z) *2 -1 ) ;
    extra_cavity *= float3(0.5, 1, 2) ;
  #endif

    //now for albedo colors
    
  #ifdef IS_BASIC_W3D_SHADER 
    float4 tmp0 = tex2D(Texture_0Sampler,  i.MainTexUV.xy );
    albedocolor = tmp0.xyz ;
    HCchannel += tmp0.w ;
  #endif

  #ifdef IS_OBJECT_BUILDING_SHADER
    float4 dif = tex2D(DiffuseTextureSampler,  i.MainTexUV.xy );
    albedocolor = dif.xyz ;
    texalpha = dif.w ;
    float4 spm = tex2D(SpecMapSampler, i.MainTexUV.xy) ;
    HCchannel += spm.b ;
    extra_glow += 1 - spm.a ;
  #endif

  #ifndef FORBID_FACTION_COLOR
    float3 realHC = (HasRecolorColors)? RecolorColor : 1 ; ;
    albedocolor *= lerp(1, realHC, saturate(HCchannel)) ;
  #endif

    float4 OUTCOLOR = 0;
    OUTCOLOR.rgb += sundiffuselight + AmbientLightColor ;
    OUTCOLOR.rgb *= extra_cavity ;
    OUTCOLOR.rgb = lerp( OUTCOLOR.rgb, 1, saturate(extra_glow));
    OUTCOLOR.rgb *= albedocolor ;
    OUTCOLOR.rgb *= tex2D(ShroudTextureSampler, i.FogCloudUV.xy).xyz ;
    OUTCOLOR.rgb *= TintColor ;

    //
    #ifdef FORCE_ENABLE_ALPHA_CLIP_BEFORE_RETURN
    clip(extra_alpha - 0.375) ;
    #else
    if(AlphaTestEnable) {clip(extra_alpha - 0.375) ; };
    #endif


    OUTCOLOR.w = 1;// extra_alpha ;
    #ifdef OPACITY_OVERRIDE_OUTPUT
    OUTCOLOR.w *= OpacityOverride ;
    #endif

    return OUTCOLOR ;
};

// low ps end

























// EXPRESSIONS AND TECHNIQUE

#ifdef COMPILE_SOFTSKIN_VS

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
    //compile vs_2_0 VS_ShadowMaker_CLIPALL(), 
};

#else

int VSchooserExpr() 
{   return clamp(NumJointsPerVertex, 0, 1) ; }

VertexShader VS_H_Array[2] = {
    compile vs_3_0 VS_H_00skin(), 
    compile vs_3_0 VS_H_11skin(), 
};

VertexShader VS_L_Array[2] = {
    compile vs_3_0 VS_L_00skin(), 
    compile vs_3_0 VS_L_11skin(), 
};

VertexShader VS_Shadow_Array[2] = {
    compile vs_2_0 VS_ShadowMaker_00skin(), 
    compile vs_2_0 VS_ShadowMaker_11skin(), 
};

#endif

int SMPSchooserExpr() 
{ 
  int index = (AlphaTestEnable)? 1 : 0 ;
  //#ifdef FORCE_ENABLE_ALPHA_CLIP_BEFORE_RETURN
  index = 1 ;
  //#endif
  return index ; 
}

PixelShader PS_Shadow_Array[2] = {
  compile ps_2_0 PS_ShadowMaker_NoAlphaTest(),
  compile ps_2_0 PS_ShadowMaker_AlphaTest(),
};

#ifdef _3DSMAX_ //预览

  #define REPLACE_DEFAULT_TECHNIQUE // forbid ingame technique

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

#endif  //  _3DSMAX_ ?

//================= ingame

#ifndef REPLACE_DEFAULT_TECHNIQUE


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
    //AlphaBlendEnable = 0;
    AlphaTestEnable = 0;//default to 0 ?
  } 
}


technique Default_M 
{    pass p0
  #ifndef IS_BUILDNG
  <string ExpressionEvaluator = "Objects";>
  #endif
  {
    VertexShader = VS_L_Array[ VSchooserExpr() ]; 
    PixelShader  = compile ps_3_0 PS_LOW_ARPBR(); 
    ZEnable = 1;
    ZFunc = 4;
    ZWriteEnable = 1;
    CullMode = 2;
    AlphaFunc = 7;
    AlphaRef = 96;
    //AlphaBlendEnable = 0;
    AlphaTestEnable = 0;
  } 
}


technique _CreateShadowMap
{    pass p0    
  {
    VertexShader = VS_Shadow_Array[ VSchooserExpr()  ]; 
    PixelShader  = 
    #ifdef FORBID_SHADOW_ALPHATEST
    compile ps_2_0 PS_ShadowMaker_NoAlphaTest() ;
    #else
    PS_Shadow_Array[ SMPSchooserExpr()  ];
    #endif
    ZEnable = 1;
    ZFunc = 4;
    ZWriteEnable = 1;
    CullMode = 2; //3
    AlphaBlendEnable = 0;
    AlphaTestEnable = 0;
  } 
}

#endif  // REPLACE_DEFAULT_TECHNIQUE ?



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

