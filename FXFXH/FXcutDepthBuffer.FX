/*

fxc.exe /O2 /T fx_2_0 /Fo   FXcutDepthBuffer.FXO   FXcutDepthBuffer.FX

*/
// THIS CAN DRILL A HOLE ON TERRAIN DEPTH BUFFER

// #define _3DSMAX_
// #define FORBID_CLIPPING_CONSTANT
#define IGNORE_SHROUD_CLOUD_SHADOW
#define FORBID_FACTION_COLOR
#define SPECIAL_SAS_HEADER

int _SasGlobal : SasGlobal  
<
    int3 SasVersion = int3(1, 0, 0);
    string UIWidget = "None";
    int MaxSupportedInstancingMode = 1;
    int MaxLocalLights = 0;
	string RenderBin = "Bridge"; //TBC
> = 0;

//RENDER SORT: renderTerrain, TerrainLikeGroundObject, Bridge, renderProps, RenderCasters_Units



#include "head0-common.FXH"

// FOR PREVIEW ===========
#ifdef _3DSMAX_

float4x4 MAXwvp : WORLDVIEWPROJECTION;

float4 VS_MAX(float4 Position : POSITION) :POSITION
{   return mul(Position, MAXwvp);    }

float4 PS_MAX_BACKFACE(float2 vpos:VPOS ) : COLOR0
{   return float4(0.3 , 0.4 , 0.2, 1);    }

float4 PS_MAX_WIREFRAME(float vface:VFACE ) : COLOR0
{   return (vface < 0)? float4(0.8 , 0.4 , 0.6, 1) : float4(0.4 , 0.2 , 0.8, 1);  }
// {   return lerp( float4(1,0,0,1) , float4(0,0,1,1) , frac(vpos.y * 0.25));}

technique MAXPREV
{
    pass P0  //SOLID FILL, RENDER BACKFACE, NORMAL Z TEST
    {
        FillMode = SOLID;
        VertexShader = compile vs_3_0 VS_MAX();
        PixelShader  = compile ps_3_0 PS_MAX_BACKFACE();
        ZEnable      = 1;
        ZWriteEnable = 1;
        ZFunc        = LESSEQUAL;
        AlphaBlendEnable = 0;
        AlphaTestEnable = 0;
        CullMode = 3;  //INV
    }
    pass P1  //WIREFRAME, RENDER BOTH SIDE, NORMAL Z TEST
    {
        FillMode = WIREFRAME;
        VertexShader = compile vs_3_0 VS_MAX();
        PixelShader  = compile ps_3_0 PS_MAX_WIREFRAME();
        ZEnable      = 1;
        ZWriteEnable = 1;
        ZFunc        = LESSEQUAL;
        AlphaBlendEnable = 0;
        AlphaTestEnable = 0;
        CullMode = 1;  //none
        //DepthBias = float(-2.0 / 65536.0);
    }

}
#endif  //  _3DSMAX_  

// PREVIEW END =====================


//ACTUAL INGAME 
// --- Vertex Shader ---
float4 VS_MAIN(float4 Position : POSITION) : POSITION
{
    float4 worldP = float4 (0,0,0,1);
    worldP.xyz = mul(float4(Position.xyz, 1), World);
    float4 clipspace = mul(worldP, ViewProjection) ;
    return clipspace ;
}


// --- Pixel Shader ---
float4 PS_BLACK() : COLOR0
{    return float4(0,0,0,0);    }

float4 PS_WHITE() : COLOR0
{    return float4(1,1,1,1);    }



// --- Technique ---


