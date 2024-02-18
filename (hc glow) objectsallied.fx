string DefaultParameterScopeBlock = "material"; 
float3 AmbientLightColor : register(vs_2_0, c4) : register(vs_3_0, c4) <bool unmanaged = 1;> = { 0.3, 0.3, 0.3 };
struct
{
    float3 Color;
    float3 Direction;
} DirectionalLight[3] : register(vs_2_0, c5) : register(ps_3_0, c5) : register(vs_3_0, c5) <bool unmanaged = 1;> = { 1.625198, 1.512711, 1.097048, 0.62914, -0.34874, 0.69465, 0.5232916, 0.6654605, 0.7815244, -0.32877, 0.90329, 0.27563, 0.4420466, 0.4102767, 0.4420466, -0.80704, -0.58635, 0.06975 };
int NumPointLights : register(ps_3_0, i0) <string SasBindAddress = "Sas.NumPointLights"; string UIWidget = "None";>;
struct
{
    float3 Color;
    float3 Position;
    float2 Range_Inner_Outer;
} PointLight[8] : register(ps_3_0, c89) <bool unmanaged = 1;>;
struct
{
    float4 WorldPositionMultiplier_XYZZ;
    float2 CurrentOffsetUV;
} Cloud : register(vs_3_0, c117) <bool unmanaged = 1;>;
float3 NoCloudMultiplier <bool unmanaged = 1;> = { 1, 1, 1 };
bool HasRecolorColors <string UIWidget = "None"; string SasBindAddress = "WW3D.HasRecolorColors"; bool ExportValue = 0;>;
float3 RecolorColor : register(ps_2_0, c0) : register(ps_3_0, c0) <bool unmanaged = 1;>;
column_major float4x4 ShadowMapWorldToShadow : register(vs_3_0, c113) <bool unmanaged = 1;>;
float OpacityOverride : register(vs_2_0, c1) : register(vs_3_0, c1) <bool unmanaged = 1;> = { 1 };
float3 TintColor : register(ps_2_0, c2) : register(ps_3_0, c2) <bool unmanaged = 1;> = { 1, 1, 1 };
float3 EyePosition : register(vs_3_0, c123) : register(ps_3_0, c123) <bool unmanaged = 1;>;
column_major float4x4 ViewProjection : register(vs_2_0, c119) : register(vs_3_0, c119) <bool unmanaged = 1;>;
float4 WorldBones[128] : register(vs_2_0, c128) : register(vs_3_0, c128) <bool unmanaged = 1;>;
bool HasShadow <string UIWidget = "None"; string SasBindAddress = "Sas.HasShadow";>;
texture ShadowMap <string UIWidget = "None"; string SasBindAddress = "Sas.Shadow[0].ShadowMap";>; 
sampler2D ShadowMapSampler : register(ps_3_0, s0) <string Texture = "ShadowMap"; string UIWidget = "None"; string SasBindAddress = "Sas.Shadow[0].ShadowMap";> =
sampler_state
{
    Texture = <ShadowMap>; 
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 0;
    AddressU = 3;
    AddressV = 3;
};
float4 Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize : register(ps_3_0, c11) <string UIWidget = "None"; string SasBindAddress = "Sas.Shadow[0].Zero_Zero_OneOverMapSize_OneOverMapSize";>;
float2 MapCellSize <string UIWidget = "None"; string SasBindAddress = "Terrain.Map.CellSize";> = { 10, 10 };
texture MacroSampler <string UIWidget = "None"; string SasBindAddress = "Terrain.MacroTexture"; string ResourceName = "ShaderPreviewMacro.dds";>; 
sampler2D MacroSamplerSampler <string Texture = "MacroSampler"; string UIWidget = "None"; string SasBindAddress = "Terrain.MacroTexture"; string ResourceName = "ShaderPreviewMacro.dds";> =
sampler_state
{
    Texture = <MacroSampler>; 
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 2;
    AddressU = 1;
    AddressV = 1;
};
int _SasGlobal : SasGlobal <string UIWidget = "None"; int3 SasVersion = int3(1, 0, 0); int MaxLocalLights = 8; int MaxSupportedInstancingMode = 1;>;
int NumJointsPerVertex <string UIWidget = "None"; string SasBindAddress = "Sas.Skeleton.NumJointsPerVertex";>;
column_major float4x3 World : World : register(vs_2_0, c124) : register(vs_3_0, c124);
texture CloudTexture <string UIWidget = "None"; string SasBindAddress = "Terrain.Cloud.Texture"; string ResourceName = "ShaderPreviewCloud.dds";>; 
sampler2D CloudTextureSampler <string Texture = "CloudTexture"; string UIWidget = "None"; string SasBindAddress = "Terrain.Cloud.Texture"; string ResourceName = "ShaderPreviewCloud.dds";> =
sampler_state
{
    Texture = <CloudTexture>; 
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 2;
    AddressU = 1;
    AddressV = 1;
};
texture EnvironmentTexture <string UIWidget = "None"; string SasBindAddress = "Objects.LightSpaceEnvironmentMap"; string ResourceType = "Cube";>; 
samplerCUBE EnvironmentTextureSampler <string Texture = "EnvironmentTexture"; string UIWidget = "None"; string SasBindAddress = "Objects.LightSpaceEnvironmentMap"; string ResourceType = "Cube";> =
sampler_state
{
    Texture = <EnvironmentTexture>; 
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 2;
    AddressU = 3;
    AddressV = 3;
    AddressW = 3;
};
texture DiffuseTexture <string UIName = "Diffuse Texture";>; 
sampler2D DiffuseTextureSampler : register(ps_2_0, s0) <string Texture = "DiffuseTexture"; string UIName = "Diffuse Texture";> =
sampler_state
{
    Texture = <DiffuseTexture>; 
    MinFilter = 3;
    MagFilter = 2;
    MipFilter = 2;
    MaxAnisotropy = 8;
    AddressU = 1;
    AddressV = 1;
};
texture NormalMap <string UIName = "Normal Texture";>; 
sampler2D NormalMapSampler <string Texture = "NormalMap"; string UIName = "Normal Texture";> =
sampler_state
{
    Texture = <NormalMap>; 
    MinFilter = 3;
    MagFilter = 2;
    MipFilter = 2;
    MaxAnisotropy = 8;
    AddressU = 1;
    AddressV = 1;
};
texture SpecMap <string UIName = "Specular Map";>; 
sampler2D SpecMapSampler : register(ps_2_0, s1) <string Texture = "SpecMap"; string UIName = "Specular Map";> =
sampler_state
{
    Texture = <SpecMap>; 
    MinFilter = 3;
    MagFilter = 2;
    MipFilter = 2;
    MaxAnisotropy = 8;
    AddressU = 1;
    AddressV = 1;
};
float EnvMult <string UIName = "Reflection Multiplier"; string UIWidget = "Slider"; float UIMax = 1; float UIMin = 0; float UIStep = 0.01;> = { 1 };
bool AlphaTestEnable <string UIName = "Alpha Test Enable";>;
struct
{
    float4 ScaleUV_OffsetUV;
} Shroud : register(vs_2_0, c11) : register(vs_3_0, c11) <string UIWidget = "None"; string SasBindAddress = "Terrain.Shroud";> = { 1, 1, 0, 0 };
texture ShroudTexture <string UIWidget = "None"; string SasBindAddress = "Terrain.Shroud.Texture";>; 
sampler2D ShroudTextureSampler <string Texture = "ShroudTexture"; string UIWidget = "None"; string SasBindAddress = "Terrain.Shroud.Texture";> =
sampler_state
{
    Texture = <ShroudTexture>; 
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 2;
    AddressU = 3;
    AddressV = 3;
};
float Time : Time;

struct VS_H_Array_Shader_0_Input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 tangent : TANGENT;
    float4 binormal : BINORMAL;
    float4 texcoord : TEXCOORD;
    float4 color : COLOR;
};

struct VS_H_Array_Shader_0_Output
{
    float4 position : POSITION;
    float4 texcoord : TEXCOORD;
    float3 texcoord1 : TEXCOORD1;
    float3 texcoord2 : TEXCOORD2;
    float3 texcoord3 : TEXCOORD3;
    float3 texcoord4 : TEXCOORD4;
    float4 texcoord5 : TEXCOORD5;
    float4 texcoord6 : TEXCOORD6;
    float4 color : COLOR;
};

VS_H_Array_Shader_0_Output VS_H_Array_Shader_0(VS_H_Array_Shader_0_Input i)  //no bone skin
{
    VS_H_Array_Shader_0_Output o;
    float4 temp0, temp1;
    temp0.x = dot(i.normal.xyz, (World._m00_m10_m20_m30).xyz);
    temp0.y = dot(i.normal.xyz, (World._m01_m11_m21_m31).xyz);
    temp0.z = dot(i.normal.xyz, (World._m02_m12_m22_m32).xyz);
    temp0.w = dot(temp0.xyz, DirectionalLight[2].Direction.xyz);
    o.texcoord1.z = temp0.x;
    o.texcoord2.z = temp0.y;
    o.texcoord3.z = temp0.z;
    temp0.x = max(temp0.w, float1(0));
    temp0.xyz = temp0.xxx * DirectionalLight[2].Color.xyz;
    temp1.z = float1(0.1);
    temp0.xyz = AmbientLightColor.xyz * temp1.zzz + temp0.xyz;
    temp0.xyz = temp0.xyz * i.color.xyz;
    temp0.w = OpacityOverride.x;
    temp1 = i.color.w * float4(0, 0, 0, 1) + float4(0.5, 0.5, 0.5, 0);
    o.color = temp0 * temp1;
    temp0 = i.position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
    temp1.z = dot(temp0, (World._m02_m12_m22_m32));
    temp1.w = float1(1);
    temp1.x = dot(temp0, (World._m00_m10_m20_m30));
    temp1.y = dot(temp0, (World._m01_m11_m21_m31));
    o.position.x = dot(temp1, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp1, (ViewProjection._m01_m11_m21_m31));
    o.position.z = dot(temp1, (ViewProjection._m02_m12_m22_m32));
    o.position.w = dot(temp1, (ViewProjection._m03_m13_m23_m33));
    temp0.xy = temp1.xy + Shroud.ScaleUV_OffsetUV.zw;
    o.texcoord6.xy = temp0.xy * Shroud.ScaleUV_OffsetUV.xy;
    temp0.xy = temp1.zz * Cloud.WorldPositionMultiplier_XYZZ.zw;
    temp0.xy = temp1.xy * Cloud.WorldPositionMultiplier_XYZZ.xy + -temp0.xy;
    o.texcoord6.zw = temp0.xy + Cloud.CurrentOffsetUV.xy;
    o.texcoord = i.texcoord.xyyx;
    temp0.x = dot(i.binormal.xyz, (World._m00_m10_m20_m30).xyz);
    o.texcoord1.x = -temp0.x;
    temp0.x = dot(i.tangent.xyz, (World._m00_m10_m20_m30).xyz);
    o.texcoord1.y = -temp0.x;
    temp0.x = dot(i.binormal.xyz, (World._m01_m11_m21_m31).xyz);
    o.texcoord2.x = -temp0.x;
    temp0.x = dot(i.tangent.xyz, (World._m01_m11_m21_m31).xyz);
    o.texcoord2.y = -temp0.x;
    temp0.x = dot(i.binormal.xyz, (World._m02_m12_m22_m32).xyz);
    o.texcoord3.x = -temp0.x;
    temp0.x = dot(i.tangent.xyz, (World._m02_m12_m22_m32).xyz);
    o.texcoord3.y = -temp0.x;
    o.texcoord4 = temp1;
    temp0.x = dot(temp1, (ShadowMapWorldToShadow._m03_m13_m23_m33));
    temp0.y = 1.0f / temp0.x;
    o.texcoord5.w = temp0.x;
    temp0.x = dot(temp1, (ShadowMapWorldToShadow._m00_m10_m20_m30));
    temp0.z = dot(temp1, (ShadowMapWorldToShadow._m01_m11_m21_m31));
    temp0.w = dot(temp1, (ShadowMapWorldToShadow._m02_m12_m22_m32));
    o.texcoord5.xyz = temp0.xzw * temp0.yyy + float3(0, 0, -0.0015);

    return o;
}


struct VS_H_Array_Shader_1_Input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 tangent : TANGENT;
    float4 binormal : BINORMAL;
    float4 blendindices : BLENDINDICES;
    float4 texcoord : TEXCOORD;
    float4 color : COLOR;
};

