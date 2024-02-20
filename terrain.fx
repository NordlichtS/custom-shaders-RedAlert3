//Electronic Arts 2008 Red Alert 3 terrain shader
//--------------
//last modified by Nordlicht 
//https://github.com/NordlichtS/custom-shaders-RedAlert3
//based on Lanyi's decompiled HLSL code
//https://github.com/lanyizi/DXDecompiler
//--------------
//improvements: (only on high quality pixel shaders)
//shadow smoothing with dynamic PCF radius based on camera height
//removed gamma correction, assume the textures are linear colored
//TBD: use horizontal projected texture for cliffs (world normal z < 0.7) to avoid texel streching

#include <helperfunctions.fxh>

string DefaultParameterScopeBlock = "material"; 

float3 EyePosition 
: register(vs_3_0, c123) <bool unmanaged = 1;>;

float3 AmbientLightColor:
register(vs_2_0, c4) : register(vs_3_0, c4) <bool unmanaged = 1;> = { 0.3, 0.3, 0.3 };
 
struct{float3 Color;    float3 Direction;} 
DirectionalLight[3]:
register(vs_2_0, c5) : register(ps_3_0, c5) : register(vs_3_0, c5) <bool unmanaged = 1;> = 
{ 1.625198, 1.512711, 1.097048, 0.62914, -0.34874, 0.69465,
0.5232916, 0.6654605, 0.7815244, -0.32877, 0.90329, 0.27563,
0.4420466, 0.4102767, 0.4420466, -0.80704, -0.58635, 0.06975 };

int NumPointLights :
register(ps_3_0, i0) <string SasBindAddress = "Sas.NumPointLights"; string UIWidget = "None";>;

struct{ float3 Color; float3 Position; float2 Range_Inner_Outer;} 
PointLight[6]: 
register(ps_3_0, c89) <bool unmanaged = 1;>;

struct{float4 WorldPositionMultiplier_XYZZ;float2 CurrentOffsetUV;} 
Cloud : 
register(vs_2_0, c117) : register(ps_3_0, c117) <bool unmanaged = 1;>;

float3 NoCloudMultiplier 
<bool unmanaged = 1;> = { 1, 1, 1 };

float3 RecolorColorDummy 
<bool unmanaged = 1;>;

column_major float4x4 ShadowMapWorldToShadow :
register(vs_2_0, c113) : register(vs_3_0, c113) <bool unmanaged = 1;>;

float OpacityOverride 
<bool unmanaged = 1;> = { 1 };

float3 TintColor 
<bool unmanaged = 1;> = { 1, 1, 1 };

column_major float4x4 ViewProjection 
: register(vs_2_0, c119) : register(vs_3_0, c119) <bool unmanaged = 1;>;

float4 WorldBones[128] 
<bool unmanaged = 1;>;

float2 MapCellSize 
<string UIWidget = "None"; string SasBindAddress = "Terrain.Map.CellSize";> = { 10, 10 };

texture MacroSampler 
<string UIWidget = "None"; string SasBindAddress = "Terrain.MacroTexture"; string ResourceName = "ShaderPreviewMacro.dds";>; 
sampler2D MacroSamplerSampler 
: register(ps_3_0, s0) <string Texture = "MacroSampler"; string UIWidget = "None"; string SasBindAddress = "Terrain.MacroTexture"; string ResourceName = "ShaderPreviewMacro.dds";> =
sampler_state
{
    Texture = <MacroSampler>; 
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 2;
    AddressU = 1;
    AddressV = 1;
};

int _SasGlobal : SasGlobal 
<string UIWidget = "None"; int3 SasVersion = int3(1, 0, 0); int MaxLocalLights = 6;>;

texture BaseSamplerClamped 
<string UIWidget = "None"; string SasBindAddress = "Terrain.BaseTexture"; int WW3DDynamicSet = 2;>; 
sampler2D BaseSamplerClampedSampler 
<string Texture = "BaseSamplerClamped"; string UIWidget = "None"; string SasBindAddress = "Terrain.BaseTexture"; int WW3DDynamicSet = 2;> =
sampler_state
{
    Texture = <BaseSamplerClamped>; 
    MinFilter = 3;
    MagFilter = 2;
    MipFilter = 2;
    MaxAnisotropy = 8;
    AddressU = 3;
    AddressV = 3;
};

texture BaseSamplerClamped_L 
<string UIWidget = "None"; string SasBindAddress = "Terrain.BaseTexture"; int WW3DDynamicSet = 2;>; 
sampler2D BaseSamplerClamped_LSampler 
<string Texture = "BaseSamplerClamped_L"; string UIWidget = "None"; string SasBindAddress = "Terrain.BaseTexture"; int WW3DDynamicSet = 2;> =
sampler_state
{
    Texture = <BaseSamplerClamped_L>; 
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 1;
    MaxAnisotropy = 1;
    AddressU = 3;
    AddressV = 3;
};

texture BaseSamplerWrapped 
<string UIWidget = "None"; string SasBindAddress = "Terrain.BaseTexture"; int WW3DDynamicSet = 2;>; 
sampler2D BaseSamplerWrappedSampler 
<string Texture = "BaseSamplerWrapped"; string UIWidget = "None"; string SasBindAddress = "Terrain.BaseTexture"; int WW3DDynamicSet = 2;> =
sampler_state
{
    Texture = <BaseSamplerWrapped>; 
    MinFilter = 3;
    MagFilter = 2;
    MipFilter = 2;
    MaxAnisotropy = 8;
    AddressU = 1;
    AddressV = 1;
};

texture BaseSamplerWrapped_L 
<string UIWidget = "None"; string SasBindAddress = "Terrain.BaseTexture"; int WW3DDynamicSet = 2;>; 
sampler2D BaseSamplerWrapped_LSampler 
<string Texture = "BaseSamplerWrapped_L"; string UIWidget = "None"; string SasBindAddress = "Terrain.BaseTexture"; int WW3DDynamicSet = 2;> =
sampler_state
{
    Texture = <BaseSamplerWrapped_L>; 
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 1;
    MaxAnisotropy = 1;
    AddressU = 1;
    AddressV = 1;
};

texture NormalSamplerClamped 
<string UIWidget = "None"; string SasBindAddress = "Terrain.NormalTexture"; int WW3DDynamicSet = 2;>; 
sampler2D NormalSamplerClampedSampler 
<string Texture = "NormalSamplerClamped"; string UIWidget = "None"; string SasBindAddress = "Terrain.NormalTexture"; int WW3DDynamicSet = 2;> =
sampler_state
{
    Texture = <NormalSamplerClamped>; 
    MinFilter = 3;
    MagFilter = 2;
    MipFilter = 2;
    MaxAnisotropy = 8;
    AddressU = 3;
    AddressV = 3;
};

texture NormalSamplerWrapped 
<string UIWidget = "None"; string SasBindAddress = "Terrain.NormalTexture"; int WW3DDynamicSet = 2;>; 
sampler2D NormalSamplerWrappedSampler 
<string Texture = "NormalSamplerWrapped"; string UIWidget = "None"; string SasBindAddress = "Terrain.NormalTexture"; int WW3DDynamicSet = 2;> =
sampler_state
{
    Texture = <NormalSamplerWrapped>; 
    MinFilter = 3;
    MagFilter = 2;
    MipFilter = 2;
    MaxAnisotropy = 8;
    AddressU = 1;
    AddressV = 1;
};

struct{float4 ScaleUV_OffsetUV;} 
Shroud: 
register(vs_2_0, c11) : register(vs_3_0, c11) <string UIWidget = "None"; string SasBindAddress = "Terrain.Shroud";> = { 1, 1, 0, 0 };

texture ShroudSampler 
<string UIWidget = "None"; string SasBindAddress = "Terrain.Shroud.Texture";>; 
sampler2D ShroudSamplerSampler 
: register(ps_3_0, s3) <string Texture = "ShroudSampler"; string UIWidget = "None"; string SasBindAddress = "Terrain.Shroud.Texture";> =
sampler_state
{
    Texture = <ShroudSampler>; 
    MinFilter = 1;//2;
    MagFilter = 1;//2;
    MipFilter = 2;
    AddressU = 3;
    AddressV = 3;
};

texture CloudSampler <string UIWidget = "None"; string SasBindAddress = "Terrain.Cloud.Texture"; string ResourceName = "ShaderPreviewCloud.dds";>; 
sampler2D CloudSamplerSampler : register(ps_2_0, s3) : register(ps_3_0, s4) <string Texture = "CloudSampler"; string UIWidget = "None"; string SasBindAddress = "Terrain.Cloud.Texture"; string ResourceName = "ShaderPreviewCloud.dds";> =
sampler_state
{
    Texture = <CloudSampler>; 
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 2;
    AddressU = 1;
    AddressV = 1;
};

bool IsTerrainAtlasEnabled 
<string UIWidget = "None"; string SasBindAddress = "Terrain.IsTerrainAtlasEnabled";>;

bool HasShadow 
<string UIWidget = "None"; string SasBindAddress = "Sas.HasShadow";>;

texture ShadowMap 
<string UIWidget = "None"; string SasBindAddress = "Sas.Shadow[0].ShadowMap";>; 
sampler2D ShadowMapSampler : 
register(ps_2_0, s4) : register(ps_3_0, s5) <string Texture = "ShadowMap"; string UIWidget = "None"; string SasBindAddress = "Sas.Shadow[0].ShadowMap";> =
sampler_state
{
    Texture = <ShadowMap>;  //changed filter, 1 point  2 linear 3 aniso 6 PyramidQuad 7 GaussianQuad
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 0;
    AddressU = 3;
    AddressV = 3;
};  //ADDRESSUV: 1=WRAP 2=MIRROR 3=CLAMP 4=BORDER 5

float4 Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize :
register(ps_2_0, c11) : register(ps_3_0, c11) <string UIWidget = "None"; string SasBindAddress = "Sas.Shadow[0].Zero_Zero_OneOverMapSize_OneOverMapSize";>;

float Time : Time;

struct VS_TerrainTile_Array_Shader_0_Input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 texcoord : TEXCOORD;
};

struct VS_TerrainTile_Array_Shader_0_Output
{
    float4 position : POSITION;
    float4 color : COLOR;
    float color1 : COLOR1;
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
    float2 texcoord2 : TEXCOORD2;
    float3 texcoord3 : TEXCOORD3;
    float4 texcoord4 : TEXCOORD4;
    float3 texcoord5 : TEXCOORD5;
    float4 texcoord6 : TEXCOORD6;
};

VS_TerrainTile_Array_Shader_0_Output VS_TerrainTile_Array_Shader_0(VS_TerrainTile_Array_Shader_0_Input i)
{
    VS_TerrainTile_Array_Shader_0_Output o;
    float4 temp0, temp1;
    float3 temp2, temp3;
    temp0 = i.position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
    o.position.x = dot(temp0, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp0, (ViewProjection._m01_m11_m21_m31));
    o.position.z = dot(temp0, (ViewProjection._m02_m12_m22_m32));
    o.position.w = dot(temp0, (ViewProjection._m03_m13_m23_m33));
    temp1.xyz = float3(1, 0, 0) * i.normal.zxy;
    temp1.xyz = i.normal.yzx * float3(0, 0, 1) + -temp1.xyz;
    o.texcoord4.x = dot(DirectionalLight[0].Direction.xyz, -temp1.xyz);
    temp2.xyz = float3(0, 0, -1) * i.normal.zxy;
    temp2.xyz = i.normal.yzx * float3(0, -1, 0) + -temp2.xyz;
    o.texcoord4.y = dot(DirectionalLight[0].Direction.xyz, -temp2.xyz);
    temp1.w = dot(DirectionalLight[0].Direction.xyz, i.normal.xyz);
    o.texcoord4.w = max(temp1.w, float1(0));
    o.texcoord4.z = temp1.w;
    temp3.xyz = EyePosition.xyz + -i.position.xyz;
    temp1.w = dot(temp3.xyz, temp3.xyz);
    temp1.w = 1 / sqrt(temp1.w);
    temp3.xyz = temp3.xyz * temp1.www + DirectionalLight[0].Direction.xyz;
    temp1.x = dot(temp3.xyz, -temp1.xyz);
    temp1.y = dot(temp3.xyz, -temp2.xyz);
    temp1.z = dot(temp3.xyz, i.normal.xyz);
    temp1.w = dot(temp1.xyz, temp1.xyz);
    temp1.w = 1 / sqrt(temp1.w);
    o.texcoord5 = temp1 * temp1.w;
    temp1.x = dot(i.normal.xyz, DirectionalLight[2].Direction.xyz);
    temp1.x = max(temp1.x, float1(0));
    temp1.xyz = temp1.xxx * DirectionalLight[2].Color.xyz;
    temp1.w = dot(i.normal.xyz, DirectionalLight[1].Direction.xyz);
    temp1.w = max(temp1.w, float1(0));
    temp1.xyz = DirectionalLight[1].Color.xyz * temp1.www + temp1.xyz;
    temp1.xyz = temp1.xyz + AmbientLightColor.xyz;
    o.color.xyz = temp1.xyz * float3(0.5, 0.5, 0.5);
    temp1.xy = Shroud.ScaleUV_OffsetUV.zw + i.position.xy;
    o.texcoord2 = temp1 * Shroud.ScaleUV_OffsetUV;
    o.texcoord6.x = dot(temp0, (ShadowMapWorldToShadow._m00_m10_m20_m30));
    o.texcoord6.y = dot(temp0, (ShadowMapWorldToShadow._m01_m11_m21_m31));
    o.texcoord6.z = dot(temp0, (ShadowMapWorldToShadow._m02_m12_m22_m32));
    o.texcoord6.w = dot(temp0, (ShadowMapWorldToShadow._m03_m13_m23_m33));
    o.color.w = float1(1);
    o.color1 = float4(1, 1, 1, 1);
    o.texcoord.xy = i.texcoord.xy;
    o.texcoord.zw = float2(0, 0);
    o.texcoord1 = float4(0, 0, 0, 0);
    o.texcoord3 = i.position;

    return o;
}


struct VS_TerrainTile_Array_Shader_1_Input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
    float4 texcoord2 : TEXCOORD2;
};

struct VS_TerrainTile_Array_Shader_1_Output
{
    float4 position : POSITION;
    float4 color : COLOR;
    float color1 : COLOR1;
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
    float2 texcoord2 : TEXCOORD2;
    float3 texcoord3 : TEXCOORD3;
    float4 texcoord4 : TEXCOORD4;
    float3 texcoord5 : TEXCOORD5;
    float4 texcoord6 : TEXCOORD6;
};

VS_TerrainTile_Array_Shader_1_Output VS_TerrainTile_Array_Shader_1(VS_TerrainTile_Array_Shader_1_Input i)
{
    VS_TerrainTile_Array_Shader_1_Output o;
    float4 temp0, temp1;
    float3 temp2, temp3, temp4;
    o.texcoord.xy = float2(3.3333334E-05, 3.3333334E-05) * i.texcoord.xy;
    o.texcoord1.xy = float2(3.3333334E-05, 3.3333334E-05) * i.texcoord1.xy;
    o.texcoord1.zw = float2(3.3333334E-05, 3.3333334E-05) * i.texcoord2.yx;
    o.texcoord.w = float1(-1) + i.position.w;
    o.texcoord.z = float1(-1) + i.normal.w;
    temp0 = i.position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
    o.position.x = dot(temp0, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp0, (ViewProjection._m01_m11_m21_m31));
    o.position.z = dot(temp0, (ViewProjection._m02_m12_m22_m32));
    o.position.w = dot(temp0, (ViewProjection._m03_m13_m23_m33));
    temp1.xyz = i.normal.xyz * float3(0.01, 0.01, 0.01) + float3(-1, -1, -1);
    temp2.xyz = temp1.zxy * float3(1, 0, 0);
    temp2.xyz = temp1.yzx * float3(0, 0, 1) + -temp2.xyz;
    o.texcoord4.x = dot(DirectionalLight[0].Direction.xyz, -temp2.xyz);
    temp3.xyz = temp1.zxy * float3(0, 0, -1);
    temp3.xyz = temp1.yzx * float3(0, -1, 0) + -temp3.xyz;
    o.texcoord4.y = dot(DirectionalLight[0].Direction.xyz, -temp3.xyz);
    temp1.w = dot(DirectionalLight[0].Direction.xyz, temp1.xyz);
    o.texcoord4.w = max(temp1.w, float1(0));
    o.texcoord4.z = temp1.w;
    temp4.xyz = EyePosition.xyz + -i.position.xyz;
    temp1.w = dot(temp4.xyz, temp4.xyz);
    temp1.w = 1 / sqrt(temp1.w);
    temp4.xyz = temp4.xyz * temp1.www + DirectionalLight[0].Direction.xyz;
    temp2.x = dot(temp4.xyz, -temp2.xyz);
    temp2.y = dot(temp4.xyz, -temp3.xyz);
    temp2.z = dot(temp4.xyz, temp1.xyz);
    temp1.w = dot(temp2.xyz, temp2.xyz);
    temp1.w = 1 / sqrt(temp1.w);
    o.texcoord5 = temp2 * temp1.w;
    temp1.w = dot(temp1.xyz, DirectionalLight[2].Direction.xyz);
    temp1.x = dot(temp1.xyz, DirectionalLight[1].Direction.xyz);
    temp1.y = max(temp1.w, float1(0));
    temp1.yzw = temp1.yyy * DirectionalLight[2].Color.xyz;
    temp1.x = max(temp1.x, float1(0));
    temp1.xyz = DirectionalLight[1].Color.xyz * temp1.xxx + temp1.yzw;
    temp1.xyz = temp1.xyz + AmbientLightColor.xyz;
    o.color.xyz = temp1.xyz * float3(0.5, 0.5, 0.5);
    temp1.xy = Shroud.ScaleUV_OffsetUV.zw + i.position.xy;
    o.texcoord2 = temp1 * Shroud.ScaleUV_OffsetUV;
    o.color.w = float1(1);
    o.color1 = float4(1, 1, 1, 1);
    o.texcoord3 = i.position;
    temp1.x = dot(temp0, (ShadowMapWorldToShadow._m00_m10_m20_m30));
    temp1.y = dot(temp0, (ShadowMapWorldToShadow._m01_m11_m21_m31));
    temp1.z = dot(temp0, (ShadowMapWorldToShadow._m02_m12_m22_m32));
    temp0.x = dot(temp0, (ShadowMapWorldToShadow._m03_m13_m23_m33));
    temp0.y = 1.0f / temp0.x;
    o.texcoord6.w = temp0.x;
    o.texcoord6.xyz = temp1.xyz * temp0.yyy + float3(0, 0, -0.0015);

    return o;
}

VertexShader VS_TerrainTile_Array[2] = {
    compile vs_3_0 VS_TerrainTile_Array_Shader_0(), 
    compile vs_3_0 VS_TerrainTile_Array_Shader_1(), 
};

struct PS_TerrainTile_Array_Shader_0_Input
{
    float4 color : COLOR;
    float color1 : COLOR1;
    float2 texcoord : TEXCOORD;
    float2 texcoord2 : TEXCOORD2;
    float3 texcoord3 : TEXCOORD3;
    float3 texcoord4 : TEXCOORD4;
    float3 texcoord5 : TEXCOORD5;
};

