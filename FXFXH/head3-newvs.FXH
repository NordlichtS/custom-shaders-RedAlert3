//#include "PBR1-constants.FXH"
#include "head2-functions.FXH"


//===============================================================
// Unified vertex shader for 0 / 1 / 2 bone cases
// BonePerVertex is a compile-time uniform (shader array style)
//===============================================================

struct VS_basicw3d_optimized_output
{
    float4 Position    : POSITION;
    float4 MainTexUV   : TEXCOORD0;
    float4 dotsun_fresnel_Valpha_Balpha : TEXCOORD1 ;
    float4 VC_ambientRGB_warfog : TEXCOORD2 ;
    float4 VC_cloudRGB_shadow : TEXCOORD3 ;
    float4 ClipSpacePos : TEXCOORD4 ;
    float4 DOT_pl0123 : TEXCOORD5 ; //1 to -1
    float4 DECAYSQ_pl0123 : TEXCOORD6 ; 
    // close 1 edge 0, veryfar -x , need saturate square in ps. actually 1- distsquare
};

struct VS_unified_notgt_input
{
    float4 position     : POSITION;
    float4 normal       : NORMAL;

    float4 position1    : POSITION1;
    float4 normal1      : NORMAL1;

    float4 texcoord     : TEXCOORD;
    float4 texcoord1    : TEXCOORD1;
    float4 color        : COLOR;

    float4 blendindices : BLENDINDICES;
    float4 blendweight  : BLENDWEIGHT;
};

//===============================================================
// Main Vertex Shader with most light calc in VS
//===============================================================
VS_basicw3d_optimized_output VS_L_Unified(VS_unified_notgt_input i, uniform int BonePerVertex)
{
    VS_basicw3d_optimized_output o;

    float4 worldPos4D = float4(i.position.xyz, 1);
    o.MainTexUV   = float4(i.texcoord.xy, i.texcoord1.xy);

    float3 worldP = i.position.xyz ; 
    float3 worldN = i.normal.xyz ;
    float  boneAlpha = 1;

    //=============================
    // -1 bones: 3dsmax special
    #ifdef _3DSMAX_ 
    if (BonePerVertex == -1)    
    {   
        worldP = mul(worldPos4D, MAXworld).xyz;
        worldN = mul(i.normal.xyz, (float3x3)MAXworld); 
    }
    #endif

    //=============================
    // 0 bones: rigid mesh
    if (BonePerVertex == 0)
    {   
        worldP = mul(worldPos4D, World);
        worldN = mul(i.normal.xyz, (float3x3)World); 

        #ifdef OPACITY_AS_NO_BONE_ALPHA
        boneAlpha = OpacityOverride;
        #endif
    }

    //=============================
    // 1 bone : hard skin
    if (BonePerVertex == 1)
    {
        int boneIndex = floor(i.blendindices.x * 2);
        float4 q0   = WorldBones[boneIndex];
        float4 off0 = WorldBones[boneIndex + 1];
        boneAlpha = off0.w;

        #ifdef BONE_ALPHA_SHRINK
        worldPos4D.xyz *= off0.w;
        #endif
        #ifdef SUPPORT_TREAD_SCROLLING
        o.MainTexUV.x += off0.w ;
        boneAlpha = 1 ;
        #endif

        worldP = QuaternionRotate(q0, worldPos4D.xyz) + off0.xyz;
        worldN = QuaternionRotate(q0, i.normal.xyz);
    }

    //=============================
    // 2 bones : soft skin
    if (BonePerVertex == 2)
    {
        int2 boneIndex = floor(i.blendindices.xy * 2);
        float4 q0   = WorldBones[boneIndex.x];
        float4 q1   = WorldBones[boneIndex.y];
        float4 off0 = WorldBones[boneIndex.x + 1];
        float4 off1 = WorldBones[boneIndex.y + 1];

        float3 wp0 = QuaternionRotate(q0, i.position.xyz ) + off0.xyz;
        float3 wp1 = QuaternionRotate(q1, i.position1.xyz ) + off1.xyz;
        float3 wn0 = QuaternionRotate(q0, i.normal.xyz);
        float3 wn1 = QuaternionRotate(q1, i.normal1.xyz);

        worldP = lerp(wp1, wp0, i.blendweight.x);
        worldN = lerp(wn1, wn0, i.blendweight.x);
        boneAlpha = lerp(off1.w, off0.w, i.blendweight.x);
    }

    //==================================================
    // Shared calculations (common to all bone cases)
    //==================================================
    worldPos4D.xyz = worldP;
    o.ClipSpacePos = mul(worldPos4D, ViewProjection);
    #ifdef _3DSMAX_
    o.ClipSpacePos = mul(worldPos4D, mul(MAXview, MAXprojection));
    #endif
    o.Position = o.ClipSpacePos ;

    worldN = normalize(worldN);
    o.VC_ambientRGB_warfog.rgb  = hp_getAccentLight(worldN) /2 + AmbientLightColor;

    float  dotsun = dot(getSUNdir() , worldN);

    float2 fogUV =      getWarfogUV(worldPos4D);
    float2 cloudUV =    getCloudUV(worldPos4D);
    float4 shadowCS =   mul(worldPos4D, ShadowMapWorldToShadow);

    float  fogColor =  tex2Dlod(ShroudTextureSampler, float4(fogUV , 0, 0));
    float3 cloudColor = tex2Dlod(CloudTextureSampler, float4(cloudUV , 0, 1));
    float  shadowColor = hp_vertex_shadow(shadowCS.xyz / shadowCS.w);

    for(int pl = 0; pl < min(4, NumPointLights); pl ++){
        //float3 plrelative = 
    }

    return o;
}