technique Default
{
    // ==========================================
    // MARKER PASS Mark Stencil (where to draw, avoid cliff)
    // ==========================================
    pass P0
    {
        VertexShader = compile vs_2_0 VS_MAIN();
        PixelShader  = compile ps_2_0 PS_BLACK();
        // Pixel shader is technically USELESS since color write off.

        AlphaBlendEnable = 0;
        AlphaTestEnable = 0;

        CullMode = 2;          // CCW (Counter-Clockwise). Process the front-facing walls of the volume.
        ZEnable = 1;           // True. Enable the depth test to check if anything is blocking the hole.
        ZWriteEnable = 0;      // False. Do not modify the existing depth buffer yet.
        ZFunc = 4;             // LessEqual. Only pass if the cylinder front is in front of the ground.
        
        ColorWriteEnable = 0;  // Disable writing to the screen. We only want to generate a mask.

        StencilEnable = 1;     // True. Turn on the stencil pipeline.
        StencilRef = 128;      // Ref value: (Binary: 10000000). We are using the 8th bit.
        StencilMask = 128;     // Read mask: (Binary: 10000000). Isolate the 8th bit when comparing.
        StencilWriteMask = 128;// Write mask (Binary: 10000000). Protect bits 1-7; only write to the 8th bit.
        
        StencilFunc = 8;       // Always. The stencil test always passes; we rely on the Z-test (ZFunc) instead.
        StencilPass = 3;       // Replace. If both Stencil and Z-test pass, overwrite the 8th bit with 128.
        StencilFail = 1;       // Keep. Do not change the stencil buffer if the stencil test fails.
        StencilZFail = 1;      // Keep. Do not change the stencil buffer if an object (like a tree) blocks the hole.


    }

    // ==========================================
    // WRITER PASS: Push Depth & Draw Interior
    // ==========================================
    pass P1
    {
        VertexShader = compile vs_2_0 VS_MAIN();
        PixelShader  = compile ps_2_0 PS_BLACK();

        AlphaBlendEnable = 0;
        AlphaTestEnable = 0;

        CullMode = 3;          // CW (RA3 INVERT CULL). Process the back-facing walls of the volume.
        ZEnable = 1;           // True. Enable depth testing.
        ZWriteEnable = 1;      // True. Crucial: We are actively overwriting ("drilling") the depth buffer here.
        ZFunc = 7;             // GreaterEqual. Only pass if the cylinder's back wall is deeper than the current ground.
        
        ColorWriteEnable = 15; // Write RGBA (Binary: 00001111). paint black the visual interior textures of the hole.

        StencilEnable = 1;     // True. Turn on the stencil pipeline.
        StencilRef = 128;      // Ref value:  (Binary: 10000000). Match against the footprint from Pass 0.
        StencilMask = 128;     // Read mask:  (Binary: 10000000). Isolate the 8th bit for evaluation.
        StencilWriteMask = 0;  // Write mask  (Binary: 00000000). Lock the stencil buffer; this pass cannot change it.
        
        StencilFunc = 3;       // Equal. Only execute this pixel if the 8th bit was marked as 128 in Pass 0.
        StencilPass = 1;       // Keep. Leave the stencil value alone when rendering.
        StencilFail = 1;       // Keep. Leave the stencil value alone if it wasn't part of the footprint.
        StencilZFail = 1;      // Keep. Leave the stencil value alone if the depth test fails.

    }
}

//  EXACTLY THE SAME FOR SHADOW
//  SHADOW ALSO USE D24S8 BUFFER
// i tried with bit 0x8
// but now we all use 128
technique _CreateShadowMap
{    
    pass P0
    {
        VertexShader = compile vs_2_0 VS_MAIN();
        PixelShader  = compile ps_2_0 PS_WHITE();
        AlphaBlendEnable = 0;
        AlphaTestEnable = 0;
        ColorWriteEnable = 0; //

        CullMode = 2;  //STANDARD
        ZEnable = True;
        ZWriteEnable = False;
        ZFunc = LessEqual;

        StencilEnable = True;
        StencilRef = 128;       
        StencilMask = 128;      
        StencilWriteMask = 128; 
        StencilFunc = Always;
        StencilPass = Replace;   // Mark the footprint with 0x08
        StencilFail = Keep;     
        StencilZFail = Zero;    //Keep?
    }

    // ==========================================
    // WRITER PASS: Push Depth & Draw Interior
    // ==========================================
    pass P1
    {
        VertexShader = compile vs_2_0 VS_MAIN();
        PixelShader  = compile ps_2_0 PS_WHITE();

        AlphaBlendEnable = 0;
        AlphaTestEnable = 0;

        CullMode = 3;   //RA3 INVERT CULL
        ColorWriteEnable = 7; // RGB= 7 , RGBA= 15
        ZEnable = True;
        ZWriteEnable = True;
        ZFunc = GreaterEqual; //INV

        StencilEnable = True;
        StencilRef = 128;
        StencilMask = 128;      // Look specifically for our Bit 3
        StencilWriteMask = 128; // Allow clearing our bit
        StencilFunc = Equal;     // Only draw where P0 marked the stencil
        StencilPass = Zero;     // CLEANUP: Set bit back to 0    
        StencilFail = Keep;     //safety
        StencilZFail = Zero;    //clear bit for the whole mesh
    }

}

/*

water avoid 

pass P2
    {
        // --- Geometry and Depth (WATER ALREADY HAS THAT) ---
        CullMode = 2;          // CCW . Standard front-face culling for regular meshes.
        ZEnable = 1;           // True. Standard depth testing so water respects the surrounding terrain.
        ZWriteEnable = 1;      // True. Standard behavior allowing water to write its own depth data.
        ZFunc = 4;             // LessEqual. Standard rendering depth test comparison behavior.
        ColorWriteEnable = 15; // Write RGBA (Binary: 00001111). Render the water color to the screen.

        // --- Stencil Configuration ---
        StencilEnable = 1;     // True. Turn on the stencil pipeline.
        StencilRef = 0;        // Ref value  (Binary: 00000000). We want to match pixels where the bit is NOT set.
        StencilMask = 128;     // Read mask  (Binary: 10000000). Check only the 8th bit, completely ignoring other game UI bits.
        StencilWriteMask = 0;  // Write mask (Binary: 00000000). Lock the stencil buffer; water shouldn't modify it.
        
        StencilFunc = 3;       // Equal. Passes only if (Buffer & 128) == 0. This discards water inside the hole footprint.
        StencilPass = 1;       // Keep. Do not alter stencil values when rendering the water.
        StencilFail = 1;       // Keep. Do not alter stencil values when water is skipped/discarded.
        StencilZFail = 1;      // Keep. Do not alter stencil values if water fails the depth check.
    }

*/