float4 PS_TerrainTile_Array_Shader_0(PS_TerrainTile_Array_Shader_0_Input i) : COLOR
{
    /*
    PRSI
      OutputRegisterOffset: 11
      Unknown1: 0
      Unknown2: 0
      OutputRegisterCount: 1
      Unknown3: 0
      Unknown4: 0
      Unknown5: 11
      Unknown6: 1
      Mappings: 1
        0 - ConstOutput: 0 ConstInput 0
    */
    float4 expr11;
    {
        float4 temp0;
                temp0.x = MapCellSize.x * (66);
            expr11.x = 1.0f / (temp0.x);
    }

    float4 out_color;
    float4 temp0, temp1, temp2, temp3, temp4, temp5, temp6;
    float3 temp7;
    temp0 = tex2D(BaseSamplerClampedSampler, i.texcoord.xy);
    temp1.xy = Cloud.WorldPositionMultiplier_XYZZ.zw * i.texcoord3.zz;
    temp1.xy = i.texcoord3.xy * Cloud.WorldPositionMultiplier_XYZZ.xy + -temp1.xy;
    temp1.xy = temp1.xy + Cloud.CurrentOffsetUV.xy;
    temp2.xy = float2(1, -1);
    temp1.zw = temp2.xy * expr11.xx;
    temp1.zw = temp1.zw * i.texcoord3.xy;
    temp2.x = log2(temp0.x);
    temp2.y = log2(temp0.y);
    temp2.z = log2(temp0.z);
    temp0.xyz = temp2.xyz * float3(2,2,2); //GAMMA
    temp2.x = exp2(temp0.x);
    temp2.y = exp2(temp0.y);
    temp2.z = exp2(temp0.z);
    temp0 = tex2D(NormalSamplerClampedSampler, i.texcoord.xy);
    temp0.xy = temp0.xy * float2(2, 2) + float2(-1, -1);
    temp0.w = temp0.x * -temp0.x + float1(1);
    temp0.w = temp0.y * -temp0.y + temp0.w;
    temp0.w = 1 / sqrt(temp0.w);
    temp3.z = 1.0f / temp0.w;
    temp3.xy = temp0.xy * float2(0.75, 0.75);
    temp4.xyz = normalize(temp3.xyz).xyz;
    temp0.xyw = i.color.xyz;
    temp3.x = float1(0);
    for (int it0 = 0; it0 < NumPointLights; ++it0) {
            temp5 = temp3.x + float4(-2, -3, -4, -5);
            temp3.xyz = temp3.xxx + float3(1, -0, -1);
            temp6.y = float1(0);
            temp6.xzw = (-abs(temp3).yyy >= 0) ? PointLight[0].Color.xyz : temp6.yyy;
            temp7.xyz = (-abs(temp3).yyy >= 0) ? PointLight[0].Position.xyz : temp6.yyy;
            temp3.yw = (-abs(temp3).yy >= 0) ? PointLight[0].Range_Inner_Outer.xy : temp6.yy;
            temp6.xyz = (-abs(temp3).zzz >= 0) ? PointLight[1].Color.xyz : temp6.xzw;
            temp7.xyz = (-abs(temp3).zzz >= 0) ? PointLight[1].Position.xyz : temp7.xyz;
            temp3.yz = (-abs(temp3).zz >= 0) ? PointLight[1].Range_Inner_Outer.xy : temp3.yw;
            temp6.xyz = (-abs(temp5).xxx >= 0) ? PointLight[2].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).xxx >= 0) ? PointLight[2].Position.xyz : temp7.xyz;
            temp3.yz = (-abs(temp5).xx >= 0) ? PointLight[2].Range_Inner_Outer.xy : temp3.yz;
            temp6.xyz = (-abs(temp5).yyy >= 0) ? PointLight[3].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).yyy >= 0) ? PointLight[3].Position.xyz : temp7.xyz;
            temp3.yz = (-abs(temp5).yy >= 0) ? PointLight[3].Range_Inner_Outer.xy : temp3.yz;
            temp6.xyz = (-abs(temp5).zzz >= 0) ? PointLight[4].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).zzz >= 0) ? PointLight[4].Position.xyz : temp7.xyz;
            temp3.yz = (-abs(temp5).zz >= 0) ? PointLight[4].Range_Inner_Outer.xy : temp3.yz;
            temp5.xyz = (-abs(temp5).www >= 0) ? PointLight[5].Color.xyz : temp6.xyz;
            temp6.xyz = (-abs(temp5).www >= 0) ? PointLight[5].Position.xyz : temp7.xyz;
            temp3.yz = (-abs(temp5).ww >= 0) ? PointLight[5].Range_Inner_Outer.xy : temp3.yz;
            temp6.xyz = temp6.xyz + -i.texcoord3.xyz;
            temp2.w = dot(temp6.xyz, temp6.xyz);
            temp2.w = 1 / sqrt(temp2.w);
            temp3.w = 1.0f / temp2.w;
            temp6.xyz = temp6.xyz * temp2.www;
            temp2.w = -temp3.y + temp3.w;
            temp3.y = -temp3.y + temp3.z;
            temp3.y = 1.0f / temp3.y;
            temp2.w = saturate(temp2.w * -temp3.y + float1(1));
            temp2.w = temp2.w * temp2.w;
            temp3.yzw = temp5.xyz * temp2.www;
            temp2.w = dot(temp4.xyz, temp6.xyz);
            temp4.w = max(temp2.w, float1(0));
            temp0.xyw = temp3.yzw * temp4.www + temp0.xyw;
        }
    temp0.xyw = temp2.xyz * temp0.xyw;
    temp0.xyw = temp0.xyw + temp0.xyw;
    temp2.w = dot(temp4.xyz, i.texcoord4.xyz);
    temp3.x = dot(temp4.xyz, i.texcoord5.xyz);
    temp3.y = (-temp2.w >= 0) ? float1(0) : float1(1);
    temp2.w = temp2.w * temp3.y;
    temp3.z = (-temp3.x >= 0) ? float1(0) : float1(1);
    temp3.y = temp3.y * temp3.z;
    temp4.x = pow( abs(temp3.x), float1(40));
    temp3.x = temp3.y * temp4.x;
    temp4 = tex2D(CloudSamplerSampler, temp1.xy);
    temp3.y = log2(temp4.x);
    temp3.z = log2(temp4.y);
    temp3.w = log2(temp4.z);
    temp3.yzw = temp3.yzw * float3(2,2,2); //GAMMA
    temp4.x = exp2(temp3.y);
    temp4.y = exp2(temp3.z);
    temp4.z = exp2(temp3.w);
    temp3.yzw = temp4.xyz * DirectionalLight[0].Color.xyz;
    temp0.z = dot(temp3.xx, temp0.zz) + float1(0);
    temp2.xyz = temp2.www * temp2.xyz + temp0.zzz;
    temp0.xyz = temp3.yzw * temp2.xyz + temp0.xyw;
    temp1 = tex2D(MacroSamplerSampler, temp1.zw);
    temp2.x = log2(temp1.x);
    temp2.y = log2(temp1.y);
    temp2.z = log2(temp1.z);
    temp1.xyz = temp2.xyz * float3(2,2,2); //GAMMA
    temp2.x = exp2(temp1.x);
    temp2.y = exp2(temp1.y);
    temp2.z = exp2(temp1.z);
    temp0.xyz = temp0.xyz * temp2.xyz + float3(-1, -1, -1);
    temp0.xyz = i.color1.xxx * temp0.xyz + float3(1, 1, 1);
    temp1 = tex2D(ShroudSamplerSampler, i.texcoord2.xy);
    out_color.xyz = temp0.xyz * temp1.xxx;
    out_color.w = i.color.w;

    return out_color;
}


struct PS_TerrainTile_Array_Shader_1_Input
{
    float4 color : COLOR;
    float color1 : COLOR1;
    float2 texcoord : TEXCOORD;
    float2 texcoord2 : TEXCOORD2;
    float3 texcoord3 : TEXCOORD3;
    float3 texcoord4 : TEXCOORD4;
    float3 texcoord5 : TEXCOORD5;
    float4 texcoord6 : TEXCOORD6;
};

float4 PS_TerrainTile_Array_Shader_1(PS_TerrainTile_Array_Shader_1_Input i) : COLOR
{
    /*
    PRSI
      OutputRegisterOffset: 12
      Unknown1: 0
      Unknown2: 0
      OutputRegisterCount: 1
      Unknown3: 0
      Unknown4: 0
      Unknown5: 12
      Unknown6: 1
      Mappings: 1
        0 - ConstOutput: 0 ConstInput 0
    */
    float4 expr12;
    {
        float4 temp0;
                temp0.x = MapCellSize.x * (66);
            expr12.x = 1.0f / (temp0.x);
    }

    float4 out_color;
    float4 temp0, temp1, temp2, temp3, temp4, temp5, temp6, temp7, temp8;
    temp0 = tex2D(BaseSamplerClampedSampler, i.texcoord.xy);
    temp1.xy = Cloud.WorldPositionMultiplier_XYZZ.zw * i.texcoord3.zz;
    temp1.xy = i.texcoord3.xy * Cloud.WorldPositionMultiplier_XYZZ.xy + -temp1.xy;
    temp1.xy = temp1.xy + Cloud.CurrentOffsetUV.xy;
    temp2.xy = float2(1, -1);
    temp1.zw = temp2.xy * expr12.xx;
    temp1.zw = temp1.zw * i.texcoord3.xy;
    temp2.x = log2(temp0.x);
    temp2.y = log2(temp0.y);
    temp2.z = log2(temp0.z);
    temp0.xyz = temp2.xyz * float3(2,2,2); //GAMMA
    temp2.x = exp2(temp0.x);
    temp2.y = exp2(temp0.y);
    temp2.z = exp2(temp0.z);
    temp0 = tex2D(NormalSamplerClampedSampler, i.texcoord.xy);
    temp0.xy = temp0.xy * float2(2, 2) + float2(-1, -1);
    temp0.w = temp0.x * -temp0.x + float1(1);
    temp0.w = temp0.y * -temp0.y + temp0.w;
    temp0.w = 1 / sqrt(temp0.w);
    temp3.z = 1.0f / temp0.w;
    temp3.xy = temp0.xy * float2(0.75, 0.75);
    temp4.xyz = normalize(temp3.xyz).xyz;
    temp0.xyw = i.color.xyz;
    temp3.x = float1(0);
    for (int it0 = 0; it0 < NumPointLights; ++it0) {
            temp5 = temp3.x + float4(-2, -3, -4, -5);
            temp3.xyz = temp3.xxx + float3(1, -0, -1);
            temp6.y = float1(0);
            temp6.xzw = (-abs(temp3).yyy >= 0) ? PointLight[0].Color.xyz : temp6.yyy;
            temp7.xyz = (-abs(temp3).yyy >= 0) ? PointLight[0].Position.xyz : temp6.yyy;
            temp3.yw = (-abs(temp3).yy >= 0) ? PointLight[0].Range_Inner_Outer.xy : temp6.yy;
            temp6.xyz = (-abs(temp3).zzz >= 0) ? PointLight[1].Color.xyz : temp6.xzw;
            temp7.xyz = (-abs(temp3).zzz >= 0) ? PointLight[1].Position.xyz : temp7.xyz;
            temp3.yz = (-abs(temp3).zz >= 0) ? PointLight[1].Range_Inner_Outer.xy : temp3.yw;
            temp6.xyz = (-abs(temp5).xxx >= 0) ? PointLight[2].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).xxx >= 0) ? PointLight[2].Position.xyz : temp7.xyz;
            temp3.yz = (-abs(temp5).xx >= 0) ? PointLight[2].Range_Inner_Outer.xy : temp3.yz;
            temp6.xyz = (-abs(temp5).yyy >= 0) ? PointLight[3].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).yyy >= 0) ? PointLight[3].Position.xyz : temp7.xyz;
            temp3.yz = (-abs(temp5).yy >= 0) ? PointLight[3].Range_Inner_Outer.xy : temp3.yz;
            temp6.xyz = (-abs(temp5).zzz >= 0) ? PointLight[4].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).zzz >= 0) ? PointLight[4].Position.xyz : temp7.xyz;
            temp3.yz = (-abs(temp5).zz >= 0) ? PointLight[4].Range_Inner_Outer.xy : temp3.yz;
            temp5.xyz = (-abs(temp5).www >= 0) ? PointLight[5].Color.xyz : temp6.xyz;
            temp6.xyz = (-abs(temp5).www >= 0) ? PointLight[5].Position.xyz : temp7.xyz;
            temp3.yz = (-abs(temp5).ww >= 0) ? PointLight[5].Range_Inner_Outer.xy : temp3.yz;
            temp6.xyz = temp6.xyz + -i.texcoord3.xyz;
            temp2.w = dot(temp6.xyz, temp6.xyz);
            temp2.w = 1 / sqrt(temp2.w);
            temp3.w = 1.0f / temp2.w;
            temp6.xyz = temp6.xyz * temp2.www;
            temp2.w = -temp3.y + temp3.w;
            temp3.y = -temp3.y + temp3.z;
            temp3.y = 1.0f / temp3.y;
            temp2.w = saturate(temp2.w * -temp3.y + float1(1));
            temp2.w = temp2.w * temp2.w;
            temp3.yzw = temp5.xyz * temp2.www;
            temp2.w = dot(temp4.xyz, temp6.xyz);
            temp4.w = max(temp2.w, float1(0));
            temp0.xyw = temp3.yzw * temp4.www + temp0.xyw;
        }
    temp0.xyw = temp2.xyz * temp0.xyw;
    temp0.xyw = temp0.xyw + temp0.xyw;
    temp2.w = dot(temp4.xyz, i.texcoord4.xyz);
    temp3.x = dot(temp4.xyz, i.texcoord5.xyz);
    temp3.y = (-temp2.w >= 0) ? float1(0) : float1(1);
    temp3.z = temp2.w * temp3.y;
    temp2.w = (-temp3.x >= 0) ? float1(0) : float1(1);
    temp2.w = temp3.y * temp2.w;
    temp4.x = pow( abs(temp3.x), float1(40));
    temp3.w = temp2.w * temp4.x;
    temp2.w = 1.0f / i.texcoord6.w;

    temp3.xy = temp2.ww * i.texcoord6.xy;
    temp4.x = i.texcoord6.z * temp2.w + float1(-0.0015); 

    /*
    temp5 = tex2D(ShadowMapSampler, temp3.xy);
    temp3.xy = i.texcoord6.xy * temp2.ww + Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.zx;
    temp6 = tex2D(ShadowMapSampler, temp3.xy);
    temp3.xy = i.texcoord6.xy * temp2.ww + Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.yz;
    temp7 = tex2D(ShadowMapSampler, temp3.xy);
    temp3.xy = i.texcoord6.xy * temp2.ww + Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.wz;
    temp8 = tex2D(ShadowMapSampler, temp3.xy);
    temp5.y = temp6.x;
    temp5.z = temp7.x;
    temp5.w = temp8.x;
    temp4 = -temp4.x + temp5;
    temp4 = (temp4 >= 0) ? float4(1, 1, 1, 1) : float4(0, 0, 0, 0);
    temp2.w = dot(float4(1, 1, 1, 1), temp4);
    temp2.w = temp2.w * float1(0.25);
    */
    //int ShadowPCFlevel= trunc(clamp(2048/ (EyePosition.z-200) , 2, 7)); //dynamic sampling shadowmap, 10-30 perpixel
    float3 ShadowProjection = (temp3.x , temp3.y, temp4.x);
    temp2.w = helper_shadowpcf(
        3,//ShadowPCFlevel,
        ShadowMapSampler,
        Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w, 
        ShadowProjection) ;

    temp3.xy = temp3.zw * temp2.ww;

    temp4 = tex2D(CloudSamplerSampler, temp1.xy);
    temp5.x = log2(temp4.x);
    temp5.y = log2(temp4.y);
    temp5.z = log2(temp4.z);
    temp4.xyz = temp5.xyz * float3(2,2,2); //GAMMA
    temp5.x = exp2(temp4.x);
    temp5.y = exp2(temp4.y);
    temp5.z = exp2(temp4.z);
    temp4.xyz = temp5.xyz * DirectionalLight[0].Color.xyz;
    temp0.z = dot(temp3.yy, temp0.zz) + float1(0);
    temp2.xyz = temp3.xxx * temp2.xyz + temp0.zzz;
    temp0.xyz = temp4.xyz * temp2.xyz + temp0.xyw;
    temp1 = tex2D(MacroSamplerSampler, temp1.zw);
    temp2.x = log2(temp1.x);
    temp2.y = log2(temp1.y);
    temp2.z = log2(temp1.z);
    temp1.xyz = temp2.xyz * float3(2,2,2); //GAMMA
    temp2.x = exp2(temp1.x);
    temp2.y = exp2(temp1.y);
    temp2.z = exp2(temp1.z);
    temp0.xyz = temp0.xyz * temp2.xyz + float3(-1, -1, -1);
    temp0.xyz = i.color1.xxx * temp0.xyz + float3(1, 1, 1);
    temp1 = tex2D(ShroudSamplerSampler, i.texcoord2.xy);
    out_color.xyz = temp0.xyz * temp1.xxx;
    out_color.w = i.color.w;

    return out_color;
}


struct PS_TerrainTile_Array_Shader_2_Input
{
    float4 color : COLOR;
    float color1 : COLOR1;
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
    float2 texcoord2 : TEXCOORD2;
    float3 texcoord3 : TEXCOORD3;
    float3 texcoord4 : TEXCOORD4;
    float3 texcoord5 : TEXCOORD5;
};

float4 PS_TerrainTile_Array_Shader_2(PS_TerrainTile_Array_Shader_2_Input i) : COLOR
{
    /*
    PRSI
      OutputRegisterOffset: 11
      Unknown1: 0
      Unknown2: 0
      OutputRegisterCount: 1
      Unknown3: 0
      Unknown4: 0
      Unknown5: 11
      Unknown6: 1
      Mappings: 1
        0 - ConstOutput: 0 ConstInput 0
    */
    float4 expr11;
    {
        float4 temp0;
                temp0.x = MapCellSize.x * (66);
            expr11.x = 1.0f / (temp0.x);
    }

    float4 out_color;
    float4 temp0, temp1, temp2, temp3, temp4, temp5, temp6;
    float3 temp7;
    temp0 = tex2D(BaseSamplerClampedSampler, i.texcoord.xy);
    temp1.xy = Cloud.WorldPositionMultiplier_XYZZ.zw * i.texcoord3.zz;
    temp1.xy = i.texcoord3.xy * Cloud.WorldPositionMultiplier_XYZZ.xy + -temp1.xy;
    temp1.xy = temp1.xy + Cloud.CurrentOffsetUV.xy;
    temp2.xy = float2(1, -1);
    temp1.zw = temp2.xy * expr11.xx;
    temp1.zw = temp1.zw * i.texcoord3.xy;
    temp2.xy = saturate(i.texcoord.wz);
    temp3 = tex2D(BaseSamplerClampedSampler, i.texcoord1.xy);
    temp4 = tex2D(BaseSamplerClampedSampler, i.texcoord1.wz);
    temp5 = lerp(temp0, temp3, temp2.x);
    temp0 = lerp(temp5, temp4, temp2.y);
    temp3.x = log2(temp0.x);
    temp3.y = log2(temp0.y);
    temp3.z = log2(temp0.z);
    temp0.xyz = temp3.xyz * float3(2,2,2); //GAMMA
    temp3.x = exp2(temp0.x);
    temp3.y = exp2(temp0.y);
    temp3.z = exp2(temp0.z);
    temp4 = tex2D(NormalSamplerClampedSampler, i.texcoord.xy);
    temp5 = tex2D(NormalSamplerClampedSampler, i.texcoord1.xy);
    temp6 = tex2D(NormalSamplerClampedSampler, i.texcoord1.wz);
    temp0.xyz = lerp(temp4.xyz, temp5.xyz, temp2.xxx);
    temp4.xyz = lerp(temp0.xyz, temp6.xyz, temp2.yyy);
    temp0.xyz = temp4.xyz * float3(2, 2, 2) + float3(-1, -1, -1);
    temp0.xyz = temp0.xyz * float3(0.75, 0.75, 1);
    temp2.xyz = normalize(temp0.xyz).xyz;
    temp0.xyz = i.color.xyz;
    temp4.x = float1(0);
    for (int it0 = 0; it0 < NumPointLights; ++it0) {
            temp5 = temp4.x + float4(-2, -3, -4, -5);
            temp4.xyz = temp4.xxx + float3(1, -0, -1);
            temp6.z = float1(0);
            temp6.xyw = (-abs(temp4).yyy >= 0) ? PointLight[0].Color.xyz : temp6.zzz;
            temp7.xyz = (-abs(temp4).yyy >= 0) ? PointLight[0].Position.xyz : temp6.zzz;
            temp4.yw = (-abs(temp4).yy >= 0) ? PointLight[0].Range_Inner_Outer.xy : temp6.zz;
            temp6.xyz = (-abs(temp4).zzz >= 0) ? PointLight[1].Color.xyz : temp6.xyw;
            temp7.xyz = (-abs(temp4).zzz >= 0) ? PointLight[1].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp4).zz >= 0) ? PointLight[1].Range_Inner_Outer.xy : temp4.yw;
            temp6.xyz = (-abs(temp5).xxx >= 0) ? PointLight[2].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).xxx >= 0) ? PointLight[2].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp5).xx >= 0) ? PointLight[2].Range_Inner_Outer.xy : temp4.yz;
            temp6.xyz = (-abs(temp5).yyy >= 0) ? PointLight[3].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).yyy >= 0) ? PointLight[3].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp5).yy >= 0) ? PointLight[3].Range_Inner_Outer.xy : temp4.yz;
            temp6.xyz = (-abs(temp5).zzz >= 0) ? PointLight[4].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).zzz >= 0) ? PointLight[4].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp5).zz >= 0) ? PointLight[4].Range_Inner_Outer.xy : temp4.yz;
            temp5.xyz = (-abs(temp5).www >= 0) ? PointLight[5].Color.xyz : temp6.xyz;
            temp6.xyz = (-abs(temp5).www >= 0) ? PointLight[5].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp5).ww >= 0) ? PointLight[5].Range_Inner_Outer.xy : temp4.yz;
            temp6.xyz = temp6.xyz + -i.texcoord3.xyz;
            temp2.w = dot(temp6.xyz, temp6.xyz);
            temp2.w = 1 / sqrt(temp2.w);
            temp3.w = 1.0f / temp2.w;
            temp6.xyz = temp6.xyz * temp2.www;
            temp2.w = -temp4.y + temp3.w;
            temp3.w = -temp4.y + temp4.z;
            temp3.w = 1.0f / temp3.w;
            temp2.w = saturate(temp2.w * -temp3.w + float1(1));
            temp2.w = temp2.w * temp2.w;
            temp4.yzw = temp5.xyz * temp2.www;
            temp2.w = dot(temp2.xyz, temp6.xyz);
            temp3.w = max(temp2.w, float1(0));
            temp0.xyz = temp4.yzw * temp3.www + temp0.xyz;
        }
    temp0.xyz = temp3.xyz * temp0.xyz;
    temp0.xyz = temp0.xyz + temp0.xyz;
    temp2.w = dot(temp2.xyz, i.texcoord4.xyz);
    temp2.x = dot(temp2.xyz, i.texcoord5.xyz);
    temp2.y = (-temp2.w >= 0) ? float1(0) : float1(1);
    temp2.z = temp2.w * temp2.y;
    temp2.w = (-temp2.x >= 0) ? float1(0) : float1(1);
    temp2.y = temp2.y * temp2.w;
    temp3.w = pow( abs(temp2.x), float1(40));
    temp2.x = temp2.y * temp3.w;
    temp4 = tex2D(CloudSamplerSampler, temp1.xy);
    temp5.x = log2(temp4.x);
    temp5.y = log2(temp4.y);
    temp5.z = log2(temp4.z);
    temp4.xyz = temp5.xyz * float3(2,2,2); //GAMMA
    temp5.x = exp2(temp4.x);
    temp5.y = exp2(temp4.y);
    temp5.z = exp2(temp4.z);
    temp4.xyz = temp5.xyz * DirectionalLight[0].Color.xyz;
    temp0.w = dot(temp2.xx, temp0.ww) + float1(0);
    temp2.xyz = temp2.zzz * temp3.xyz + temp0.www;
    temp0.xyz = temp4.xyz * temp2.xyz + temp0.xyz;
    temp1 = tex2D(MacroSamplerSampler, temp1.zw);
    temp2.x = log2(temp1.x);
    temp2.y = log2(temp1.y);
    temp2.z = log2(temp1.z);
    temp1.xyz = temp2.xyz * float3(2,2,2); //GAMMA
    temp2.x = exp2(temp1.x);
    temp2.y = exp2(temp1.y);
    temp2.z = exp2(temp1.z);
    temp0.xyz = temp0.xyz * temp2.xyz + float3(-1, -1, -1);
    temp0.xyz = i.color1.xxx * temp0.xyz + float3(1, 1, 1);
    temp1 = tex2D(ShroudSamplerSampler, i.texcoord2.xy);
    out_color.xyz = temp0.xyz * temp1.xxx;
    out_color.w = i.color.w;

    return out_color;
}


struct PS_TerrainTile_Array_Shader_3_Input
{
    float4 color : COLOR;
    float color1 : COLOR1;
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
    float2 texcoord2 : TEXCOORD2;
    float3 texcoord3 : TEXCOORD3;
    float3 texcoord4 : TEXCOORD4;
    float3 texcoord5 : TEXCOORD5;
    float3 texcoord6 : TEXCOORD6;
};

