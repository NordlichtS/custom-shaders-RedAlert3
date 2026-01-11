//use a second texture as mask ? or the first alpha
/*
fxc.exe /O2 /T fx_2_0 /Fo   basicw3dMASK.fxo   basicw3dMASK.FX
fxc.exe /O2 /T fx_2_0 /Fo   (FOR_3DSMAX_ONLY)basicw3dMASK.fxo   basicw3dMASK.FX


*/
#define IGNORE_FOG_CLOUD_SHADOW
//#define _3DSMAX_


#define SPECIAL_SAS_HEADER

int _SasGlobal : SasGlobal  
<
    int3 SasVersion = int3(1, 0, 0);
    string UIWidget = "None";
    int MaxSupportedInstancingMode = 1;
    int MaxLocalLights = 0;
    
	string RenderBin = "StaticSort1";

> = 0;



int BlendMode <string UIName = "BlendMode(012:opaque/alpha/add)"; int UIMin = 0; int UIMax = 2;> = 2 ;

int BaseUV <string UIName = "BaseUV(0123:uv0/uv1/world/screen)"; int UIMin = -1; int UIMax = 4;> = 0;
int MaskUV <string UIName = "MaskUV(0123:uv0/uv1/world/scrern)"; int UIMin = -1; int UIMax = 4;> = -1;

int MaskChannel <string UIName = "MaskChannel(1234RGBA,-1234invert)"; int UIMin = -4; int UIMax = 4;> = 2;
bool UseRecolorColors <string UIName = "UseRecolorColors";> = 0;
bool HouseColorPulse  <string UIName = "HouseColorPulse";> = 0;

//bool UseSunlight <string UIName = "UseSunlight(USELESS)";> = 0;
//float3 ColorDiffuse  <string UIName = "ColorDiffuse"; string UIWidget = "Color";> = 1;
float3 ColorEmissive <string UIName = "ColorEmissive"; string UIWidget = "Color";> = 1;
float EmissiveHDRMultipler <string UIName = "EmissiveHDRMultipler"; string UIWidget = "Slider";float UIMin = 0; float UIMax = 64;> =1.25;

// ACTUAL COLOR = TEXTURE * (EMMISIVE or HC) * HDR

float Opacity <string UIName = "Opacity(Center)"; string UIWidget = "Slider"; float UIMin = 0; float UIMax = 1;> = 0.25 ;
float EdgeFadeOut <string UIName = "EdgeFadeOut"; string UIWidget = "Spinner"; float UIMin = -1; float UIMax = 1;> = -0.5 ;
//EFO <0 means edge alpha = 1 , usually 0
//float RimFadeOut <string UIName = "RimFadeOut"; string UIWidget = "Spinner"; float UIMin = -1; float UIMax = 1;> = 0 ;
// ECO <0 means fade to transparent, else brighter


texture Texture_0 <string UIName = "Texture_0(base)";>; 
sampler2D Texture_0Sampler <string Texture = "Texture_0";> =
sampler_state{
    Texture = <Texture_0>; 
    MinFilter = 2; //
    MagFilter = 2; //linear
    MipFilter = 2;
    AddressU = 1;
    AddressV = 1;
};
texture Texture_1 <string UIName = "Texture_1(mask)";>; 
sampler2D Texture_1Sampler <string Texture = "Texture_1";> =
sampler_state{
    Texture = <Texture_1>; 
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 0;
    //MIPMAPLODBIAS = -2 ;
    AddressU = 1;
    AddressV = 1;
};


#include "head2-functions.FXH"  // hahahahahahahaha


//vs=========================