struct VS_H_Array_Shader_1_Output
{
    float4 position : POSITION;
    float4 texcoord : TEXCOORD;
    float3 texcoord1 : TEXCOORD1;
    float3 texcoord2 : TEXCOORD2;
    float3 texcoord3 : TEXCOORD3;
    float3 texcoord4 : TEXCOORD4;
    float4 texcoord5 : TEXCOORD5;
    float4 texcoord6 : TEXCOORD6;
    float4 color : COLOR;
};

VS_H_Array_Shader_1_Output VS_H_Array_Shader_1(VS_H_Array_Shader_1_Input i)  //have bones skin
{
    VS_H_Array_Shader_1_Output o;
    float4 temp0, temp1, temp2, temp3, temp4;
    float addr0;
    temp0.x = (i.blendindices.x < -i.blendindices.x) ? 1 : 0;
    temp0.y = frac(i.blendindices.x);
    temp0.z = -temp0.y + i.blendindices.x;
    temp0.y = (-temp0.y < temp0.y) ? 1 : 0;
    temp0.x = temp0.x * temp0.y + temp0.z;
    temp0.x = temp0.x + temp0.x;
    addr0.x = temp0.x;
    temp0.w = i.color.w * WorldBones[1 + addr0.x].w;
    temp1.w = OpacityOverride.x;
    temp0.xyz = float3(0.5, 0.5, 0.5);
    temp2.x = i.blendindices.x + i.blendindices.x;
    temp2.y = frac(temp2.x);
    temp2.z = temp2.x + -temp2.y;
    temp2.y = (-temp2.y < temp2.y) ? 1 : 0;
    temp2.x = (temp2.x < -temp2.x) ? 1 : 0;
    temp2.x = temp2.x * temp2.y + temp2.z;
    addr0.x = temp2.x;
    temp2 = i.normal.zxyy * WorldBones[0 + addr0.x].yzxy;
    temp2 = WorldBones[0 + addr0.x].wwwx * i.normal.xyzx + temp2;
    temp3 = i.normal.yzxz * WorldBones[0 + addr0.x].zxyz;
    temp2 = temp2 * float4(1, 1, 1, -1) + -temp3;
    temp3.xyz = temp2.www * WorldBones[0 + addr0.x].xyz;
    temp3.xyz = WorldBones[0 + addr0.x].www * temp2.xyz + -temp3.xyz;
    temp3.xyz = WorldBones[0 + addr0.x].yzx * temp2.zxy + temp3.xyz;
    temp2.xyz = WorldBones[0 + addr0.x].zxy * -temp2.yzx + temp3.xyz;
    temp2.w = dot(temp2.xyz, DirectionalLight[2].Direction.xyz);
    temp2.w = max(temp2.w, float1(0));
    temp3.xyz = temp2.www * DirectionalLight[2].Color.xyz;
    temp2.w = float1(0.1);
    temp3.xyz = AmbientLightColor.xyz * temp2.www + temp3.xyz;
    temp1.xyz = temp3.xyz * i.color.xyz;
    o.color = temp0 * temp1;
    temp0 = i.position.zxyy * WorldBones[0 + addr0.x].yzxy;
    temp0 = WorldBones[0 + addr0.x].wwwx * i.position.xyzx + temp0;
    temp1 = i.position.yzxz * WorldBones[0 + addr0.x].zxyz;
    temp0 = temp0 * float4(1, 1, 1, -1) + -temp1;
    temp1.xyz = temp0.www * WorldBones[0 + addr0.x].xyz;
    temp1.xyz = WorldBones[0 + addr0.x].www * temp0.xyz + -temp1.xyz;
    temp1.xyz = WorldBones[0 + addr0.x].yzx * temp0.zxy + temp1.xyz;
    temp0.xyz = WorldBones[0 + addr0.x].zxy * -temp0.yzx + temp1.xyz;
    temp0.xyz = temp0.xyz + WorldBones[1 + addr0.x].xyz;
    temp0.w = float1(1);
    o.position.x = dot(temp0, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp0, (ViewProjection._m01_m11_m21_m31));
    o.position.z = dot(temp0, (ViewProjection._m02_m12_m22_m32));
    o.position.w = dot(temp0, (ViewProjection._m03_m13_m23_m33));
    temp1.xy = temp0.xy + Shroud.ScaleUV_OffsetUV.zw;
    o.texcoord6.xy = temp1.xy * Shroud.ScaleUV_OffsetUV.xy;
    temp1.xy = temp0.zz * Cloud.WorldPositionMultiplier_XYZZ.zw;
    temp1.xy = temp0.xy * Cloud.WorldPositionMultiplier_XYZZ.xy + -temp1.xy;
    o.texcoord6.zw = temp1.xy + Cloud.CurrentOffsetUV.xy;
    o.texcoord = i.texcoord.xyyx;
    temp1 = i.binormal.zxyy * WorldBones[0 + addr0.x].yzxy;
    temp1 = WorldBones[0 + addr0.x].wwwx * i.binormal.xyzx + temp1;
    temp3 = i.binormal.yzxz * WorldBones[0 + addr0.x].zxyz;
    temp1 = temp1 * float4(1, 1, 1, -1) + -temp3;
    temp3.xyz = temp1.www * WorldBones[0 + addr0.x].xyz;
    temp3.xyz = WorldBones[0 + addr0.x].www * temp1.xyz + -temp3.xyz;
    temp3.xyz = WorldBones[0 + addr0.x].yzx * temp1.zxy + temp3.xyz;
    temp1.xyz = WorldBones[0 + addr0.x].zxy * -temp1.yzx + temp3.xyz;
    o.texcoord1.x = -temp1.x;
    temp3 = i.tangent.zxyy * WorldBones[0 + addr0.x].yzxy;
    temp3 = WorldBones[0 + addr0.x].wwwx * i.tangent.xyzx + temp3;
    temp4 = i.tangent.yzxz * WorldBones[0 + addr0.x].zxyz;
    temp3 = temp3 * float4(1, 1, 1, -1) + -temp4;
    temp4.xyz = temp3.www * WorldBones[0 + addr0.x].xyz;
    temp4.xyz = WorldBones[0 + addr0.x].www * temp3.xyz + -temp4.xyz;
    temp4.xyz = WorldBones[0 + addr0.x].yzx * temp3.zxy + temp4.xyz;
    temp3.xyz = WorldBones[0 + addr0.x].zxy * -temp3.yzx + temp4.xyz;
    o.texcoord1.y = -temp3.x;
    o.texcoord1.z = temp2.x;
    o.texcoord2.x = -temp1.y;
    o.texcoord3.x = -temp1.z;
    o.texcoord2.y = -temp3.y;
    o.texcoord3.y = -temp3.z;
    o.texcoord2.z = temp2.y;
    o.texcoord3.z = temp2.z;
    o.texcoord4 = temp0;
    temp1.x = dot(temp0, (ShadowMapWorldToShadow._m00_m10_m20_m30));
    temp1.y = dot(temp0, (ShadowMapWorldToShadow._m01_m11_m21_m31));
    temp1.z = dot(temp0, (ShadowMapWorldToShadow._m02_m12_m22_m32));
    temp0.x = dot(temp0, (ShadowMapWorldToShadow._m03_m13_m23_m33));
    temp0.y = 1.0f / temp0.x;
    o.texcoord5.w = temp0.x;
    o.texcoord5.xyz = temp1.xyz * temp0.yyy + float3(0, 0, -0.0015);

    return o;
}

VertexShader VS_H_Array[2] = {
    compile vs_3_0 VS_H_Array_Shader_0(), 
    compile vs_3_0 VS_H_Array_Shader_1(), 
};

struct PS_H_Array_Shader_0_Input
{
    float2 texcoord : TEXCOORD;
    float3 texcoord1 : TEXCOORD1;
    float3 texcoord2 : TEXCOORD2;
    float3 texcoord3 : TEXCOORD3;
    float3 texcoord4 : TEXCOORD4;
    float4 texcoord6 : TEXCOORD6;
    float4 color : COLOR;
};

float4 PS_H_Array_Shader_0(PS_H_Array_Shader_0_Input i) : COLOR //no hc no shadow

{
    float4 out_color;
    float4 temp0, temp1, temp2, temp3, temp4, temp5, temp6;
    float3 temp7, tempglow ; //add glow
    float2 temp8;
    temp0.xyz = EyePosition.xyz + -i.texcoord4.xyz;
    temp1.xyz = normalize(temp0.xyz).xyz;
    temp0 = tex2D(DiffuseTextureSampler, i.texcoord.xy);
    temp2.x = log2(temp0.x);
    temp2.y = log2(temp0.y);
    temp2.z = log2(temp0.z);
    temp0.xyz = temp2.xyz * float3(2.2, 2.2, 2.2);
    temp2.x = exp2(temp0.x);
    temp2.y = exp2(temp0.y);
    temp2.z = exp2(temp0.z);
    temp3 = tex2D(NormalMapSampler, i.texcoord.xy);
    temp0.xyz = temp3.xyz * float3(2, 2, 0) + float3(-1, -1, 1);
//  temp0.xyz = temp0.xyz * float3(1.5, 1.5, 1);
//    temp0.z = sqrt(1 - dot(temp0.xy, temp0.xy));

    temp3.x = dot(temp0.xyz, i.texcoord1.xyz);
    temp3.y = dot(temp0.xyz, i.texcoord2.xyz);
    temp3.z = dot(temp0.xyz, i.texcoord3.xyz);
    temp0.xyz = normalize(temp3.xyz).xyz;
    temp3 = tex2D(SpecMapSampler, i.texcoord.xy);
    tempglow.xyz = temp3.yyy * RecolorColor.xyz ; //add hc zero
    temp1.w = dot(temp1.xyz, temp0.xyz);
    temp1.w = temp1.w + temp1.w;
    temp1.xyz = temp0.xyz * -temp1.www + temp1.xyz;
    temp1.xyz = -temp1.xyz;
    temp1 = texCUBE(EnvironmentTextureSampler, temp1.xyz);
    temp1.xyz = temp1.xyz * DirectionalLight[0].Color.xyz;
    temp1.xyz = temp3.xxx * temp1.xyz;
    temp1.xyz = temp2.xyz * i.color.xyz + temp1.xyz;
    temp3 = tex2D(CloudTextureSampler, i.texcoord6.zw);
    temp4.x = log2(temp3.x);
    temp4.y = log2(temp3.y);
    temp4.z = log2(temp3.z);
    temp3.xyz = temp4.xyz * float3(2.2, 2.2, 2.2);
    temp4.x = exp2(temp3.x);
    temp4.y = exp2(temp3.y);
    temp4.z = exp2(temp3.z);
    temp1.w = dot(temp0.xyz, DirectionalLight[0].Direction.xyz);
    temp2.w = max(temp1.w, float1(0));
    temp3.xyz = temp4.xyz * DirectionalLight[0].Color.xyz;
    temp4.xyz = temp2.xyz * temp2.www;
    temp1.xyz = temp3.xyz * temp4.xyz + temp1.xyz;
    temp1.w = dot(temp0.xyz, DirectionalLight[1].Direction.xyz);
    temp2.w = max(temp1.w, float1(0));
    temp3.xyz = temp2.xyz * temp2.www;
    temp1.xyz = DirectionalLight[1].Color.xyz * temp3.xyz + temp1.xyz;
    temp3.xyz = float3(0, 0, 0);
    temp1.w = float1(0);
    for (int it0 = 0; it0 < NumPointLights; ++it0) {
            temp4 = temp1.w + float4(-0, -1, -2, -3);
            temp5 = temp1.w + float4(-4, -5, -6, -7);
            temp6.x = float1(0);
            temp6.yzw = (-abs(temp4).xxx >= 0) ? PointLight[0].Color.xyz : temp6.xxx;
            temp7.xyz = (-abs(temp4).xxx >= 0) ? PointLight[0].Position.xyz : temp6.xxx;
            temp8.xy = (-abs(temp4).xx >= 0) ? PointLight[0].Range_Inner_Outer.xy : temp6.xx;
            temp6.xyz = (-abs(temp4).yyy >= 0) ? PointLight[1].Color.xyz : temp6.yzw;
            temp7.xyz = (-abs(temp4).yyy >= 0) ? PointLight[1].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp4).yy >= 0) ? PointLight[1].Range_Inner_Outer.xy : temp8.xy;
            temp6.xyz = (-abs(temp4).zzz >= 0) ? PointLight[2].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp4).zzz >= 0) ? PointLight[2].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp4).zz >= 0) ? PointLight[2].Range_Inner_Outer.xy : temp4.xy;
            temp6.xyz = (-abs(temp4).www >= 0) ? PointLight[3].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp4).www >= 0) ? PointLight[3].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp4).ww >= 0) ? PointLight[3].Range_Inner_Outer.xy : temp4.xy;
            temp6.xyz = (-abs(temp5).xxx >= 0) ? PointLight[4].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).xxx >= 0) ? PointLight[4].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp5).xx >= 0) ? PointLight[4].Range_Inner_Outer.xy : temp4.xy;
            temp6.xyz = (-abs(temp5).yyy >= 0) ? PointLight[5].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).yyy >= 0) ? PointLight[5].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp5).yy >= 0) ? PointLight[5].Range_Inner_Outer.xy : temp4.xy;
            temp6.xyz = (-abs(temp5).zzz >= 0) ? PointLight[6].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).zzz >= 0) ? PointLight[6].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp5).zz >= 0) ? PointLight[6].Range_Inner_Outer.xy : temp4.xy;
            temp5.xyz = (-abs(temp5).www >= 0) ? PointLight[7].Color.xyz : temp6.xyz;
            temp6.xyz = (-abs(temp5).www >= 0) ? PointLight[7].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp5).ww >= 0) ? PointLight[7].Range_Inner_Outer.xy : temp4.xy;
            temp6.xyz = temp6.xyz + -i.texcoord4.xyz;
            temp2.w = dot(temp6.xyz, temp6.xyz);
            temp2.w = 1 / sqrt(temp2.w);
            temp3.w = 1.0f / temp2.w;
            temp6.xyz = temp6.xyz * temp2.www;
            temp2.w = -temp4.x + temp3.w;
            temp3.w = -temp4.x + temp4.y;
            temp3.w = 1.0f / temp3.w;
            temp2.w = saturate(temp2.w * -temp3.w + float1(1));
            temp2.w = temp2.w * temp2.w;
            temp4.xyz = temp5.xyz * temp2.www;
            temp2.w = dot(temp0.xyz, temp6.xyz);
            temp3.w = max(temp2.w, float1(0));
            temp3.xyz = temp4.xyz * temp3.www + temp3.xyz;
            temp1.w = temp1.w + float1(1);
        }
    temp0.xyz = temp3.xyz * temp2.xyz + temp1.xyz;
    out_color.w = temp0.w * i.color.w;
    temp0.xyz = temp0.xyz * TintColor.xyz + tempglow.xyz; //add glow
    temp1 = tex2D(ShroudTextureSampler, i.texcoord6.xy);
    out_color.xyz = temp0.xyz * temp1.xyz;

    return out_color;
}