float4 PS_TerrainTile_Array_Shader_3(PS_TerrainTile_Array_Shader_3_Input i) : COLOR
{
    /*
    PRSI
      OutputRegisterOffset: 12
      Unknown1: 0
      Unknown2: 0
      OutputRegisterCount: 1
      Unknown3: 0
      Unknown4: 0
      Unknown5: 12
      Unknown6: 1
      Mappings: 1
        0 - ConstOutput: 0 ConstInput 0
    */
    float4 expr12;
    {
        float4 temp0;
                temp0.x = MapCellSize.x * (66);
            expr12.x = 1.0f / (temp0.x);
    }

    float4 out_color;
    float4 temp0, temp1, temp2, temp3, temp4, temp5, temp6, temp7;
    temp0 = tex2D(BaseSamplerClampedSampler, i.texcoord.xy);
    temp1.xy = Cloud.WorldPositionMultiplier_XYZZ.zw * i.texcoord3.zz;
    temp1.xy = i.texcoord3.xy * Cloud.WorldPositionMultiplier_XYZZ.xy + -temp1.xy;
    temp1.xy = temp1.xy + Cloud.CurrentOffsetUV.xy;
    temp2.xy = float2(1, -1);
    temp1.zw = temp2.xy * expr12.xx;
    temp1.zw = temp1.zw * i.texcoord3.xy;
    temp2.xy = saturate(i.texcoord.wz);
    temp3 = tex2D(BaseSamplerClampedSampler, i.texcoord1.xy);
    temp4 = tex2D(BaseSamplerClampedSampler, i.texcoord1.wz);
    temp5 = lerp(temp0, temp3, temp2.x);
    temp0 = lerp(temp5, temp4, temp2.y);
    temp3.x = log2(temp0.x);
    temp3.y = log2(temp0.y);
    temp3.z = log2(temp0.z);
    temp0.xyz = temp3.xyz * float3(2,2,2); //GAMMA
    temp3.x = exp2(temp0.x);
    temp3.y = exp2(temp0.y);
    temp3.z = exp2(temp0.z);
    temp4 = tex2D(NormalSamplerClampedSampler, i.texcoord.xy);
    temp5 = tex2D(NormalSamplerClampedSampler, i.texcoord1.xy);
    temp6 = tex2D(NormalSamplerClampedSampler, i.texcoord1.wz);
    temp0.xyz = lerp(temp4.xyz, temp5.xyz, temp2.xxx);
    temp4.xyz = lerp(temp0.xyz, temp6.xyz, temp2.yyy);
    temp0.xyz = temp4.xyz * float3(2, 2, 2) + float3(-1, -1, -1);
    temp0.xyz = temp0.xyz * float3(0.75, 0.75, 1);
    temp2.xyz = normalize(temp0.xyz).xyz;
    temp0.xyz = i.color.xyz;
    temp4.x = float1(0);
    for (int it0 = 0; it0 < NumPointLights; ++it0) {
            temp5 = temp4.x + float4(-2, -3, -4, -5);
            temp4.xyz = temp4.xxx + float3(1, -0, -1);
            temp6.z = float1(0);
            temp6.xyw = (-abs(temp4).yyy >= 0) ? PointLight[0].Color.xyz : temp6.zzz;
            temp7.xyz = (-abs(temp4).yyy >= 0) ? PointLight[0].Position.xyz : temp6.zzz;
            temp4.yw = (-abs(temp4).yy >= 0) ? PointLight[0].Range_Inner_Outer.xy : temp6.zz;
            temp6.xyz = (-abs(temp4).zzz >= 0) ? PointLight[1].Color.xyz : temp6.xyw;
            temp7.xyz = (-abs(temp4).zzz >= 0) ? PointLight[1].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp4).zz >= 0) ? PointLight[1].Range_Inner_Outer.xy : temp4.yw;
            temp6.xyz = (-abs(temp5).xxx >= 0) ? PointLight[2].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).xxx >= 0) ? PointLight[2].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp5).xx >= 0) ? PointLight[2].Range_Inner_Outer.xy : temp4.yz;
            temp6.xyz = (-abs(temp5).yyy >= 0) ? PointLight[3].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).yyy >= 0) ? PointLight[3].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp5).yy >= 0) ? PointLight[3].Range_Inner_Outer.xy : temp4.yz;
            temp6.xyz = (-abs(temp5).zzz >= 0) ? PointLight[4].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).zzz >= 0) ? PointLight[4].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp5).zz >= 0) ? PointLight[4].Range_Inner_Outer.xy : temp4.yz;
            temp5.xyz = (-abs(temp5).www >= 0) ? PointLight[5].Color.xyz : temp6.xyz;
            temp6.xyz = (-abs(temp5).www >= 0) ? PointLight[5].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp5).ww >= 0) ? PointLight[5].Range_Inner_Outer.xy : temp4.yz;
            temp6.xyz = temp6.xyz + -i.texcoord3.xyz;
            temp2.w = dot(temp6.xyz, temp6.xyz);
            temp2.w = 1 / sqrt(temp2.w);
            temp3.w = 1.0f / temp2.w;
            temp6.xyz = temp6.xyz * temp2.www;
            temp2.w = -temp4.y + temp3.w;
            temp3.w = -temp4.y + temp4.z;
            temp3.w = 1.0f / temp3.w;
            temp2.w = saturate(temp2.w * -temp3.w + float1(1));
            temp2.w = temp2.w * temp2.w;
            temp4.yzw = temp5.xyz * temp2.www;
            temp2.w = dot(temp2.xyz, temp6.xyz);
            temp3.w = max(temp2.w, float1(0));
            temp0.xyz = temp4.yzw * temp3.www + temp0.xyz;
        }
    temp0.xyz = temp3.xyz * temp0.xyz;
    temp0.xyz = temp0.xyz + temp0.xyz;
    temp2.w = dot(temp2.xyz, i.texcoord4.xyz);
    temp2.x = dot(temp2.xyz, i.texcoord5.xyz);
    temp2.y = (-temp2.w >= 0) ? float1(0) : float1(1);
    temp2.z = temp2.w * temp2.y;
    temp3.w = (-temp2.x >= 0) ? float1(0) : float1(1);
    temp2.y = temp2.y * temp3.w;
    temp3.w = pow( abs(temp2.x) , float1(40));
    temp2.w = temp2.y * temp3.w;

    /*
    temp4 = tex2D(ShadowMapSampler, i.texcoord6.xy);
    temp2.xy = Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.zx + i.texcoord6.xy;
    temp5 = tex2D(ShadowMapSampler, temp2.xy);
    temp2.xy = Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.yz + i.texcoord6.xy;
    temp6 = tex2D(ShadowMapSampler, temp2.xy);
    temp2.xy = Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.wz + i.texcoord6.xy;
    temp7 = tex2D(ShadowMapSampler, temp2.xy);
    temp4.y = temp5.x;
    temp4.z = temp6.x;
    temp4.w = temp7.x;
    temp4 = temp4 + -i.texcoord6.z;
    temp4 = (temp4 >= 0) ? float4(1, 1, 1, 1) : float4(0, 0, 0, 0);
    temp2.x = dot(float4(1, 1, 1, 1), temp4);
    temp2.x = temp2.x * float1(0.25);
    */

    temp2.x = helper_shadowpcf(
        2,//ShadowPCFlevel,
        ShadowMapSampler,
        Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w, 
        i.texcoord6.xyz) ;

    temp2.xy = temp2.zw * temp2.xx;
    temp4 = tex2D(CloudSamplerSampler, temp1.xy);
    temp5.x = log2(temp4.x);
    temp5.y = log2(temp4.y);
    temp5.z = log2(temp4.z);
    temp4.xyz = temp5.xyz * float3(2,2,2); //GAMMA
    temp5.x = exp2(temp4.x);
    temp5.y = exp2(temp4.y);
    temp5.z = exp2(temp4.z);
    temp4.xyz = temp5.xyz * DirectionalLight[0].Color.xyz;
    temp0.w = dot(temp2.yy, temp0.ww) + float1(0);
    temp2.xyz = temp2.xxx * temp3.xyz + temp0.www;
    temp0.xyz = temp4.xyz * temp2.xyz + temp0.xyz;
    temp1 = tex2D(MacroSamplerSampler, temp1.zw);
    temp2.x = log2(temp1.x);
    temp2.y = log2(temp1.y);
    temp2.z = log2(temp1.z);
    temp1.xyz = temp2.xyz * float3(2,2,2); //GAMMA
    temp2.x = exp2(temp1.x);
    temp2.y = exp2(temp1.y);
    temp2.z = exp2(temp1.z);
    temp0.xyz = temp0.xyz * temp2.xyz + float3(-1, -1, -1);
    temp0.xyz = i.color1.xxx * temp0.xyz + float3(1, 1, 1);
    temp1 = tex2D(ShroudSamplerSampler, i.texcoord2.xy);
    out_color.xyz = temp0.xyz * temp1.xxx;
    out_color.w = i.color.w;

    return out_color;
}

PixelShader PS_TerrainTile_Array[4] = {
    compile ps_3_0 PS_TerrainTile_Array_Shader_0(), 
    compile ps_3_0 PS_TerrainTile_Array_Shader_1(), 
    compile ps_3_0 PS_TerrainTile_Array_Shader_2(), 
    compile ps_3_0 PS_TerrainTile_Array_Shader_3(), 
};

struct PS_Cliff_Array_Shader_0_Input
{
    float4 color : COLOR;
    float color1 : COLOR1;
    float2 texcoord : TEXCOORD;
    float2 texcoord2 : TEXCOORD2;
    float3 texcoord3 : TEXCOORD3;
    float3 texcoord4 : TEXCOORD4;
    float3 texcoord5 : TEXCOORD5;
};

float4 PS_Cliff_Array_Shader_0(PS_Cliff_Array_Shader_0_Input i) : COLOR
{
    /*
    PRSI
      OutputRegisterOffset: 11
      Unknown1: 0
      Unknown2: 0
      OutputRegisterCount: 1
      Unknown3: 0
      Unknown4: 0
      Unknown5: 11
      Unknown6: 1
      Mappings: 1
        0 - ConstOutput: 0 ConstInput 0
    */
    float4 expr11;
    {
        float4 temp0;
                temp0.x = MapCellSize.x * (66);
            expr11.x = 1.0f / (temp0.x);
    }

    float4 out_color;
    float4 temp0, temp1, temp2, temp3, temp4, temp5, temp6;
    float3 temp7;
    temp0 = tex2D(BaseSamplerWrappedSampler, i.texcoord.xy);
    temp1.xy = Cloud.WorldPositionMultiplier_XYZZ.zw * i.texcoord3.zz;
    temp1.xy = i.texcoord3.xy * Cloud.WorldPositionMultiplier_XYZZ.xy + -temp1.xy;
    temp1.xy = temp1.xy + Cloud.CurrentOffsetUV.xy;
    temp2.xy = float2(1, -1);
    temp1.zw = temp2.xy * expr11.xx;
    temp1.zw = temp1.zw * i.texcoord3.xy;
    temp2.x = log2(temp0.x);
    temp2.y = log2(temp0.y);
    temp2.z = log2(temp0.z);
    temp0.xyz = temp2.xyz * float3(2,2,2); //GAMMA
    temp2.x = exp2(temp0.x);
    temp2.y = exp2(temp0.y);
    temp2.z = exp2(temp0.z);
    temp0 = tex2D(NormalSamplerWrappedSampler, i.texcoord.xy);
    temp0.xy = temp0.xy * float2(2, 2) + float2(-1, -1);
    temp0.w = temp0.x * -temp0.x + float1(1);
    temp0.w = temp0.y * -temp0.y + temp0.w;
    temp0.w = 1 / sqrt(temp0.w);
    temp3.z = 1.0f / temp0.w;
    temp3.xy = temp0.xy * float2(0.75, 0.75);
    temp4.xyz = normalize(temp3.xyz).xyz;
    temp0.xyw = i.color.xyz;
    temp3.x = float1(0);
    for (int it0 = 0; it0 < NumPointLights; ++it0) {
            temp5 = temp3.x + float4(-2, -3, -4, -5);
            temp3.xyz = temp3.xxx + float3(1, -0, -1);
            temp6.y = float1(0);
            temp6.xzw = (-abs(temp3).yyy >= 0) ? PointLight[0].Color.xyz : temp6.yyy;
            temp7.xyz = (-abs(temp3).yyy >= 0) ? PointLight[0].Position.xyz : temp6.yyy;
            temp3.yw = (-abs(temp3).yy >= 0) ? PointLight[0].Range_Inner_Outer.xy : temp6.yy;
            temp6.xyz = (-abs(temp3).zzz >= 0) ? PointLight[1].Color.xyz : temp6.xzw;
            temp7.xyz = (-abs(temp3).zzz >= 0) ? PointLight[1].Position.xyz : temp7.xyz;
            temp3.yz = (-abs(temp3).zz >= 0) ? PointLight[1].Range_Inner_Outer.xy : temp3.yw;
            temp6.xyz = (-abs(temp5).xxx >= 0) ? PointLight[2].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).xxx >= 0) ? PointLight[2].Position.xyz : temp7.xyz;
            temp3.yz = (-abs(temp5).xx >= 0) ? PointLight[2].Range_Inner_Outer.xy : temp3.yz;
            temp6.xyz = (-abs(temp5).yyy >= 0) ? PointLight[3].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).yyy >= 0) ? PointLight[3].Position.xyz : temp7.xyz;
            temp3.yz = (-abs(temp5).yy >= 0) ? PointLight[3].Range_Inner_Outer.xy : temp3.yz;
            temp6.xyz = (-abs(temp5).zzz >= 0) ? PointLight[4].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).zzz >= 0) ? PointLight[4].Position.xyz : temp7.xyz;
            temp3.yz = (-abs(temp5).zz >= 0) ? PointLight[4].Range_Inner_Outer.xy : temp3.yz;
            temp5.xyz = (-abs(temp5).www >= 0) ? PointLight[5].Color.xyz : temp6.xyz;
            temp6.xyz = (-abs(temp5).www >= 0) ? PointLight[5].Position.xyz : temp7.xyz;
            temp3.yz = (-abs(temp5).ww >= 0) ? PointLight[5].Range_Inner_Outer.xy : temp3.yz;
            temp6.xyz = temp6.xyz + -i.texcoord3.xyz;
            temp2.w = dot(temp6.xyz, temp6.xyz);
            temp2.w = 1 / sqrt(temp2.w);
            temp3.w = 1.0f / temp2.w;
            temp6.xyz = temp6.xyz * temp2.www;
            temp2.w = -temp3.y + temp3.w;
            temp3.y = -temp3.y + temp3.z;
            temp3.y = 1.0f / temp3.y;
            temp2.w = saturate(temp2.w * -temp3.y + float1(1));
            temp2.w = temp2.w * temp2.w;
            temp3.yzw = temp5.xyz * temp2.www;
            temp2.w = dot(temp4.xyz, temp6.xyz);
            temp4.w = max(temp2.w, float1(0));
            temp0.xyw = temp3.yzw * temp4.www + temp0.xyw;
        }
    temp0.xyw = temp2.xyz * temp0.xyw;
    temp0.xyw = temp0.xyw + temp0.xyw;
    temp2.w = dot(temp4.xyz, i.texcoord4.xyz);
    temp3.x = dot(temp4.xyz, i.texcoord5.xyz);
    temp3.y = (-temp2.w >= 0) ? float1(0) : float1(1);
    temp2.w = temp2.w * temp3.y;
    temp3.z = (-temp3.x >= 0) ? float1(0) : float1(1);
    temp3.y = temp3.y * temp3.z;
    temp4.x = pow( abs(temp3.x), float1(40));
    temp3.x = temp3.y * temp4.x;
    temp4 = tex2D(CloudSamplerSampler, temp1.xy);
    temp3.y = log2(temp4.x);
    temp3.z = log2(temp4.y);
    temp3.w = log2(temp4.z);
    temp3.yzw = temp3.yzw * float3(2,2,2); //GAMMA
    temp4.x = exp2(temp3.y);
    temp4.y = exp2(temp3.z);
    temp4.z = exp2(temp3.w);
    temp3.yzw = temp4.xyz * DirectionalLight[0].Color.xyz;
    temp0.z = dot(temp3.xx, temp0.zz) + float1(0);
    temp2.xyz = temp2.www * temp2.xyz + temp0.zzz;
    temp0.xyz = temp3.yzw * temp2.xyz + temp0.xyw;
    temp1 = tex2D(MacroSamplerSampler, temp1.zw);
    temp2.x = log2(temp1.x);
    temp2.y = log2(temp1.y);
    temp2.z = log2(temp1.z);
    temp1.xyz = temp2.xyz * float3(2,2,2); //GAMMA
    temp2.x = exp2(temp1.x);
    temp2.y = exp2(temp1.y);
    temp2.z = exp2(temp1.z);
    temp0.xyz = temp0.xyz * temp2.xyz + float3(-1, -1, -1);
    temp0.xyz = i.color1.xxx * temp0.xyz + float3(1, 1, 1);
    temp1 = tex2D(ShroudSamplerSampler, i.texcoord2.xy);
    out_color.xyz = temp0.xyz * temp1.xxx;
    out_color.w = i.color.w;

    return out_color;
}


struct PS_Cliff_Array_Shader_1_Input
{
    float4 color : COLOR;
    float color1 : COLOR1;
    float2 texcoord : TEXCOORD;
    float2 texcoord2 : TEXCOORD2;
    float3 texcoord3 : TEXCOORD3;
    float3 texcoord4 : TEXCOORD4;
    float3 texcoord5 : TEXCOORD5;
    float3 texcoord6 : TEXCOORD6;
};

float4 PS_Cliff_Array_Shader_1(PS_Cliff_Array_Shader_1_Input i) : COLOR
{
    /*
    PRSI
      OutputRegisterOffset: 12
      Unknown1: 0
      Unknown2: 0
      OutputRegisterCount: 1
      Unknown3: 0
      Unknown4: 0
      Unknown5: 12
      Unknown6: 1
      Mappings: 1
        0 - ConstOutput: 0 ConstInput 0
    */
    float4 expr12;
    {
        float4 temp0;
                temp0.x = MapCellSize.x * (66);
            expr12.x = 1.0f / (temp0.x);
    }

    float4 out_color;
    float4 temp0, temp1, temp2, temp3, temp4, temp5, temp6, temp7;
    temp0 = tex2D(BaseSamplerWrappedSampler, i.texcoord.xy);
    temp1.xy = Cloud.WorldPositionMultiplier_XYZZ.zw * i.texcoord3.zz;
    temp1.xy = i.texcoord3.xy * Cloud.WorldPositionMultiplier_XYZZ.xy + -temp1.xy;
    temp1.xy = temp1.xy + Cloud.CurrentOffsetUV.xy;
    temp2.xy = float2(1, -1);
    temp1.zw = temp2.xy * expr12.xx;
    temp1.zw = temp1.zw * i.texcoord3.xy;
    temp2.x = log2(temp0.x);
    temp2.y = log2(temp0.y);
    temp2.z = log2(temp0.z);
    temp0.xyz = temp2.xyz * float3(2,2,2); //GAMMA
    temp2.x = exp2(temp0.x);
    temp2.y = exp2(temp0.y);
    temp2.z = exp2(temp0.z);
    temp0 = tex2D(NormalSamplerWrappedSampler, i.texcoord.xy);
    temp0.xy = temp0.xy * float2(2, 2) + float2(-1, -1);
    temp0.w = temp0.x * -temp0.x + float1(1);
    temp0.w = temp0.y * -temp0.y + temp0.w;
    temp0.w = 1 / sqrt(temp0.w);
    temp3.z = 1.0f / temp0.w;
    temp3.xy = temp0.xy * float2(0.75, 0.75);
    temp4.xyz = normalize(temp3.xyz).xyz;
    temp0.xyw = i.color.xyz;
    temp3.x = float1(0);
    for (int it0 = 0; it0 < NumPointLights; ++it0) {
            temp5 = temp3.x + float4(-2, -3, -4, -5);
            temp3.xyz = temp3.xxx + float3(1, -0, -1);
            temp6.y = float1(0);
            temp6.xzw = (-abs(temp3).yyy >= 0) ? PointLight[0].Color.xyz : temp6.yyy;
            temp7.xyz = (-abs(temp3).yyy >= 0) ? PointLight[0].Position.xyz : temp6.yyy;
            temp3.yw = (-abs(temp3).yy >= 0) ? PointLight[0].Range_Inner_Outer.xy : temp6.yy;
            temp6.xyz = (-abs(temp3).zzz >= 0) ? PointLight[1].Color.xyz : temp6.xzw;
            temp7.xyz = (-abs(temp3).zzz >= 0) ? PointLight[1].Position.xyz : temp7.xyz;
            temp3.yz = (-abs(temp3).zz >= 0) ? PointLight[1].Range_Inner_Outer.xy : temp3.yw;
            temp6.xyz = (-abs(temp5).xxx >= 0) ? PointLight[2].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).xxx >= 0) ? PointLight[2].Position.xyz : temp7.xyz;
            temp3.yz = (-abs(temp5).xx >= 0) ? PointLight[2].Range_Inner_Outer.xy : temp3.yz;
            temp6.xyz = (-abs(temp5).yyy >= 0) ? PointLight[3].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).yyy >= 0) ? PointLight[3].Position.xyz : temp7.xyz;
            temp3.yz = (-abs(temp5).yy >= 0) ? PointLight[3].Range_Inner_Outer.xy : temp3.yz;
            temp6.xyz = (-abs(temp5).zzz >= 0) ? PointLight[4].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).zzz >= 0) ? PointLight[4].Position.xyz : temp7.xyz;
            temp3.yz = (-abs(temp5).zz >= 0) ? PointLight[4].Range_Inner_Outer.xy : temp3.yz;
            temp5.xyz = (-abs(temp5).www >= 0) ? PointLight[5].Color.xyz : temp6.xyz;
            temp6.xyz = (-abs(temp5).www >= 0) ? PointLight[5].Position.xyz : temp7.xyz;
            temp3.yz = (-abs(temp5).ww >= 0) ? PointLight[5].Range_Inner_Outer.xy : temp3.yz;
            temp6.xyz = temp6.xyz + -i.texcoord3.xyz;
            temp2.w = dot(temp6.xyz, temp6.xyz);
            temp2.w = 1 / sqrt(temp2.w);
            temp3.w = 1.0f / temp2.w;
            temp6.xyz = temp6.xyz * temp2.www;
            temp2.w = -temp3.y + temp3.w;
            temp3.y = -temp3.y + temp3.z;
            temp3.y = 1.0f / temp3.y;
            temp2.w = saturate(temp2.w * -temp3.y + float1(1));
            temp2.w = temp2.w * temp2.w;
            temp3.yzw = temp5.xyz * temp2.www;
            temp2.w = dot(temp4.xyz, temp6.xyz);
            temp4.w = max(temp2.w, float1(0));
            temp0.xyw = temp3.yzw * temp4.www + temp0.xyw;
        }
    temp0.xyw = temp2.xyz * temp0.xyw;
    temp0.xyw = temp0.xyw + temp0.xyw;
    temp2.w = dot(temp4.xyz, i.texcoord4.xyz);
    temp3.x = dot(temp4.xyz, i.texcoord5.xyz);
    temp3.y = (-temp2.w >= 0) ? float1(0) : float1(1);
    temp3.z = temp2.w * temp3.y;
    temp2.w = (-temp3.x >= 0) ? float1(0) : float1(1);
    temp2.w = temp3.y * temp2.w;
    temp4.x = pow( abs(temp3.x), float1(40));
    temp3.w = temp2.w * temp4.x;

    /*
    temp4 = tex2D(ShadowMapSampler, i.texcoord6.xy);
    temp3.xy = Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.zx + i.texcoord6.xy;
    temp5 = tex2D(ShadowMapSampler, temp3.xy);
    temp3.xy = Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.yz + i.texcoord6.xy;
    temp6 = tex2D(ShadowMapSampler, temp3.xy);
    temp3.xy = Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.wz + i.texcoord6.xy;
    temp7 = tex2D(ShadowMapSampler, temp3.xy);
    temp4.y = temp5.x;
    temp4.z = temp6.x;
    temp4.w = temp7.x;
    temp4 = temp4 + -i.texcoord6.z;
    temp4 = (temp4 >= 0) ? float4(1, 1, 1, 1) : float4(0, 0, 0, 0);
    temp2.w = dot(float4(1, 1, 1, 1), temp4);
    temp2.w = temp2.w * float1(0.25);
    */
    temp2.w = helper_shadowpcf(
        3,//ShadowPCFlevel,
        ShadowMapSampler,
        Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w, 
        i.texcoord6.xyz) ;

    temp3.xy = temp3.zw * temp2.ww;
    temp4 = tex2D(CloudSamplerSampler, temp1.xy);
    temp5.x = log2(temp4.x);
    temp5.y = log2(temp4.y);
    temp5.z = log2(temp4.z);
    temp4.xyz = temp5.xyz * float3(2,2,2); //GAMMA
    temp5.x = exp2(temp4.x);
    temp5.y = exp2(temp4.y);
    temp5.z = exp2(temp4.z);
    temp4.xyz = temp5.xyz * DirectionalLight[0].Color.xyz;
    temp0.z = dot(temp3.yy, temp0.zz) + float1(0);
    temp2.xyz = temp3.xxx * temp2.xyz + temp0.zzz;
    temp0.xyz = temp4.xyz * temp2.xyz + temp0.xyw;
    temp1 = tex2D(MacroSamplerSampler, temp1.zw);
    temp2.x = log2(temp1.x);
    temp2.y = log2(temp1.y);
    temp2.z = log2(temp1.z);
    temp1.xyz = temp2.xyz * float3(2,2,2); //GAMMA
    temp2.x = exp2(temp1.x);
    temp2.y = exp2(temp1.y);
    temp2.z = exp2(temp1.z);
    temp0.xyz = temp0.xyz * temp2.xyz + float3(-1, -1, -1);
    temp0.xyz = i.color1.xxx * temp0.xyz + float3(1, 1, 1);
    temp1 = tex2D(ShroudSamplerSampler, i.texcoord2.xy);
    out_color.xyz = temp0.xyz * temp1.xxx;
    out_color.w = i.color.w;

    return out_color;
}

