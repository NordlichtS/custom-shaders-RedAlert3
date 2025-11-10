// facet triangle render without geometry shader

#include "head3-vsps.FXH" //WILL INCLUDE EVERYTHING

//we need new struct for vs2ps
//special vs + ps will be here, shadow use original


struct VS_facet_output
{
    float4 Position : POSITION;   //VS一定要输出的clip space渲染坐标
    float4 VertexColor : COLOR0;  //顶点颜色，直接照抄RGB， W还有用
    float4 MainTexUV  : TEXCOORD0; //XY是主帖图UV, ZW是建筑损伤图 (并没有反)
    float4 ShadowCS : TEXCOORD1; // 阴影的 CLIP SPACE 坐标，像素里还得除
    float4 FogCloudUV : TEXCOORD2; //迷雾和云的UV
    float3 WorldEyeDir : TEXCOORD3;  //世界空间相对于眼睛位置

};

// MAX预览用的============================ 

struct VS_facet_input
{
    float4 position : POSITION;
    float4 texcoord : TEXCOORD; 
    float4 texcoordNEW : TEXCOORD1 ;
    float4 color : COLOR;

    float4 blendindices : BLENDINDICES;
    float4 blendweight : BLENDWEIGHT;
    float4 position1 : POSITION1;

};

#ifdef _3DSMAX_  //=====
VS_facet_output VS_facet_MAX(VS_facet_input i)  
{ 
    VS_facet_output  o;

    float4 WorldPosition = float4(0,0,0,1);
    o.ShadowCS = o.FogCloudUV = 0 ;
    o.MainTexUV = float4(i.texcoord.xy , i.texcoordNEW.xy) ; //直接转存贴图UV

    o.VertexColor.rgb = 1 ; // 
    o.VertexColor.w = PV_vertexALPHA ; //!!!

    // 从object space 到 world space===========

    WorldPosition = mul(float4(i.position.xyz, 1), MAXworld);
    o.WorldEyeDir = WorldPosition.xyz - ViewI[3].xyz ; //世界坐标

    o.Position = mul(i.position , MAXwvp); //给rasterizer的clip space坐标

    return o; 
};
#endif // 3dsmax end

//====================== HIGH + LOW VS


VS_facet_output  VS_facet_00skin (VS_facet_input  i)  //no bone skin
{
    VS_facet_output o; //声明下输出数组的结构缩写

    float4 WorldPosition = float4(0,0,0,1);
    o.VertexColor = 1;//i.color ;  //没骨骼ALPHA
    o.MainTexUV = float4(i.texcoord.xy , i.texcoordNEW.xy) ; //直接转存贴图UV

    // 从object space 到 world space===========
    WorldPosition.xyz = mul(float4(i.position.xyz, 1), World);;
    
    o.WorldEyeDir = WorldPosition.xyz - EyePosition ;
    //if(HasShadow) 
    o.ShadowCS = mul(WorldPosition, ShadowMapWorldToShadow); ;
    o.FogCloudUV.xy = getWarfogUV( WorldPosition) ;
    o.FogCloudUV.zw = getCloudUV ( WorldPosition) ;

    o.Position = mul(WorldPosition, ViewProjection); //给rasterizer的clip space坐标

    return o;
};



VS_facet_output  VS_facet_11skin (VS_facet_input  i)  //HARD bone skin
{
    VS_facet_output o; //声明下输出数组的结构缩写

    float4 WorldPosition = float4(0,0,0,1);
    o.VertexColor = 1;//i.color ;  
    o.MainTexUV = float4(i.texcoord.xy , i.texcoordNEW.xy) ; //直接转存贴图UV

    // 从object space 到 world space===========
    int BoneIndex = floor(i.blendindices.x * 2)  ;
    float4 bone_Quaternion   = WorldBones[BoneIndex.x];
    float4 bone_offset_alpha = WorldBones[BoneIndex.x + 1];

    float3 BoneSpacePos = i.position.xyz ;
    #ifdef BONE_ALPHA_SHRINK
    BoneSpacePos *= bone_offset_alpha.w ;
    o.VertexColor.a = 1 ;
    #endif

    WorldPosition.xyz = QuaternionRotate( bone_Quaternion, BoneSpacePos) + bone_offset_alpha.xyz ;
    o.VertexColor.w = bone_offset_alpha.w ;


    o.WorldEyeDir = WorldPosition.xyz - EyePosition ;
    //if(HasShadow) 
    o.ShadowCS = mul(WorldPosition, ShadowMapWorldToShadow); ;
    o.FogCloudUV.xy = getWarfogUV( WorldPosition) ;
    o.FogCloudUV.zw = getCloudUV ( WorldPosition) ;

    #ifdef SUPPORT_TREAD_SCROLLING
    o.MainTexUV.x += o.VertexColor.a ;
    o.VertexColor.a = 1 ;
    #endif

    o.Position = mul(WorldPosition, ViewProjection); //给rasterizer的clip space坐标

    return o;
};



