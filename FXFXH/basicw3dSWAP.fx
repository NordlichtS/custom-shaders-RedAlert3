//MOVE UV BY OPACITY
/*
fxc.exe /O2 /T fx_2_0 /Fo   basicw3dSWAP.fxo   basicw3dSWAP.FX

fxc.exe /O2 /T fx_2_0 /Fo   MAX_basicw3dSWAP.fxo   basicw3dSWAP.FX

*/

// #define _3DSMAX_
#define IGNORE_FOG_CLOUD_SHADOW //阳光阴影之类的计算全部去掉
#define FORBID_CLIPPING_CONSTANT //忽视common里面的各种 test enable
//#define USE_EDGE_FADE_OUT // 启用 EdgeFadeOut 而不是 NoCloudMultiplier
//#define USE_OWN_EDGEFADEOUT // 用自己的 而不是common里面的C3 避免重定义

//#define QuaternionRotate Quaternion_RotateVector

#define SPECIAL_SAS_HEADER

////////////////////////

 #include "COMMON.FXH"  // this must be as early as possible



int _SasGlobal : SasGlobal  
<
    int3 SasVersion = int3(1, 0, 0);
    string UIWidget = "None";
    int MaxSupportedInstancingMode = 1;
    int MaxLocalLights = 0;
    
	string RenderBin = "StaticSort1"; // 最后渲染

> = 0;



int BlendMode <string UIName = "BlendMode(012:opaque/alpha/add)"; int UIMin = 0; int UIMax = 2;> = 1 ;


bool UseRecolorColors <string UIName = "UseRecolorColors";> = 0;

float4 ColorMult_0 <string UIName = "ColorMult_0"; string UIWidget = "Color";> = 1;
float4 ColorMult_1 <string UIName = "ColorMult_1"; string UIWidget = "Color";> = 1;

bool SWAP_progress <string UIName = "SWAP_progress(0:mesh/1:bone)";> = 1 ;
bool SWAP_invert <string UIName = "SWAP_invert";> = 1 ;
float SWAP_autoFrequency <string UIName = "SWAP_autoFrequency(HZ)"; float UIMin = -16; float UIMax = 16;> = 1 ;

//float EdgeFadeOut <string UIName = "EdgeFadeOut"; string UIWidget = "Spinner"; float UIMin = -1; float UIMax = 1;> = -0.5 ;
//EFO <0 means edge alpha = 1 and center fade , usually 0

bool AlphaTestEnable    < string UIName = "Alpha Test Enable";> = 0;
bool CullingEnable      < string UIName = "Culling Enable";> = 1;
bool DepthWriteEnable   < string UIName = "Depth Write Enable";> = 0;
bool DepthTestEnable    < string UIName = "Depth Test Enable";> = 0; //false for always show



texture Texture_0 <string UIName = "Texture_0";>; 
sampler2D Texture_0Sampler <string Texture = "Texture_0";> =
sampler_state{
    Texture = <Texture_0>; 
    MinFilter = 2; //
    MagFilter = 2; //linear
    MipFilter = 2;
    MIPMAPLODBIAS = -1 ;
    AddressU = 1; //wrap cycle
    AddressV = 1;
};



// #include "head2-functions.FXH"  // hahahahahahahaha


//vs=========================

struct VStmp_out
{
    float4 Position    : POSITION ;
    float2 MainTexUV   : TEXCOORD0 ;
    float4 ColorMult   : TEXCOORD1 ;
    float3 WorldPE     : TEXCOORD2 ; //relative to eye
};

struct VS_unified_notgt_input
{
    float4 position     : POSITION;
    //float4 normal       : NORMAL;

    float4 position1    : POSITION1;
    //float4 normal1      : NORMAL1;

    float4 texcoord0    : TEXCOORD0;
    float4 texcoord1    : TEXCOORD1;
    float4 color        : COLOR;

    float4 blendindices : BLENDINDICES;
    float4 blendweight  : BLENDWEIGHT;
};

//===============================================================
// Main Vertex Shader 