PixelShader PS_Cliff_Array[2] = {
    compile ps_3_0 PS_Cliff_Array_Shader_0(), 
    compile ps_3_0 PS_Cliff_Array_Shader_1(), 
};

struct PS_Road_Array_Shader_0_Input
{
    float4 color : COLOR;
    float color1 : COLOR1;
    float2 texcoord : TEXCOORD;
    float2 texcoord2 : TEXCOORD2;
    float3 texcoord3 : TEXCOORD3;
    float3 texcoord4 : TEXCOORD4;
    float3 texcoord5 : TEXCOORD5;
};

float4 PS_Road_Array_Shader_0(PS_Road_Array_Shader_0_Input i) : COLOR
{
    /*
    PRSI
      OutputRegisterOffset: 11
      Unknown1: 0
      Unknown2: 0
      OutputRegisterCount: 1
      Unknown3: 0
      Unknown4: 0
      Unknown5: 11
      Unknown6: 1
      Mappings: 1
        0 - ConstOutput: 0 ConstInput 0
    */
    float4 expr11;
    {
        float4 temp0;
                temp0.x = MapCellSize.x * (66);
            expr11.x = 1.0f / (temp0.x);
    }

    float4 out_color;
    float4 temp0, temp1, temp2, temp3, temp4, temp5, temp6;
    float3 temp7;
    temp0 = tex2D(BaseSamplerWrappedSampler, i.texcoord.xy);
    temp1.xy = Cloud.WorldPositionMultiplier_XYZZ.zw * i.texcoord3.zz;
    temp1.xy = i.texcoord3.xy * Cloud.WorldPositionMultiplier_XYZZ.xy + -temp1.xy;
    temp1.xy = temp1.xy + Cloud.CurrentOffsetUV.xy;
    temp2.xy = float2(1, -1);
    temp1.zw = temp2.xy * expr11.xx;
    temp1.zw = temp1.zw * i.texcoord3.xy;
    temp2.x = log2(temp0.x);
    temp2.y = log2(temp0.y);
    temp2.z = log2(temp0.z);
    temp0.xyz = temp2.xyz * float3(2,2,2); //GAMMA
    temp2.x = exp2(temp0.x);
    temp2.y = exp2(temp0.y);
    temp2.z = exp2(temp0.z);
    out_color.w = temp0.w * i.color.w;
    temp0 = tex2D(NormalSamplerWrappedSampler, i.texcoord.xy);
    temp0.xyz = temp0.xyz * float3(2, 2, 2) + float3(-1, -1, -1);
    temp0.xyz = temp0.xyz * float3(0.75, 0.75, 1);
    temp3.xyz = normalize(temp0.xyz).xyz;
    temp0.xyz = i.color.xyz;
    temp4.x = float1(0);
    for (int it0 = 0; it0 < NumPointLights; ++it0) {
            temp5 = temp4.x + float4(-2, -3, -4, -5);
            temp4.xyz = temp4.xxx + float3(1, -0, -1);
            temp6.z = float1(0);
            temp6.xyw = (-abs(temp4).yyy >= 0) ? PointLight[0].Color.xyz : temp6.zzz;
            temp7.xyz = (-abs(temp4).yyy >= 0) ? PointLight[0].Position.xyz : temp6.zzz;
            temp4.yw = (-abs(temp4).yy >= 0) ? PointLight[0].Range_Inner_Outer.xy : temp6.zz;
            temp6.xyz = (-abs(temp4).zzz >= 0) ? PointLight[1].Color.xyz : temp6.xyw;
            temp7.xyz = (-abs(temp4).zzz >= 0) ? PointLight[1].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp4).zz >= 0) ? PointLight[1].Range_Inner_Outer.xy : temp4.yw;
            temp6.xyz = (-abs(temp5).xxx >= 0) ? PointLight[2].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).xxx >= 0) ? PointLight[2].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp5).xx >= 0) ? PointLight[2].Range_Inner_Outer.xy : temp4.yz;
            temp6.xyz = (-abs(temp5).yyy >= 0) ? PointLight[3].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).yyy >= 0) ? PointLight[3].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp5).yy >= 0) ? PointLight[3].Range_Inner_Outer.xy : temp4.yz;
            temp6.xyz = (-abs(temp5).zzz >= 0) ? PointLight[4].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).zzz >= 0) ? PointLight[4].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp5).zz >= 0) ? PointLight[4].Range_Inner_Outer.xy : temp4.yz;
            temp5.xyz = (-abs(temp5).www >= 0) ? PointLight[5].Color.xyz : temp6.xyz;
            temp6.xyz = (-abs(temp5).www >= 0) ? PointLight[5].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp5).ww >= 0) ? PointLight[5].Range_Inner_Outer.xy : temp4.yz;
            temp6.xyz = temp6.xyz + -i.texcoord3.xyz;
            temp2.w = dot(temp6.xyz, temp6.xyz);
            temp2.w = 1 / sqrt(temp2.w);
            temp3.w = 1.0f / temp2.w;
            temp6.xyz = temp6.xyz * temp2.www;
            temp2.w = -temp4.y + temp3.w;
            temp3.w = -temp4.y + temp4.z;
            temp3.w = 1.0f / temp3.w;
            temp2.w = saturate(temp2.w * -temp3.w + float1(1));
            temp2.w = temp2.w * temp2.w;
            temp4.yzw = temp5.xyz * temp2.www;
            temp2.w = dot(temp3.xyz, temp6.xyz);
            temp3.w = max(temp2.w, float1(0));
            temp0.xyz = temp4.yzw * temp3.www + temp0.xyz;
        }
    temp0.xyz = temp2.xyz * temp0.xyz;
    temp0.xyz = temp0.xyz + temp0.xyz;
    temp2.w = dot(temp3.xyz, i.texcoord4.xyz);
    temp3.x = dot(temp3.xyz, i.texcoord5.xyz);
    temp3.y = (-temp2.w >= 0) ? float1(0) : float1(1);
    temp2.w = temp2.w * temp3.y;
    temp3.z = (-temp3.x >= 0) ? float1(0) : float1(1);
    temp3.y = temp3.y * temp3.z;
    temp4.x = pow(abs(temp3.x), float1(40));
    temp3.x = temp3.y * temp4.x;
    temp4 = tex2D(CloudSamplerSampler, temp1.xy);
    temp3.y = log2(temp4.x);
    temp3.z = log2(temp4.y);
    temp3.w = log2(temp4.z);
    temp3.yzw = temp3.yzw * float3(2,2,2); //GAMMA
    temp4.x = exp2(temp3.y);
    temp4.y = exp2(temp3.z);
    temp4.z = exp2(temp3.w);
    temp3.yzw = temp4.xyz * DirectionalLight[0].Color.xyz;
    temp0.w = dot(temp3.xx, temp0.ww) + float1(0);
    temp2.xyz = temp2.www * temp2.xyz + temp0.www;
    temp0.xyz = temp3.yzw * temp2.xyz + temp0.xyz;
    temp1 = tex2D(MacroSamplerSampler, temp1.zw);
    temp2.x = log2(temp1.x);
    temp2.y = log2(temp1.y);
    temp2.z = log2(temp1.z);
    temp1.xyz = temp2.xyz * float3(2,2,2); //GAMMA
    temp2.x = exp2(temp1.x);
    temp2.y = exp2(temp1.y);
    temp2.z = exp2(temp1.z);
    temp0.xyz = temp0.xyz * temp2.xyz + float3(-1, -1, -1);
    temp0.xyz = i.color1.xxx * temp0.xyz + float3(1, 1, 1);
    temp1 = tex2D(ShroudSamplerSampler, i.texcoord2.xy);
    out_color.xyz = temp0.xyz * temp1.xxx;

    return out_color;
}


struct PS_Road_Array_Shader_1_Input
{
    float4 color : COLOR;
    float color1 : COLOR1;
    float2 texcoord : TEXCOORD;
    float2 texcoord2 : TEXCOORD2;
    float3 texcoord3 : TEXCOORD3;
    float3 texcoord4 : TEXCOORD4;
    float3 texcoord5 : TEXCOORD5;
    float4 texcoord6 : TEXCOORD6;
};

float4 PS_Road_Array_Shader_1(PS_Road_Array_Shader_1_Input i) : COLOR
{
    /*
    PRSI
      OutputRegisterOffset: 12
      Unknown1: 0
      Unknown2: 0
      OutputRegisterCount: 1
      Unknown3: 0
      Unknown4: 0
      Unknown5: 12
      Unknown6: 1
      Mappings: 1
        0 - ConstOutput: 0 ConstInput 0
    */
    float4 expr12;
    {
        float4 temp0;
                temp0.x = MapCellSize.x * (66);
            expr12.x = 1.0f / (temp0.x);
    }

    float4 out_color;
    float4 temp0, temp1, temp2, temp3, temp4, temp5, temp6, temp7, temp8;
    temp0 = tex2D(BaseSamplerWrappedSampler, i.texcoord.xy);
    temp1.xy = Cloud.WorldPositionMultiplier_XYZZ.zw * i.texcoord3.zz;
    temp1.xy = i.texcoord3.xy * Cloud.WorldPositionMultiplier_XYZZ.xy + -temp1.xy;
    temp1.xy = temp1.xy + Cloud.CurrentOffsetUV.xy;
    temp2.xy = float2(1, -1);
    temp1.zw = temp2.xy * expr12.xx;
    temp1.zw = temp1.zw * i.texcoord3.xy;
    temp2.x = log2(temp0.x);
    temp2.y = log2(temp0.y);
    temp2.z = log2(temp0.z);
    temp0.xyz = temp2.xyz * float3(2,2,2); //GAMMA
    temp2.x = exp2(temp0.x);
    temp2.y = exp2(temp0.y);
    temp2.z = exp2(temp0.z);
    out_color.w = temp0.w * i.color.w;
    temp0 = tex2D(NormalSamplerWrappedSampler, i.texcoord.xy);
    temp0.xyz = temp0.xyz * float3(2, 2, 2) + float3(-1, -1, -1);
    temp0.xyz = temp0.xyz * float3(0.75, 0.75, 1);
    temp3.xyz = normalize(temp0.xyz).xyz;
    temp0.xyz = i.color.xyz;
    temp4.x = float1(0);
    for (int it0 = 0; it0 < NumPointLights; ++it0) {
            temp5 = temp4.x + float4(-2, -3, -4, -5);
            temp4.xyz = temp4.xxx + float3(1, -0, -1);
            temp6.z = float1(0);
            temp6.xyw = (-abs(temp4).yyy >= 0) ? PointLight[0].Color.xyz : temp6.zzz;
            temp7.xyz = (-abs(temp4).yyy >= 0) ? PointLight[0].Position.xyz : temp6.zzz;
            temp4.yw = (-abs(temp4).yy >= 0) ? PointLight[0].Range_Inner_Outer.xy : temp6.zz;
            temp6.xyz = (-abs(temp4).zzz >= 0) ? PointLight[1].Color.xyz : temp6.xyw;
            temp7.xyz = (-abs(temp4).zzz >= 0) ? PointLight[1].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp4).zz >= 0) ? PointLight[1].Range_Inner_Outer.xy : temp4.yw;
            temp6.xyz = (-abs(temp5).xxx >= 0) ? PointLight[2].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).xxx >= 0) ? PointLight[2].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp5).xx >= 0) ? PointLight[2].Range_Inner_Outer.xy : temp4.yz;
            temp6.xyz = (-abs(temp5).yyy >= 0) ? PointLight[3].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).yyy >= 0) ? PointLight[3].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp5).yy >= 0) ? PointLight[3].Range_Inner_Outer.xy : temp4.yz;
            temp6.xyz = (-abs(temp5).zzz >= 0) ? PointLight[4].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).zzz >= 0) ? PointLight[4].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp5).zz >= 0) ? PointLight[4].Range_Inner_Outer.xy : temp4.yz;
            temp5.xyz = (-abs(temp5).www >= 0) ? PointLight[5].Color.xyz : temp6.xyz;
            temp6.xyz = (-abs(temp5).www >= 0) ? PointLight[5].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp5).ww >= 0) ? PointLight[5].Range_Inner_Outer.xy : temp4.yz;
            temp6.xyz = temp6.xyz + -i.texcoord3.xyz;
            temp2.w = dot(temp6.xyz, temp6.xyz);
            temp2.w = 1 / sqrt(temp2.w);
            temp3.w = 1.0f / temp2.w;
            temp6.xyz = temp6.xyz * temp2.www;
            temp2.w = -temp4.y + temp3.w;
            temp3.w = -temp4.y + temp4.z;
            temp3.w = 1.0f / temp3.w;
            temp2.w = saturate(temp2.w * -temp3.w + float1(1));
            temp2.w = temp2.w * temp2.w;
            temp4.yzw = temp5.xyz * temp2.www;
            temp2.w = dot(temp3.xyz, temp6.xyz);
            temp3.w = max(temp2.w, float1(0));
            temp0.xyz = temp4.yzw * temp3.www + temp0.xyz;
        }
    temp0.xyz = temp2.xyz * temp0.xyz;
    temp0.xyz = temp0.xyz + temp0.xyz;
    temp2.w = dot(temp3.xyz, i.texcoord4.xyz);
    temp3.x = dot(temp3.xyz, i.texcoord5.xyz);
    temp3.y = (-temp2.w >= 0) ? float1(0) : float1(1);
    temp3.z = temp2.w * temp3.y;
    temp2.w = (-temp3.x >= 0) ? float1(0) : float1(1);
    temp2.w = temp3.y * temp2.w;
    temp4.x = pow(abs(temp3.x), float1(40));
    temp3.w = temp2.w * temp4.x;
    temp2.w = 1.0f / i.texcoord6.w;
    temp3.xy = temp2.ww * i.texcoord6.xy;
    temp4.x = i.texcoord6.z * temp2.w + float1(-0.0015);


    /*
    temp5 = tex2D(ShadowMapSampler, temp3.xy);
    temp3.xy = i.texcoord6.xy * temp2.ww + Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.zx;
    temp6 = tex2D(ShadowMapSampler, temp3.xy);
    temp3.xy = i.texcoord6.xy * temp2.ww + Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.yz;
    temp7 = tex2D(ShadowMapSampler, temp3.xy);
    temp3.xy = i.texcoord6.xy * temp2.ww + Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.wz;
    temp8 = tex2D(ShadowMapSampler, temp3.xy);
    temp5.y = temp6.x;
    temp5.z = temp7.x;
    temp5.w = temp8.x;
    temp4 = -temp4.x + temp5;
    temp4 = (temp4 >= 0) ? float4(1, 1, 1, 1) : float4(0, 0, 0, 0);
    temp2.w = dot(float4(1, 1, 1, 1), temp4);
    temp2.w = temp2.w * float1(0.25);
    */
    float3 ShadowProjection = (temp3.x, temp3.y, temp4.x);
    temp2.x = helper_shadowpcf(
        3,//ShadowPCFlevel,
        ShadowMapSampler,
        Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w, 
        ShadowProjection) ;

    temp3.xy = temp3.zw * temp2.ww;
    temp4 = tex2D(CloudSamplerSampler, temp1.xy);
    temp5.x = log2(temp4.x);
    temp5.y = log2(temp4.y);
    temp5.z = log2(temp4.z);
    temp4.xyz = temp5.xyz * float3(2,2,2); //GAMMA
    temp5.x = exp2(temp4.x);
    temp5.y = exp2(temp4.y);
    temp5.z = exp2(temp4.z);
    temp4.xyz = temp5.xyz * DirectionalLight[0].Color.xyz;
    temp0.w = dot(temp3.yy, temp0.ww) + float1(0);
    temp2.xyz = temp3.xxx * temp2.xyz + temp0.www;
    temp0.xyz = temp4.xyz * temp2.xyz + temp0.xyz;
    temp1 = tex2D(MacroSamplerSampler, temp1.zw);
    temp2.x = log2(temp1.x);
    temp2.y = log2(temp1.y);
    temp2.z = log2(temp1.z);
    temp1.xyz = temp2.xyz * float3(2,2,2); //GAMMA
    temp2.x = exp2(temp1.x);
    temp2.y = exp2(temp1.y);
    temp2.z = exp2(temp1.z);
    temp0.xyz = temp0.xyz * temp2.xyz + float3(-1, -1, -1);
    temp0.xyz = i.color1.xxx * temp0.xyz + float3(1, 1, 1);
    temp1 = tex2D(ShroudSamplerSampler, i.texcoord2.xy);
    out_color.xyz = temp0.xyz * temp1.xxx;

    return out_color;
}

PixelShader PS_Road_Array[2] = {
    compile ps_3_0 PS_Road_Array_Shader_0(), 
    compile ps_3_0 PS_Road_Array_Shader_1(), 
};

struct PS_Scorch_Array_Shader_0_Input
{
    float4 color : COLOR;
    float color1 : COLOR1;
    float2 texcoord : TEXCOORD;
    float2 texcoord2 : TEXCOORD2;
    float3 texcoord3 : TEXCOORD3;
    float3 texcoord4 : TEXCOORD4;
};

