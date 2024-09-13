//COLOR EMMISSIVE RGB AVERAGE CONTROLS THE LUMINANCE

string DefaultParameterScopeBlock = "material"; 
float3 AmbientLightColor <bool unmanaged = 1;> = { 0.3, 0.3, 0.3 };

struct {    float3 Color;    float3 Direction;
} DirectionalLight[3] <bool unmanaged = 1;> = { 1.625198, 1.512711, 1.097048, 0.62914, -0.34874, 0.69465, 0.5232916, 0.6654605, 0.7815244, -0.32877, 0.90329, 0.27563, 0.4420466, 0.4102767, 0.4420466, -0.80704, -0.58635, 0.06975 };

struct {    float3 Color;    float3 Position;    float2 Range_Inner_Outer;
} PointLight[8] <bool unmanaged = 1;>;

struct {    float4 WorldPositionMultiplier_XYZZ;    float2 CurrentOffsetUV;
} Cloud <bool unmanaged = 1;>;
float3 NoCloudMultiplier <bool unmanaged = 1;> = { 1, 1, 1 };

// float3 RecolorColorDummy <bool unmanaged = 1;>;
float3 RecolorColor : register(ps_2_0, c0) : register(ps_3_0, c0) <bool unmanaged = 1;>;

row_major float4x4 ShadowMapWorldToShadow <bool unmanaged = 1;>;
float OpacityOverride <bool unmanaged = 1;> = { 1 };
float3 TintColor <bool unmanaged = 1;> = { 1, 1, 1 };
float3 EyePosition <bool unmanaged = 1;>;
row_major float4x4 ViewProjection <bool unmanaged = 1;>;
float4 WorldBones[128] <bool unmanaged = 1;>;
column_major float4x4 World : World : register(vs_2_0, c15);
column_major float4x4 WorldViewProjection : WorldViewProjection : register(vs_2_0, c11);



texture Texture1 <string UIWidget = "None";>; 
sampler2D Texture1Sampler : register(ps_2_0, s0) <string Texture = "Texture1"; string UIWidget = "None";> =
sampler_state
{
    Texture = <Texture1>; 
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 2;
    AddressU = 3;
    AddressV = 1;
};

texture Texture2 <string UIWidget = "None";>; 
sampler2D Texture2Sampler : register(ps_2_0, s1) <string Texture = "Texture2"; string UIWidget = "None";> =
sampler_state
{
    Texture = <Texture2>; 
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 2;
    AddressU = 3;
    AddressV = 1;
};

float3 ColorEmissive : register(ps_2_0, c11) <string UIName = "Emissive Material Color"; string UIWidget = "Color";> = { 1, 1, 1 };

struct{    float4 ScaleUV_OffsetUV;} 
Shroud : register(vs_2_0, c17) <string UIWidget = "None"; string SasBindAddress = "Terrain.Shroud";> = { 1, 1, 0, 0 };


texture ShroudTexture <string UIWidget = "None"; string SasBindAddress = "Terrain.Shroud.Texture"; string ResourceName = "ShaderPreviewShroud.dds";>; 
sampler2D ShroudTextureSampler : register(ps_2_0, s2) <string Texture = "ShroudTexture"; string UIWidget = "None"; string SasBindAddress = "Terrain.Shroud.Texture"; string ResourceName = "ShaderPreviewShroud.dds";> =
sampler_state
{
    Texture = <ShroudTexture>; 
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 2;
    AddressU = 3;
    AddressV = 3;
};

//========================================

struct Default_M_PixelShader1_Input
{
    float2 texcoord : TEXCOORD;
    float2 texcoord1 : TEXCOORD1;
    float2 texcoord2 : TEXCOORD2;
    float color : COLOR;
};

float4 Default_M_PixelShader1(Default_M_PixelShader1_Input i) : COLOR
{
    float4 out_color;
    float4 temp0, temp1, temp2;
    float4 temp3;
    temp0 = tex2D(ShroudTextureSampler, i.texcoord2.xy);
    temp1 = tex2D(Texture1Sampler, i.texcoord.xy);
    temp2 = tex2D(Texture2Sampler, i.texcoord1.xy);
    temp0.x = temp0.x + float1(-0.75);
    temp0.x = temp0.x + temp0.x;
    temp3.w = max(temp0.x, float1(0));
    temp0.x = temp3.w + temp3.w;
    temp1 = temp1 * temp2;
    float luminance = (ColorEmissive.x + ColorEmissive.y + ColorEmissive.z) *0.4 ;
    temp0.yzw = temp1.zyx * luminance;
    temp1.w = temp1.w * i.color.x;
    temp1.xyz = temp0.xxx * temp0.wzy * RecolorColor.xyz; //
    out_color = temp1;

    return out_color;
}


struct Default_M_VertexShader2_Input
{
    float4 position : POSITION;
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
    float4 color : COLOR;
};