VStmp_out VS_L_Unified(VS_unified_notgt_input i, uniform int BonePerVertex)
{
    VStmp_out o;

    float4 worldPos4D = float4(i.position.xyz, 1);
    float3 worldP = i.position.xyz ; 
    //float3 worldN = i.normal.xyz ;
    float boneAlpha = 1;

    //=============================
    // -1 bones: 3dsmax special
    #ifdef _3DSMAX_ 
    if (BonePerVertex == -1)    
    {   
        worldP = mul(worldPos4D, MAXworld).xyz;
        boneAlpha = frac(Time /8 * SWAP_autoFrequency); ;
    }
    #endif

    //=============================
    // 0 bones: rigid mesh
    if (BonePerVertex == 0)
    {   
        worldP = mul(worldPos4D, World);
        boneAlpha = frac(Time * SWAP_autoFrequency);
    }

    //=============================
    // 1 bone : hard skin
    if (BonePerVertex == 1)
    {
        int boneIndex = floor(i.blendindices.x * 2);
        float4 q0   = WorldBones[boneIndex];
        float4 off0 = WorldBones[boneIndex + 1];
        worldP = QuaternionRotate(q0, worldPos4D.xyz) + off0.xyz;
        boneAlpha = off0.w;
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

    worldPos4D.xyz = worldP;
    float4 ClipSpacePos = mul(worldPos4D, getVPmatrix());
    float realprogress = (SWAP_progress)? boneAlpha : OpacityOverride;
    realprogress = (SWAP_invert)? (1 - realprogress) : realprogress ;
    float2 realUV = lerp(i.texcoord0.xy, i.texcoord1.xy, realprogress);
    float4 realColorMult = lerp(ColorMult_0, ColorMult_1, realprogress) ;

    o.Position = ClipSpacePos ;
    o.MainTexUV = realUV ;
    o.ColorMult = realColorMult ;
    o.WorldPE = worldP - getEYEpos(); 

    return o;
}

// ps =======================

struct PSmask_in
{
    float2 MainTexUV   : TEXCOORD0 ;
    float4 ColorMult   : TEXCOORD1 ;
    float3 WorldPE     : TEXCOORD2 ; //relative to eye
    float2 vpos : VPOS ;
};

float4 PS_gradient_mask (PSmask_in i) : COLOR 
{

    float4 pixcolor = tex2D(Texture_0Sampler, i.MainTexUV)  ;  //sample base, RGBA
    pixcolor *= i.ColorMult ;

    if(HasRecolorColors && UseRecolorColors){
        pixcolor.rgb = dot(pixcolor.rgb, 0.5)  ;
        pixcolor.rgb *= RecolorColor ;
    }

    pixcolor.rgb *= pixcolor.rgb ; //SRGB to linear ;
    float4 finalcolor = pixcolor;

    #ifdef _3DSMAX_
    if(PV_SRGB) finalcolor.rgb = sqrt(finalcolor.rgb);
    #endif

    return finalcolor;
}

// finish ===============================


//#ifndef _3DSMAX_
VertexShader VS_basic_array[3] = {
    compile vs_3_0 VS_L_Unified(0), 
    compile vs_3_0 VS_L_Unified(1), 
    compile vs_3_0 VS_L_Unified(2) //disable nrm for soft skin
};
//#endif

technique Default
{
    pass P0 <string ExpressionEvaluator = "BasicW3D";>
    {
        #ifdef _3DSMAX_
        VertexShader = compile vs_3_0 VS_L_Unified(-1);
        #else
        VertexShader = VS_basic_array[ clamp(NumJointsPerVertex, 0, 2) ]; 
        #endif
        PixelShader = compile ps_3_0 PS_gradient_mask(); 
        
        ZFunc = 4; //ZFUNC_INFRONT
        AlphaFunc = 7; //GreaterEqual
        AlphaRef = 1; // 1/255

		CullMode = ( CullingEnable ? D3DCULL_CW : D3DCULL_NONE );

        ZEnable = ( DepthTestEnable ); // false for always show
		ZWriteEnable = ( DepthWriteEnable );
		AlphaTestEnable = ( AlphaTestEnable );
		AlphaBlendEnable = ( BlendMode != 0  );
		// SrcBlend =  ( (BlendMode != 0) ? D3DBLEND_ONE : D3DBLEND_SRCALPHA );
        SrcBlend = D3DBLEND_SRCALPHA ;
		DestBlend = ( (BlendMode == 2) ? D3DBLEND_ONE : D3DBLEND_INVSRCALPHA );

        /*
        #ifdef _3DSMAX_
		ZWriteEnable = ( DepthWriteEnable );
		CullMode = ( CullingEnable ? D3DCULL_CW : D3DCULL_NONE );
		AlphaTestEnable = ( AlphaTestEnable );
		AlphaBlendEnable = ( BlendMode != 0  );
		SrcBlend = ( (BlendMode == 2) ? D3DBLEND_ONE : D3DBLEND_SRCALPHA );
		DestBlend = ( (BlendMode == 2) ? D3DBLEND_ONE : D3DBLEND_INVSRCALPHA );
        #endif
        */
    }
}