VS_facet_output  VS_facet_22skin (VS_facet_input  i)  //SOFT bone skin
{
    VS_facet_output o; //声明下输出数组的结构缩写

    float4 WorldPosition = float4(0,0,0,1);
    o.VertexColor = 1 ;// i.color ;  
    o.MainTexUV = float4(i.texcoord.xy , i.texcoordNEW.xy) ; //直接转存贴图UV

    // 从object space 到 world space===========
    int2 BoneIndex = floor(i.blendindices.xy * 2)  ;
    float secondBlend = i.blendweight.y ; //第二个骨骼的权重
    float4 bone_Quaternion_0   = WorldBones[BoneIndex.x];
    float4 bone_Quaternion_1   = WorldBones[BoneIndex.y];
    float4 bone_offset_alpha_0 = WorldBones[BoneIndex.x + 1];
    float4 bone_offset_alpha_1 = WorldBones[BoneIndex.y + 1];

    float3 BoneSpacePos0 = i.position.xyz ;
    float3 BoneSpacePos1 = i.position1.xyz ;
    #ifdef BONE_ALPHA_SHRINK
    BoneSpacePos0 *= bone_offset_alpha_0.w ;
    BoneSpacePos1 *= bone_offset_alpha_1.w ;
    o.VertexColor.a = 1 ;
    #endif

    float3 worldP0 = QuaternionRotate( bone_Quaternion_0 , BoneSpacePos0) + bone_offset_alpha_0.xyz ;
    float3 worldP1 = QuaternionRotate( bone_Quaternion_1 , BoneSpacePos1) + bone_offset_alpha_1.xyz ;
    WorldPosition.xyz = lerp(worldP0, worldP1, secondBlend) ;
    o.VertexColor.w = lerp(bone_offset_alpha_0.w , bone_offset_alpha_1.w , secondBlend) ; 

    o.WorldEyeDir = WorldPosition.xyz - EyePosition ;
    //if(HasShadow) 
    o.ShadowCS = mul(WorldPosition, ShadowMapWorldToShadow); 
    o.FogCloudUV.xy = getWarfogUV( WorldPosition) ;
    o.FogCloudUV.zw = getCloudUV ( WorldPosition) ;

    o.Position = mul(WorldPosition, ViewProjection); //给rasterizer的clip space坐标

    return o;
};

//VS END ============================

//PS START ====================================

struct PS_facet_input
{
    float  vface : VFACE ; // + facing camera, - backface ? NO, INVERTED
    float2 vpos : VPOS ; //screen pixel 

    float4 VertexColor : COLOR0;  //顶点颜色，可能现在没用了？W还有用
    float4 MainTexUV  : TEXCOORD0; //XY是主帖图UV, ZW是建筑损伤图 (并没有反)
    float4 ShadowCS : TEXCOORD1; // 阴影的 CLIP SPACE 坐标，像素里还得除
    float4 FogCloudUV : TEXCOORD2; //迷雾和云的UV
    float3 WorldEyeDir : TEXCOORD3;  //世界空间相对于眼睛位置
};