struct VStmp_out
{
    float4 Position    : POSITION;
    float4 MainTexUV   : TEXCOORD0;
    float4 dotsun_fresnel_Valpha_Balpha : TEXCOORD1 ;
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
VStmp_out VS_L_Unified(VS_unified_notgt_input i, uniform int BonePerVertex)
{
    VStmp_out o;

    float4 worldPos4D = float4(i.position.xyz, 1);
    float3 worldP = i.position.xyz ; 
    float3 worldN = i.normal.xyz ;
    float boneAlpha = 1;
    float vertexAlpha = i.color.a ;

    //=============================
    // -1 bones: 3dsmax special
    #ifdef _3DSMAX_ 
    if (BonePerVertex == -1)    
    {   
        worldP = mul(worldPos4D, MAXworld).xyz;
        worldN = mul(i.normal.xyz, (float3x3)MAXworld); 
        boneAlpha = saturate(Time /8) ;
    }
    #endif

    //=============================
    // 0 bones: rigid mesh
    if (BonePerVertex == 0)
    {   
        worldP = mul(worldPos4D, World);
        worldN = mul(i.normal.xyz, (float3x3)World); 
        boneAlpha = OpacityOverride;
    }

    //=============================
    // 1 bone : hard skin
    if (BonePerVertex == 1)
    {
        int boneIndex = floor(i.blendindices.x * 2);
        float4 q0   = WorldBones[boneIndex];
        float4 off0 = WorldBones[boneIndex + 1];
        worldP = QuaternionRotate(q0, worldPos4D.xyz) + off0.xyz;
        worldN = QuaternionRotate(q0, i.normal.xyz);
        boneAlpha = off0.w;
        vertexAlpha *= OpacityOverride ;
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
        vertexAlpha *= OpacityOverride ;

    }

    //==================================================
// Shared calculations (common to all bone cases)

    worldPos4D.xyz = worldP;
    float4 ClipSpacePos = mul(worldPos4D, getVPmatrix());

    worldN = normalize(worldN);
    float3 worldpos2eye = worldP - getEYEpos() ;
    float3 viewvec = normalize(- worldpos2eye);

    float dotsun = dot(getSUNdir() , worldN);
    float sharpness = abs(EdgeFadeOut);
    float fresnel = 1 ; 
    if(sharpness > 0.01 ) //
    { fresnel = dot(viewvec, worldN) / sharpness ; }
    //center always 1, edge maybe 0 or 1
    //in ps : lerp edge center fr

    float2 uvtypes[4] ;
    uvtypes[0] = i.texcoord.xy ;
    uvtypes[1] = i.texcoord1.xy ;
    uvtypes[2] = worldP.xy /64 ; 
    uvtypes[3] = ClipSpacePos.xy / ClipSpacePos.w * 0.5 + 0.5 ;
    float2 baseuv = uvtypes[ clamp( BaseUV, 0,3) ] ;
    float2 maskuv = uvtypes[ clamp( MaskUV, 0,3) ] ;

    const float margin = 2/256 ;
    o.dotsun_fresnel_Valpha_Balpha.x = dotsun ;
    o.dotsun_fresnel_Valpha_Balpha.y = fresnel ;
    o.dotsun_fresnel_Valpha_Balpha.z = vertexAlpha ;
    o.dotsun_fresnel_Valpha_Balpha.w = boneAlpha *(1 + 2* margin) -margin;
    o.Position = ClipSpacePos ;
    o.MainTexUV = float4(baseuv, maskuv);

    return o;
}

// ps =======================

struct PSmask_in
{
    float4 MainTexUV   : TEXCOORD0;
    float4 dotsun_fresnel_Valpha_Balpha : TEXCOORD1 ;
    float2 vpos : VPOS ;
};

float4 PS_gradient_mask (PSmask_in i) : COLOR 
{
    float2 ssTexUV = (i.vpos + 0.5) /256 ;
    float3 colorMultiplier = 1 ;
    float  alphaMultiplier = 1 ;
    float2 baseuv = (BaseUV == -1) ? ssTexUV : i.MainTexUV.xy ;
    float2 maskuv = (MaskUV == -1) ? ssTexUV : i.MainTexUV.zw ;    

    float maskvalue = -1 ; //default: mask always below scan, always show
    float scanvalue = i.dotsun_fresnel_Valpha_Balpha.a ;
    //finding mask
    float4 maskTEXcolor = -1 ;
    if(MaskChannel != 0){
        maskTEXcolor = tex2D(Texture_1Sampler, maskuv) ; //sample mask
        maskvalue = maskTEXcolor[ clamp( abs(MaskChannel) -1 , 0, 3 ) ];
        maskvalue = (MaskChannel <0)? (1- maskvalue) : maskvalue ;
    };

    //hiding is decided here =========================
    //#ifndef _3DSMAX_
    if(scanvalue < maskvalue) return float4(0,0,0,0) ; 
    //#endif
    //hide pixel, early terminate ====================

    float4 baseTEXcolor = tex2D(Texture_0Sampler, baseuv)  ;  //sample base
    //house color handle
    float3 realHC = (HasRecolorColors)? RecolorColor : 1;
    colorMultiplier *= (UseRecolorColors)? realHC : ColorEmissive ;
    if(HouseColorPulse) //ripple effect
    {  colorMultiplier += realHC * frac(maskvalue - Time) ; }
    colorMultiplier *= baseTEXcolor.rgb ;
    colorMultiplier *= colorMultiplier * EmissiveHDRMultipler ; //SRGB to linear

    //opacity handle
    alphaMultiplier *= i.dotsun_fresnel_Valpha_Balpha.z ;
    float edgeAlpha = (EdgeFadeOut <0 )? 1 : 0 ;
    float fresnel = smoothstep(0, 1, abs(i.dotsun_fresnel_Valpha_Balpha.y));
    alphaMultiplier *= lerp(edgeAlpha, Opacity, fresnel) ;
    alphaMultiplier *= i.dotsun_fresnel_Valpha_Balpha.z ;

    // rim handle
    float rim = (scanvalue - maskvalue) *64 ;
    rim = saturate(1 - rim);

    float4 finalcolor = float4(colorMultiplier.rgb, 1);
    if(BlendMode == 1){
        finalcolor.a = alphaMultiplier * baseTEXcolor.a;
    }else{
        finalcolor.rgb *= alphaMultiplier;
    };
    finalcolor.rgb += realHC * rim ;

    #ifdef _3DSMAX_
    if(PV_SRGB) finalcolor.rgb = sqrt(finalcolor.rgb);
    //if(scanvalue < maskvalue) finalcolor = 0 ; 
    #endif

    return finalcolor;
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

technique Default
{
    pass P0 <string ExpressionEvaluator = "BasicW3D";>
    {
        #ifdef _3DSMAX_
        VertexShader = compile vs_3_0 VS_L_Unified(-1) ;
        #else
        VertexShader = VS_Array[VSchooserExpr()]; 
        #endif
        PixelShader = compile ps_3_0 PS_gradient_mask(); 
        ZEnable = 1; //true
        ZFunc = 4; //ZFUNC_INFRONT
        AlphaFunc = 7; //GreaterEqual
        AlphaRef = 2; // 2/255

        #ifdef _3DSMAX_
		ZWriteEnable = ( DepthWriteEnable );
		CullMode = ( CullingEnable ? D3DCULL_CW : D3DCULL_NONE );
		AlphaTestEnable = ( AlphaTestEnable );
		AlphaBlendEnable = ( BlendMode != 0  );
		SrcBlend = ( (BlendMode == 2) ? D3DBLEND_ONE : D3DBLEND_SRCALPHA );
		DestBlend = ( (BlendMode == 2) ? D3DBLEND_ONE : D3DBLEND_INVSRCALPHA );
        #endif
    }
}