float4 PS_Scorch_Array_Shader_0(PS_Scorch_Array_Shader_0_Input i) : COLOR
{
    /*
    PRSI
      OutputRegisterOffset: 11
      Unknown1: 0
      Unknown2: 0
      OutputRegisterCount: 1
      Unknown3: 0
      Unknown4: 0
      Unknown5: 11
      Unknown6: 1
      Mappings: 1
        0 - ConstOutput: 0 ConstInput 0
    */
    float4 expr11;
    {
        float4 temp0;
                temp0.x = MapCellSize.x * (66);
            expr11.x = 1.0f / (temp0.x);
    }

    float4 out_color;
    float4 temp0, temp1, temp2, temp3, temp4, temp5, temp6;
    float3 temp7;
    temp0 = tex2D(BaseSamplerClampedSampler, i.texcoord.xy);
    temp1.xy = Cloud.WorldPositionMultiplier_XYZZ.zw * i.texcoord3.zz;
    temp1.xy = i.texcoord3.xy * Cloud.WorldPositionMultiplier_XYZZ.xy + -temp1.xy;
    temp1.xy = temp1.xy + Cloud.CurrentOffsetUV.xy;
    temp2.xy = float2(1, -1);
    temp1.zw = temp2.xy * expr11.xx;
    temp1.zw = temp1.zw * i.texcoord3.xy;
    temp2.x = log2(temp0.x);
    temp2.y = log2(temp0.y);
    temp2.z = log2(temp0.z);
    temp0.xyz = temp2.xyz * float3(2,2,2); //GAMMA
    temp2.x = exp2(temp0.x);
    temp2.y = exp2(temp0.y);
    temp2.z = exp2(temp0.z);
    out_color.w = temp0.w * i.color.w;
    temp0 = tex2D(NormalSamplerClampedSampler, i.texcoord.xy);
    temp0.xyz = temp0.xyz * float3(2, 2, 2) + float3(-1, -1, -1);
    temp0.xyz = temp0.xyz * float3(0.75, 0.75, 1);
    temp3.xyz = normalize(temp0.xyz).xyz;
    temp0.xyz = i.color.xyz;
    temp4.x = float1(0);
    for (int it0 = 0; it0 < NumPointLights; ++it0) {
            temp5 = temp4.x + float4(-2, -3, -4, -5);
            temp4.xyz = temp4.xxx + float3(1, -0, -1);
            temp6.z = float1(0);
            temp6.xyw = (-abs(temp4).yyy >= 0) ? PointLight[0].Color.xyz : temp6.zzz;
            temp7.xyz = (-abs(temp4).yyy >= 0) ? PointLight[0].Position.xyz : temp6.zzz;
            temp4.yw = (-abs(temp4).yy >= 0) ? PointLight[0].Range_Inner_Outer.xy : temp6.zz;
            temp6.xyz = (-abs(temp4).zzz >= 0) ? PointLight[1].Color.xyz : temp6.xyw;
            temp7.xyz = (-abs(temp4).zzz >= 0) ? PointLight[1].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp4).zz >= 0) ? PointLight[1].Range_Inner_Outer.xy : temp4.yw;
            temp6.xyz = (-abs(temp5).xxx >= 0) ? PointLight[2].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).xxx >= 0) ? PointLight[2].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp5).xx >= 0) ? PointLight[2].Range_Inner_Outer.xy : temp4.yz;
            temp6.xyz = (-abs(temp5).yyy >= 0) ? PointLight[3].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).yyy >= 0) ? PointLight[3].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp5).yy >= 0) ? PointLight[3].Range_Inner_Outer.xy : temp4.yz;
            temp6.xyz = (-abs(temp5).zzz >= 0) ? PointLight[4].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).zzz >= 0) ? PointLight[4].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp5).zz >= 0) ? PointLight[4].Range_Inner_Outer.xy : temp4.yz;
            temp5.xyz = (-abs(temp5).www >= 0) ? PointLight[5].Color.xyz : temp6.xyz;
            temp6.xyz = (-abs(temp5).www >= 0) ? PointLight[5].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp5).ww >= 0) ? PointLight[5].Range_Inner_Outer.xy : temp4.yz;
            temp6.xyz = temp6.xyz + -i.texcoord3.xyz;
            temp0.w = dot(temp6.xyz, temp6.xyz);
            temp0.w = 1 / sqrt(temp0.w);
            temp2.w = 1.0f / temp0.w;
            temp6.xyz = temp6.xyz * temp0.www;
            temp0.w = -temp4.y + temp2.w;
            temp2.w = -temp4.y + temp4.z;
            temp2.w = 1.0f / temp2.w;
            temp0.w = saturate(temp0.w * -temp2.w + float1(1));
            temp0.w = temp0.w * temp0.w;
            temp4.yzw = temp5.xyz * temp0.www;
            temp0.w = dot(temp3.xyz, temp6.xyz);
            temp2.w = max(temp0.w, float1(0));
            temp0.xyz = temp4.yzw * temp2.www + temp0.xyz;
        }
    temp0.xyz = temp2.xyz * temp0.xyz;
    temp0.xyz = temp0.xyz + temp0.xyz;
    temp0.w = dot(temp3.xyz, i.texcoord4.xyz);
    temp2.w = (-temp0.w >= 0) ? float1(0) : float1(1);
    temp0.w = temp0.w * temp2.w;
    temp3 = tex2D(CloudSamplerSampler, temp1.xy);
    temp4.x = log2(temp3.x);
    temp4.y = log2(temp3.y);
    temp4.z = log2(temp3.z);
    temp3.xyz = temp4.xyz * float3(2,2,2); //GAMMA
    temp4.x = exp2(temp3.x);
    temp4.y = exp2(temp3.y);
    temp4.z = exp2(temp3.z);
    temp3.xyz = temp4.xyz * DirectionalLight[0].Color.xyz;
    temp2.xyz = temp2.xyz * temp0.www;
    temp0.xyz = temp3.xyz * temp2.xyz + temp0.xyz;
    temp1 = tex2D(MacroSamplerSampler, temp1.zw);
    temp2.x = log2(temp1.x);
    temp2.y = log2(temp1.y);
    temp2.z = log2(temp1.z);
    temp1.xyz = temp2.xyz * float3(2,2,2); //GAMMA
    temp2.x = exp2(temp1.x);
    temp2.y = exp2(temp1.y);
    temp2.z = exp2(temp1.z);
    temp0.xyz = temp0.xyz * temp2.xyz + float3(-1, -1, -1);
    temp0.xyz = i.color1.xxx * temp0.xyz + float3(1, 1, 1);
    temp1 = tex2D(ShroudSamplerSampler, i.texcoord2.xy);
    out_color.xyz = temp0.xyz * temp1.xxx;

    return out_color;
}


struct PS_Scorch_Array_Shader_1_Input
{
    float4 color : COLOR;
    float color1 : COLOR1;
    float2 texcoord : TEXCOORD;
    float2 texcoord2 : TEXCOORD2;
    float3 texcoord3 : TEXCOORD3;
    float3 texcoord4 : TEXCOORD4;
    float3 texcoord6 : TEXCOORD6;
};

float4 PS_Scorch_Array_Shader_1(PS_Scorch_Array_Shader_1_Input i) : COLOR
{
    /*
    PRSI
      OutputRegisterOffset: 12
      Unknown1: 0
      Unknown2: 0
      OutputRegisterCount: 1
      Unknown3: 0
      Unknown4: 0
      Unknown5: 12
      Unknown6: 1
      Mappings: 1
        0 - ConstOutput: 0 ConstInput 0
    */
    float4 expr12;
    {
        float4 temp0;
                temp0.x = MapCellSize.x * (66);
            expr12.x = 1.0f / (temp0.x);
    }

    float4 out_color;
    float4 temp0, temp1, temp2, temp3, temp4, temp5, temp6;
    float3 temp7;
    temp0 = tex2D(BaseSamplerClampedSampler, i.texcoord.xy);
    temp1.xy = Cloud.WorldPositionMultiplier_XYZZ.zw * i.texcoord3.zz;
    temp1.xy = i.texcoord3.xy * Cloud.WorldPositionMultiplier_XYZZ.xy + -temp1.xy;
    temp1.xy = temp1.xy + Cloud.CurrentOffsetUV.xy;
    temp2.xy = float2(1, -1);
    temp1.zw = temp2.xy * expr12.xx;
    temp1.zw = temp1.zw * i.texcoord3.xy;
    temp2.x = log2(temp0.x);
    temp2.y = log2(temp0.y);
    temp2.z = log2(temp0.z);
    temp0.xyz = temp2.xyz * float3(2,2,2); //GAMMA
    temp2.x = exp2(temp0.x);
    temp2.y = exp2(temp0.y);
    temp2.z = exp2(temp0.z);
    out_color.w = temp0.w * i.color.w;
    temp0 = tex2D(NormalSamplerClampedSampler, i.texcoord.xy);
    temp0.xyz = temp0.xyz * float3(2, 2, 2) + float3(-1, -1, -1);
    temp0.xyz = temp0.xyz * float3(0.75, 0.75, 1);
    temp3.xyz = normalize(temp0.xyz).xyz;
    temp0.xyz = i.color.xyz;
    temp4.x = float1(0);
    for (int it0 = 0; it0 < NumPointLights; ++it0) {
            temp5 = temp4.x + float4(-2, -3, -4, -5);
            temp4.xyz = temp4.xxx + float3(1, -0, -1);
            temp6.z = float1(0);
            temp6.xyw = (-abs(temp4).yyy >= 0) ? PointLight[0].Color.xyz : temp6.zzz;
            temp7.xyz = (-abs(temp4).yyy >= 0) ? PointLight[0].Position.xyz : temp6.zzz;
            temp4.yw = (-abs(temp4).yy >= 0) ? PointLight[0].Range_Inner_Outer.xy : temp6.zz;
            temp6.xyz = (-abs(temp4).zzz >= 0) ? PointLight[1].Color.xyz : temp6.xyw;
            temp7.xyz = (-abs(temp4).zzz >= 0) ? PointLight[1].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp4).zz >= 0) ? PointLight[1].Range_Inner_Outer.xy : temp4.yw;
            temp6.xyz = (-abs(temp5).xxx >= 0) ? PointLight[2].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).xxx >= 0) ? PointLight[2].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp5).xx >= 0) ? PointLight[2].Range_Inner_Outer.xy : temp4.yz;
            temp6.xyz = (-abs(temp5).yyy >= 0) ? PointLight[3].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).yyy >= 0) ? PointLight[3].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp5).yy >= 0) ? PointLight[3].Range_Inner_Outer.xy : temp4.yz;
            temp6.xyz = (-abs(temp5).zzz >= 0) ? PointLight[4].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).zzz >= 0) ? PointLight[4].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp5).zz >= 0) ? PointLight[4].Range_Inner_Outer.xy : temp4.yz;
            temp5.xyz = (-abs(temp5).www >= 0) ? PointLight[5].Color.xyz : temp6.xyz;
            temp6.xyz = (-abs(temp5).www >= 0) ? PointLight[5].Position.xyz : temp7.xyz;
            temp4.yz = (-abs(temp5).ww >= 0) ? PointLight[5].Range_Inner_Outer.xy : temp4.yz;
            temp6.xyz = temp6.xyz + -i.texcoord3.xyz;
            temp0.w = dot(temp6.xyz, temp6.xyz);
            temp0.w = 1 / sqrt(temp0.w);
            temp2.w = 1.0f / temp0.w;
            temp6.xyz = temp6.xyz * temp0.www;
            temp0.w = -temp4.y + temp2.w;
            temp2.w = -temp4.y + temp4.z;
            temp2.w = 1.0f / temp2.w;
            temp0.w = saturate(temp0.w * -temp2.w + float1(1));
            temp0.w = temp0.w * temp0.w;
            temp4.yzw = temp5.xyz * temp0.www;
            temp0.w = dot(temp3.xyz, temp6.xyz);
            temp2.w = max(temp0.w, float1(0));
            temp0.xyz = temp4.yzw * temp2.www + temp0.xyz;
        }
    temp0.xyz = temp2.xyz * temp0.xyz;
    temp0.xyz = temp0.xyz + temp0.xyz;
    temp0.w = dot(temp3.xyz, i.texcoord4.xyz);
    temp2.w = (-temp0.w >= 0) ? float1(0) : float1(1);
    temp0.w = temp0.w * temp2.w;

    /*
    temp3 = tex2D(ShadowMapSampler, i.texcoord6.xy);
    temp4.xy = Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.zx + i.texcoord6.xy;
    temp4 = tex2D(ShadowMapSampler, temp4.xy);
    temp4.yz = Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.yz + i.texcoord6.xy;
    temp5 = tex2D(ShadowMapSampler, temp4.yz);
    temp4.yz = Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.wz + i.texcoord6.xy;
    temp6 = tex2D(ShadowMapSampler, temp4.yz);
    temp3.y = temp4.x;
    temp3.z = temp5.x;
    temp3.w = temp6.x;
    temp3 = temp3 + -i.texcoord6.z;
    temp3 = (temp3 >= 0) ? float4(1, 1, 1, 1) : float4(0, 0, 0, 0);
    temp2.w = dot(float4(1, 1, 1, 1), temp3);
    temp0.w = temp0.w * temp2.w;
    temp0.w = temp0.w * float1(0.25);
    */
    temp2.x = helper_shadowpcf(
        2,//ShadowPCFlevel,
        ShadowMapSampler,
        Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w, 
        i.texcoord6.xyz) ;

    temp3 = tex2D(CloudSamplerSampler, temp1.xy);
    temp4.x = log2(temp3.x);
    temp4.y = log2(temp3.y);
    temp4.z = log2(temp3.z);
    temp3.xyz = temp4.xyz * float3(2,2,2); //GAMMA
    temp4.x = exp2(temp3.x);
    temp4.y = exp2(temp3.y);
    temp4.z = exp2(temp3.z);
    temp3.xyz = temp4.xyz * DirectionalLight[0].Color.xyz;
    temp2.xyz = temp2.xyz * temp0.www;
    temp0.xyz = temp3.xyz * temp2.xyz + temp0.xyz;
    temp1 = tex2D(MacroSamplerSampler, temp1.zw);
    temp2.x = log2(temp1.x);
    temp2.y = log2(temp1.y);
    temp2.z = log2(temp1.z);
    temp1.xyz = temp2.xyz * float3(2,2,2); //GAMMA
    temp2.x = exp2(temp1.x);
    temp2.y = exp2(temp1.y);
    temp2.z = exp2(temp1.z);
    temp0.xyz = temp0.xyz * temp2.xyz + float3(-1, -1, -1);
    temp0.xyz = i.color1.xxx * temp0.xyz + float3(1, 1, 1);
    temp1 = tex2D(ShroudSamplerSampler, i.texcoord2.xy);
    out_color.xyz = temp0.xyz * temp1.xxx;

    return out_color;
}

PixelShader PS_Scorch_Array[2] = {
    compile ps_3_0 PS_Scorch_Array_Shader_0(), 
    compile ps_3_0 PS_Scorch_Array_Shader_1(), 
};

//END HIGH SHADERS, START M SHADERS

struct VS_TerrainTile_M_Array_Shader_0_Input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 texcoord : TEXCOORD;
};

struct VS_TerrainTile_M_Array_Shader_0_Output
{
    float4 position : POSITION;
    float4 color1 : COLOR1;
    float4 color : COLOR;
    float2 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
    float4 texcoord5 : TEXCOORD5;
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
};

VS_TerrainTile_M_Array_Shader_0_Output VS_TerrainTile_M_Array_Shader_0(VS_TerrainTile_M_Array_Shader_0_Input i)
{
    /*
    PRSI
      OutputRegisterOffset: 12
      Unknown1: 0
      Unknown2: 0
      OutputRegisterCount: 1
      Unknown3: 0
      Unknown4: 0
      Unknown5: 12
      Unknown6: 1
      Mappings: 1
        0 - ConstOutput: 0 ConstInput 0
    */
    float4 expr12;
    {
        float4 temp0;
                temp0.x = MapCellSize.x * (66);
            expr12.x = 1.0f / (temp0.x);
    }

    VS_TerrainTile_M_Array_Shader_0_Output o;
    float4 temp0, temp1;
    temp0 = i.position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
    o.position.x = dot(temp0, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp0, (ViewProjection._m01_m11_m21_m31));
    o.position.z = dot(temp0, (ViewProjection._m02_m12_m22_m32));
    o.position.w = dot(temp0, (ViewProjection._m03_m13_m23_m33));
    temp1.x = dot(i.normal.xyz, DirectionalLight[0].Direction.xyz);
    temp1.x = max(temp1.x, float1(0));
    temp1.xyz = temp1.xxx * DirectionalLight[0].Color.xyz;
    o.color1.xyz = temp1.xyz * float3(0.5, 0.5, 0.5);
    temp1.x = dot(i.normal.xyz, DirectionalLight[2].Direction.xyz);
    temp1.x = max(temp1.x, float1(0));
    temp1.xyz = temp1.xxx * DirectionalLight[2].Color.xyz;
    temp1.w = dot(i.normal.xyz, DirectionalLight[1].Direction.xyz);
    temp1.w = max(temp1.w, float1(0));
    temp1.xyz = DirectionalLight[1].Color.xyz * temp1.www + temp1.xyz;
    temp1.xyz = temp1.xyz + AmbientLightColor.xyz;
    o.color.xyz = temp1.xyz * float3(0.5, 0.5, 0.5);
    temp1.xy = i.position.xy + Shroud.ScaleUV_OffsetUV.zw;
    o.texcoord2 = temp1 * Shroud.ScaleUV_OffsetUV;
    temp1.xy = i.position.zz * Cloud.WorldPositionMultiplier_XYZZ.zw;
    temp1.xy = i.position.xy * Cloud.WorldPositionMultiplier_XYZZ.xy + -temp1.xy;
    o.texcoord3.xy = temp1.xy + Cloud.CurrentOffsetUV.xy;
    temp1.xw = float2(1, -1);
    temp1.xy = temp1.wx * expr12.xx;
    o.texcoord3.zw = temp1.xy * i.position.yx;
    o.texcoord5.x = dot(temp0, (ShadowMapWorldToShadow._m00_m10_m20_m30));
    o.texcoord5.y = dot(temp0, (ShadowMapWorldToShadow._m01_m11_m21_m31));
    o.texcoord5.z = dot(temp0, (ShadowMapWorldToShadow._m02_m12_m22_m32));
    o.texcoord5.w = dot(temp0, (ShadowMapWorldToShadow._m03_m13_m23_m33));
    o.color.w = float1(1);
    o.color1.w = float1(1);
    o.texcoord.xy = i.texcoord.xy;
    o.texcoord.zw = float2(0, 0);
    o.texcoord1 = float4(0, 0, 0, 0);

    return o;
}


struct VS_TerrainTile_M_Array_Shader_1_Input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
    float4 texcoord2 : TEXCOORD2;
};

struct VS_TerrainTile_M_Array_Shader_1_Output
{
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
    float4 position : POSITION;
    float4 color1 : COLOR1;
    float4 color : COLOR;
    float2 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
    float4 texcoord5 : TEXCOORD5;
};

VS_TerrainTile_M_Array_Shader_1_Output VS_TerrainTile_M_Array_Shader_1(VS_TerrainTile_M_Array_Shader_1_Input i)
{
    /*
    PRSI
      OutputRegisterOffset: 12
      Unknown1: 0
      Unknown2: 0
      OutputRegisterCount: 1
      Unknown3: 0
      Unknown4: 0
      Unknown5: 12
      Unknown6: 1
      Mappings: 1
        0 - ConstOutput: 0 ConstInput 0
    */
    float4 expr12;
    {
        float4 temp0;
                temp0.x = MapCellSize.x * (66);
            expr12.x = 1.0f / (temp0.x);
    }

    VS_TerrainTile_M_Array_Shader_1_Output o;
    float4 temp0, temp1;
    float3 temp2;
    o.texcoord.xy = i.texcoord.xy * float2(3.3333334E-05, 3.3333334E-05);
    o.texcoord1.xy = i.texcoord1.xy * float2(3.3333334E-05, 3.3333334E-05);
    o.texcoord1.zw = i.texcoord2.yx * float2(3.3333334E-05, 3.3333334E-05);
    o.texcoord.w = i.position.w + float1(-1);
    o.texcoord.z = i.normal.w + float1(-1);
    temp0 = i.position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
    o.position.x = dot(temp0, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp0, (ViewProjection._m01_m11_m21_m31));
    o.position.z = dot(temp0, (ViewProjection._m02_m12_m22_m32));
    o.position.w = dot(temp0, (ViewProjection._m03_m13_m23_m33));
    temp1.xyz = i.normal.xyz * float3(0.01, 0.01, 0.01) + float3(-1, -1, -1);
    temp1.w = dot(temp1.xyz, DirectionalLight[0].Direction.xyz);
    temp1.w = max(temp1.w, float1(0));
    temp2.xyz = temp1.www * DirectionalLight[0].Color.xyz;
    o.color1.xyz = temp2.xyz * float3(0.5, 0.5, 0.5);
    temp1.w = dot(temp1.xyz, DirectionalLight[2].Direction.xyz);
    temp1.x = dot(temp1.xyz, DirectionalLight[1].Direction.xyz);
    temp1.y = max(temp1.w, float1(0));
    temp1.yzw = temp1.yyy * DirectionalLight[2].Color.xyz;
    temp1.x = max(temp1.x, float1(0));
    temp1.xyz = DirectionalLight[1].Color.xyz * temp1.xxx + temp1.yzw;
    temp1.xyz = temp1.xyz + AmbientLightColor.xyz;
    o.color.xyz = temp1.xyz * float3(0.5, 0.5, 0.5);
    temp1.xy = i.position.xy + Shroud.ScaleUV_OffsetUV.zw;
    o.texcoord2 = temp1 * Shroud.ScaleUV_OffsetUV;
    temp1.xy = i.position.zz * Cloud.WorldPositionMultiplier_XYZZ.zw;
    temp1.xy = i.position.xy * Cloud.WorldPositionMultiplier_XYZZ.xy + -temp1.xy;
    o.texcoord3.xy = temp1.xy + Cloud.CurrentOffsetUV.xy;
    temp1.yz = float2(-1, 1);
    temp1.xy = temp1.yz * expr12.xx;
    o.texcoord3.zw = temp1.xy * i.position.yx;
    o.color.w = float1(1);
    o.color1.w = float1(1);
    temp1.x = dot(temp0, (ShadowMapWorldToShadow._m00_m10_m20_m30));
    temp1.y = dot(temp0, (ShadowMapWorldToShadow._m01_m11_m21_m31));
    temp1.z = dot(temp0, (ShadowMapWorldToShadow._m02_m12_m22_m32));
    temp0.x = dot(temp0, (ShadowMapWorldToShadow._m03_m13_m23_m33));
    temp0.y = 1.0f / temp0.x;
    o.texcoord5.w = temp0.x;
    o.texcoord5.xyz = temp1.xyz * temp0.yyy + float3(0, 0, -0.0015);

    return o;
}

VertexShader VS_TerrainTile_M_Array[2] = {
    compile vs_2_0 VS_TerrainTile_M_Array_Shader_0(), 
    compile vs_2_0 VS_TerrainTile_M_Array_Shader_1(), 
};

struct PS_TerrainTile_M_Array_Shader_0_Input
{
    float4 color : COLOR;
    float4 color1 : COLOR1;
    float2 texcoord : TEXCOORD;
    float2 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
};

float4 PS_TerrainTile_M_Array_Shader_0(PS_TerrainTile_M_Array_Shader_0_Input i) : COLOR
{
    float4 out_color;
    float4 temp0, temp1, temp2;
    temp0 = tex2D(CloudSamplerSampler, i.texcoord3.xy);
    temp1 = tex2D(BaseSamplerClampedSampler, i.texcoord.xy);
    temp2.x = log2(temp0.x);
    temp2.y = log2(temp0.y);
    temp2.z = log2(temp0.z);
    temp0.xyz = temp2.xyz * float3(2,2,2); //GAMMA
    temp2.x = exp2(temp0.x);
    temp2.y = exp2(temp0.y);
    temp2.z = exp2(temp0.z);
    temp0.xyz = i.color1.xyz;
    temp0.xyz = temp0.xyz * temp2.xyz + i.color.xyz;
    temp0.xyz = temp1.xyz * temp0.xyz;
    temp0.xyz = temp0.xyz + temp0.xyz;
    temp1.xy = i.texcoord3.wz;
    temp1 = tex2D(MacroSamplerSampler, temp1.xy);
    temp2 = tex2D(ShroudSamplerSampler, i.texcoord2.xy);
    temp0.xyz = temp0.xyz * temp1.xyz + float3(-1, -1, -1);
    temp0.xyz = i.color1.www * temp0.xyz + float3(1, 1, 1);
    temp0.xyz = temp2.xxx * temp0.xyz;
    temp0.w = i.color.w;
    out_color = temp0;

    return out_color;
}


struct PS_TerrainTile_M_Array_Shader_1_Input
{
    float4 color : COLOR;
    float4 color1 : COLOR1;
    float2 texcoord : TEXCOORD;
    float2 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
    float4 texcoord5 : TEXCOORD5;
};