struct PS_H_Array_Shader_1_Input
{
    float2 texcoord : TEXCOORD;
    float3 texcoord1 : TEXCOORD1;
    float3 texcoord2 : TEXCOORD2;
    float3 texcoord3 : TEXCOORD3;
    float3 texcoord4 : TEXCOORD4;
    float3 texcoord5 : TEXCOORD5;
    float4 texcoord6 : TEXCOORD6;
    float4 color : COLOR;
};

float4 PS_H_Array_Shader_1(PS_H_Array_Shader_1_Input i) : COLOR //no hc shadow
{
    float4 out_color;
    float4 temp0, temp1, temp2, temp3, temp4, temp5, temp6;
    float3 temp7, tempglow ; //add glow
    float2 temp8;
    temp0.xyz = EyePosition.xyz + -i.texcoord4.xyz;
    temp1.xyz = normalize(temp0.xyz).xyz;
    temp0 = tex2D(DiffuseTextureSampler, i.texcoord.xy);
    temp2.x = log2(temp0.x);
    temp2.y = log2(temp0.y);
    temp2.z = log2(temp0.z);
    temp0.xyz = temp2.xyz * float3(2.2, 2.2, 2.2);
    temp2.x = exp2(temp0.x);
    temp2.y = exp2(temp0.y);
    temp2.z = exp2(temp0.z);
    temp3 = tex2D(NormalMapSampler, i.texcoord.xy);
    temp0.xyz = temp3.xyz * float3(2, 2, 0) + float3(-1, -1, 1);
//  temp0.xyz = temp0.xyz * float3(1.5, 1.5, 1);
//    temp0.z = sqrt(1 - dot(temp0.xy, temp0.xy));

    temp3.x = dot(temp0.xyz, i.texcoord1.xyz);
    temp3.y = dot(temp0.xyz, i.texcoord2.xyz);
    temp3.z = dot(temp0.xyz, i.texcoord3.xyz);
    temp0.xyz = normalize(temp3.xyz).xyz;
    temp3 = tex2D(ShadowMapSampler, i.texcoord5.xy);
    temp4.xy = Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.zx + i.texcoord5.xy;
    temp4 = tex2D(ShadowMapSampler, temp4.xy);
    temp4.yz = Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.yz + i.texcoord5.xy;
    temp5 = tex2D(ShadowMapSampler, temp4.yz);
    temp4.yz = Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.wz + i.texcoord5.xy;
    temp6 = tex2D(ShadowMapSampler, temp4.yz);
    temp3.y = temp4.x;
    temp3.z = temp5.x;
    temp3.w = temp6.x;
    temp3 = temp3 + -i.texcoord5.z;
    temp3 = (temp3 >= 0) ? float4(1, 1, 1, 1) : float4(0, 0, 0, 0);
    temp1.w = dot(float4(1, 1, 1, 1), temp3);
    temp1.w = temp1.w * float1(0.25);
    temp3 = tex2D(SpecMapSampler, i.texcoord.xy);
    tempglow.xyz = temp3.yyy * RecolorColor.xyz ; //add hc zero
    temp2.w = dot(temp1.xyz, temp0.xyz);
    temp2.w = temp2.w + temp2.w;
    temp1.xyz = temp0.xyz * -temp2.www + temp1.xyz;
    temp1.xyz = -temp1.xyz;
    temp4 = texCUBE(EnvironmentTextureSampler, temp1.xyz);
    temp1.xyz = temp4.xyz * DirectionalLight[0].Color.xyz;
    temp1.xyz = temp3.xxx * temp1.xyz;
    temp1.xyz = temp1.www * temp1.xyz;
    temp1.xyz = temp2.xyz * i.color.xyz + temp1.xyz;
    temp3 = tex2D(CloudTextureSampler, i.texcoord6.zw);
    temp4.x = log2(temp3.x);
    temp4.y = log2(temp3.y);
    temp4.z = log2(temp3.z);
    temp3.xyz = temp4.xyz * float3(2.2, 2.2, 2.2);
    temp4.x = exp2(temp3.x);
    temp4.y = exp2(temp3.y);
    temp4.z = exp2(temp3.z);
    temp3.xyz = temp1.www * temp4.xyz;
    temp1.w = dot(temp0.xyz, DirectionalLight[0].Direction.xyz);
    temp2.w = max(temp1.w, float1(0));
    temp3.xyz = temp3.xyz * DirectionalLight[0].Color.xyz;
    temp4.xyz = temp2.xyz * temp2.www;
    temp1.xyz = temp3.xyz * temp4.xyz + temp1.xyz;
    temp1.w = dot(temp0.xyz, DirectionalLight[1].Direction.xyz);
    temp2.w = max(temp1.w, float1(0));
    temp3.xyz = temp2.xyz * temp2.www;
    temp1.xyz = DirectionalLight[1].Color.xyz * temp3.xyz + temp1.xyz;
    temp3.xyz = float3(0, 0, 0);
    temp1.w = float1(0);
    for (int it0 = 0; it0 < NumPointLights; ++it0) {
            temp4 = temp1.w + float4(-0, -1, -2, -3);
            temp5 = temp1.w + float4(-4, -5, -6, -7);
            temp6.y = float1(0);
            temp6.xzw = (-abs(temp4).xxx >= 0) ? PointLight[0].Color.xyz : temp6.yyy;
            temp7.xyz = (-abs(temp4).xxx >= 0) ? PointLight[0].Position.xyz : temp6.yyy;
            temp8.xy = (-abs(temp4).xx >= 0) ? PointLight[0].Range_Inner_Outer.xy : temp6.yy;
            temp6.xyz = (-abs(temp4).yyy >= 0) ? PointLight[1].Color.xyz : temp6.xzw;
            temp7.xyz = (-abs(temp4).yyy >= 0) ? PointLight[1].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp4).yy >= 0) ? PointLight[1].Range_Inner_Outer.xy : temp8.xy;
            temp6.xyz = (-abs(temp4).zzz >= 0) ? PointLight[2].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp4).zzz >= 0) ? PointLight[2].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp4).zz >= 0) ? PointLight[2].Range_Inner_Outer.xy : temp4.xy;
            temp6.xyz = (-abs(temp4).www >= 0) ? PointLight[3].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp4).www >= 0) ? PointLight[3].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp4).ww >= 0) ? PointLight[3].Range_Inner_Outer.xy : temp4.xy;
            temp6.xyz = (-abs(temp5).xxx >= 0) ? PointLight[4].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).xxx >= 0) ? PointLight[4].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp5).xx >= 0) ? PointLight[4].Range_Inner_Outer.xy : temp4.xy;
            temp6.xyz = (-abs(temp5).yyy >= 0) ? PointLight[5].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).yyy >= 0) ? PointLight[5].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp5).yy >= 0) ? PointLight[5].Range_Inner_Outer.xy : temp4.xy;
            temp6.xyz = (-abs(temp5).zzz >= 0) ? PointLight[6].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).zzz >= 0) ? PointLight[6].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp5).zz >= 0) ? PointLight[6].Range_Inner_Outer.xy : temp4.xy;
            temp5.xyz = (-abs(temp5).www >= 0) ? PointLight[7].Color.xyz : temp6.xyz;
            temp6.xyz = (-abs(temp5).www >= 0) ? PointLight[7].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp5).ww >= 0) ? PointLight[7].Range_Inner_Outer.xy : temp4.xy;
            temp6.xyz = temp6.xyz + -i.texcoord4.xyz;
            temp2.w = dot(temp6.xyz, temp6.xyz);
            temp2.w = 1 / sqrt(temp2.w);
            temp3.w = 1.0f / temp2.w;
            temp6.xyz = temp6.xyz * temp2.www;
            temp2.w = -temp4.x + temp3.w;
            temp3.w = -temp4.x + temp4.y;
            temp3.w = 1.0f / temp3.w;
            temp2.w = saturate(temp2.w * -temp3.w + float1(1));
            temp2.w = temp2.w * temp2.w;
            temp4.xyz = temp5.xyz * temp2.www;
            temp2.w = dot(temp0.xyz, temp6.xyz);
            temp3.w = max(temp2.w, float1(0));
            temp3.xyz = temp4.xyz * temp3.www + temp3.xyz;
            temp1.w = temp1.w + float1(1);
        }
    temp0.xyz = temp3.xyz * temp2.xyz + temp1.xyz;
    out_color.w = temp0.w * i.color.w;
    temp0.xyz = temp0.xyz * TintColor.xyz + tempglow.xyz; //add glow
    temp1 = tex2D(ShroudTextureSampler, i.texcoord6.xy);
    out_color.xyz = temp0.xyz * temp1.xyz;

    return out_color;
}


struct PS_H_Array_Shader_2_Input
{
    float2 texcoord : TEXCOORD;
    float3 texcoord1 : TEXCOORD1;
    float3 texcoord2 : TEXCOORD2;
    float3 texcoord3 : TEXCOORD3;
    float3 texcoord4 : TEXCOORD4;
    float4 texcoord6 : TEXCOORD6;
    float4 color : COLOR;
};

