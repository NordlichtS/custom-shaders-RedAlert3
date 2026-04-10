/*

fxc.exe /O2 /T fx_2_0 /Fo   FXcutDepthBuffer.FXO   FXcutDepthBuffer.FX

*/
// THIS CAN DRILL A HOLE ON TERRAIN DEPTH BUFFER

// #define _3DSMAX_
// #define FORBID_CLIPPING_CONSTANT
#define IGNORE_FOG_CLOUD_SHADOW
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

//todo: find render bin

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

        CullMode = 2;  //STANDARD
        ColorWriteEnable = 0; //

        // Standard Z-test, but DO NOT write to Z-buffer
        ZEnable = True;
        ZWriteEnable = False;
        ZFunc = LessEqual;

        StencilEnable = True;
        StencilRef = 0x8;       // Use 3rd Bit (Value 8)
        StencilMask = 0x8;      // Only read 3rd Bit 
        StencilWriteMask = 0x8; // Only write to 3rd Bit 
        StencilFunc = Always;
        StencilPass = Replace;   // Mark the footprint with 0x08
        StencilFail = Keep;
        StencilZFail = Zero;    //keep?
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

        CullMode = 3;  //RA3 INVERT CULL
        ColorWriteEnable = 15; // RGB= 7 , RGBA= 15

        // Enable Z-write to "push" the depth buffer.
        // GreaterEqual : only write if the backface is deeper than ground.
        ZEnable = True;
        ZWriteEnable = True;
        ZFunc = GreaterEqual; 

        // Require the stencil footprint from Pass 1
        StencilEnable = True;
        StencilRef = 0x8;
        StencilMask = 0x8;      // Look specifically for our 3rd Bit 
        StencilWriteMask = 0x8; // Allow clearing our bit
        StencilFunc = Equal;     // Only draw where P0 marked the stencil
        StencilPass = Zero;     // CLEANUP: Set bit back to 0 after drill  
        StencilFail = Keep;     //safety
        StencilZFail = Zero;    //clear bit for the whole mesh
    }
}

//  EXACTLY THE SAME FOR SHADOW
//  SHADOW ALSO USE D24S8 BUFFER
technique _CreateShadowMap
{    
    pass P0
    {
        VertexShader = compile vs_2_0 VS_MAIN();
        PixelShader  = compile ps_2_0 PS_WHITE();
        AlphaBlendEnable = 0;
        AlphaTestEnable = 0;

        CullMode = 2;  //STANDARD
        ColorWriteEnable = 0; //
        ZEnable = True;
        ZWriteEnable = False;
        ZFunc = LessEqual;

        StencilEnable = True;
        StencilRef = 0x8;       
        StencilMask = 0x8;      
        StencilWriteMask = 0x8; 
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
        StencilRef = 0x8;
        StencilMask = 0x8;      // Look specifically for our Bit 3
        StencilWriteMask = 0x8; // Allow clearing our bit
        StencilFunc = Equal;     // Only draw where P0 marked the stencil
        StencilPass = Zero;     // CLEANUP: Set bit back to 0    
        StencilFail = Keep;     //safety
        StencilZFail = Zero;    //clear bit for the whole mesh
    }

}