//shadow=======================

struct VS_ShadowMaker_output  //
{
    float4 Position : POSITION;   //VS一定要输出的clip space渲染坐标
    float  Valpha : COLOR1;  //顶点alpha
    float4 MainTexUV : TEXCOORD0; //XY是主帖图UV,ZW是建筑损伤图UV
    float4 ClipSpacePos : TEXCOORD1;  // PERSPECTIVE DIVISION IN PS
};

VS_ShadowMaker_output VS_SHADOW_Unified(VS_unified_notgt_input i, uniform int BonePerVertex)
{
    VS_ShadowMaker_output o;

    float4 worldPos4D = float4(i.position.xyz, 1);
    float3 worldP = i.position.xyz ;
    float  boneAlpha = 1;

    //=============================
    // 0 bones: rigid mesh
    if (BonePerVertex == 0)
    {   
        worldP = mul(worldPos4D, World);

        #ifdef OPACITY_AS_NO_BONE_ALPHA
        boneAlpha = OpacityOverride;
        #endif
    }

    //=============================
    // 1 bone : hard skin
    if (BonePerVertex == 1)
    {
        int boneIndex = floor(i.blendindices.x * 2);
        float4 q0   = WorldBones[boneIndex];
        float4 off0 = WorldBones[boneIndex + 1];
        boneAlpha = off0.w;

        #ifdef BONE_ALPHA_SHRINK
        worldPos4D.xyz *= off0.w;
        #endif
        #ifdef SUPPORT_TREAD_SCROLLING
        o.MainTexUV.x += off0.w ;
        boneAlpha = 1 ;
        #endif

        worldP = QuaternionRotate(q0, worldPos4D.xyz) + off0.xyz;
    }

    //=============================
    // 2 bones : soft skin
    if (BonePerVertex == 2)
    {
        int2 boneIndex = floor(i.blendindices.xy * 2);
        float4 q0   = WorldBones[boneIndex.x];
        float4 q1   = WorldBones[boneIndex.y];
        float4 off0 = WorldBones[boneIndex.x + 1];
        float4 off1 = WorldBones[boneIndex.y + 1];

        float3 wp0 = QuaternionRotate(q0, i.position.xyz ) + off0.xyz;
        float3 wp1 = QuaternionRotate(q1, i.position1.xyz ) + off1.xyz;

        worldP = lerp(wp1, wp0, i.blendweight.x);
        boneAlpha = lerp(off1.w, off0.w, i.blendweight.x);
    }

    //==================================================
    // Shared calculations (common to all bone cases)
    //==================================================
    worldPos4D.xyz = worldP;
    o.ClipSpacePos = mul(worldPos4D, ViewProjection);
    o.Position = o.ClipSpacePos ;
    o.MainTexUV = float4(i.texcoord.xy, i.texcoord1.xy);
    o.Valpha = boneAlpha ;

    return o;
}