float4 PS_H_Array_Shader_2(PS_H_Array_Shader_2_Input i) : COLOR //hc sun
{
    float4 out_color;
    float4 temp0, temp1, temp2, temp3, temp4, temp5;
    float3 temp6, temp7, tempglow ; //add glow
    float2 temp8;
    temp0.xyz = EyePosition.xyz + -i.texcoord4.xyz;
    temp1.xyz = normalize(temp0.xyz).xyz;
    temp0 = tex2D(DiffuseTextureSampler, i.texcoord.xy);
    temp2 = tex2D(SpecMapSampler, i.texcoord.xy);
    tempglow.xyz = temp2.yyy * RecolorColor.xyz ; //glow channel
    temp3.xyz = temp0.xyz * RecolorColor.xyz;
//    temp3.xyz = temp0.xyz * RecolorColor.xyz + -temp0.xyz;  //fixed bloom
    temp3.xyz = temp3.xyz  + -temp0.xyz;
    temp0.xyz = temp2.zzz * temp3.xyz + temp0.xyz;
    temp2.y = log2(temp0.x);
    temp2.z = log2(temp0.y);
    temp2.w = log2(temp0.z);
    temp0.xyz = temp2.yzw * float3(2.2, 2.2, 2.2);
    temp2.y = exp2(temp0.x);
    temp2.z = exp2(temp0.y);
    temp2.w = exp2(temp0.z);

    temp3 = tex2D(NormalMapSampler, i.texcoord.xy);
    temp0.xyz = temp3.xyz * float3(2, 2, 0) + float3(-1, -1, 1);
//  temp0.xyz = temp0.xyz * float3(1.5, 1.5, 1);
//    temp0.z = sqrt(1 - dot(temp0.xy, temp0.xy));

    temp3.x = dot(temp0.xyz, i.texcoord1.xyz);
    temp3.y = dot(temp0.xyz, i.texcoord2.xyz);
    temp3.z = dot(temp0.xyz, i.texcoord3.xyz);
    temp0.xyz = normalize(temp3.xyz).xyz;
    temp1.w = dot(temp1.xyz, temp0.xyz);
    temp1.w = temp1.w + temp1.w;
    temp1.xyz = temp0.xyz * -temp1.www + temp1.xyz;
    temp1.xyz = -temp1.xyz;
    temp1 = texCUBE(EnvironmentTextureSampler, temp1.xyz);
    temp1.xyz = temp1.xyz * DirectionalLight[0].Color.xyz;
    temp1.xyz = temp2.xxx * temp1.xyz;
    temp1.xyz = temp2.yzw * i.color.xyz + temp1.xyz;
    temp3 = tex2D(CloudTextureSampler, i.texcoord6.zw);
    temp4.x = log2(temp3.x);
    temp4.y = log2(temp3.y);
    temp4.z = log2(temp3.z);
    temp3.xyz = temp4.xyz * float3(2.2, 2.2, 2.2);
    temp4.x = exp2(temp3.x);
    temp4.y = exp2(temp3.y);
    temp4.z = exp2(temp3.z);
    temp1.w = dot(temp0.xyz, DirectionalLight[0].Direction.xyz);
    temp2.x = max(temp1.w, float1(0));
    temp3.xyz = temp4.xyz * DirectionalLight[0].Color.xyz;
    temp4.xyz = temp2.yzw * temp2.xxx;
    temp1.xyz = temp3.xyz * temp4.xyz + temp1.xyz;
    temp1.w = dot(temp0.xyz, DirectionalLight[1].Direction.xyz);
    temp2.x = max(temp1.w, float1(0));
    temp3.xyz = temp2.yzw * temp2.xxx;
    temp1.xyz = DirectionalLight[1].Color.xyz * temp3.xyz + temp1.xyz;
    temp3.xyz = float3(0, 0, 0);
    temp1.w = float1(0);
    for (int it0 = 0; it0 < NumPointLights; ++it0) {
            temp4 = temp1.w + float4(-0, -1, -2, -3);
            temp5 = temp1.w + float4(-4, -5, -6, -7);
            temp2.x = float1(0);
            temp6.xyz = (-abs(temp4).xxx >= 0) ? PointLight[0].Color.xyz : temp2.xxx;
            temp7.xyz = (-abs(temp4).xxx >= 0) ? PointLight[0].Position.xyz : temp2.xxx;
            temp8.xy = (-abs(temp4).xx >= 0) ? PointLight[0].Range_Inner_Outer.xy : temp2.xx;
            temp6.xyz = (-abs(temp4).yyy >= 0) ? PointLight[1].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp4).yyy >= 0) ? PointLight[1].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp4).yy >= 0) ? PointLight[1].Range_Inner_Outer.xy : temp8.xy;
            temp6.xyz = (-abs(temp4).zzz >= 0) ? PointLight[2].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp4).zzz >= 0) ? PointLight[2].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp4).zz >= 0) ? PointLight[2].Range_Inner_Outer.xy : temp4.xy;
            temp6.xyz = (-abs(temp4).www >= 0) ? PointLight[3].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp4).www >= 0) ? PointLight[3].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp4).ww >= 0) ? PointLight[3].Range_Inner_Outer.xy : temp4.xy;
            temp6.xyz = (-abs(temp5).xxx >= 0) ? PointLight[4].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).xxx >= 0) ? PointLight[4].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp5).xx >= 0) ? PointLight[4].Range_Inner_Outer.xy : temp4.xy;
            temp6.xyz = (-abs(temp5).yyy >= 0) ? PointLight[5].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).yyy >= 0) ? PointLight[5].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp5).yy >= 0) ? PointLight[5].Range_Inner_Outer.xy : temp4.xy;
            temp6.xyz = (-abs(temp5).zzz >= 0) ? PointLight[6].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).zzz >= 0) ? PointLight[6].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp5).zz >= 0) ? PointLight[6].Range_Inner_Outer.xy : temp4.xy;
            temp5.xyz = (-abs(temp5).www >= 0) ? PointLight[7].Color.xyz : temp6.xyz;
            temp6.xyz = (-abs(temp5).www >= 0) ? PointLight[7].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp5).ww >= 0) ? PointLight[7].Range_Inner_Outer.xy : temp4.xy;
            temp6.xyz = temp6.xyz + -i.texcoord4.xyz;
            temp2.x = dot(temp6.xyz, temp6.xyz);
            temp2.x = 1 / sqrt(temp2.x);
            temp3.w = 1.0f / temp2.x;
            temp6.xyz = temp6.xyz * temp2.xxx;
            temp2.x = -temp4.x + temp3.w;
            temp3.w = -temp4.x + temp4.y;
            temp3.w = 1.0f / temp3.w;
            temp2.x = saturate(temp2.x * -temp3.w + float1(1));
            temp2.x = temp2.x * temp2.x;
            temp4.xyz = temp5.xyz * temp2.xxx;
            temp2.x = dot(temp0.xyz, temp6.xyz);
            temp3.w = max(temp2.x, float1(0));
            temp3.xyz = temp4.xyz * temp3.www + temp3.xyz;
            temp1.w = temp1.w + float1(1);
        }
    temp0.xyz = temp3.xyz * temp2.yzw + temp1.xyz;
    out_color.w = temp0.w * i.color.w;
    temp0.xyz = temp0.xyz * TintColor.xyz;
    temp1 = tex2D(ShroudTextureSampler, i.texcoord6.xy);
    out_color.xyz = temp0.xyz * temp1.xyz  + tempglow.xyz; //add glow

    return out_color;
}


struct PS_H_Array_Shader_3_Input
{
    float2 texcoord : TEXCOORD;
    float3 texcoord1 : TEXCOORD1;
    float3 texcoord2 : TEXCOORD2;
    float3 texcoord3 : TEXCOORD3;
    float3 texcoord4 : TEXCOORD4;
    float3 texcoord5 : TEXCOORD5;
    float4 texcoord6 : TEXCOORD6;
    float4 color : COLOR;
};

float4 PS_H_Array_Shader_3(PS_H_Array_Shader_3_Input i) : COLOR //hc shadow (the only useful one)
{
    float4 out_color;
    float4 temp0, temp1, temp2, temp3, temp4, temp5, temp6;
    float3 temp7, tempglow ; //add glow
    float2 temp8;
    temp0.xyz = EyePosition.xyz + -i.texcoord4.xyz;
    temp1.xyz = normalize(temp0.xyz).xyz;
    temp0 = tex2D(DiffuseTextureSampler, i.texcoord.xy);
    temp2 = tex2D(SpecMapSampler, i.texcoord.xy);
    tempglow.xyz = temp2.yyy * RecolorColor.xyz ; //glow channel
    temp3.xyz = temp0.xyz * RecolorColor.xyz;
//    temp3.xyz = temp0.xyz * RecolorColor.xyz + -temp0.xyz;  //fixed bloom
    temp3.xyz = temp3.xyz + -temp0.xyz;
    temp0.xyz = temp2.zzz * temp3.xyz + temp0.xyz;
    temp2.y = log2(temp0.x);
    temp2.z = log2(temp0.y);
    temp2.w = log2(temp0.z);
    temp0.xyz = temp2.yzw * float3(2.2, 2.2, 2.2);
    temp2.y = exp2(temp0.x);
    temp2.z = exp2(temp0.y);
    temp2.w = exp2(temp0.z);

    temp3 = tex2D(NormalMapSampler, i.texcoord.xy);
    temp0.xyz = temp3.xyz * float3(2, 2, 0) + float3(-1, -1, 1);
//  temp0.xyz = temp0.xyz * float3(1.5, 1.5, 1);
//  temp0.z = sqrt(1 - dot(temp0.xy, temp0.xy)); //normal fix

    temp3.x = dot(temp0.xyz, i.texcoord1.xyz);
    temp3.y = dot(temp0.xyz, i.texcoord2.xyz);
    temp3.z = dot(temp0.xyz, i.texcoord3.xyz);
    temp0.xyz = normalize(temp3.xyz).xyz;
    temp3 = tex2D(ShadowMapSampler, i.texcoord5.xy);
    temp4.xy = Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.zx + i.texcoord5.xy;
    temp4 = tex2D(ShadowMapSampler, temp4.xy);
    temp4.yz = Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.yz + i.texcoord5.xy;
    temp5 = tex2D(ShadowMapSampler, temp4.yz);
    temp4.yz = Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.wz + i.texcoord5.xy;
    temp6 = tex2D(ShadowMapSampler, temp4.yz);
    temp3.y = temp4.x;
    temp3.z = temp5.x;
    temp3.w = temp6.x;
    temp3 = temp3 + -i.texcoord5.z;
    temp3 = (temp3 >= 0) ? float4(1, 1, 1, 1) : float4(0, 0, 0, 0);
    temp1.w = dot(float4(1, 1, 1, 1), temp3);
    temp1.w = temp1.w * float1(0.25);
    temp3.x = dot(temp1.xyz, temp0.xyz);
    temp3.x = temp3.x + temp3.x;
    temp1.xyz = temp0.xyz * -temp3.xxx + temp1.xyz;
    temp1.xyz = -temp1.xyz;
    temp3 = texCUBE(EnvironmentTextureSampler, temp1.xyz);
    temp1.xyz = temp3.xyz * DirectionalLight[0].Color.xyz;
    temp1.xyz = temp2.xxx * temp1.xyz;
    temp1.xyz = temp1.www * temp1.xyz;
    temp1.xyz = temp2.yzw * i.color.xyz + temp1.xyz;
    temp3 = tex2D(CloudTextureSampler, i.texcoord6.zw);
    temp4.x = log2(temp3.x);
    temp4.y = log2(temp3.y);
    temp4.z = log2(temp3.z);
    temp3.xyz = temp4.xyz * float3(2.2, 2.2, 2.2);
    temp4.x = exp2(temp3.x);
    temp4.y = exp2(temp3.y);
    temp4.z = exp2(temp3.z);
    temp3.xyz = temp1.www * temp4.xyz;
    temp1.w = dot(temp0.xyz, DirectionalLight[0].Direction.xyz);
    temp2.x = max(temp1.w, float1(0));
    temp3.xyz = temp3.xyz * DirectionalLight[0].Color.xyz;
    temp4.xyz = temp2.yzw * temp2.xxx;
    temp1.xyz = temp3.xyz * temp4.xyz + temp1.xyz;
    temp1.w = dot(temp0.xyz, DirectionalLight[1].Direction.xyz);
    temp2.x = max(temp1.w, float1(0));
    temp3.xyz = temp2.yzw * temp2.xxx;
    temp1.xyz = DirectionalLight[1].Color.xyz * temp3.xyz + temp1.xyz;
    temp3.xyz = float3(0, 0, 0);
    temp1.w = float1(0);
    for (int it0 = 0; it0 < NumPointLights; ++it0) {
            temp4 = temp1.w + float4(-0, -1, -2, -3);
            temp5 = temp1.w + float4(-4, -5, -6, -7);
            temp6.y = float1(0);
            temp6.xzw = (-abs(temp4).xxx >= 0) ? PointLight[0].Color.xyz : temp6.yyy;
            temp7.xyz = (-abs(temp4).xxx >= 0) ? PointLight[0].Position.xyz : temp6.yyy;
            temp8.xy = (-abs(temp4).xx >= 0) ? PointLight[0].Range_Inner_Outer.xy : temp6.yy;
            temp6.xyz = (-abs(temp4).yyy >= 0) ? PointLight[1].Color.xyz : temp6.xzw;
            temp7.xyz = (-abs(temp4).yyy >= 0) ? PointLight[1].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp4).yy >= 0) ? PointLight[1].Range_Inner_Outer.xy : temp8.xy;
            temp6.xyz = (-abs(temp4).zzz >= 0) ? PointLight[2].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp4).zzz >= 0) ? PointLight[2].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp4).zz >= 0) ? PointLight[2].Range_Inner_Outer.xy : temp4.xy;
            temp6.xyz = (-abs(temp4).www >= 0) ? PointLight[3].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp4).www >= 0) ? PointLight[3].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp4).ww >= 0) ? PointLight[3].Range_Inner_Outer.xy : temp4.xy;
            temp6.xyz = (-abs(temp5).xxx >= 0) ? PointLight[4].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).xxx >= 0) ? PointLight[4].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp5).xx >= 0) ? PointLight[4].Range_Inner_Outer.xy : temp4.xy;
            temp6.xyz = (-abs(temp5).yyy >= 0) ? PointLight[5].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).yyy >= 0) ? PointLight[5].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp5).yy >= 0) ? PointLight[5].Range_Inner_Outer.xy : temp4.xy;
            temp6.xyz = (-abs(temp5).zzz >= 0) ? PointLight[6].Color.xyz : temp6.xyz;
            temp7.xyz = (-abs(temp5).zzz >= 0) ? PointLight[6].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp5).zz >= 0) ? PointLight[6].Range_Inner_Outer.xy : temp4.xy;
            temp5.xyz = (-abs(temp5).www >= 0) ? PointLight[7].Color.xyz : temp6.xyz;
            temp6.xyz = (-abs(temp5).www >= 0) ? PointLight[7].Position.xyz : temp7.xyz;
            temp4.xy = (-abs(temp5).ww >= 0) ? PointLight[7].Range_Inner_Outer.xy : temp4.xy;
            temp6.xyz = temp6.xyz + -i.texcoord4.xyz;
            temp2.x = dot(temp6.xyz, temp6.xyz);
            temp2.x = 1 / sqrt(temp2.x);
            temp3.w = 1.0f / temp2.x;
            temp6.xyz = temp6.xyz * temp2.xxx;
            temp2.x = -temp4.x + temp3.w;
            temp3.w = -temp4.x + temp4.y;
            temp3.w = 1.0f / temp3.w;
            temp2.x = saturate(temp2.x * -temp3.w + float1(1));
            temp2.x = temp2.x * temp2.x;
            temp4.xyz = temp5.xyz * temp2.xxx;
            temp2.x = dot(temp0.xyz, temp6.xyz);
            temp3.w = max(temp2.x, float1(0));
            temp3.xyz = temp4.xyz * temp3.www + temp3.xyz;
            temp1.w = temp1.w + float1(1);
        }
    temp0.xyz = temp3.xyz * temp2.yzw + temp1.xyz;
    out_color.w = temp0.w * i.color.w;
    temp0.xyz = temp0.xyz * TintColor.xyz ;
    temp1 = tex2D(ShroudTextureSampler, i.texcoord6.xy);
    out_color.xyz = temp0.xyz * temp1.xyz + tempglow.xyz; //add glow

    return out_color;
}

