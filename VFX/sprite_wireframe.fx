//==============================================================
// Simple DX9 SM3.0 Wireframe + Point Sprite Preview Shader
// For 3ds Max Direct3D 9 viewport
//==============================================================

//----------------------
// Global parameters
//----------------------
float4x4 World      : WORLD;
float4x4 View       : VIEW;
float4x4 Projection : PROJECTION;

// Combined matrix for convenience
float4x4 WorldViewProj : WORLDVIEWPROJECTION;



// Alpha multiplier for both techniques
float  GlobalAlpha = 1.0;




//----------------------
// Texturing
//----------------------
texture DiffuseTexture
<	string UIName = "DiffuseTexture";>;

sampler2D DiffuseSampler = sampler_state
{
    Texture   = <DiffuseTexture>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    MIPMAPLODBIAS = -1 ;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};


//==============================================================
// Vertex / Pixel shader interfaces
//==============================================================

// Common vertex input: position, color, texcoord0
struct VS_IN
{
    float3 Position : POSITION;
    float3 Normal   : NORMAL ;
    float2 Texcoord : TEXCOORD0;
};

//----------------------
// Wireframe path
//----------------------
struct VS_OUT_WIREFRAME
{
    float4 Position : POSITION;
    float4 Color    : COLOR0;
};

VS_OUT_WIREFRAME VS_Wireframe(VS_IN IN)
{
    VS_OUT_WIREFRAME OUT;

    OUT.Position = mul(float4(IN.Position, 1.0), WorldViewProj);

    // Use vertex color, modulated by global parameters
    float4 color ; 
    color.a = GlobalAlpha;
    color.rgb = abs(IN.Normal);

    OUT.Color = color;

    return OUT;
}

float4 PS_Wireframe(VS_OUT_WIREFRAME IN) : COLOR0
{
    // Just pass the interpolated color through
    return IN.Color;
}


//----------------------
// Point sprite path
//----------------------
struct VS_OUT_POINT
{
    float4 Position : POSITION;
    float4 Color    : COLOR0;
    float2 Texcoord : TEXCOORD0;  // For point sprites, UVs will be auto-generated
    float  Size     : PSIZE;
};

VS_OUT_POINT VS_PointSprite(VS_IN IN)
{
    VS_OUT_POINT OUT;

    OUT.Position = mul(float4(IN.Position, 1.0), WorldViewProj);

    // For D3D9 point sprites, TEXCOORD0 is *auto-generated*
    // by the rasterizer in [0,1] across the sprite.
    // Whatever we write here is ignored, but we must still provide it.
    OUT.Texcoord = float2(0.0, 0.0);

    // Use vertex diffuse color, modulated by globals
    float4 color ; 
    color.a = GlobalAlpha;
    color.rgb = abs(IN.Normal);

    OUT.Color = color;

    // Per-vertex point size in pixels
    OUT.Size = 4096 / OUT.Position.w;

    return OUT;
}

float4 PS_PointSprite(VS_OUT_POINT IN) : COLOR0
{
    // For point sprites, TEXCOORD0 will be [0,1] across the sprite quad
    float4 texColor = tex2D(DiffuseSampler, IN.Texcoord);
    texColor.rgb *= IN.Color.rgb;


    // Modulate texture by vertex color
    float4 result = texColor ;

    return result;
}


//==============================================================
// Techniques
//==============================================================




technique Together
{
    pass P0  //wire
    {
        // Shaders
        VertexShader = compile vs_3_0 VS_Wireframe();
        PixelShader  = compile ps_3_0 PS_Wireframe();

        // Depth test/write: standard
        ZEnable      = TRUE;
        ZWriteEnable = TRUE;
        ZFunc        = LESSEQUAL;

        // Alpha blending
        AlphaBlendEnable = TRUE;
        SrcBlend         = SRCALPHA;
        DestBlend        = INVSRCALPHA;

        // Wireframe rasterization
        FillMode = WIREFRAME;

        // Cull as you prefer; NONE is safest for preview
        CullMode = NONE;
    }
    pass P1  //sprite
    {
        // Shaders
        VertexShader = compile vs_3_0 VS_PointSprite();
        PixelShader  = compile ps_3_0 PS_PointSprite();

        // Depth test/write: standard
        ZEnable      = TRUE;
        ZWriteEnable = TRUE;
        ZFunc        = LESSEQUAL;

        // Alpha blending
        AlphaBlendEnable = 0;
        ALPHATESTENABLE = 1;
        SrcBlend         = SRCALPHA;
        DestBlend        = INVSRCALPHA;

        // sprites are quads
        FillMode = POINT;

        // No culling for point sprites
        CullMode = NONE;

        // Enable fixed-function point sprite behavior in D3D9
        PointSpriteEnable = TRUE;
        PointScaleEnable  = FALSE;     // Use PSIZE directly
    }
}

//----------------------
// Colored wireframe
//----------------------
technique ColoredWireframe
{
    pass P0
    {
        // Shaders
        VertexShader = compile vs_3_0 VS_Wireframe();
        PixelShader  = compile ps_3_0 PS_Wireframe();

        // Depth test/write: standard
        ZEnable      = TRUE;
        ZWriteEnable = TRUE;
        ZFunc        = LESSEQUAL;

        // Alpha blending
        AlphaBlendEnable = TRUE;
        SrcBlend         = SRCALPHA;
        DestBlend        = INVSRCALPHA;

        // Wireframe rasterization
        FillMode = WIREFRAME;

        // Cull as you prefer; NONE is safest for preview
        CullMode = CW;
    }
}


//----------------------
// Point cloud with sprite texture
//----------------------
technique PointCloudSprite
{
    pass P0
    {
        // Shaders
        VertexShader = compile vs_3_0 VS_PointSprite();
        PixelShader  = compile ps_3_0 PS_PointSprite();

        // Depth test/write: standard
        ZEnable      = TRUE;
        ZWriteEnable = TRUE;
        ZFunc        = LESSEQUAL;

        // Alpha blending
        AlphaBlendEnable = 0;
        ALPHATESTENABLE = 1;
        SrcBlend         = SRCALPHA;
        DestBlend        = INVSRCALPHA;

        // Solid fill (sprites are quads)
        FillMode = POINT        ;

        // No culling for point sprites
        CullMode = NONE;

        // Enable fixed-function point sprite behavior in D3D9
        PointSpriteEnable = TRUE;
        PointScaleEnable  = FALSE;     // Use PSIZE directly
    }
}