struct Default_M_VertexShader2_Output
{
    float4 position : POSITION;
    float2 texcoord2 : TEXCOORD2;
    float2 texcoord : TEXCOORD;
    float2 texcoord1 : TEXCOORD1;
    float color : COLOR;
};

Default_M_VertexShader2_Output Default_M_VertexShader2(Default_M_VertexShader2_Input i)
{
    Default_M_VertexShader2_Output o;
    float4 temp0;
    float2 temp1;
    temp0 = i.position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
    o.position.x = dot(temp0, (WorldViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp0, (WorldViewProjection._m01_m11_m21_m31));
    o.position.z = dot(temp0, (WorldViewProjection._m02_m12_m22_m32));
    o.position.w = dot(temp0, (WorldViewProjection._m03_m13_m23_m33));
    temp1.x = dot(temp0, (World._m00_m10_m20_m30));
    temp1.y = dot(temp0, (World._m01_m11_m21_m31));
    temp0.xy = temp1.xy + Shroud.ScaleUV_OffsetUV.zw;
    o.texcoord2 = temp0 * Shroud.ScaleUV_OffsetUV;
    o.texcoord = i.texcoord;
    o.texcoord1 = i.texcoord1;
    o.color = i.color.x;

    return o;
}


struct Default_PixelShader3_Input
{
    float2 texcoord : TEXCOORD;
    float2 texcoord1 : TEXCOORD1;
    float2 texcoord2 : TEXCOORD2;
    float color : COLOR;
};

float4 Default_PixelShader3(Default_PixelShader3_Input i) : COLOR
{
    float4 out_color;
    float4 temp0, temp1, temp2;
    float4 temp3;
    temp0 = tex2D(ShroudTextureSampler, i.texcoord2.xy);
    temp1 = tex2D(Texture1Sampler, i.texcoord.xy);
    temp2 = tex2D(Texture2Sampler, i.texcoord1.xy);
    temp0.x = temp0.x + float1(-0.75);
    temp0.x = temp0.x + temp0.x;
    temp3.w = max(temp0.x, float1(0));
    temp0.x = temp3.w + temp3.w;
    temp1 = temp1 * temp2;
    float luminance = (ColorEmissive.x + ColorEmissive.y + ColorEmissive.z) *0.4 ;
    temp0.yzw = temp1.zyx * luminance;
    temp1.w = temp1.w * i.color.x;
    temp2.x = log2(temp0.w);
    temp2.y = log2(temp0.z);
    temp2.z = log2(temp0.y);
    temp0.yzw = temp2.zyx * float3(2, 2, 2);
    temp2.x = exp2(temp0.w);
    temp2.y = exp2(temp0.z);
    temp2.z = exp2(temp0.y);
    temp1.xyz = temp0.xxx * temp2.xyz * RecolorColor.xyz; //
    out_color = temp1;

    return out_color;
}


struct Default_VertexShader4_Input
{
    float4 position : POSITION;
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
    float4 color : COLOR;
};

struct Default_VertexShader4_Output
{
    float4 position : POSITION;
    float2 texcoord2 : TEXCOORD2;
    float2 texcoord : TEXCOORD;
    float2 texcoord1 : TEXCOORD1;
    float color : COLOR;
};

Default_VertexShader4_Output Default_VertexShader4(Default_VertexShader4_Input i)
{
    Default_VertexShader4_Output o;
    float4 temp0;
    float2 temp1;
    temp0 = i.position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
    o.position.x = dot(temp0, (WorldViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp0, (WorldViewProjection._m01_m11_m21_m31));
    o.position.z = dot(temp0, (WorldViewProjection._m02_m12_m22_m32));
    o.position.w = dot(temp0, (WorldViewProjection._m03_m13_m23_m33));
    temp1.x = dot(temp0, (World._m00_m10_m20_m30));
    temp1.y = dot(temp0, (World._m01_m11_m21_m31));
    temp0.xy = temp1.xy + Shroud.ScaleUV_OffsetUV.zw;
    o.texcoord2 = temp0 * Shroud.ScaleUV_OffsetUV;
    o.texcoord = i.texcoord;
    o.texcoord1 = i.texcoord1;
    o.color = i.color.x;

    return o;
}

//=====================================

technique Default
{
    pass pass0
    {
        VertexShader = compile vs_2_0 Default_VertexShader4(); 
        PixelShader = compile ps_2_0 Default_PixelShader3(); 
        ZEnable = 1;
        ZWriteEnable = 0;
        ZFunc = 4;
        AlphaBlendEnable = 1;
        CullMode = 1;
        SrcBlend = 5;
        DestBlend = 2;
    }
}

technique Default_M
{
    pass pass0
    {
        VertexShader = compile vs_2_0 Default_M_VertexShader2(); 
        PixelShader = compile ps_2_0 Default_M_PixelShader1(); 
        ZEnable = 1;
        ZWriteEnable = 0;
        ZFunc = 4;
        AlphaBlendEnable = 1;
        CullMode = 1;
        SrcBlend = 5;
        DestBlend = 2;
    }
}