PixelShader PS_H_Array[4] = {
    compile ps_3_0 PS_H_Array_Shader_0(), 
    compile ps_3_0 PS_H_Array_Shader_1(), 
    compile ps_3_0 PS_H_Array_Shader_2(), 
    compile ps_3_0 PS_H_Array_Shader_3(), 
};

struct VS_M_Array_Shader_0_Input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 tangent : TANGENT;
    float4 binormal : BINORMAL;
    float4 texcoord : TEXCOORD;
    float4 color : COLOR;
};

struct VS_M_Array_Shader_0_Output
{
    float4 position : POSITION;
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
    float3 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
    float4 texcoord4 : TEXCOORD4;
    float2 texcoord5 : TEXCOORD5;
    float4 color : COLOR;
};

VS_M_Array_Shader_0_Output VS_M_Array_Shader_0(VS_M_Array_Shader_0_Input i)
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

    VS_M_Array_Shader_0_Output o;
    float4 temp0, temp1, temp2;
    float3 temp3, temp4;
    temp0 = i.position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
    temp1.z = dot(temp0, (World._m02_m12_m22_m32));
    temp1.w = float1(1);
    temp1.x = dot(temp0, (World._m00_m10_m20_m30));
    temp1.y = dot(temp0, (World._m01_m11_m21_m31));
    o.position.x = dot(temp1, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp1, (ViewProjection._m01_m11_m21_m31));
    o.position.z = dot(temp1, (ViewProjection._m02_m12_m22_m32));
    o.position.w = dot(temp1, (ViewProjection._m03_m13_m23_m33));
    temp0.x = dot(i.binormal.xyz, (World._m00_m10_m20_m30).xyz);
    temp0.y = dot(i.binormal.xyz, (World._m01_m11_m21_m31).xyz);
    temp0.z = dot(i.binormal.xyz, (World._m02_m12_m22_m32).xyz);
    o.texcoord1.x = dot(DirectionalLight[0].Direction.xyz, -temp0.xyz);
    temp2.x = dot(i.tangent.xyz, (World._m00_m10_m20_m30).xyz);
    temp2.y = dot(i.tangent.xyz, (World._m01_m11_m21_m31).xyz);
    temp2.z = dot(i.tangent.xyz, (World._m02_m12_m22_m32).xyz);
    o.texcoord1.y = dot(DirectionalLight[0].Direction.xyz, -temp2.xyz);
    temp3.x = dot(i.normal.xyz, (World._m00_m10_m20_m30).xyz);
    temp3.y = dot(i.normal.xyz, (World._m01_m11_m21_m31).xyz);
    temp3.z = dot(i.normal.xyz, (World._m02_m12_m22_m32).xyz);
    o.texcoord1.z = dot(DirectionalLight[0].Direction.xyz, temp3.xyz);
    temp4.xyz = -temp1.xyz + EyePosition.xyz;
    temp0.w = dot(temp4.xyz, temp4.xyz);
    temp0.w = 1 / sqrt(temp0.w);
    temp4.xyz = temp4.xyz * temp0.www + DirectionalLight[0].Direction.xyz;
    temp0.x = dot(temp4.xyz, -temp0.xyz);
    temp0.y = dot(temp4.xyz, -temp2.xyz);
    temp0.z = dot(temp4.xyz, temp3.xyz);
    temp0.w = dot(temp0.xyz, temp0.xyz);
    temp0.w = 1 / sqrt(temp0.w);
    o.texcoord2 = temp0 * temp0.w;
    temp0.x = dot(temp3.xyz, DirectionalLight[2].Direction.xyz);
    temp0.y = dot(temp3.xyz, DirectionalLight[1].Direction.xyz);
    temp0.x = max(temp0.x, float1(0));
    temp0.xzw = temp0.xxx * DirectionalLight[2].Color.xyz;
    temp0.y = max(temp0.y, float1(0));
    temp0.xyz = DirectionalLight[1].Color.xyz * temp0.yyy + temp0.xzw;
    temp2.xzw = float3(1, 0.1, -1);
    temp0.xyz = AmbientLightColor.xyz * temp2.zzz + temp0.xyz;
    temp0.w = OpacityOverride.x;
    o.color = temp0 * i.color;
    temp0.xy = temp1.xy + Shroud.ScaleUV_OffsetUV.zw;
    o.texcoord3.xy = temp0.xy * Shroud.ScaleUV_OffsetUV.xy;
    temp0.xy = temp1.zz * Cloud.WorldPositionMultiplier_XYZZ.zw;
    temp0.xy = temp1.xy * Cloud.WorldPositionMultiplier_XYZZ.xy + -temp0.xy;
    o.texcoord3.zw = temp0.xy + Cloud.CurrentOffsetUV.xy;
    temp0.xy = temp2.xw * expr12.xx;
    o.texcoord5 = temp1 * temp0;
    o.texcoord = i.texcoord.xyyx;
    o.texcoord1.w = float1(0);
    temp0.x = dot(temp1, (ShadowMapWorldToShadow._m03_m13_m23_m33));
    temp0.y = 1.0f / temp0.x;
    o.texcoord4.w = temp0.x;
    temp0.x = dot(temp1, (ShadowMapWorldToShadow._m00_m10_m20_m30));
    temp0.z = dot(temp1, (ShadowMapWorldToShadow._m01_m11_m21_m31));
    temp0.w = dot(temp1, (ShadowMapWorldToShadow._m02_m12_m22_m32));
    o.texcoord4.xyz = temp0.xzw * temp0.yyy + float3(0, 0, -0.0015);

    return o;
}


struct VS_M_Array_Shader_1_Input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 tangent : TANGENT;
    float4 binormal : BINORMAL;
    float4 blendindices : BLENDINDICES;
    float4 texcoord : TEXCOORD;
    float4 color : COLOR;
};

struct VS_M_Array_Shader_1_Output
{
    float4 position : POSITION;
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
    float3 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
    float4 texcoord4 : TEXCOORD4;
    float2 texcoord5 : TEXCOORD5;
    float4 color : COLOR;
};