float4 PS_TerrainTile_M_Array_Shader_1(PS_TerrainTile_M_Array_Shader_1_Input i) : COLOR
{
    float4 out_color;
    float4 temp0, temp1, temp2, temp3, temp4, temp5, temp6, temp7, temp8;
    temp0.w = 1.0f / i.texcoord5.w;
    temp0.xy = temp0.ww * i.texcoord5.xy;
    temp1.xy = i.texcoord5.xy * temp0.ww + Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.zx;
    temp2.xy = i.texcoord5.xy * temp0.ww + Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.yz;
    temp3.xy = i.texcoord5.xy * temp0.ww + Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.wz;
    temp4.xy = i.texcoord3.wz;
    temp5 = tex2D(ShadowMapSampler, temp0.xy);
    temp1 = tex2D(ShadowMapSampler, temp1.xy);
    temp2 = tex2D(ShadowMapSampler, temp2.xy);
    temp3 = tex2D(ShadowMapSampler, temp3.xy);
    temp6 = tex2D(CloudSamplerSampler, i.texcoord3.xy);
    temp7 = tex2D(BaseSamplerClampedSampler, i.texcoord.xy);
    temp4 = tex2D(MacroSamplerSampler, temp4.xy);
    temp8 = tex2D(ShroudSamplerSampler, i.texcoord2.xy);
    temp5.y = temp1.x;
    temp5.z = temp2.x;
    temp4.w = i.texcoord5.z * temp0.w + float1(-0.0015);
    temp5.w = temp3.x;
    temp0 = temp5 + -temp4.w;
    temp0 = (temp0 >= 0) ? float4(1, 1, 1, 1) : float4(0, 0, 0, 0);
    temp4.w = dot(float4(1, 1, 1, 1), temp0);
    temp4.w = temp4.w * float1(0.25);
    temp0.x = log2(temp6.x);
    temp0.y = log2(temp6.y);
    temp0.z = log2(temp6.z);
    temp0.xyz = temp0.xyz * float3(2,2,2); //GAMMA
    temp1.x = exp2(temp0.x);
    temp1.y = exp2(temp0.y);
    temp1.z = exp2(temp0.z);
    temp0.xyz = temp1.xyz * i.color1.xyz;
    temp0.xyz = temp0.xyz * temp4.www + i.color.xyz;
    temp0.xyz = temp7.xyz * temp0.xyz;
    temp0.xyz = temp0.xyz + temp0.xyz;
    temp0.xyz = temp0.xyz * temp4.xyz + float3(-1, -1, -1);
    temp0.xyz = i.color1.www * temp0.xyz + float3(1, 1, 1);
    temp0.xyz = temp8.xxx * temp0.xyz;
    temp0.w = i.color.w;
    out_color = temp0;

    return out_color;
}


struct PS_TerrainTile_M_Array_Shader_2_Input
{
    float4 color : COLOR;
    float4 color1 : COLOR1;
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
    float2 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
};

float4 PS_TerrainTile_M_Array_Shader_2(PS_TerrainTile_M_Array_Shader_2_Input i) : COLOR
{
    float4 out_color;
    float4 temp0, temp1, temp2, temp3, temp4, temp5;
    float3 temp6;
    temp0 = tex2D(CloudSamplerSampler, i.texcoord3.xy);
    temp1.x = log2(temp0.x);
    temp1.y = log2(temp0.y);
    temp1.z = log2(temp0.z);
    temp0.xyz = temp1.xyz * float3(2,2,2); //GAMMA
    temp1.x = exp2(temp0.x);
    temp1.y = exp2(temp0.y);
    temp1.z = exp2(temp0.z);
    temp0.xyz = i.color1.xyz;
    temp0.xyz = temp0.xyz * temp1.xyz + i.color.xyz;
    temp1.xy = i.texcoord1.wz;
    temp2.xy = i.texcoord3.wz;
    temp1 = tex2D(BaseSamplerClampedSampler, temp1.xy);
    temp3 = tex2D(BaseSamplerClampedSampler, i.texcoord.xy);
    temp4 = tex2D(BaseSamplerClampedSampler, i.texcoord1.xy);
    temp2 = tex2D(MacroSamplerSampler, temp2.xy);
    temp5 = tex2D(ShroudSamplerSampler, i.texcoord2.xy);
    temp5.zw = saturate(i.texcoord.zw);
    temp6.xyz = lerp(temp3.xyz, temp4.xyz, temp5.www);
    temp3.xyz = lerp(temp6.xyz, temp1.xyz, temp5.zzz);
    temp0.xyz = temp0.xyz * temp3.xyz;
    temp0.xyz = temp0.xyz + temp0.xyz;
    temp0.xyz = temp0.xyz * temp2.xyz + float3(-1, -1, -1);
    temp0.xyz = i.color1.www * temp0.xyz + float3(1, 1, 1);
    temp0.xyz = temp5.xxx * temp0.xyz;
    temp0.w = i.color.w;
    out_color = temp0;

    return out_color;
}


struct PS_TerrainTile_M_Array_Shader_3_Input
{
    float4 color : COLOR;
    float4 color1 : COLOR1;
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
    float2 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
    float3 texcoord5 : TEXCOORD5;
};

float4 PS_TerrainTile_M_Array_Shader_3(PS_TerrainTile_M_Array_Shader_3_Input i) : COLOR
{
    float4 out_color;
    float4 temp0, temp1, temp2, temp3, temp4, temp5, temp6, temp7, temp8, temp9;
    temp0.xy = i.texcoord5.xy + Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.zx;
    temp1.xy = i.texcoord5.xy + Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.yz;
    temp2.xy = i.texcoord5.xy + Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.wz;
    temp3.xy = i.texcoord1.wz;
    temp4.xy = i.texcoord3.wz;
    temp0 = tex2D(ShadowMapSampler, temp0.xy);
    temp1 = tex2D(ShadowMapSampler, temp1.xy);
    temp2 = tex2D(ShadowMapSampler, temp2.xy);
    temp5 = tex2D(ShadowMapSampler, i.texcoord5.xy);
    temp6 = tex2D(CloudSamplerSampler, i.texcoord3.xy);
    temp3 = tex2D(BaseSamplerClampedSampler, temp3.xy);
    temp7 = tex2D(BaseSamplerClampedSampler, i.texcoord.xy);
    temp8 = tex2D(BaseSamplerClampedSampler, i.texcoord1.xy);
    temp4 = tex2D(MacroSamplerSampler, temp4.xy);
    temp9 = tex2D(ShroudSamplerSampler, i.texcoord2.xy);
    temp5.y = temp0.x;
    temp5.z = temp1.x;
    temp5.w = temp2.x;
    temp0 = temp5 + -i.texcoord5.z;
    temp0 = (temp0 >= 0) ? float4(1, 1, 1, 1) : float4(0, 0, 0, 0);
    temp3.w = dot(float4(1, 1, 1, 1), temp0);
    temp3.w = temp3.w * float1(0.25);
    temp0.x = log2(temp6.x);
    temp0.y = log2(temp6.y);
    temp0.z = log2(temp6.z);
    temp0.xyz = temp0.xyz * float3(2,2,2); //GAMMA
    temp1.x = exp2(temp0.x);
    temp1.y = exp2(temp0.y);
    temp1.z = exp2(temp0.z);
    temp0.xyz = temp1.xyz * i.color1.xyz;
    temp0.xyz = temp0.xyz * temp3.www + i.color.xyz;
    temp1.xy = saturate(i.texcoord.wz);
    temp2.xyz = lerp(temp7.xyz, temp8.xyz, temp1.xxx);
    temp5.xyz = lerp(temp2.xyz, temp3.xyz, temp1.yyy);
    temp0.xyz = temp0.xyz * temp5.xyz;
    temp0.xyz = temp0.xyz + temp0.xyz;
    temp0.xyz = temp0.xyz * temp4.xyz + float3(-1, -1, -1);
    temp0.xyz = i.color1.www * temp0.xyz + float3(1, 1, 1);
    temp0.xyz = temp9.xxx * temp0.xyz;
    temp0.w = i.color.w;
    out_color = temp0;

    return out_color;
}

PixelShader PS_TerrainTile_M_Array[4] = {
    compile ps_2_0 PS_TerrainTile_M_Array_Shader_0(), 
    compile ps_2_0 PS_TerrainTile_M_Array_Shader_1(), 
    compile ps_2_0 PS_TerrainTile_M_Array_Shader_2(), 
    compile ps_2_0 PS_TerrainTile_M_Array_Shader_3(), 
};

struct PS_Cliff_M_Array_Shader_0_Input
{
    float4 color : COLOR;
    float4 color1 : COLOR1;
    float2 texcoord : TEXCOORD;
    float2 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
};

float4 PS_Cliff_M_Array_Shader_0(PS_Cliff_M_Array_Shader_0_Input i) : COLOR
{
    float4 out_color;
    float4 temp0, temp1, temp2;
    temp0 = tex2D(CloudSamplerSampler, i.texcoord3.xy);
    temp1 = tex2D(BaseSamplerWrappedSampler, i.texcoord.xy);
    temp2.x = log2(temp0.x);
    temp2.y = log2(temp0.y);
    temp2.z = log2(temp0.z);
    temp0.xyz = temp2.xyz * float3(2,2,2); //GAMMA
    temp2.x = exp2(temp0.x);
    temp2.y = exp2(temp0.y);
    temp2.z = exp2(temp0.z);
    temp0.xyz = i.color1.xyz;
    temp0.xyz = temp0.xyz * temp2.xyz + i.color.xyz;
    temp0.xyz = temp1.xyz * temp0.xyz;
    temp0.xyz = temp0.xyz + temp0.xyz;
    temp1.xy = i.texcoord3.wz;
    temp1 = tex2D(MacroSamplerSampler, temp1.xy);
    temp2 = tex2D(ShroudSamplerSampler, i.texcoord2.xy);
    temp0.xyz = temp0.xyz * temp1.xyz + float3(-1, -1, -1);
    temp0.xyz = i.color1.www * temp0.xyz + float3(1, 1, 1);
    temp0.xyz = temp2.xxx * temp0.xyz;
    temp0.w = i.color.w;
    out_color = temp0;

    return out_color;
}


struct PS_Cliff_M_Array_Shader_1_Input
{
    float4 color : COLOR;
    float4 color1 : COLOR1;
    float2 texcoord : TEXCOORD;
    float2 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
    float3 texcoord5 : TEXCOORD5;
};

float4 PS_Cliff_M_Array_Shader_1(PS_Cliff_M_Array_Shader_1_Input i) : COLOR
{
    float4 out_color;
    float4 temp0, temp1, temp2, temp3, temp4, temp5, temp6, temp7;
    temp0.xy = i.texcoord5.xy + Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.zx;
    temp1.xy = i.texcoord5.xy + Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.yz;
    temp2.xy = i.texcoord5.xy + Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.wz;
    temp3.xy = i.texcoord3.wz;
    temp0 = tex2D(ShadowMapSampler, temp0.xy);
    temp1 = tex2D(ShadowMapSampler, temp1.xy);
    temp2 = tex2D(ShadowMapSampler, temp2.xy);
    temp4 = tex2D(ShadowMapSampler, i.texcoord5.xy);
    temp5 = tex2D(CloudSamplerSampler, i.texcoord3.xy);
    temp6 = tex2D(BaseSamplerWrappedSampler, i.texcoord.xy);
    temp3 = tex2D(MacroSamplerSampler, temp3.xy);
    temp7 = tex2D(ShroudSamplerSampler, i.texcoord2.xy);
    temp4.y = temp0.x;
    temp4.z = temp1.x;
    temp4.w = temp2.x;
    temp0 = temp4 + -i.texcoord5.z;
    temp0 = (temp0 >= 0) ? float4(1, 1, 1, 1) : float4(0, 0, 0, 0);
    temp3.w = dot(float4(1, 1, 1, 1), temp0);
    temp3.w = temp3.w * float1(0.25);
    temp0.x = log2(temp5.x);
    temp0.y = log2(temp5.y);
    temp0.z = log2(temp5.z);
    temp0.xyz = temp0.xyz * float3(2,2,2); //GAMMA
    temp1.x = exp2(temp0.x);
    temp1.y = exp2(temp0.y);
    temp1.z = exp2(temp0.z);
    temp0.xyz = temp1.xyz * i.color1.xyz;
    temp0.xyz = temp0.xyz * temp3.www + i.color.xyz;
    temp0.xyz = temp6.xyz * temp0.xyz;
    temp0.xyz = temp0.xyz + temp0.xyz;
    temp0.xyz = temp0.xyz * temp3.xyz + float3(-1, -1, -1);
    temp0.xyz = i.color1.www * temp0.xyz + float3(1, 1, 1);
    temp0.xyz = temp7.xxx * temp0.xyz;
    temp0.w = i.color.w;
    out_color = temp0;

    return out_color;
}

PixelShader PS_Cliff_M_Array[2] = {
    compile ps_2_0 PS_Cliff_M_Array_Shader_0(), 
    compile ps_2_0 PS_Cliff_M_Array_Shader_1(), 
};

struct PS_Road_M_Array_Shader_0_Input
{
    float4 color : COLOR;
    float4 color1 : COLOR1;
    float2 texcoord : TEXCOORD;
    float2 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
};

float4 PS_Road_M_Array_Shader_0(PS_Road_M_Array_Shader_0_Input i) : COLOR
{
    float4 out_color;
    float4 temp0, temp1, temp2, temp3;
    temp0 = tex2D(CloudSamplerSampler, i.texcoord3.xy);
    temp1 = tex2D(BaseSamplerWrappedSampler, i.texcoord.xy);
    temp2.x = log2(temp0.x);
    temp2.y = log2(temp0.y);
    temp2.z = log2(temp0.z);
    temp0.xyz = temp2.xyz * float3(2,2,2); //GAMMA
    temp2.x = exp2(temp0.x);
    temp2.y = exp2(temp0.y);
    temp2.z = exp2(temp0.z);
    temp0.xyz = i.color1.xyz;
    temp0.xyz = temp0.xyz * temp2.xyz + i.color.xyz;
    temp0.xyz = temp1.xyz * temp0.xyz;
    temp1.w = temp1.w * i.color.w;
    temp0.xyz = temp0.xyz + temp0.xyz;
    temp2.xy = i.texcoord3.wz;
    temp2 = tex2D(MacroSamplerSampler, temp2.xy);
    temp3 = tex2D(ShroudSamplerSampler, i.texcoord2.xy);
    temp0.xyz = temp0.xyz * temp2.xyz + float3(-1, -1, -1);
    temp0.xyz = i.color1.www * temp0.xyz + float3(1, 1, 1);
    temp1.xyz = temp3.xxx * temp0.xyz;
    out_color = temp1;

    return out_color;
}


struct PS_Road_M_Array_Shader_1_Input
{
    float4 color : COLOR;
    float4 color1 : COLOR1;
    float2 texcoord : TEXCOORD;
    float2 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
    float4 texcoord5 : TEXCOORD5;
};

float4 PS_Road_M_Array_Shader_1(PS_Road_M_Array_Shader_1_Input i) : COLOR
{
    float4 out_color;
    float4 temp0, temp1, temp2, temp3, temp4, temp5, temp6, temp7, temp8;
    temp0.w = 1.0f / i.texcoord5.w;
    temp0.xy = temp0.ww * i.texcoord5.xy;
    temp1.xy = i.texcoord5.xy * temp0.ww + Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.zx;
    temp2.xy = i.texcoord5.xy * temp0.ww + Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.yz;
    temp3.xy = i.texcoord5.xy * temp0.ww + Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.wz;
    temp4.xy = i.texcoord3.wz;
    temp5 = tex2D(ShadowMapSampler, temp0.xy);
    temp1 = tex2D(ShadowMapSampler, temp1.xy);
    temp2 = tex2D(ShadowMapSampler, temp2.xy);
    temp3 = tex2D(ShadowMapSampler, temp3.xy);
    temp6 = tex2D(CloudSamplerSampler, i.texcoord3.xy);
    temp7 = tex2D(BaseSamplerWrappedSampler, i.texcoord.xy);
    temp4 = tex2D(MacroSamplerSampler, temp4.xy);
    temp8 = tex2D(ShroudSamplerSampler, i.texcoord2.xy);
    temp5.y = temp1.x;
    temp5.z = temp2.x;
    temp4.w = i.texcoord5.z * temp0.w + float1(-0.0015);
    temp5.w = temp3.x;
    temp0 = temp5 + -temp4.w;
    temp0 = (temp0 >= 0) ? float4(1, 1, 1, 1) : float4(0, 0, 0, 0);
    temp4.w = dot(float4(1, 1, 1, 1), temp0);
    temp4.w = temp4.w * float1(0.25);
    temp0.x = log2(temp6.x);
    temp0.y = log2(temp6.y);
    temp0.z = log2(temp6.z);
    temp0.xyz = temp0.xyz * float3(2,2,2); //GAMMA
    temp1.x = exp2(temp0.x);
    temp1.y = exp2(temp0.y);
    temp1.z = exp2(temp0.z);
    temp0.xyz = temp1.xyz * i.color1.xyz;
    temp0.xyz = temp0.xyz * temp4.www + i.color.xyz;
    temp0.xyz = temp7.xyz * temp0.xyz;
    temp1.w = temp7.w * i.color.w;
    temp0.xyz = temp0.xyz + temp0.xyz;
    temp0.xyz = temp0.xyz * temp4.xyz + float3(-1, -1, -1);
    temp0.xyz = i.color1.www * temp0.xyz + float3(1, 1, 1);
    temp1.xyz = temp8.xxx * temp0.xyz;
    out_color = temp1;

    return out_color;
}

PixelShader PS_Road_M_Array[2] = {
    compile ps_2_0 PS_Road_M_Array_Shader_0(), 
    compile ps_2_0 PS_Road_M_Array_Shader_1(), 
};

struct PS_Scorch_M_Array_Shader_0_Input
{
    float4 color : COLOR;
    float4 color1 : COLOR1;
    float2 texcoord : TEXCOORD;
    float2 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
};

float4 PS_Scorch_M_Array_Shader_0(PS_Scorch_M_Array_Shader_0_Input i) : COLOR
{
    float4 out_color;
    float4 temp0, temp1, temp2, temp3;
    temp0 = tex2D(CloudSamplerSampler, i.texcoord3.xy);
    temp1 = tex2D(BaseSamplerClampedSampler, i.texcoord.xy);
    temp2.x = log2(temp0.x);
    temp2.y = log2(temp0.y);
    temp2.z = log2(temp0.z);
    temp0.xyz = temp2.xyz * float3(2,2,2); //GAMMA
    temp2.x = exp2(temp0.x);
    temp2.y = exp2(temp0.y);
    temp2.z = exp2(temp0.z);
    temp0.xyz = i.color1.xyz;
    temp0.xyz = temp0.xyz * temp2.xyz + i.color.xyz;
    temp0.xyz = temp1.xyz * temp0.xyz;
    temp1.w = temp1.w * i.color.w;
    temp0.xyz = temp0.xyz + temp0.xyz;
    temp2.xy = i.texcoord3.wz;
    temp2 = tex2D(MacroSamplerSampler, temp2.xy);
    temp3 = tex2D(ShroudSamplerSampler, i.texcoord2.xy);
    temp0.xyz = temp0.xyz * temp2.xyz + float3(-1, -1, -1);
    temp0.xyz = i.color1.www * temp0.xyz + float3(1, 1, 1);
    temp1.xyz = temp3.xxx * temp0.xyz;
    out_color = temp1;

    return out_color;
}


struct PS_Scorch_M_Array_Shader_1_Input
{
    float4 color : COLOR;
    float4 color1 : COLOR1;
    float2 texcoord : TEXCOORD;
    float2 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
    float3 texcoord5 : TEXCOORD5;
};

float4 PS_Scorch_M_Array_Shader_1(PS_Scorch_M_Array_Shader_1_Input i) : COLOR
{
    float4 out_color;
    float4 temp0, temp1, temp2, temp3, temp4, temp5, temp6, temp7;
    temp0.xy = i.texcoord5.xy + Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.zx;
    temp1.xy = i.texcoord5.xy + Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.yz;
    temp2.xy = i.texcoord5.xy + Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.wz;
    temp3.xy = i.texcoord3.wz;
    temp0 = tex2D(ShadowMapSampler, temp0.xy);
    temp1 = tex2D(ShadowMapSampler, temp1.xy);
    temp2 = tex2D(ShadowMapSampler, temp2.xy);
    temp4 = tex2D(ShadowMapSampler, i.texcoord5.xy);
    temp5 = tex2D(CloudSamplerSampler, i.texcoord3.xy);
    temp6 = tex2D(BaseSamplerClampedSampler, i.texcoord.xy);
    temp3 = tex2D(MacroSamplerSampler, temp3.xy);
    temp7 = tex2D(ShroudSamplerSampler, i.texcoord2.xy);
    temp4.y = temp0.x;
    temp4.z = temp1.x;
    temp4.w = temp2.x;
    temp0 = temp4 + -i.texcoord5.z;
    temp0 = (temp0 >= 0) ? float4(1, 1, 1, 1) : float4(0, 0, 0, 0);
    temp3.w = dot(float4(1, 1, 1, 1), temp0);
    temp3.w = temp3.w * float1(0.25);
    temp0.x = log2(temp5.x);
    temp0.y = log2(temp5.y);
    temp0.z = log2(temp5.z);
    temp0.xyz = temp0.xyz * float3(2,2,2); //GAMMA
    temp1.x = exp2(temp0.x);
    temp1.y = exp2(temp0.y);
    temp1.z = exp2(temp0.z);
    temp0.xyz = temp1.xyz * i.color1.xyz;
    temp0.xyz = temp0.xyz * temp3.www + i.color.xyz;
    temp0.xyz = temp6.xyz * temp0.xyz;
    temp1.w = temp6.w * i.color.w;
    temp0.xyz = temp0.xyz + temp0.xyz;
    temp0.xyz = temp0.xyz * temp3.xyz + float3(-1, -1, -1);
    temp0.xyz = i.color1.www * temp0.xyz + float3(1, 1, 1);
    temp1.xyz = temp7.xxx * temp0.xyz;
    out_color = temp1;

    return out_color;
}

PixelShader PS_Scorch_M_Array[2] = {
    compile ps_2_0 PS_Scorch_M_Array_Shader_0(), 
    compile ps_2_0 PS_Scorch_M_Array_Shader_1(), 
};

float4 _CreateDepthMap_PixelShader25(float texcoord : TEXCOORD) : COLOR
{
    float4 out_color;
    float4 temp0;
    temp0 = texcoord.x;
    out_color = temp0;

    return out_color;
}


struct _CreateDepthMap_VertexShader26_Output
{
    float4 position : POSITION;
    float texcoord : TEXCOORD;
};

