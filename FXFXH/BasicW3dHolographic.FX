//  THIS SHADER IS FOR OVERRIDE ONLY 
//  IT HAS NO ADJUSTABLE CONSTANT, 
//  AND OF COURSE NO TEXTURES

#define IGNORE_FOG_CLOUD_SHADOW
//#define _3DSMAX_


#define SPECIAL_SAS_HEADER

int _SasGlobal : SasGlobal  
<
    int3 SasVersion = int3(1, 0, 0);
    string UIWidget = "None";
    int MaxSupportedInstancingMode = 1;
    int MaxLocalLights = 0;
    
	string RenderBin = "StaticSort4";
> = 0;




#include "head2-functions.FXH"  // hahahahahahahaha


//vs=========================

struct VStmp_out
{
    float4 Position    : POSITION;
    float4 ClipSpacePos  : TEXCOORD1 ;
    float4 WorldP_fromEye_BoneAlpha : TEXCOORD2 ;
};

struct VS_unified_onlypos_input
{
    float4 position     : POSITION;
    //float4 normal       : NORMAL;

    float4 position1    : POSITION1;
    //float4 normal1      : NORMAL1;

    //float4 texcoord     : TEXCOORD;
    //float4 texcoord1    : TEXCOORD1;
    //float4 color        : COLOR;

    float4 blendindices : BLENDINDICES;
    float4 blendweight  : BLENDWEIGHT;
};

//===============================================================
// Main Vertex Shader with most light calc in VS
//===============================================================
VStmp_out VS_L_Unified(VS_unified_onlypos_input i, uniform int BonePerVertex)
{
    VStmp_out o;

    float4 worldPos4D = float4(i.position.xyz, 1);
    float3 worldP = i.position.xyz ; 
    float boneAlpha = 1;

    //=============================
    // -1 bones: 3dsmax special
    #ifdef _3DSMAX_ 
    if (BonePerVertex == -1)    
    {   
        worldP = mul(worldPos4D, MAXworld).xyz;
    }
    #endif

    // 0 bones: rigid mesh
    if (BonePerVertex == 0)
    {   
        worldP = mul(worldPos4D, World);
        boneAlpha = 1; //!
    }

    // 1 bone : hard skin
    if (BonePerVertex == 1)
    {
        int boneIndex = floor(i.blendindices.x * 2);
        float4 q0   = WorldBones[boneIndex];
        float4 off0 = WorldBones[boneIndex + 1];
        worldP = QuaternionRotate(q0, worldPos4D.xyz) + off0.xyz;
        boneAlpha = off0.w;
    }

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
    // Shared calculations 

    worldPos4D.xyz = worldP;
    o.ClipSpacePos = mul(worldPos4D, getVPmatrix());
    o.Position = o.ClipSpacePos ;

    o.WorldP_fromEye_BoneAlpha.xyz = worldP - getEYEpos() ;
    o.WorldP_fromEye_BoneAlpha.w = boneAlpha;

    return o;
}


// VS END, PS START

struct PStmp_in
{
    //float4 ClipSpacePos  : TEXCOORD1 ;
    float4 WorldP_fromEye_BoneAlpha : TEXCOORD2 ;
    float2 vpos : VPOS ;
};

float4 PS_holographic (PStmp_in i) : COLOR 
{
    // first do holo grid
    float3 WorldEyeDir = i.WorldP_fromEye_BoneAlpha.xyz ;
    float3 WorldP = WorldEyeDir + getEYEpos();
    //float3 NDCpos = i.ClipSpacePos.xyz / i.ClipSpacePos.w ;


    //choice cube
    float3 gridcoord = WorldP;
    gridcoord.z += Time ;
    // gridcoord.xy = mul(gridcoord.xy , float2x2(1,-1,1,1));  gridcoord.z *= 1.5 ;
    gridcoord = frac(gridcoord /4) *2 -1 ; //4 is grid separation
    gridcoord *= gridcoord ; 
    float dist2grid = max(gridcoord.z, max(gridcoord.x, gridcoord.y)); 

    //choice line
    //float scanphase = frac((i.vpos.y - Time) / 8) ;
    // choice world line
    //float scanphase = frac((WorldEyeDir.z - Time) / 1) ;

    float Fterm ;
    Fterm = hp_getFacetFresnelCheapRewrite(WorldEyeDir);

    //optional, facet fresnel ?
    /*
    float3 N = cross(ddy(WorldEyeDir), ddx(WorldEyeDir)) ;
    N = normalize(N); //backface correction not needed
    float3 V = - normalize(WorldEyeDir);
    Fterm = 1.25- abs( dot(N, V) );
    */

    float4 FinalColor = 1;
    FinalColor.rgb *= min((1 - dist2grid) , ( 0.125 + Fterm )) ;
    FinalColor.rgb *= (HasRecolorColors)? RecolorColor : 1 ;

    #ifdef _3DSMAX_
    if(PV_SRGB) { FinalColor.xyz = sqrt(FinalColor.xyz) ; } //linear to srgb
    #endif
    return FinalColor;
}



// finish ===============================

int VSchooserExpr() 
{   return clamp(NumJointsPerVertex, 0, 2) ; }

#ifndef _3DSMAX_
VertexShader VS_Array[3] = {
    compile vs_3_0 VS_L_Unified(0), 
    compile vs_3_0 VS_L_Unified(1), 
    compile vs_3_0 VS_L_Unified(2), //disable nrm for soft skin
};
#endif

static const int BlendMode <string UIName = "BlendMode(012:opaque/alpha/add)"; int UIMin = 0; int UIMax = 2;> = 2 ;

technique Default
{
    pass P0 <string ExpressionEvaluator = "BasicW3D";>
    {
        #ifdef _3DSMAX_
        VertexShader = compile vs_3_0 VS_L_Unified(-1) ;
        #else
        VertexShader = VS_Array[VSchooserExpr()]; 
        #endif
        PixelShader = compile ps_3_0 PS_holographic(); 
        ZEnable = 1; //true
        ZFunc = 4; //ZFUNC_INFRONT
		AlphaTestEnable = 0;
		AlphaBlendEnable = 1;
		SrcBlend =  D3DBLEND_ONE ;
		DestBlend = D3DBLEND_ONE ;
        CullMode = D3DCULL_CW ;

        #ifdef _3DSMAX_
		ZWriteEnable = ( DepthWriteEnable ); 
        #else
		ZWriteEnable = 0 ; 
        #endif
    }
}