VS_M_Array_Shader_1_Output VS_M_Array_Shader_1(VS_M_Array_Shader_1_Input i)
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

    VS_M_Array_Shader_1_Output o;
    float4 temp0, temp1, temp2, temp3, temp4;
    float addr0;
    temp0.x = i.blendindices.x + i.blendindices.x;
    temp0.y = frac(temp0.x);
    temp0.z = temp0.x + -temp0.y;
    temp0.y = (-temp0.y < temp0.y) ? 1 : 0;
    temp0.x = (temp0.x < -temp0.x) ? 1 : 0;
    temp0.x = temp0.x * temp0.y + temp0.z;
    addr0.x = temp0.x;
    temp0 = i.position.zxyy * WorldBones[0 + addr0.x].yzxy;
    temp0 = WorldBones[0 + addr0.x].wwwx * i.position.xyzx + temp0;
    temp1 = i.position.yzxz * WorldBones[0 + addr0.x].zxyz;
    temp0 = temp0 * float4(1, 1, 1, -1) + -temp1;
    temp1.xyz = temp0.www * WorldBones[0 + addr0.x].xyz;
    temp1.xyz = WorldBones[0 + addr0.x].www * temp0.xyz + -temp1.xyz;
    temp1.xyz = WorldBones[0 + addr0.x].yzx * temp0.zxy + temp1.xyz;
    temp0.xyz = WorldBones[0 + addr0.x].zxy * -temp0.yzx + temp1.xyz;
    temp0.xyz = temp0.xyz + WorldBones[1 + addr0.x].xyz;
    temp0.w = float1(1);
    o.position.x = dot(temp0, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp0, (ViewProjection._m01_m11_m21_m31));
    o.position.z = dot(temp0, (ViewProjection._m02_m12_m22_m32));
    o.position.w = dot(temp0, (ViewProjection._m03_m13_m23_m33));
    temp1 = i.binormal.zxyy * WorldBones[0 + addr0.x].yzxy;
    temp1 = WorldBones[0 + addr0.x].wwwx * i.binormal.xyzx + temp1;
    temp2 = i.binormal.yzxz * WorldBones[0 + addr0.x].zxyz;
    temp1 = temp1 * float4(1, 1, 1, -1) + -temp2;
    temp2.xyz = temp1.www * WorldBones[0 + addr0.x].xyz;
    temp2.xyz = WorldBones[0 + addr0.x].www * temp1.xyz + -temp2.xyz;
    temp2.xyz = WorldBones[0 + addr0.x].yzx * temp1.zxy + temp2.xyz;
    temp1.xyz = WorldBones[0 + addr0.x].zxy * -temp1.yzx + temp2.xyz;
    o.texcoord1.x = dot(DirectionalLight[0].Direction.xyz, -temp1.xyz);
    temp2 = i.tangent.zxyy * WorldBones[0 + addr0.x].yzxy;
    temp2 = WorldBones[0 + addr0.x].wwwx * i.tangent.xyzx + temp2;
    temp3 = i.tangent.yzxz * WorldBones[0 + addr0.x].zxyz;
    temp2 = temp2 * float4(1, 1, 1, -1) + -temp3;
    temp3.xyz = temp2.www * WorldBones[0 + addr0.x].xyz;
    temp3.xyz = WorldBones[0 + addr0.x].www * temp2.xyz + -temp3.xyz;
    temp3.xyz = WorldBones[0 + addr0.x].yzx * temp2.zxy + temp3.xyz;
    temp2.xyz = WorldBones[0 + addr0.x].zxy * -temp2.yzx + temp3.xyz;
    o.texcoord1.y = dot(DirectionalLight[0].Direction.xyz, -temp2.xyz);
    temp3 = i.normal.zxyy * WorldBones[0 + addr0.x].yzxy;
    temp3 = WorldBones[0 + addr0.x].wwwx * i.normal.xyzx + temp3;
    temp4 = i.normal.yzxz * WorldBones[0 + addr0.x].zxyz;
    temp3 = temp3 * float4(1, 1, 1, -1) + -temp4;
    temp4.xyz = temp3.www * WorldBones[0 + addr0.x].xyz;
    temp4.xyz = WorldBones[0 + addr0.x].www * temp3.xyz + -temp4.xyz;
    temp4.xyz = WorldBones[0 + addr0.x].yzx * temp3.zxy + temp4.xyz;
    temp3.xyz = WorldBones[0 + addr0.x].zxy * -temp3.yzx + temp4.xyz;
    o.texcoord1.z = dot(DirectionalLight[0].Direction.xyz, temp3.xyz);
    temp4.xyz = -temp0.xyz + EyePosition.xyz;
    temp1.w = dot(temp4.xyz, temp4.xyz);
    temp1.w = 1 / sqrt(temp1.w);
    temp4.xyz = temp4.xyz * temp1.www + DirectionalLight[0].Direction.xyz;
    temp1.x = dot(temp4.xyz, -temp1.xyz);
    temp1.y = dot(temp4.xyz, -temp2.xyz);
    temp1.z = dot(temp4.xyz, temp3.xyz);
    temp1.w = dot(temp1.xyz, temp1.xyz);
    temp1.w = 1 / sqrt(temp1.w);
    o.texcoord2 = temp1 * temp1.w;
    temp1.x = dot(temp3.xyz, DirectionalLight[2].Direction.xyz);
    temp1.y = dot(temp3.xyz, DirectionalLight[1].Direction.xyz);
    temp1.x = max(temp1.x, float1(0));
    temp1.xzw = temp1.xxx * DirectionalLight[2].Color.xyz;
    temp1.y = max(temp1.y, float1(0));
    temp1.xyz = DirectionalLight[1].Color.xyz * temp1.yyy + temp1.xzw;
    temp2.xyw = float3(1, -1, 0.1);
    temp1.xyz = AmbientLightColor.xyz * temp2.www + temp1.xyz;
    temp2.z = (i.blendindices.x < -i.blendindices.x) ? 1 : 0;
    temp2.w = frac(i.blendindices.x);
    temp3.x = -temp2.w + i.blendindices.x;
    temp2.w = (-temp2.w < temp2.w) ? 1 : 0;
    temp2.z = temp2.z * temp2.w + temp3.x;
    temp2.z = temp2.z + temp2.z;
    addr0.x = temp2.z;
    temp3.w = i.color.w * WorldBones[1 + addr0.x].w;
    temp1.w = OpacityOverride.x;
    temp3.xyz = i.color.xyz;
    o.color = temp1 * temp3;
    temp1.xy = temp0.xy + Shroud.ScaleUV_OffsetUV.zw;
    o.texcoord3.xy = temp1.xy * Shroud.ScaleUV_OffsetUV.xy;
    temp1.xy = temp0.zz * Cloud.WorldPositionMultiplier_XYZZ.zw;
    temp1.xy = temp0.xy * Cloud.WorldPositionMultiplier_XYZZ.xy + -temp1.xy;
    o.texcoord3.zw = temp1.xy + Cloud.CurrentOffsetUV.xy;
    temp1.xy = temp2.xy * expr12.xx;
    o.texcoord5 = temp0 * temp1;
    o.texcoord = i.texcoord.xyyx;
    o.texcoord1.w = float1(0);
    temp1.x = dot(temp0, (ShadowMapWorldToShadow._m00_m10_m20_m30));
    temp1.y = dot(temp0, (ShadowMapWorldToShadow._m01_m11_m21_m31));
    temp1.z = dot(temp0, (ShadowMapWorldToShadow._m02_m12_m22_m32));
    temp0.x = dot(temp0, (ShadowMapWorldToShadow._m03_m13_m23_m33));
    temp0.y = 1.0f / temp0.x;
    o.texcoord4.w = temp0.x;
    o.texcoord4.xyz = temp1.xyz * temp0.yyy + float3(0, 0, -0.0015);

    return o;
}

VertexShader VS_M_Array[2] = {
    compile vs_3_0 VS_M_Array_Shader_0(), 
    compile vs_3_0 VS_M_Array_Shader_1(), 
};

struct PS_M_Array_Shader_0_Input
{
    float2 texcoord : TEXCOORD;
    float3 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
    float4 color : COLOR;
    float3 texcoord1 : TEXCOORD1;
};

float4 PS_M_Array_Shader_0(PS_M_Array_Shader_0_Input i) : COLOR
{
    float4 out_color;
    float4 temp0, temp1, temp2;
    temp0 = /* not implemented _pp modifier */ tex2D(DiffuseTextureSampler, i.texcoord.xy);
    out_color.w = /* not implemented _pp modifier */ temp0.w * i.color.w;
    temp1 = /* not implemented _pp modifier */ tex2D(NormalMapSampler, i.texcoord.xy);
    temp1.xyz = /* not implemented _pp modifier */ temp1.xyz * float3(2, 2, 2) + float3(-1, -1, -1);
    temp1.xyz = /* not implemented _pp modifier */ temp1.xyz * float3(1.5, 1.5, 1);
    temp2.xyz = /* not implemented _pp modifier */ normalize(temp1.xyz).xyz;
    temp0.w = /* not implemented _pp modifier */ dot(temp2.xyz, i.texcoord2.xyz);
    temp1.x = /* not implemented _pp modifier */ dot(temp2.xyz, i.texcoord1.xyz);
    temp1.y = (-temp0.w >= 0) ? float1(0) : float1(1);
    temp1.z = pow(temp0.w, float1(50));
    temp0.w = (-temp1.x >= 0) ? float1(0) : float1(1);
    temp1.x = /* not implemented _pp modifier */ temp1.x * temp0.w;
    temp0.w = temp1.y * temp0.w;
    temp0.w = /* not implemented _pp modifier */ temp1.z * temp0.w;
    temp2 = /* not implemented _pp modifier */ tex2D(SpecMapSampler, i.texcoord.xy);
    temp1.y = /* not implemented _pp modifier */ temp2.x * float1(0.8);
    temp0.w = /* not implemented _pp modifier */ temp0.w * temp1.y;
    temp1.xyz = /* not implemented _pp modifier */ temp0.xyz * temp1.xxx + temp0.www;
    temp2 = /* not implemented _pp modifier */ tex2D(CloudTextureSampler, i.texcoord3.zw);
    temp2.xyz = temp2.xyz * DirectionalLight[0].Color.xyz;
    temp1.xyz = temp1.xyz * temp2.xyz;
    temp0.xyz = /* not implemented _pp modifier */ temp0.xyz * i.color.xyz + temp1.xyz;
    temp0.xyz = /* not implemented _pp modifier */ temp0.xyz * TintColor.xyz;
    temp1 = /* not implemented _pp modifier */ tex2D(ShroudTextureSampler, i.texcoord3.xy);
    out_color.xyz = /* not implemented _pp modifier */ temp0.xyz * temp1.xyz;

    return out_color;
}


struct PS_M_Array_Shader_1_Input
{
    float2 texcoord : TEXCOORD;
    float3 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
    float3 texcoord4 : TEXCOORD4;
    float4 color : COLOR;
    float3 texcoord1 : TEXCOORD1;
};

float4 PS_M_Array_Shader_1(PS_M_Array_Shader_1_Input i) : COLOR
{
    float4 out_color;
    float4 temp0, temp1, temp2;
    temp0 = /* not implemented _pp modifier */ tex2D(DiffuseTextureSampler, i.texcoord.xy);
    out_color.w = /* not implemented _pp modifier */ temp0.w * i.color.w;
    temp1.xy = Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.zx + i.texcoord4.xy;
    temp1 = tex2D(ShadowMapSampler, temp1.xy);
    temp1.y = temp1.x;
    temp2.xy = Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.yz + i.texcoord4.xy;
    temp2 = tex2D(ShadowMapSampler, temp2.xy);
    temp1.z = temp2.x;
    temp2.xy = Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.wz + i.texcoord4.xy;
    temp2 = tex2D(ShadowMapSampler, temp2.xy);
    temp1.w = temp2.x;
    temp2 = tex2D(ShadowMapSampler, i.texcoord4.xy);
    temp1.x = temp2.x;
    temp1 = temp1 + -i.texcoord4.z;
    temp1 = (temp1 >= 0) ? float4(1, 1, 1, 1) : float4(0, 0, 0, 0);
    temp0.w = dot(float4(1, 1, 1, 1), temp1);
    temp0.w = temp0.w * float1(0.25);
    temp1 = /* not implemented _pp modifier */ tex2D(NormalMapSampler, i.texcoord.xy);
    temp1.xyz = /* not implemented _pp modifier */ temp1.xyz * float3(2, 2, 2) + float3(-1, -1, -1);
    temp1.xyz = /* not implemented _pp modifier */ temp1.xyz * float3(1.5, 1.5, 1);
    temp2.xyz = /* not implemented _pp modifier */ normalize(temp1.xyz).xyz;
    temp1.x = /* not implemented _pp modifier */ dot(temp2.xyz, i.texcoord2.xyz);
    temp1.y = /* not implemented _pp modifier */ dot(temp2.xyz, i.texcoord1.xyz);
    temp1.z = (-temp1.x >= 0) ? float1(0) : float1(1);
    temp2.x = pow(temp1.x, float1(50));
    temp1.x = (-temp1.y >= 0) ? float1(0) : float1(1);
    temp1.xy = temp1.zy * temp1.xx;
    temp1.w = /* not implemented _pp modifier */ temp2.x * temp1.x;
    temp1.xy = /* not implemented _pp modifier */ temp0.ww * temp1.yw;
    temp2 = /* not implemented _pp modifier */ tex2D(SpecMapSampler, i.texcoord.xy);
    temp0.w = /* not implemented _pp modifier */ temp2.x * float1(0.8);
    temp0.w = /* not implemented _pp modifier */ temp1.y * temp0.w;
    temp1.xyz = /* not implemented _pp modifier */ temp0.xyz * temp1.xxx + temp0.www;
    temp2 = /* not implemented _pp modifier */ tex2D(CloudTextureSampler, i.texcoord3.zw);
    temp2.xyz = temp2.xyz * DirectionalLight[0].Color.xyz;
    temp1.xyz = temp1.xyz * temp2.xyz;
    temp0.xyz = /* not implemented _pp modifier */ temp0.xyz * i.color.xyz + temp1.xyz;
    temp0.xyz = /* not implemented _pp modifier */ temp0.xyz * TintColor.xyz;
    temp1 = /* not implemented _pp modifier */ tex2D(ShroudTextureSampler, i.texcoord3.xy);
    out_color.xyz = /* not implemented _pp modifier */ temp0.xyz * temp1.xyz;

    return out_color;
}


struct PS_M_Array_Shader_2_Input
{
    float2 texcoord : TEXCOORD;
    float3 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
    float4 color : COLOR;
    float3 texcoord1 : TEXCOORD1;
};