_CreateDepthMap_VertexShader26_Output _CreateDepthMap_VertexShader26(float4 position : POSITION)
{
    _CreateDepthMap_VertexShader26_Output o;
    float4 temp0;
    float2 temp1;
    temp0 = position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
    o.position.x = dot(temp0, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp0, (ViewProjection._m01_m11_m21_m31));
    temp1.y = dot(temp0, (ViewProjection._m03_m13_m23_m33));
    temp1.x = dot(temp0, (ViewProjection._m02_m12_m22_m32));
    temp0.x = 1.0f / temp1.y;
    o.position.zw = temp1.xy;
    o.texcoord = temp1.x * temp0.x;

    return o;
}


float4 _CreateShadowMap_PixelShader27(float texcoord : TEXCOORD) : COLOR
{
    float4 out_color;
    float4 temp0;
    temp0 = texcoord.x;
    out_color = temp0;

    return out_color;
}


struct _CreateShadowMap_VertexShader28_Output
{
    float4 position : POSITION;
    float texcoord : TEXCOORD;
};

_CreateShadowMap_VertexShader28_Output _CreateShadowMap_VertexShader28(float4 position : POSITION)
{
    _CreateShadowMap_VertexShader28_Output o;
    float4 temp0;
    float2 temp1;
    temp0 = position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
    o.position.x = dot(temp0, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp0, (ViewProjection._m01_m11_m21_m31));
    temp1.y = dot(temp0, (ViewProjection._m03_m13_m23_m33));
    temp1.x = dot(temp0, (ViewProjection._m02_m12_m22_m32));
    temp0.x = 1.0f / temp1.y;
    o.position.zw = temp1.xy;
    o.texcoord = temp1.x * temp0.x;

    return o;
}


struct Scorch_L_PixelShader29_Input
{
    float2 texcoord : TEXCOORD;
    float2 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
};

float4 Scorch_L_PixelShader29(Scorch_L_PixelShader29_Input i) : COLOR
{
    float4 out_color;
    float4 temp0, temp1;
    temp0 = tex2D(ShroudSamplerSampler, i.texcoord2.xy);
    temp1 = tex2D(BaseSamplerClamped_LSampler, i.texcoord.xy);
    temp1 = temp1 * i.texcoord3;
    temp1.xyz = temp0.xxx * temp1.xyz;
    out_color = temp1;

    return out_color;
}


struct Scorch_L_VertexShader30_Input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 color : COLOR;
    float4 texcoord : TEXCOORD;
};

struct Scorch_L_VertexShader30_Output
{
    float4 position : POSITION;
    float4 texcoord3 : TEXCOORD3;
    float2 texcoord2 : TEXCOORD2;
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
};

Scorch_L_VertexShader30_Output Scorch_L_VertexShader30(Scorch_L_VertexShader30_Input i)
{
    Scorch_L_VertexShader30_Output o;
    float4 temp0;
    float3 temp1;
    temp0 = i.position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
    o.position.x = dot(temp0, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp0, (ViewProjection._m01_m11_m21_m31));
    o.position.z = dot(temp0, (ViewProjection._m02_m12_m22_m32));
    o.position.w = dot(temp0, (ViewProjection._m03_m13_m23_m33));
    temp0.xyz = i.normal.xyz * float3(2.55, 2.55, 2.55) + float3(-1, -1, -1);
    temp0.w = dot(temp0.xyz, DirectionalLight[1].Direction.xyz);
    temp0.w = max(temp0.w, float1(0));
    temp1.xyz = temp0.www * DirectionalLight[1].Color.xyz;
    temp0.w = dot(temp0.xyz, DirectionalLight[0].Direction.xyz);
    temp0.x = dot(temp0.xyz, DirectionalLight[2].Direction.xyz);
    temp0.y = max(temp0.w, float1(0));
    temp0.yzw = DirectionalLight[0].Color.xyz * temp0.yyy + temp1.xyz;
    temp0.x = max(temp0.x, float1(0));
    temp0.xyz = DirectionalLight[2].Color.xyz * temp0.xxx + temp0.yzw;
    temp0.xyz = temp0.xyz + AmbientLightColor.xyz;
    o.texcoord3.xyz = temp0.xyz * i.color.xyz;
    temp0.xy = i.position.xy + Shroud.ScaleUV_OffsetUV.zw;
    o.texcoord2 = temp0 * Shroud.ScaleUV_OffsetUV;
    o.texcoord.xy = i.texcoord.xy * float2(3.3333334E-05, 3.3333334E-05);
    o.texcoord.zw = float2(0, 0);
    o.texcoord1 = float4(0, 0, 0, 0);
    o.texcoord3.w = i.color.w;

    return o;
}


struct Road_L_PixelShader31_Input
{
    float2 texcoord : TEXCOORD;
    float2 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
};

float4 Road_L_PixelShader31(Road_L_PixelShader31_Input i) : COLOR
{
    float4 out_color;
    float4 temp0, temp1;
    temp0 = tex2D(ShroudSamplerSampler, i.texcoord2.xy);
    temp1 = tex2D(BaseSamplerWrapped_LSampler, i.texcoord.xy);
    temp1 = temp1 * i.texcoord3;
    temp1.xyz = temp0.xxx * temp1.xyz;
    out_color = temp1;

    return out_color;
}


struct Road_L_VertexShader32_Input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 color : COLOR;
    float4 texcoord : TEXCOORD;
};

struct Road_L_VertexShader32_Output
{
    float4 position : POSITION;
    float4 texcoord3 : TEXCOORD3;
    float2 texcoord2 : TEXCOORD2;
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
};

Road_L_VertexShader32_Output Road_L_VertexShader32(Road_L_VertexShader32_Input i)
{
    Road_L_VertexShader32_Output o;
    float4 temp0;
    temp0 = i.position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
    o.position.x = dot(temp0, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp0, (ViewProjection._m01_m11_m21_m31));
    o.position.z = dot(temp0, (ViewProjection._m02_m12_m22_m32));
    o.position.w = dot(temp0, (ViewProjection._m03_m13_m23_m33));
    temp0.x = dot(i.normal.xyz, DirectionalLight[1].Direction.xyz);
    temp0.x = max(temp0.x, float1(0));
    temp0.xyz = temp0.xxx * DirectionalLight[1].Color.xyz;
    temp0.w = dot(i.normal.xyz, DirectionalLight[0].Direction.xyz);
    temp0.w = max(temp0.w, float1(0));
    temp0.xyz = DirectionalLight[0].Color.xyz * temp0.www + temp0.xyz;
    temp0.w = dot(i.normal.xyz, DirectionalLight[2].Direction.xyz);
    temp0.w = max(temp0.w, float1(0));
    temp0.xyz = DirectionalLight[2].Color.xyz * temp0.www + temp0.xyz;
    temp0.xyz = temp0.xyz + AmbientLightColor.xyz;
    o.texcoord3.xyz = temp0.xyz * i.color.xyz;
    temp0.xy = i.position.xy + Shroud.ScaleUV_OffsetUV.zw;
    o.texcoord2 = temp0 * Shroud.ScaleUV_OffsetUV;
    o.texcoord.xy = i.texcoord.xy;
    o.texcoord.zw = float2(0, 0);
    o.texcoord1 = float4(0, 0, 0, 0);
    o.texcoord3.w = i.color.w;

    return o;
}


struct Cliff_L_PixelShader33_Input
{
    float2 texcoord : TEXCOORD;
    float2 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
};

float4 Cliff_L_PixelShader33(Cliff_L_PixelShader33_Input i) : COLOR
{
    float4 out_color;
    float4 temp0, temp1;
    temp0 = tex2D(BaseSamplerWrapped_LSampler, i.texcoord.xy);
    temp1 = tex2D(ShroudSamplerSampler, i.texcoord2.xy);
    temp0.xyz = temp0.xyz * i.texcoord3.xyz;
    temp0.xyz = temp1.xxx * temp0.xyz;
    temp0.w = i.texcoord3.w;
    out_color = temp0;

    return out_color;
}


struct Cliff_L_VertexShader34_Input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 color : COLOR;
    float4 texcoord : TEXCOORD;
};

struct Cliff_L_VertexShader34_Output
{
    float4 position : POSITION;
    float4 texcoord3 : TEXCOORD3;
    float2 texcoord2 : TEXCOORD2;
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
};

Cliff_L_VertexShader34_Output Cliff_L_VertexShader34(Cliff_L_VertexShader34_Input i)
{
    Cliff_L_VertexShader34_Output o;
    float4 temp0;
    temp0 = i.position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
    o.position.x = dot(temp0, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp0, (ViewProjection._m01_m11_m21_m31));
    o.position.z = dot(temp0, (ViewProjection._m02_m12_m22_m32));
    o.position.w = dot(temp0, (ViewProjection._m03_m13_m23_m33));
    temp0.x = dot(i.normal.xyz, DirectionalLight[1].Direction.xyz);
    temp0.x = max(temp0.x, float1(0));
    temp0.xyz = temp0.xxx * DirectionalLight[1].Color.xyz;
    temp0.w = dot(i.normal.xyz, DirectionalLight[0].Direction.xyz);
    temp0.w = max(temp0.w, float1(0));
    temp0.xyz = DirectionalLight[0].Color.xyz * temp0.www + temp0.xyz;
    temp0.w = dot(i.normal.xyz, DirectionalLight[2].Direction.xyz);
    temp0.w = max(temp0.w, float1(0));
    temp0.xyz = DirectionalLight[2].Color.xyz * temp0.www + temp0.xyz;
    temp0.xyz = temp0.xyz + AmbientLightColor.xyz;
    o.texcoord3.xyz = temp0.xyz * i.color.xyz;
    temp0.xy = i.position.xy + Shroud.ScaleUV_OffsetUV.zw;
    o.texcoord2 = temp0 * Shroud.ScaleUV_OffsetUV;
    o.texcoord.xy = i.texcoord.xy;
    o.texcoord.zw = float2(0, 0);
    o.texcoord1 = float4(0, 0, 0, 0);
    o.texcoord3.w = i.color.w;

    return o;
}


struct TerrainTile_L_PixelShader35_Input
{
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
    float2 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
};

float4 TerrainTile_L_PixelShader35(TerrainTile_L_PixelShader35_Input i) : COLOR
{
    float4 out_color;
    float4 temp0, temp1, temp2, temp3;
    float3 temp4;
    temp0.xy = i.texcoord1.wz;
    temp0 = tex2D(BaseSamplerClamped_LSampler, temp0.xy);
    temp1 = tex2D(BaseSamplerClamped_LSampler, i.texcoord.xy);
    temp2 = tex2D(BaseSamplerClamped_LSampler, i.texcoord1.xy);
    temp3 = tex2D(ShroudSamplerSampler, i.texcoord2.xy);
    temp3.zw = saturate(i.texcoord.zw);
    temp4.xyz = lerp(temp1.xyz, temp2.xyz, temp3.www);
    temp1.xyz = lerp(temp4.xyz, temp0.xyz, temp3.zzz);
    temp0.xyz = temp1.xyz * i.texcoord3.xyz;
    temp0.xyz = temp3.xxx * temp0.xyz;
    temp0.w = i.texcoord3.w;
    out_color = temp0;

    return out_color;
}


struct TerrainTile_L_VertexShader36_Input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
    float4 texcoord2 : TEXCOORD2;
};

struct TerrainTile_L_VertexShader36_Output
{
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
    float4 position : POSITION;
    float4 texcoord3 : TEXCOORD3;
    float2 texcoord2 : TEXCOORD2;
};

TerrainTile_L_VertexShader36_Output TerrainTile_L_VertexShader36(TerrainTile_L_VertexShader36_Input i)
{
    TerrainTile_L_VertexShader36_Output o;
    float4 temp0;
    float3 temp1;
    o.texcoord.xy = i.texcoord.xy * float2(3.3333334E-05, 3.3333334E-05);
    o.texcoord1.xy = i.texcoord1.xy * float2(3.3333334E-05, 3.3333334E-05);
    o.texcoord1.zw = i.texcoord2.yx * float2(3.3333334E-05, 3.3333334E-05);
    o.texcoord.w = i.position.w + float1(-1);
    o.texcoord.z = i.normal.w + float1(-1);
    temp0 = i.position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
    o.position.x = dot(temp0, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp0, (ViewProjection._m01_m11_m21_m31));
    o.position.z = dot(temp0, (ViewProjection._m02_m12_m22_m32));
    o.position.w = dot(temp0, (ViewProjection._m03_m13_m23_m33));
    temp0.xyz = i.normal.xyz * float3(0.01, 0.01, 0.01) + float3(-1, -1, -1);
    temp0.w = dot(temp0.xyz, DirectionalLight[1].Direction.xyz);
    temp0.w = max(temp0.w, float1(0));
    temp1.xyz = temp0.www * DirectionalLight[1].Color.xyz;
    temp0.w = dot(temp0.xyz, DirectionalLight[0].Direction.xyz);
    temp0.x = dot(temp0.xyz, DirectionalLight[2].Direction.xyz);
    temp0.y = max(temp0.w, float1(0));
    temp0.yzw = DirectionalLight[0].Color.xyz * temp0.yyy + temp1.xyz;
    temp0.x = max(temp0.x, float1(0));
    temp0.xyz = DirectionalLight[2].Color.xyz * temp0.xxx + temp0.yzw;
    o.texcoord3.xyz = temp0.xyz + AmbientLightColor.xyz;
    temp0.xy = i.position.xy + Shroud.ScaleUV_OffsetUV.zw;
    o.texcoord2 = temp0 * Shroud.ScaleUV_OffsetUV;
    o.texcoord3.w = float1(1);

    return o;
}


float Scorch_M_Expression37()
{
    float1 expr0;
    expr0.x = HasShadow.x;
    return expr0;
}


struct Scorch_M_VertexShader38_Input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 color : COLOR;
    float4 texcoord : TEXCOORD;
};

struct Scorch_M_VertexShader38_Output
{
    float4 position : POSITION;
    float4 color1 : COLOR1;
    float4 color : COLOR;
    float2 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
    float4 texcoord5 : TEXCOORD5;
};

Scorch_M_VertexShader38_Output Scorch_M_VertexShader38(Scorch_M_VertexShader38_Input i)
{
    /*
    PRSI
      OutputRegisterOffset: 12
      Unknown1: 0
      Unknown2: 0
      OutputRegisterCount: 1
      Unknown3: 0
      Unknown4: 0
      Unknown5: 12
      Unknown6: 1
      Mappings: 1
        0 - ConstOutput: 0 ConstInput 0
    */
    float4 expr12;
    {
        float4 temp0;
                temp0.x = MapCellSize.x * (66);
            expr12.x = 1.0f / (temp0.x);
    }

    Scorch_M_VertexShader38_Output o;
    float4 temp0, temp1;
    float3 temp2;
    temp0 = i.position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
    o.position.x = dot(temp0, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp0, (ViewProjection._m01_m11_m21_m31));
    o.position.z = dot(temp0, (ViewProjection._m02_m12_m22_m32));
    o.position.w = dot(temp0, (ViewProjection._m03_m13_m23_m33));
    temp1.xyz = i.normal.xyz * float3(2.55, 2.55, 2.55) + float3(-1, -1, -1);
    temp1.w = dot(temp1.xyz, DirectionalLight[0].Direction.xyz);
    temp1.w = max(temp1.w, float1(0));
    temp2.xyz = temp1.www * DirectionalLight[0].Color.xyz;
    o.color1.xyz = temp2.xyz * float3(0.5, 0.5, 0.5);
    temp1.w = dot(temp1.xyz, DirectionalLight[2].Direction.xyz);
    temp1.x = dot(temp1.xyz, DirectionalLight[1].Direction.xyz);
    temp1.y = max(temp1.w, float1(0));
    temp1.yzw = temp1.yyy * DirectionalLight[2].Color.xyz;
    temp1.x = max(temp1.x, float1(0));
    temp1.xyz = DirectionalLight[1].Color.xyz * temp1.xxx + temp1.yzw;
    temp1.xyz = temp1.xyz + AmbientLightColor.xyz;
    temp1.xyz = temp1.xyz * i.color.xyz;
    o.color.xyz = temp1.xyz * float3(0.5, 0.5, 0.5);
    temp1.xy = i.position.xy + Shroud.ScaleUV_OffsetUV.zw;
    o.texcoord2 = temp1 * Shroud.ScaleUV_OffsetUV;
    temp1.xy = i.position.zz * Cloud.WorldPositionMultiplier_XYZZ.zw;
    temp1.xy = i.position.xy * Cloud.WorldPositionMultiplier_XYZZ.xy + -temp1.xy;
    o.texcoord3.xy = temp1.xy + Cloud.CurrentOffsetUV.xy;
    temp1.yz = float2(-1, 1);
    temp1.xy = temp1.yz * expr12.xx;
    o.texcoord3.zw = temp1.xy * i.position.yx;
    o.color.w = i.color.w;
    o.color1.w = float1(1);
    o.texcoord.xy = i.texcoord.xy * float2(3.3333334E-05, 3.3333334E-05);
    o.texcoord.zw = float2(0, 0);
    o.texcoord1 = float4(0, 0, 0, 0);
    temp1.x = dot(temp0, (ShadowMapWorldToShadow._m00_m10_m20_m30));
    temp1.y = dot(temp0, (ShadowMapWorldToShadow._m01_m11_m21_m31));
    temp1.z = dot(temp0, (ShadowMapWorldToShadow._m02_m12_m22_m32));
    temp0.x = dot(temp0, (ShadowMapWorldToShadow._m03_m13_m23_m33));
    temp0.y = 1.0f / temp0.x;
    o.texcoord5.w = temp0.x;
    o.texcoord5.xyz = temp1.xyz * temp0.yyy + float3(0, 0, -0.0015);

    return o;
}


float Road_M_Expression39()
{
    float1 expr0;
    expr0.x = HasShadow.x;
    return expr0;
}


struct Road_M_VertexShader40_Input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 color : COLOR;
    float4 texcoord : TEXCOORD;
};

struct Road_M_VertexShader40_Output
{
    float4 position : POSITION;
    float4 color1 : COLOR1;
    float4 color : COLOR;
    float2 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
    float4 texcoord5 : TEXCOORD5;
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
};

Road_M_VertexShader40_Output Road_M_VertexShader40(Road_M_VertexShader40_Input i)
{
    /*
    PRSI
      OutputRegisterOffset: 12
      Unknown1: 0
      Unknown2: 0
      OutputRegisterCount: 1
      Unknown3: 0
      Unknown4: 0
      Unknown5: 12
      Unknown6: 1
      Mappings: 1
        0 - ConstOutput: 0 ConstInput 0
    */
    float4 expr12;
    {
        float4 temp0;
                temp0.x = MapCellSize.x * (66);
            expr12.x = 1.0f / (temp0.x);
    }

    Road_M_VertexShader40_Output o;
    float4 temp0, temp1;
    temp0 = i.position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
    o.position.x = dot(temp0, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp0, (ViewProjection._m01_m11_m21_m31));
    o.position.z = dot(temp0, (ViewProjection._m02_m12_m22_m32));
    o.position.w = dot(temp0, (ViewProjection._m03_m13_m23_m33));
    temp1.x = dot(i.normal.xyz, DirectionalLight[0].Direction.xyz);
    temp1.x = max(temp1.x, float1(0));
    temp1.xyz = temp1.xxx * DirectionalLight[0].Color.xyz;
    o.color1.xyz = temp1.xyz * float3(0.5, 0.5, 0.5);
    temp1.x = dot(i.normal.xyz, DirectionalLight[2].Direction.xyz);
    temp1.x = max(temp1.x, float1(0));
    temp1.xyz = temp1.xxx * DirectionalLight[2].Color.xyz;
    temp1.w = dot(i.normal.xyz, DirectionalLight[1].Direction.xyz);
    temp1.w = max(temp1.w, float1(0));
    temp1.xyz = DirectionalLight[1].Color.xyz * temp1.www + temp1.xyz;
    temp1.xyz = temp1.xyz + AmbientLightColor.xyz;
    temp1.xyz = temp1.xyz * i.color.xyz;
    o.color.xyz = temp1.xyz * float3(0.5, 0.5, 0.5);
    temp1.xy = i.position.xy + Shroud.ScaleUV_OffsetUV.zw;
    o.texcoord2 = temp1 * Shroud.ScaleUV_OffsetUV;
    temp1.xy = i.position.zz * Cloud.WorldPositionMultiplier_XYZZ.zw;
    temp1.xy = i.position.xy * Cloud.WorldPositionMultiplier_XYZZ.xy + -temp1.xy;
    o.texcoord3.xy = temp1.xy + Cloud.CurrentOffsetUV.xy;
    temp1.xw = float2(1, -1);
    temp1.xy = temp1.wx * expr12.xx;
    o.texcoord3.zw = temp1.xy * i.position.yx;
    o.texcoord5.x = dot(temp0, (ShadowMapWorldToShadow._m00_m10_m20_m30));
    o.texcoord5.y = dot(temp0, (ShadowMapWorldToShadow._m01_m11_m21_m31));
    o.texcoord5.z = dot(temp0, (ShadowMapWorldToShadow._m02_m12_m22_m32));
    o.texcoord5.w = dot(temp0, (ShadowMapWorldToShadow._m03_m13_m23_m33));
    o.color.w = i.color.w;
    o.color1.w = float1(1);
    o.texcoord.xy = i.texcoord.xy;
    o.texcoord.zw = float2(0, 0);
    o.texcoord1 = float4(0, 0, 0, 0);

    return o;
}


float Cliff_M_Expression41()
{
    float1 expr0;
    expr0.x = HasShadow.x;
    return expr0;
}


struct Cliff_M_VertexShader42_Input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 color : COLOR;
    float4 texcoord : TEXCOORD;
};

struct Cliff_M_VertexShader42_Output
{
    float4 position : POSITION;
    float4 color1 : COLOR1;
    float4 color : COLOR;
    float2 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
    float4 texcoord5 : TEXCOORD5;
};