float4 PS_H_FACET (PS_facet_input i) : COLOR 
{
    float4 OUTCOLOR = float4(0,0,0,1); 

    //先算出面法线
    float3 N = cross(ddy(i.WorldEyeDir), ddx(i.WorldEyeDir)) ;
    N = normalize(N); //backface correction not needed
    float3 V = - normalize(i.WorldEyeDir) ;
    float3 R = reflect(-V , N) ;

    float3 albedo = 1 ;
    float SPMvalue = 0 ;

    float3 extra_glow = 0 ; //add
    float3 extra_cavity = 1 ; //mult

    float HCchannel = 0 ;
    float3 hcmask = 1 ;

  #ifdef IS_BASIC_W3D_SHADER  //!!!
    float4 tex0color = tex2D(Texture_0Sampler,  i.MainTexUV.xy );
    albedo = tex0color.rgb ;
    HCchannel = tex0color.a ;
  #endif

  #ifdef IS_OBJECT_BUILDING_SHADER  
    float4 dif = tex2D(DiffuseTextureSampler,  i.MainTexUV.xy );
    float4 spm = tex2D(SpecMapSampler,         i.MainTexUV.xy );
    albedo = dif.rgb ;
    SPMvalue = spm.r ;
    HCchannel = spm.b ;
  #endif

  #ifdef IS_BUILDNG
    float4 dmgtex = tex2D(DamagedTextureSampler , i.MainTexUV.zw);
    dmgtex = (i.VertexColor.w < 0.375)? dmgtex : 1 ;
    albedo *= dmgtex.rgb * dmgtex.a ;
    SPMvalue *= dmgtex.r * dmgtex.g * dmgtex.b ;
    //#ifdef DAMAGE_BURNRED
    extra_glow.r += (dmgtex.a < 0.375)? 0 : (1 - dmgtex.a)  ; 
    //#endif
  #endif

  #ifdef SUPPORT_FROZEN
    SPMvalue = 1 ;
  #endif

    float3 realHC = 1 ;  //hc mixer
  #ifndef FORBID_FACTION_COLOR
    realHC = (HasRecolorColors)? RecolorColor : 1 ;
    hcmask = lerp(1, realHC, HCchannel) ;
    albedo *= lerp(albedo, 1, HCchannel) ; //gamma
    albedo *= hcmask ; //need another mult
  #else
    albedo *= albedo ;
  #endif

    //main BRDF =========

    //AMBIENT ====
    float3 skycolor = hp_getAccentLight(N) /2 ;

    //SUN ====
    float3 Lsun     = DirectionalLight[0].Direction.xyz ;
    float3 SUNcolor = DirectionalLight[0].Color.xyz ;
  #ifdef _3DSMAX_  //MAX预览阳光方向与颜色覆盖
    Lsun     = PV_SunlightDirection ; 
    SUNcolor = PV_SunlightColor ;
  #endif
    
    float  sun_tilt = dot(N , Lsun) ;
    float  sun_specfactor = dot(R, Lsun);

    //point lights ====
    float3 PLtotal = float3(0,0,0) ;
    for (int itpl = 0; itpl < min(8, NumPointLights); itpl++ ) //itpl < min(8, NumPointLights)
    {

    #ifdef _3DSMAX_
      break ;
    #endif
    };

    //final mixing 

  #ifdef ALLOW_STEALTH

  #endif  

    return OUTCOLOR; //alpha always 1
};


// ps for mid and low ========================

float4 PS_LOW_FACET (PS_facet_input i) : COLOR 
{
        return 1 ;
};



// EXPRESSIONS AND TECHNIQUE =========================

//#ifdef COMPILE_SOFTSKIN_VS

int VSchooserExpr() 
{   return clamp(NumJointsPerVertex, 0, 2) ; }

VertexShader VS_facet_Array[3] = {
    compile vs_3_0 VS_facet_00skin(), 
    compile vs_3_0 VS_facet_11skin(), 
    compile vs_3_0 VS_facet_22skin(), 
};

VertexShader VS_Shadow_Array[3] = {
    compile vs_2_0 VS_ShadowMaker_00skin(), 
    compile vs_2_0 VS_ShadowMaker_11skin(), 
    compile vs_2_0 VS_ShadowMaker_22skin(), 
    
};

// all alpha test are forbidden



#ifdef _3DSMAX_ //预览

  #define REPLACE_DEFAULT_TECHNIQUE // forbid ingame technique

technique MAXPREV
{    pass p0 
    {
        VertexShader = compile vs_3_0 VS_facet_MAX(); 
        PixelShader = compile ps_3_0 PS_H_FACET();
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
    PixelShader  = compile ps_3_0 PS_H_FACET(); 
    ZEnable = 1;
    ZFunc = 4;
    ZWriteEnable = 1;
  #ifdef RENDER_BACKFACE
    CullMode = 1;
  #else
    CullMode = 2;
  #endif
    AlphaFunc = 7;
    AlphaRef = 0; //95<0.375<96
    AlphaBlendEnable = 0;
    AlphaTestEnable = 0;
  } 
}


technique Default_M 
{    pass p0
  #ifndef IS_BUILDNG
  <string ExpressionEvaluator = "Objects";>
  #endif
  {
    VertexShader = VS_L_Array[ VSchooserExpr() ]; 
    PixelShader  = compile ps_3_0 PS_LOW_FACET(); 
    ZEnable = 1;
    ZFunc = 4;
    ZWriteEnable = 1;
    CullMode = 2;
    AlphaFunc = 7;
    AlphaRef = 0;
    AlphaBlendEnable = 0;
    AlphaTestEnable = 0;
  } 
}


technique _CreateShadowMap
{    pass p0    
  {
    VertexShader = VS_Shadow_Array[ VSchooserExpr()  ]; 
    PixelShader  = compile ps_2_0 PS_ShadowMaker_NoAlphaTest();
    ZEnable = 1;
    ZFunc = 4;
    ZWriteEnable = 1;
    CullMode = 2; //3
    AlphaBlendEnable = 0;
    AlphaTestEnable = 0;
  } 
}

#endif  // REPLACE_DEFAULT_TECHNIQUE ?
