/*
fxc.exe /O2 /T fx_2_0 /Fo   FXO\FXscreenSpaceShadow.fxo   FXscreenSpaceShadow.fx

Full-screen deferred shadow visibility mask.

Input geometry is expected to be a screen quad with POSITION.xy already in
normalized device coordinates [-1, 1].  Output is greyscale:
    1.0 = lit / no shadow
    0.0 = fully shadowed
*/

#define DEFERRED_RENDER
#define FORBID_CLIPPING_CONSTANT
#define SPECIAL_SAS_HEADER

int _SasGlobal : SasGlobal
<
    int3 SasVersion = int3(1, 0, 0);
    string UIWidget = "None";
    int MaxSupportedInstancingMode = 1;
    int MaxLocalLights = 0;
    string RenderBin = "StaticSort5";
> = 0;

#include "head0-COMMON.FXH"

float ShadowDepthBiasTexels
<
    string UIName = "ShadowDepthBiasTexels";
    float UIMin = 0.0;
    float UIMax = 8.0;
    float UIStep = 0.25;
> = 1.0;

float ShadowTransitionRangeTexels
<
    string UIName = "ShadowTransitionRangeTexels";
    float UIMin = 0.25;
    float UIMax = 8.0;
    float UIStep = 0.25;
> = 1.0;

float ShadowTransitionStartBias
<
    string UIName = "ShadowTransitionStartBias";
    float UIMin = 0.0;
    float UIMax = 2.0;
    float UIStep = 0.125;
> = 1.0;

struct VS_ScreenShadow_Out
{
    float4 Position    : POSITION;
    float2 ScreenUV    : TEXCOORD0;
    float3 WorldEyeRay : TEXCOORD1;
};

VS_ScreenShadow_Out VS_ScreenShadow(float4 Position : POSITION)
{
    VS_ScreenShadow_Out o;

    // The engine supplies a full-screen quad already in NDC/clip xy.
    o.Position = float4(Position.xy, 0.0, 1.0);

    // DX9 samples screen textures at texel centers.  The +0.5 pixel offset is
    // applied when sampling the view-space depth buffer.
    o.ScreenUV = Position.xy * float2(0.5, -0.5) + 0.5;
    o.ScreenUV += 0.5 / FrameBufferSize;

    // Reconstruct a view ray with z length 1, matching the deferred point-light
    // convention: viewPosition = viewRay * viewSpaceDepth.
    float4 screenFarPlanePosition = float4(Position.xy, 1.0, 1.0);
    float4 viewFarPlanePosition4 = mul(screenFarPlanePosition, ProjectionI);
    float3 viewFarPlanePosition = viewFarPlanePosition4.xyz / viewFarPlanePosition4.w;
    float3 viewEyeRay = viewFarPlanePosition / viewFarPlanePosition.z;

    o.WorldEyeRay = mul(float4(viewEyeRay, 0.0), ViewI).xyz;

    return o;
}

float ScreenSpaceInvShadowTrilinear(float3 SMUV)
{
    if (!HasShadow)
    {
        return 1.0;
    }

    // Avoid letting shadow-map border color decide pixels outside the light frustum.
    if (SMUV.x < 0.0 || SMUV.x > 1.0 || SMUV.y < 0.0 || SMUV.y > 1.0)
    {
        return 1.0;
    }

    float oneOverMapSize = Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w;
    float2 texel = float2(0.0, oneOverMapSize);
    float2 uvLerp = frac(SMUV.xy / oneOverMapSize);

    // Same sampling pattern as hp_invshadow_trilinear(): LU, LD, RU, RD.
    float4 shadowDepth = float4(
        tex2D(ShadowMapSampler, SMUV.xy + texel.xx).x,
        tex2D(ShadowMapSampler, SMUV.xy + texel.xy).x,
        tex2D(ShadowMapSampler, SMUV.xy + texel.yx).x,
        tex2D(ShadowMapSampler, SMUV.xy + texel.yy).x
    );

    float receiverDepth = SMUV.z - ShadowDepthBiasTexels * oneOverMapSize;
    float transitionRange = max(oneOverMapSize * ShadowTransitionRangeTexels, 1.0 / 65536.0);

    // Positive depth delta means the shadow map is farther than the receiver:
    // this pixel can see the sun.  Saturate creates the softened comparison
    // band before the bilinear interpolation.
    float4 sunlight = saturate((shadowDepth - receiverDepth) / transitionRange
                             + ShadowTransitionStartBias);

    float2 bilinearLR = lerp(sunlight.xy, sunlight.zw, uvLerp.x);
    float visibility = lerp(bilinearLR.x, bilinearLR.y, uvLerp.y);

    // Match the non-dithered object shaders: round the smooth comparison band.
    return visibility * visibility * (3.0 - 2.0 * visibility);
}

float4 PS_ScreenShadow(VS_ScreenShadow_Out i) : COLOR0
{
    float viewSpaceDepth = tex2D(DepthTextureSampler, i.ScreenUV).x;

    // No useful geometry depth: keep the mask lit so sky/background is not darkened.
    if (viewSpaceDepth <= 0.0)
    {
        return float4(1.0, 1.0, 1.0, 1.0);
    }

    float3 worldEyeVector = i.WorldEyeRay * viewSpaceDepth;
    float4 worldPosition = float4(EyePosition + worldEyeVector, 1.0);

    float4 shadowClip = mul(worldPosition, ShadowMapWorldToShadow);
    if (shadowClip.w <= 0.0)
    {
        return float4(1.0, 1.0, 1.0, 1.0);
    }

    float3 shadowUV = shadowClip.xyz / shadowClip.w;
    float visibility = ScreenSpaceInvShadowTrilinear(shadowUV);

    return float4(visibility.xxx, 1.0);
}

technique Default
{
    pass P0
    {
        VertexShader = compile vs_3_0 VS_ScreenShadow();
        PixelShader  = compile ps_3_0 PS_ScreenShadow();

        ZEnable = 0;
        ZWriteEnable = 0;
        CullMode = 1;
        AlphaTestEnable = 0;
        AlphaBlendEnable = 0;
        ColorWriteEnable = 15;
    }
}