Cliff_M_VertexShader42_Output Cliff_M_VertexShader42(Cliff_M_VertexShader42_Input i)
{
    /*
    PRSI
      OutputRegisterOffset: 12
      Unknown1: 0
      Unknown2: 0
      OutputRegisterCount: 1
      Unknown3: 0
      Unknown4: 0
      Unknown5: 12
      Unknown6: 1
      Mappings: 1
        0 - ConstOutput: 0 ConstInput 0
    */
    float4 expr12;
    {
        float4 temp0;
                temp0.x = MapCellSize.x * (66);
            expr12.x = 1.0f / (temp0.x);
    }

    Cliff_M_VertexShader42_Output o;
    float4 temp0, temp1;
    temp0 = i.position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
    o.position.x = dot(temp0, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp0, (ViewProjection._m01_m11_m21_m31));
    o.position.z = dot(temp0, (ViewProjection._m02_m12_m22_m32));
    o.position.w = dot(temp0, (ViewProjection._m03_m13_m23_m33));
    temp1.x = dot(i.normal.xyz, DirectionalLight[0].Direction.xyz);
    temp1.x = max(temp1.x, float1(0));
    temp1.xyz = temp1.xxx * DirectionalLight[0].Color.xyz;
    o.color1.xyz = temp1.xyz * float3(0.5, 0.5, 0.5);
    temp1.x = dot(i.normal.xyz, DirectionalLight[2].Direction.xyz);
    temp1.x = max(temp1.x, float1(0));
    temp1.xyz = temp1.xxx * DirectionalLight[2].Color.xyz;
    temp1.w = dot(i.normal.xyz, DirectionalLight[1].Direction.xyz);
    temp1.w = max(temp1.w, float1(0));
    temp1.xyz = DirectionalLight[1].Color.xyz * temp1.www + temp1.xyz;
    temp1.xyz = temp1.xyz + AmbientLightColor.xyz;
    temp1.xyz = temp1.xyz * i.color.xyz;
    o.color.xyz = temp1.xyz * float3(0.5, 0.5, 0.5);
    temp1.xy = i.position.xy + Shroud.ScaleUV_OffsetUV.zw;
    o.texcoord2 = temp1 * Shroud.ScaleUV_OffsetUV;
    temp1.xy = i.position.zz * Cloud.WorldPositionMultiplier_XYZZ.zw;
    temp1.xy = i.position.xy * Cloud.WorldPositionMultiplier_XYZZ.xy + -temp1.xy;
    o.texcoord3.xy = temp1.xy + Cloud.CurrentOffsetUV.xy;
    temp1.xw = float2(1, -1);
    temp1.xy = temp1.wx * expr12.xx;
    o.texcoord3.zw = temp1.xy * i.position.yx;
    o.color.w = i.color.w;
    o.color1.w = float1(1);
    o.texcoord.xy = i.texcoord.xy;
    o.texcoord.zw = float2(0, 0);
    o.texcoord1 = float4(0, 0, 0, 0);
    temp1.x = dot(temp0, (ShadowMapWorldToShadow._m00_m10_m20_m30));
    temp1.y = dot(temp0, (ShadowMapWorldToShadow._m01_m11_m21_m31));
    temp1.z = dot(temp0, (ShadowMapWorldToShadow._m02_m12_m22_m32));
    temp0.x = dot(temp0, (ShadowMapWorldToShadow._m03_m13_m23_m33));
    temp0.y = 1.0f / temp0.x;
    o.texcoord5.w = temp0.x;
    o.texcoord5.xyz = temp1.xyz * temp0.yyy + float3(0, 0, -0.0015);

    return o;
}


float TerrainTile_M_Expression43()
{
    float4 temp0;
    float1 expr0;
    temp0.x = IsTerrainAtlasEnabled.x + IsTerrainAtlasEnabled.x;
    expr0.x = temp0.x + HasShadow.x;
    return expr0;
}


float TerrainTile_M_Expression44()
{
    float1 expr0;
    expr0.x = IsTerrainAtlasEnabled.x;
    return expr0;
}


float Scorch_Expression45()
{
    float1 expr0;
    expr0.x = HasShadow.x;
    return expr0;
}


struct Scorch_VertexShader46_Input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 color : COLOR;
    float4 texcoord : TEXCOORD;
    float4 tangent : TANGENT;
};

struct Scorch_VertexShader46_Output
{
    float4 position : POSITION;
    float4 color : COLOR;
    float color1 : COLOR1;
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
    float2 texcoord2 : TEXCOORD2;
    float3 texcoord3 : TEXCOORD3;
    float4 texcoord4 : TEXCOORD4;
    float3 texcoord5 : TEXCOORD5;  //float3
    float4 texcoord6 : TEXCOORD6;
};

Scorch_VertexShader46_Output Scorch_VertexShader46(Scorch_VertexShader46_Input i)
{
    Scorch_VertexShader46_Output o;
    float4 temp0, temp1;
    float3 temp2, temp4;
    float2 temp3;
    temp0 = i.position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
    o.position.x = dot(temp0, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp0, (ViewProjection._m01_m11_m21_m31));
    o.position.z = dot(temp0, (ViewProjection._m02_m12_m22_m32));
    o.position.w = dot(temp0, (ViewProjection._m03_m13_m23_m33));
    temp1.xyz = EyePosition.xyz + -i.position.xyz;
    temp1.w = dot(temp1.xyz, temp1.xyz);
    temp1.w = 1 / sqrt(temp1.w);
    temp1.xyz = temp1.xyz * temp1.www + DirectionalLight[0].Direction.xyz;
    temp2.xyz = i.tangent.xyz * float3(2.55, 2.55, 2.55) + float3(-1, -1, -1);
    temp3.x = dot(temp1.xyz, -temp2.xyz);
    temp2.x = dot(DirectionalLight[0].Direction.xyz, -temp2.xyz);
    temp4.xyz = i.normal.xyz * float3(2.55, 2.55, 2.55) + float3(-1, -1, -1);
    temp3.y = dot(temp1.xyz, temp4.xyz);
    temp1.x = dot(temp3.xxy, temp3.xxy);
    temp1.x = 1 / sqrt(temp1.x);
    o.texcoord5 = temp3.xxy * temp1.x;  //    o.texcoord5 = temp3.xxyw * temp1.x;
    temp1.x = dot(temp4.xyz, DirectionalLight[2].Direction.xyz);
    temp1.x = max(temp1.x, float1(0));
    temp1.xyz = temp1.xxx * DirectionalLight[2].Color.xyz;
    temp1.w = dot(temp4.xyz, DirectionalLight[1].Direction.xyz);
    temp2.y = dot(DirectionalLight[0].Direction.xyz, temp4.xyz);
    temp1.w = max(temp1.w, float1(0));
    temp1.xyz = DirectionalLight[1].Color.xyz * temp1.www + temp1.xyz;
    temp1.xyz = temp1.xyz + AmbientLightColor.xyz;
    temp1.xyz = temp1.xyz * i.color.xyz;
    o.color.xyz = temp1.xyz * float3(0.5, 0.5, 0.5);
    temp1.xy = Shroud.ScaleUV_OffsetUV.zw + i.position.xy;
    o.texcoord2 = temp1 * Shroud.ScaleUV_OffsetUV;
    o.color.w = i.color.w;
    o.color1 = float4(1, 1, 1, 1);
    o.texcoord.xy = float2(3.3333334E-05, 3.3333334E-05) * i.texcoord.xy;
    o.texcoord.zw = float2(0, 0);
    o.texcoord1 = float4(0, 0, 0, 0);
    o.texcoord3 = i.position;
    temp2.z = max(temp2.y, float1(0));
    o.texcoord4 = temp2.xxyz;
    temp1.x = dot(temp0, (ShadowMapWorldToShadow._m00_m10_m20_m30));
    temp1.y = dot(temp0, (ShadowMapWorldToShadow._m01_m11_m21_m31));
    temp1.z = dot(temp0, (ShadowMapWorldToShadow._m02_m12_m22_m32));
    temp0.x = dot(temp0, (ShadowMapWorldToShadow._m03_m13_m23_m33));
    temp0.y = 1.0f / temp0.x;
    o.texcoord6.w = temp0.x;
    o.texcoord6.xyz = temp1.xyz * temp0.yyy + float3(0, 0, -0.0015);

    return o;
}


float Road_Expression47()
{
    float1 expr0;
    expr0.x = HasShadow.x;
    return expr0;
}


struct Road_VertexShader48_Input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 color : COLOR;
    float4 texcoord : TEXCOORD;
};

struct Road_VertexShader48_Output
{
    float4 position : POSITION;
    float4 color : COLOR;
    float color1 : COLOR1;
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
    float2 texcoord2 : TEXCOORD2;
    float3 texcoord3 : TEXCOORD3;
    float4 texcoord4 : TEXCOORD4;
    float3 texcoord5 : TEXCOORD5;
    float4 texcoord6 : TEXCOORD6;
};

Road_VertexShader48_Output Road_VertexShader48(Road_VertexShader48_Input i)
{
    Road_VertexShader48_Output o;
    float4 temp0, temp1;
    float3 temp2, temp3;
    temp0 = i.position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
    o.position.x = dot(temp0, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp0, (ViewProjection._m01_m11_m21_m31));
    o.position.z = dot(temp0, (ViewProjection._m02_m12_m22_m32));
    o.position.w = dot(temp0, (ViewProjection._m03_m13_m23_m33));
    temp1.xyz = float3(1, 0, 0) * i.normal.zxy;
    temp1.xyz = i.normal.yzx * float3(0, 0, 1) + -temp1.xyz;
    o.texcoord4.x = dot(DirectionalLight[0].Direction.xyz, -temp1.xyz);
    temp2.xyz = float3(0, 0, -1) * i.normal.zxy;
    temp2.xyz = i.normal.yzx * float3(0, -1, 0) + -temp2.xyz;
    o.texcoord4.y = dot(DirectionalLight[0].Direction.xyz, -temp2.xyz);
    temp1.w = dot(DirectionalLight[0].Direction.xyz, i.normal.xyz);
    o.texcoord4.w = max(temp1.w, float1(0));
    o.texcoord4.z = temp1.w;
    temp3.xyz = EyePosition.xyz + -i.position.xyz;
    temp1.w = dot(temp3.xyz, temp3.xyz);
    temp1.w = 1 / sqrt(temp1.w);
    temp3.xyz = temp3.xyz * temp1.www + DirectionalLight[0].Direction.xyz;
    temp1.x = dot(temp3.xyz, -temp1.xyz);
    temp1.y = dot(temp3.xyz, -temp2.xyz);
    temp1.z = dot(temp3.xyz, i.normal.xyz);
    temp1.w = dot(temp1.xyz, temp1.xyz);
    temp1.w = 1 / sqrt(temp1.w);
    o.texcoord5 = temp1 * temp1.w;
    temp1.x = dot(i.normal.xyz, DirectionalLight[2].Direction.xyz);
    temp1.x = max(temp1.x, float1(0));
    temp1.xyz = temp1.xxx * DirectionalLight[2].Color.xyz;
    temp1.w = dot(i.normal.xyz, DirectionalLight[1].Direction.xyz);
    temp1.w = max(temp1.w, float1(0));
    temp1.xyz = DirectionalLight[1].Color.xyz * temp1.www + temp1.xyz;
    temp1.xyz = temp1.xyz + AmbientLightColor.xyz;
    temp1.xyz = temp1.xyz * i.color.xyz;
    o.color.xyz = temp1.xyz * float3(0.5, 0.5, 0.5);
    temp1.xy = Shroud.ScaleUV_OffsetUV.zw + i.position.xy;
    o.texcoord2 = temp1 * Shroud.ScaleUV_OffsetUV;
    o.texcoord6.x = dot(temp0, (ShadowMapWorldToShadow._m00_m10_m20_m30));
    o.texcoord6.y = dot(temp0, (ShadowMapWorldToShadow._m01_m11_m21_m31));
    o.texcoord6.z = dot(temp0, (ShadowMapWorldToShadow._m02_m12_m22_m32));
    o.texcoord6.w = dot(temp0, (ShadowMapWorldToShadow._m03_m13_m23_m33));
    o.color.w = i.color.w;
    o.color1 = float4(1, 1, 1, 1);
    o.texcoord.xy = i.texcoord.xy;
    o.texcoord.zw = float2(0, 0);
    o.texcoord1 = float4(0, 0, 0, 0);
    o.texcoord3 = i.position;

    return o;
}


float Cliff_Expression49()
{
    float1 expr0;
    expr0.x = HasShadow.x;
    return expr0;
}


struct Cliff_VertexShader50_Input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 color : COLOR;
    float4 texcoord : TEXCOORD;
};

struct Cliff_VertexShader50_Output
{
    float4 position : POSITION;
    float4 color : COLOR;
    float color1 : COLOR1;
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
    float2 texcoord2 : TEXCOORD2;
    float3 texcoord3 : TEXCOORD3;
    float4 texcoord4 : TEXCOORD4;
    float3 texcoord5 : TEXCOORD5;
    float4 texcoord6 : TEXCOORD6;
};

Cliff_VertexShader50_Output Cliff_VertexShader50(Cliff_VertexShader50_Input i)
{
    Cliff_VertexShader50_Output o;
    float4 temp0, temp1;
    float3 temp2, temp3;
    temp0 = i.position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
    o.position.x = dot(temp0, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp0, (ViewProjection._m01_m11_m21_m31));
    o.position.z = dot(temp0, (ViewProjection._m02_m12_m22_m32));
    o.position.w = dot(temp0, (ViewProjection._m03_m13_m23_m33));
    temp1.xyz = float3(1, 0, 0) * i.normal.zxy;
    temp1.xyz = i.normal.yzx * float3(0, 0, 1) + -temp1.xyz;
    o.texcoord4.x = dot(DirectionalLight[0].Direction.xyz, -temp1.xyz);
    temp2.xyz = float3(0, 0, -1) * i.normal.zxy;
    temp2.xyz = i.normal.yzx * float3(0, -1, 0) + -temp2.xyz;
    o.texcoord4.y = dot(DirectionalLight[0].Direction.xyz, -temp2.xyz);
    temp1.w = dot(DirectionalLight[0].Direction.xyz, i.normal.xyz);
    o.texcoord4.w = max(temp1.w, float1(0));
    o.texcoord4.z = temp1.w;
    temp3.xyz = EyePosition.xyz + -i.position.xyz;
    temp1.w = dot(temp3.xyz, temp3.xyz);
    temp1.w = 1 / sqrt(temp1.w);
    temp3.xyz = temp3.xyz * temp1.www + DirectionalLight[0].Direction.xyz;
    temp1.x = dot(temp3.xyz, -temp1.xyz);
    temp1.y = dot(temp3.xyz, -temp2.xyz);
    temp1.z = dot(temp3.xyz, i.normal.xyz);
    temp1.w = dot(temp1.xyz, temp1.xyz);
    temp1.w = 1 / sqrt(temp1.w);
    o.texcoord5 = temp1 * temp1.w;
    temp1.x = dot(i.normal.xyz, DirectionalLight[2].Direction.xyz);
    temp1.x = max(temp1.x, float1(0));
    temp1.xyz = temp1.xxx * DirectionalLight[2].Color.xyz;
    temp1.w = dot(i.normal.xyz, DirectionalLight[1].Direction.xyz);
    temp1.w = max(temp1.w, float1(0));
    temp1.xyz = DirectionalLight[1].Color.xyz * temp1.www + temp1.xyz;
    temp1.xyz = temp1.xyz + AmbientLightColor.xyz;
    temp1.xyz = temp1.xyz * i.color.xyz;
    o.color.xyz = temp1.xyz * float3(0.5, 0.5, 0.5);
    temp1.xy = Shroud.ScaleUV_OffsetUV.zw + i.position.xy;
    o.texcoord2 = temp1 * Shroud.ScaleUV_OffsetUV;
    o.color.w = i.color.w;
    o.color1 = float4(1, 1, 1, 1);
    o.texcoord.xy = i.texcoord.xy;
    o.texcoord.zw = float2(0, 0);
    o.texcoord1 = float4(0, 0, 0, 0);
    o.texcoord3 = i.position;
    temp1.x = dot(temp0, (ShadowMapWorldToShadow._m00_m10_m20_m30));
    temp1.y = dot(temp0, (ShadowMapWorldToShadow._m01_m11_m21_m31));
    temp1.z = dot(temp0, (ShadowMapWorldToShadow._m02_m12_m22_m32));
    temp0.x = dot(temp0, (ShadowMapWorldToShadow._m03_m13_m23_m33));
    temp0.y = 1.0f / temp0.x;
    o.texcoord6.w = temp0.x;
    o.texcoord6.xyz = temp1.xyz * temp0.yyy + float3(0, 0, -0.0015);

    return o;
}


float TerrainTile_Expression51()
{
    float4 temp0;
    float1 expr0;
    temp0.x = IsTerrainAtlasEnabled.x + IsTerrainAtlasEnabled.x;
    expr0.x = temp0.x + HasShadow.x;
    return expr0;
}


float TerrainTile_Expression52()
{
    float1 expr0;
    expr0.x = IsTerrainAtlasEnabled.x;
    return expr0;
}

technique TerrainTile
{
    pass P0
    {
        VertexShader = VS_TerrainTile_Array[TerrainTile_Expression52()]; 
        PixelShader = PS_TerrainTile_Array[TerrainTile_Expression51()]; 
        ZEnable = 1;
        ZWriteEnable = 1;
        ZFunc = 4;
        CullMode = 2;
        AlphaBlendEnable = 0;
        AlphaTestEnable = 0;
    }
}

technique Cliff
{
    pass P0
    {
        VertexShader = compile vs_3_0 Cliff_VertexShader50(); 
        PixelShader = PS_Cliff_Array[Cliff_Expression49()]; 
        ZEnable = 1;
        ZWriteEnable = 0;
        ZFunc = 4;
        CullMode = 2;
        AlphaBlendEnable = 1;
        SrcBlend = 5;
        DestBlend = 6;
        AlphaTestEnable = 0;
    }
}

technique Road
{
    pass P0
    {
        VertexShader = compile vs_3_0 Road_VertexShader48(); 
        PixelShader = PS_Road_Array[Road_Expression47()]; 
        ZEnable = 1;
        ZWriteEnable = 0;
        ZFunc = 4;
        CullMode = 2;
        AlphaBlendEnable = 1;
        SrcBlend = 5;
        DestBlend = 6;
        AlphaTestEnable = 0;
        DepthBias = -0.0004;
    }
}

technique Scorch
{
    pass P0
    {
        VertexShader = compile vs_3_0 Scorch_VertexShader46(); 
        PixelShader = PS_Scorch_Array[Scorch_Expression45()]; 
        ZEnable = 1;
        ZWriteEnable = 0;
        ZFunc = 4;
        CullMode = 2;
        AlphaBlendEnable = 1;
        SrcBlend = 5;
        DestBlend = 6;
        AlphaTestEnable = 0;
        DepthBias = -0.0002;
    }
}

technique TerrainTile_M
{
    pass P0
    {
        VertexShader = VS_TerrainTile_M_Array[TerrainTile_M_Expression44()]; 
        PixelShader = PS_TerrainTile_M_Array[TerrainTile_M_Expression43()]; 
        ZEnable = 1;
        ZWriteEnable = 1;
        ZFunc = 4;
        CullMode = 2;
        AlphaBlendEnable = 0;
        AlphaTestEnable = 0;
    }
}

technique Cliff_M
{
    pass P0
    {
        VertexShader = compile vs_2_0 Cliff_M_VertexShader42(); 
        PixelShader = PS_Cliff_M_Array[Cliff_M_Expression41()]; 
        ZEnable = 1;
        ZWriteEnable = 0;
        ZFunc = 4;
        CullMode = 2;
        AlphaBlendEnable = 1;
        SrcBlend = 5;
        DestBlend = 6;
        AlphaTestEnable = 0;
    }
}

technique Road_M
{
    pass P0
    {
        VertexShader = compile vs_2_0 Road_M_VertexShader40(); 
        PixelShader = PS_Road_M_Array[Road_M_Expression39()]; 
        ZEnable = 1;
        ZWriteEnable = 0;
        ZFunc = 4;
        CullMode = 2;
        AlphaBlendEnable = 1;
        SrcBlend = 5;
        DestBlend = 6;
        AlphaTestEnable = 0;
        DepthBias = -0.0004;
    }
}

technique Scorch_M
{
    pass P0
    {
        VertexShader = compile vs_2_0 Scorch_M_VertexShader38(); 
        PixelShader = PS_Scorch_M_Array[Scorch_M_Expression37()]; 
        ZEnable = 1;
        ZWriteEnable = 0;
        ZFunc = 4;
        CullMode = 2;
        AlphaBlendEnable = 1;
        SrcBlend = 5;
        DestBlend = 6;
        AlphaTestEnable = 0;
        DepthBias = -0.0002;
    }
}

technique TerrainTile_L
{
    pass P0
    {
        VertexShader = compile vs_2_0 TerrainTile_L_VertexShader36(); 
        PixelShader = compile ps_2_0 TerrainTile_L_PixelShader35(); 
        ZEnable = 1;
        ZWriteEnable = 1;
        ZFunc = 4;
        CullMode = 2;
        AlphaBlendEnable = 0;
        AlphaTestEnable = 0;
    }
}

technique Cliff_L
{
    pass P0
    {
        VertexShader = compile vs_2_0 Cliff_L_VertexShader34(); 
        PixelShader = compile ps_2_0 Cliff_L_PixelShader33(); 
        ZEnable = 1;
        ZWriteEnable = 0;
        ZFunc = 4;
        CullMode = 2;
        AlphaBlendEnable = 1;
        SrcBlend = 5;
        DestBlend = 6;
        AlphaTestEnable = 0;
    }
}

technique Road_L
{
    pass P0
    {
        VertexShader = compile vs_2_0 Road_L_VertexShader32(); 
        PixelShader = compile ps_2_0 Road_L_PixelShader31(); 
        ZEnable = 1;
        ZWriteEnable = 0;
        ZFunc = 4;
        CullMode = 2;
        AlphaBlendEnable = 1;
        SrcBlend = 5;
        DestBlend = 6;
        AlphaTestEnable = 0;
        DepthBias = -0.0004;
    }
}

technique Scorch_L
{
    pass P0
    {
        VertexShader = compile vs_2_0 Scorch_L_VertexShader30(); 
        PixelShader = compile ps_2_0 Scorch_L_PixelShader29(); 
        ZEnable = 1;
        ZWriteEnable = 0;
        ZFunc = 4;
        CullMode = 2;
        AlphaBlendEnable = 1;
        SrcBlend = 5;
        DestBlend = 6;
        AlphaTestEnable = 0;
        DepthBias = -0.0002;
    }
}

technique _CreateShadowMap
{
    pass P0
    {
        VertexShader = compile vs_2_0 _CreateShadowMap_VertexShader28(); 
        PixelShader = compile ps_2_0 _CreateShadowMap_PixelShader27(); 
        ZEnable = 1;
        ZWriteEnable = 1;
        ZFunc = 4;
        CullMode = 2;
        AlphaBlendEnable = 0;
        AlphaTestEnable = 0;
    }
}

technique _CreateDepthMap
{
    pass P0
    {
        VertexShader = compile vs_2_0 _CreateDepthMap_VertexShader26(); 
        PixelShader = compile ps_2_0 _CreateDepthMap_PixelShader25(); 
        ZEnable = 1;
        ZWriteEnable = 1;
        ZFunc = 4;
        CullMode = 2;
        AlphaBlendEnable = 0;
        AlphaTestEnable = 0;
    }
}