float4 PS_M_Array_Shader_2(PS_M_Array_Shader_2_Input i) : COLOR
{
    float4 out_color;
    float4 temp0, temp1, temp2;
    temp0 = /* not implemented _pp modifier */ tex2D(DiffuseTextureSampler, i.texcoord.xy);
    out_color.w = /* not implemented _pp modifier */ temp0.w * i.color.w;
    temp1.xyz = temp0.xyz * RecolorColor.xyz;
    temp1.xyz = temp1.xyz * float3(2, 2, 2) + -temp0.xyz;
    temp2 = /* not implemented _pp modifier */ tex2D(SpecMapSampler, i.texcoord.xy);
    temp0.xyz = /* not implemented _pp modifier */ temp2.zzz * temp1.xyz + temp0.xyz;
    temp0.w = /* not implemented _pp modifier */ temp2.x * float1(0.8);
    temp1 = /* not implemented _pp modifier */ tex2D(NormalMapSampler, i.texcoord.xy);
    temp1.xyz = /* not implemented _pp modifier */ temp1.xyz * float3(2, 2, 2) + float3(-1, -1, -1);
    temp1.xyz = /* not implemented _pp modifier */ temp1.xyz * float3(1.5, 1.5, 1);
    temp2.xyz = /* not implemented _pp modifier */ normalize(temp1.xyz).xyz;
    temp1.x = /* not implemented _pp modifier */ dot(temp2.xyz, i.texcoord2.xyz);
    temp1.y = /* not implemented _pp modifier */ dot(temp2.xyz, i.texcoord1.xyz);
    temp1.z = (-temp1.x >= 0) ? float1(0) : float1(1);
    temp2.x = pow(temp1.x, float1(50));
    temp1.x = (-temp1.y >= 0) ? float1(0) : float1(1);
    temp1.xy = temp1.zy * temp1.xx;
    temp1.x = /* not implemented _pp modifier */ temp2.x * temp1.x;
    temp0.w = /* not implemented _pp modifier */ temp0.w * temp1.x;
    temp1.xyz = /* not implemented _pp modifier */ temp0.xyz * temp1.yyy + temp0.www;
    temp2 = /* not implemented _pp modifier */ tex2D(CloudTextureSampler, i.texcoord3.zw);
    temp2.xyz = temp2.xyz * DirectionalLight[0].Color.xyz;
    temp1.xyz = temp1.xyz * temp2.xyz;
    temp0.xyz = /* not implemented _pp modifier */ temp0.xyz * i.color.xyz + temp1.xyz;
    temp0.xyz = /* not implemented _pp modifier */ temp0.xyz * TintColor.xyz;
    temp1 = /* not implemented _pp modifier */ tex2D(ShroudTextureSampler, i.texcoord3.xy);
    out_color.xyz = /* not implemented _pp modifier */ temp0.xyz * temp1.xyz;

    return out_color;
}


struct PS_M_Array_Shader_3_Input
{
    float2 texcoord : TEXCOORD;
    float3 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
    float3 texcoord4 : TEXCOORD4;
    float4 color : COLOR;
    float3 texcoord1 : TEXCOORD1;
};

float4 PS_M_Array_Shader_3(PS_M_Array_Shader_3_Input i) : COLOR
{
    float4 out_color;
    float4 temp0, temp1, temp2;
    temp0 = /* not implemented _pp modifier */ tex2D(DiffuseTextureSampler, i.texcoord.xy);
    out_color.w = /* not implemented _pp modifier */ temp0.w * i.color.w;
    temp1.xyz = temp0.xyz * RecolorColor.xyz;
    temp1.xyz = temp1.xyz * float3(2, 2, 2) + -temp0.xyz;
    temp2 = /* not implemented _pp modifier */ tex2D(SpecMapSampler, i.texcoord.xy);
    temp0.xyz = /* not implemented _pp modifier */ temp2.zzz * temp1.xyz + temp0.xyz;
    temp0.w = /* not implemented _pp modifier */ temp2.x * float1(0.8);
    temp1.xy = Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.zx + i.texcoord4.xy;
    temp1 = tex2D(ShadowMapSampler, temp1.xy);
    temp1.y = temp1.x;
    temp2.xy = Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.yz + i.texcoord4.xy;
    temp2 = tex2D(ShadowMapSampler, temp2.xy);
    temp1.z = temp2.x;
    temp2.xy = Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.wz + i.texcoord4.xy;
    temp2 = tex2D(ShadowMapSampler, temp2.xy);
    temp1.w = temp2.x;
    temp2 = tex2D(ShadowMapSampler, i.texcoord4.xy);
    temp1.x = temp2.x;
    temp1 = temp1 + -i.texcoord4.z;
    temp1 = (temp1 >= 0) ? float4(1, 1, 1, 1) : float4(0, 0, 0, 0);
    temp1.x = dot(float4(1, 1, 1, 1), temp1);
    temp1.x = temp1.x * float1(0.25);
    temp2 = /* not implemented _pp modifier */ tex2D(NormalMapSampler, i.texcoord.xy);
    temp1.yzw = /* not implemented _pp modifier */ temp2.xyz * float3(2, 2, 2) + float3(-1, -1, -1);
    temp1.yzw = /* not implemented _pp modifier */ temp1.yzw * float3(1.5, 1.5, 1);
    temp2.xyz = /* not implemented _pp modifier */ normalize(temp1.yzww.xyz).xyz;
    temp1.y = /* not implemented _pp modifier */ dot(temp2.xyz, i.texcoord2.xyz);
    temp1.z = /* not implemented _pp modifier */ dot(temp2.xyz, i.texcoord1.xyz);
    temp1.w = (-temp1.y >= 0) ? float1(0) : float1(1);
    temp2.x = pow(temp1.y, float1(50));
    temp1.y = (-temp1.z >= 0) ? float1(0) : float1(1);
    temp2.y = /* not implemented _pp modifier */ temp1.z * temp1.y;
    temp1.y = temp1.w * temp1.y;
    temp2.z = /* not implemented _pp modifier */ temp2.x * temp1.y;
    temp1.xy = /* not implemented _pp modifier */ temp1.xx * temp2.yz;
    temp0.w = /* not implemented _pp modifier */ temp0.w * temp1.y;
    temp1.xyz = /* not implemented _pp modifier */ temp0.xyz * temp1.xxx + temp0.www;
    temp2 = /* not implemented _pp modifier */ tex2D(CloudTextureSampler, i.texcoord3.zw);
    temp2.xyz = temp2.xyz * DirectionalLight[0].Color.xyz;
    temp1.xyz = temp1.xyz * temp2.xyz;
    temp0.xyz = /* not implemented _pp modifier */ temp0.xyz * i.color.xyz + temp1.xyz;
    temp0.xyz = /* not implemented _pp modifier */ temp0.xyz * TintColor.xyz;
    temp1 = /* not implemented _pp modifier */ tex2D(ShroudTextureSampler, i.texcoord3.xy);
    out_color.xyz = /* not implemented _pp modifier */ temp0.xyz * temp1.xyz;

    return out_color;
}

PixelShader PS_M_Array[4] = {
    compile ps_3_0 PS_M_Array_Shader_0(), 
    compile ps_3_0 PS_M_Array_Shader_1(), 
    compile ps_3_0 PS_M_Array_Shader_2(), 
    compile ps_3_0 PS_M_Array_Shader_3(), 
};

struct VS_L_Array_Shader_0_Input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 texcoord : TEXCOORD;
    float4 color : COLOR;
};

struct VS_L_Array_Shader_0_Output
{
    float4 position : POSITION;
    float4 color : COLOR;
    float2 texcoord1 : TEXCOORD1;
    float4 texcoord : TEXCOORD;
};

VS_L_Array_Shader_0_Output VS_L_Array_Shader_0(VS_L_Array_Shader_0_Input i)
{
    VS_L_Array_Shader_0_Output o;
    float4 temp0, temp1;
    float3 temp2;
    temp0 = i.position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
    temp1.z = dot(temp0, (World._m02_m12_m22_m32));
    temp1.w = float1(1);
    temp1.x = dot(temp0, (World._m00_m10_m20_m30));
    temp1.y = dot(temp0, (World._m01_m11_m21_m31));
    o.position.x = dot(temp1, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp1, (ViewProjection._m01_m11_m21_m31));
    o.position.z = dot(temp1, (ViewProjection._m02_m12_m22_m32));
    o.position.w = dot(temp1, (ViewProjection._m03_m13_m23_m33));
    temp0.xy = temp1.xy + Shroud.ScaleUV_OffsetUV.zw;
    temp1.x = dot(i.normal.xyz, (World._m00_m10_m20_m30).xyz);
    temp1.y = dot(i.normal.xyz, (World._m01_m11_m21_m31).xyz);
    temp1.z = dot(i.normal.xyz, (World._m02_m12_m22_m32).xyz);
    temp0.z = dot(temp1.xyz, DirectionalLight[1].Direction.xyz);
    temp0.z = max(temp0.z, float1(0));
    temp2.xyz = temp0.zzz * DirectionalLight[1].Color.xyz;
    temp0.z = dot(temp1.xyz, DirectionalLight[0].Direction.xyz);
    temp0.w = dot(temp1.xyz, DirectionalLight[2].Direction.xyz);
    temp0.z = max(temp0.z, float1(0));
    temp1.xyz = DirectionalLight[0].Color.xyz * temp0.zzz + temp2.xyz;
    temp0.z = max(temp0.w, float1(0));
    temp1.xyz = DirectionalLight[2].Color.xyz * temp0.zzz + temp1.xyz;
    temp0.z = float1(0.1);
    temp1.xyz = AmbientLightColor.xyz * temp0.zzz + temp1.xyz;
    temp1.w = OpacityOverride.x;
    o.color = temp1 * i.color;
    o.texcoord1 = temp0 * Shroud.ScaleUV_OffsetUV;
    o.texcoord = i.texcoord.xyyx;

    return o;
}


struct VS_L_Array_Shader_1_Input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 blendindices : BLENDINDICES;
    float4 texcoord : TEXCOORD;
    float4 color : COLOR;
};

struct VS_L_Array_Shader_1_Output
{
    float4 position : POSITION;
    float4 color : COLOR;
    float2 texcoord1 : TEXCOORD1;
    float4 texcoord : TEXCOORD;
};

VS_L_Array_Shader_1_Output VS_L_Array_Shader_1(VS_L_Array_Shader_1_Input i)
{
    VS_L_Array_Shader_1_Output o;
    float4 temp0, temp1, temp2;
    float addr0;
    temp0.x = i.blendindices.x + i.blendindices.x;
    temp0.y = frac(temp0.x);
    temp0.z = temp0.x + -temp0.y;
    temp0.y = (-temp0.y < temp0.y) ? 1 : 0;
    temp0.x = (temp0.x < -temp0.x) ? 1 : 0;
    temp0.x = temp0.x * temp0.y + temp0.z;
    addr0.x = temp0.x;
    temp0 = i.position.zxyy * WorldBones[0 + addr0.x].yzxy;
    temp0 = WorldBones[0 + addr0.x].wwwx * i.position.xyzx + temp0;
    temp1 = i.position.yzxz * WorldBones[0 + addr0.x].zxyz;
    temp0 = temp0 * float4(1, 1, 1, -1) + -temp1;
    temp1.xyz = temp0.www * WorldBones[0 + addr0.x].xyz;
    temp1.xyz = WorldBones[0 + addr0.x].www * temp0.xyz + -temp1.xyz;
    temp1.xyz = WorldBones[0 + addr0.x].yzx * temp0.zxy + temp1.xyz;
    temp0.xyz = WorldBones[0 + addr0.x].zxy * -temp0.yzx + temp1.xyz;
    temp0.xyz = temp0.xyz + WorldBones[1 + addr0.x].xyz;
    temp0.w = float1(1);
    o.position.x = dot(temp0, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp0, (ViewProjection._m01_m11_m21_m31));
    o.position.z = dot(temp0, (ViewProjection._m02_m12_m22_m32));
    o.position.w = dot(temp0, (ViewProjection._m03_m13_m23_m33));
    temp0.xy = temp0.xy + Shroud.ScaleUV_OffsetUV.zw;
    temp1 = i.normal.zxyy * WorldBones[0 + addr0.x].yzxy;
    temp1 = WorldBones[0 + addr0.x].wwwx * i.normal.xyzx + temp1;
    temp2 = i.normal.yzxz * WorldBones[0 + addr0.x].zxyz;
    temp1 = temp1 * float4(1, 1, 1, -1) + -temp2;
    temp2.xyz = temp1.www * WorldBones[0 + addr0.x].xyz;
    temp2.xyz = WorldBones[0 + addr0.x].www * temp1.xyz + -temp2.xyz;
    temp2.xyz = WorldBones[0 + addr0.x].yzx * temp1.zxy + temp2.xyz;
    temp1.xyz = WorldBones[0 + addr0.x].zxy * -temp1.yzx + temp2.xyz;
    temp0.z = dot(temp1.xyz, DirectionalLight[0].Direction.xyz);
    temp0.z = max(temp0.z, float1(0));
    temp0.w = dot(temp1.xyz, DirectionalLight[1].Direction.xyz);
    temp1.x = dot(temp1.xyz, DirectionalLight[2].Direction.xyz);
    temp0.w = max(temp0.w, float1(0));
    temp1.yzw = temp0.www * DirectionalLight[1].Color.xyz;
    temp1.yzw = DirectionalLight[0].Color.xyz * temp0.zzz + temp1.yzw;
    temp0.z = max(temp1.x, float1(0));
    temp1.xyz = DirectionalLight[2].Color.xyz * temp0.zzz + temp1.yzw;
    temp0.w = float1(0.1);
    temp1.xyz = AmbientLightColor.xyz * temp0.www + temp1.xyz;
    temp0.z = (i.blendindices.x < -i.blendindices.x) ? 1 : 0;
    temp0.w = frac(i.blendindices.x);
    temp2.x = -temp0.w + i.blendindices.x;
    temp0.w = (-temp0.w < temp0.w) ? 1 : 0;
    temp0.z = temp0.z * temp0.w + temp2.x;
    temp0.z = temp0.z + temp0.z;
    addr0.x = temp0.z;
    temp2.w = i.color.w * WorldBones[1 + addr0.x].w;
    temp1.w = OpacityOverride.x;
    temp2.xyz = i.color.xyz;
    o.color = temp1 * temp2;
    o.texcoord1 = temp0 * Shroud.ScaleUV_OffsetUV;
    o.texcoord = i.texcoord.xyyx;

    return o;
}

VertexShader VS_L_Array[2] = {
    compile vs_2_0 VS_L_Array_Shader_0(), 
    compile vs_2_0 VS_L_Array_Shader_1(), 
};

struct PS_L_Array_Shader_0_Input
{
    float4 color : COLOR;
    float2 texcoord : TEXCOORD;
    float2 texcoord1 : TEXCOORD1;
};

float4 PS_L_Array_Shader_0(PS_L_Array_Shader_0_Input i) : COLOR
{
    float4 out_color;
    float4 temp0, temp1, temp2;
    temp0 = tex2D(DiffuseTextureSampler, i.texcoord.xy);
    temp1 = tex2D(ShroudTextureSampler, i.texcoord1.xy);
    temp0.xyz = temp0.xyz * i.color.xyz;
    temp2.w = temp0.w * i.color.w;
    temp0.xyz = temp0.xyz * TintColor.xyz;
    temp2.xyz = temp1.xyz * temp0.xyz;
    out_color = temp2;

    return out_color;
}


struct PS_L_Array_Shader_1_Input
{
    float4 color : COLOR;
    float2 texcoord : TEXCOORD;
    float2 texcoord1 : TEXCOORD1;
};

float4 PS_L_Array_Shader_1(PS_L_Array_Shader_1_Input i) : COLOR
{
    float4 out_color;
    float4 temp0, temp1, temp2;
    float3 temp3;
    temp0 = tex2D(SpecMapSampler, i.texcoord.xy);
    temp1 = tex2D(DiffuseTextureSampler, i.texcoord.xy);
    temp2 = tex2D(ShroudTextureSampler, i.texcoord1.xy);
    temp3.xyz = temp1.xyz * RecolorColor.xyz;
    temp3.xyz = temp3.xyz * float3(2, 2, 2) + -temp1.xyz;
    temp0.xyz = temp0.zzz * temp3.xyz + temp1.xyz;
    temp1.w = temp1.w * i.color.w;
    temp0.xyz = temp0.xyz * i.color.xyz;
    temp0.xyz = temp0.xyz * TintColor.xyz;
    temp1.xyz = temp2.xyz * temp0.xyz;
    out_color = temp1;

    return out_color;
}

PixelShader PS_L_Array[2] = {
    compile ps_2_0 PS_L_Array_Shader_0(), 
    compile ps_2_0 PS_L_Array_Shader_1(), 
};

struct VSCreateShadowMap_Array_Shader_0_Input
{
    float4 position : POSITION;
    float4 texcoord : TEXCOORD;
    float4 color : COLOR;
};

struct VSCreateShadowMap_Array_Shader_0_Output
{
    float4 position : POSITION;
    float texcoord1 : TEXCOORD1;
    float color : COLOR;
    float2 texcoord : TEXCOORD;
};

VSCreateShadowMap_Array_Shader_0_Output VSCreateShadowMap_Array_Shader_0(VSCreateShadowMap_Array_Shader_0_Input i)
{
    VSCreateShadowMap_Array_Shader_0_Output o;
    float4 temp0, temp1;
    temp0 = i.position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
    temp1.x = dot(temp0, (World._m00_m10_m20_m30));
    temp1.y = dot(temp0, (World._m01_m11_m21_m31));
    temp1.z = dot(temp0, (World._m02_m12_m22_m32));
    temp1.w = float1(1);
    o.position.x = dot(temp1, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp1, (ViewProjection._m01_m11_m21_m31));
    temp0.y = dot(temp1, (ViewProjection._m03_m13_m23_m33));
    temp0.x = dot(temp1, (ViewProjection._m02_m12_m22_m32));
    temp0.z = 1.0f / temp0.y;
    o.position.zw = temp0.xy;
    o.texcoord1 = temp0.x * temp0.z;
    o.color = i.color.w * OpacityOverride.x;
    o.texcoord = i.texcoord;

    return o;
}


struct VSCreateShadowMap_Array_Shader_1_Input
{
    float4 position : POSITION;
    float4 blendindices : BLENDINDICES;
    float4 texcoord : TEXCOORD;
    float4 color : COLOR;
};

struct VSCreateShadowMap_Array_Shader_1_Output
{
    float4 position : POSITION;
    float texcoord1 : TEXCOORD1;
    float color : COLOR;
    float2 texcoord : TEXCOORD;
};

VSCreateShadowMap_Array_Shader_1_Output VSCreateShadowMap_Array_Shader_1(VSCreateShadowMap_Array_Shader_1_Input i)
{
    VSCreateShadowMap_Array_Shader_1_Output o;
    float4 temp0, temp1;
    float addr0;
    temp0.x = i.blendindices.x + i.blendindices.x;
    temp0.y = frac(temp0.x);
    temp0.z = temp0.x + -temp0.y;
    temp0.y = (-temp0.y < temp0.y) ? 1 : 0;
    temp0.x = (temp0.x < -temp0.x) ? 1 : 0;
    temp0.x = temp0.x * temp0.y + temp0.z;
    addr0.x = temp0.x;
    temp0 = i.position.zxyy * WorldBones[0 + addr0.x].yzxy;
    temp0 = WorldBones[0 + addr0.x].wwwx * i.position.xyzx + temp0;
    temp1 = i.position.yzxz * WorldBones[0 + addr0.x].zxyz;
    temp0 = temp0 * float4(1, 1, 1, -1) + -temp1;
    temp1.xyz = temp0.www * WorldBones[0 + addr0.x].xyz;
    temp1.xyz = WorldBones[0 + addr0.x].www * temp0.xyz + -temp1.xyz;
    temp1.xyz = WorldBones[0 + addr0.x].yzx * temp0.zxy + temp1.xyz;
    temp0.xyz = WorldBones[0 + addr0.x].zxy * -temp0.yzx + temp1.xyz;
    temp0.xyz = temp0.xyz + WorldBones[1 + addr0.x].xyz;
    temp0.w = float1(1);
    o.position.x = dot(temp0, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp0, (ViewProjection._m01_m11_m21_m31));
    temp1.y = dot(temp0, (ViewProjection._m03_m13_m23_m33));
    temp1.x = dot(temp0, (ViewProjection._m02_m12_m22_m32));
    temp0.x = 1.0f / temp1.y;
    o.position.zw = temp1.xy;
    o.texcoord1 = temp1.x * temp0.x;
    temp0.x = (i.blendindices.x < -i.blendindices.x) ? 1 : 0;
    temp0.y = frac(i.blendindices.x);
    temp0.z = -temp0.y + i.blendindices.x;
    temp0.y = (-temp0.y < temp0.y) ? 1 : 0;
    temp0.x = temp0.x * temp0.y + temp0.z;
    temp0.x = temp0.x + temp0.x;
    addr0.x = temp0.x;
    temp0.x = i.color.w * WorldBones[1 + addr0.x].w;
    o.color = temp0.x * OpacityOverride.x;
    o.texcoord = i.texcoord;

    return o;
}

VertexShader VSCreateShadowMap_Array[2] = {
    compile vs_2_0 VSCreateShadowMap_Array_Shader_0(), 
    compile vs_2_0 VSCreateShadowMap_Array_Shader_1(), 
};

float4 PSCreateShadowMap_Array_Shader_0(float texcoord1 : TEXCOORD1) : COLOR
{
    float4 out_color;
    float4 temp0;
    temp0 = texcoord1.x;
    out_color = temp0;

    return out_color;
}


struct PSCreateShadowMap_Array_Shader_1_Input
{
    float2 texcoord : TEXCOORD;
    float texcoord1 : TEXCOORD1;
    float color : COLOR;
};

float4 PSCreateShadowMap_Array_Shader_1(PSCreateShadowMap_Array_Shader_1_Input i) : COLOR
{
    float4 out_color;
    float4 temp0;
    temp0 = tex2D(DiffuseTextureSampler, i.texcoord.xy);
    temp0 = temp0.w * i.color.x + float4(-0.3764706, -0.3764706, -0.3764706, -0.3764706);
    clip(temp0);
    temp0 = i.texcoord1.x;
    out_color = temp0;

    return out_color;
}

PixelShader PSCreateShadowMap_Array[2] = {
    compile ps_2_0 PSCreateShadowMap_Array_Shader_0(), 
    compile ps_2_0 PSCreateShadowMap_Array_Shader_1(), 
};

float _CreateShadowMap_Expression21()
{
    float1 expr0;
    expr0.x = AlphaTestEnable.x;
    return expr0;
}


float _CreateShadowMap_Expression22()
{
    float1 expr0;
    expr0.x = min(NumJointsPerVertex.x, (1));
    return expr0;
}


float Default_L_Expression23()
{
    float1 expr0;
    expr0.x = HasRecolorColors.x;
    return expr0;
}


float Default_L_Expression24()
{
    float1 expr0;
    expr0.x = min(NumJointsPerVertex.x, (1));
    return expr0;
}


float Default_M_Expression25()  
{
    float4 temp0;
    float1 expr0;
    temp0.x = HasRecolorColors.x + HasRecolorColors.x;
    expr0.x = temp0.x + HasShadow.x;
    return expr0;
}


float Default_M_Expression26()  
{
    float1 expr0;
    expr0.x = min(NumJointsPerVertex.x, (1));
    return expr0;
}


float Default_Expression27()  //high pixel shader, choose ps index 0123
{
    float4 temp0;
    float1 expr0;
    temp0.x = HasRecolorColors.x + HasRecolorColors.x;
    expr0.x = temp0.x + HasShadow.x;
    return expr0;  //have all need =3
}


float Default_Expression28()  //high vertex shader
{
    float1 expr0;
    expr0.x = min(NumJointsPerVertex.x, (1));
    return expr0;
}

technique Default
{
    pass p0 <string ExpressionEvaluator = "Objects";>
    {
        VertexShader = VS_H_Array[Default_Expression28()]; 
        PixelShader = PS_H_Array[Default_Expression27()]; 
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        SrcBlend = 5;
        DestBlend = 6;
        AlphaFunc = 7;
        AlphaRef = 96;
    }
}

technique Default_M
{
    pass p0 <string ExpressionEvaluator = "Objects";>
    {
        VertexShader = VS_M_Array[Default_M_Expression26()]; 
        PixelShader = PS_M_Array[Default_M_Expression25()]; 
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        SrcBlend = 5;
        DestBlend = 6;
        AlphaFunc = 7;
        AlphaRef = 96;
    }
}

technique Default_L
{
    pass p0 <string ExpressionEvaluator = "Objects";>
    {
        VertexShader = VS_L_Array[Default_L_Expression24()]; 
        PixelShader = PS_L_Array[Default_L_Expression23()]; 
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        SrcBlend = 5;
        DestBlend = 6;
        AlphaFunc = 7;
        AlphaRef = 96;
    }
}

technique _CreateShadowMap
{
    pass p0
    {
        VertexShader = VSCreateShadowMap_Array[_CreateShadowMap_Expression22()]; 
        PixelShader = PSCreateShadowMap_Array[_CreateShadowMap_Expression21()]; 
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        AlphaBlendEnable = 0;
        AlphaTestEnable = 0;
    }
}

