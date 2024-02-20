//Electronic Arts 2008 Red Alert 3 units shader, PBR rewrite
//--------------
//last modified by Nordlicht 
//https://github.com/NordlichtS/custom-shaders-RedAlert3
//based on Lanyi's decompiled HLSL code
//https://github.com/lanyizi/DXDecompiler
//improvements: (only on high quality pixel shaders)
//basically a total rewrite
//diffuse: generic cameo for whole faction
//spm: material id map, 
//red= 0-0.5 metalness
//red= 0.5-1 inverted roughness
//green= AO
//green= 0-0.125 cavity (adjustable)
//blue= player color density
//alpha= inverted glow intensity
//SOFT PCF SHADOWS radius4
//no gamma correction, please use linear color texture
//----------

#include <helperfunctions.fxh> //haha gotcha

string DefaultParameterScopeBlock = "material"; 
//start input parameters

float3 AmbientLightColor : register(vs_2_0, c4) : register(vs_3_0, c4) 
<bool unmanaged = 1;> = { 0.3, 0.3, 0.3 };

struct {float3 Color; float3 Direction;} 
DirectionalLight[3] : register(vs_2_0, c5) : register(ps_3_0, c5) : register(vs_3_0, c5) 
<bool unmanaged = 1;> = 
{ 1.625198, 1.512711, 1.097048, 0.62914, -0.34874, 0.69465,   //first one is sunlight, maybe
0.5232916, 0.6654605, 0.7815244, -0.32877, 0.90329, 0.27563,   //looks like blue sky color from above
0.4420466, 0.4102767, 0.4420466, -0.80704, -0.58635, 0.06975 };  //what is this

struct {float3 Color; float3 Position; float2 Range_Inner_Outer;} 
PointLight[8] : register(ps_3_0, c89) 
<bool unmanaged = 1;>;

struct {float4 WorldPositionMultiplier_XYZZ; float2 CurrentOffsetUV;}
Cloud : register(vs_3_0, c117) 
<bool unmanaged = 1;>;

int NumPointLights : register(ps_3_0, i0) 
<string SasBindAddress = "Sas.NumPointLights"; string UIWidget = "None";>;

float3 NoCloudMultiplier 
<bool unmanaged = 1;> = { 1, 1, 1 };

bool HasShadow 
<string UIWidget = "None"; string SasBindAddress = "Sas.HasShadow";> ={1};

bool HasRecolorColors 
<string UIWidget = "None"; string SasBindAddress = "WW3D.HasRecolorColors"; bool ExportValue = 0;> ={1};

float3 RecolorColor : register(ps_2_0, c0) : register(ps_3_0, c0) 
<bool unmanaged = 1;> = { 1,0,0 };
//player faction color, should not have UIname
//string UIName = "HCpreview"; string UIWidget = "Color";

column_major float4x4 ShadowMapWorldToShadow : register(vs_3_0, c113) 
<bool unmanaged = 1;>;

float OpacityOverride : register(vs_2_0, c1) : register(vs_3_0, c1) 
<bool unmanaged = 1;> = { 1 };

float3 TintColor : register(ps_2_0, c2) : register(ps_3_0, c2) 
<bool unmanaged = 1;> = { 1, 1, 1 };

float3 EyePosition : register(vs_3_0, c123) : register(ps_3_0, c123) 
<bool unmanaged = 1;>;

column_major float4x4 ViewProjection : register(vs_2_0, c119) : register(vs_3_0, c119) 
<bool unmanaged = 1;>;

float4 WorldBones[128] : register(vs_2_0, c128) : register(vs_3_0, c128) 
<bool unmanaged = 1;>;

texture ShadowMap 
<string UIWidget = "None"; string SasBindAddress = "Sas.Shadow[0].ShadowMap";>; 
sampler2D ShadowMapSampler : register(ps_3_0, s0) 
<string Texture = "ShadowMap"; string UIWidget = "None"; string SasBindAddress = "Sas.Shadow[0].ShadowMap";> 
= sampler_state
{
    Texture = <ShadowMap>;  //filter: 1 point  2 linear 3 aniso 6 PyramidQuad 7 GaussianQuad
    MinFilter = 1;
    MagFilter = 1;
    MipFilter = 0;
    AddressU = 3;
    AddressV = 3;
};

float4 Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize : register(ps_3_0, c11) //HAHA
<string UIWidget = "None"; string SasBindAddress = "Sas.Shadow[0].Zero_Zero_OneOverMapSize_OneOverMapSize";>;

float2 MapCellSize 
<string UIWidget = "None"; string SasBindAddress = "Terrain.Map.CellSize";> = { 10, 10 };

texture MacroSampler 
<string UIWidget = "None"; string SasBindAddress = "Terrain.MacroTexture"; string ResourceName = "ShaderPreviewMacro.dds";>; 
sampler2D MacroSamplerSampler 
<string Texture = "MacroSampler"; string UIWidget = "None"; string SasBindAddress = "Terrain.MacroTexture"; string ResourceName = "ShaderPreviewMacro.dds";> 
= sampler_state
{
    Texture = <MacroSampler>; 
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 2;
    AddressU = 1;
    AddressV = 1;
};

int _SasGlobal : SasGlobal 
<string UIWidget = "None"; int3 SasVersion = int3(1, 0, 0); int MaxLocalLights = 8; int MaxSupportedInstancingMode = 1;>;

int NumJointsPerVertex 
<string UIWidget = "None"; string SasBindAddress = "Sas.Skeleton.NumJointsPerVertex";>;

column_major float4x3 World : World : register(vs_2_0, c124) : register(vs_3_0, c124);

texture CloudTexture 
<string UIWidget = "None"; string SasBindAddress = "Terrain.Cloud.Texture"; string ResourceName = "ShaderPreviewCloud.dds";>; 
sampler2D CloudTextureSampler 
<string Texture = "CloudTexture"; string UIWidget = "None"; string SasBindAddress = "Terrain.Cloud.Texture"; string ResourceName = "ShaderPreviewCloud.dds";>
= sampler_state
{
    Texture = <CloudTexture>; 
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 2;
    AddressU = 1;
    AddressV = 1;
};

texture EnvironmentTexture 
<string UIWidget = "None"; string SasBindAddress = "Objects.LightSpaceEnvironmentMap"; string ResourceType = "Cube";>; 
samplerCUBE EnvironmentTextureSampler 
<string Texture = "EnvironmentTexture"; string UIWidget = "None"; string SasBindAddress = "Objects.LightSpaceEnvironmentMap"; string ResourceType = "Cube";>
= sampler_state
{
    Texture = <EnvironmentTexture>; 
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 2;
    AddressU = 3;
    AddressV = 3;
    AddressW = 3;
};

texture DiffuseTexture 
<string UIName = "PaintCameo (DiffuseTexture)";>;  //repurposed to generic cameo albedo
sampler2D DiffuseTextureSampler : register(ps_2_0, s0) <string Texture = "DiffuseTexture";> 
= sampler_state
{
    Texture = <DiffuseTexture>; 
    MinFilter = 3;
    MagFilter = 2;
    MipFilter = 2;
    MaxAnisotropy = 8;
    AddressU = 1;
    AddressV = 1;
};

texture SpecMap 
<string UIName = "M.I.D.(SpecMap)";>;  //Red is insulent-metal map and inverse roughness, Green is AO + cavity, Blue is Paint HC, Alpha is glow HC
sampler2D SpecMapSampler : register(ps_2_0, s1) <string Texture = "SpecMap";>
= sampler_state
{
    Texture = <SpecMap>; 
    MinFilter = 3;
    MagFilter = 2;
    MipFilter = 2;
    MaxAnisotropy = 8;
    AddressU = 1;
    AddressV = 1;
};

texture NormalMap 
<string UIName = "NormalMap";>; 
sampler2D NormalMapSampler <string Texture = "NormalMap";>
= sampler_state
{
    Texture = <NormalMap>; 
    MinFilter = 3;
    MagFilter = 2;
    MipFilter = 2;
    MaxAnisotropy = 8;
    AddressU = 1;
    AddressV = 1;
};

// float EnvMult <string UIName = "Reflection Multiplier"; string UIWidget = "Slider"; float UIMax = 1; float UIMin = 0; float UIStep = 0.01;> = { 1 };

bool AlphaTestEnable 
<string UIName = "AlphaTestEnable";> = {0};  //is it even needed? ok we use cameo tex alpha as alphatest

struct {float4 ScaleUV_OffsetUV;} Shroud : register(vs_2_0, c11) : register(vs_3_0, c11) 
<string UIWidget = "None"; string SasBindAddress = "Terrain.Shroud";> = { 1, 1, 0, 0 };

texture ShroudTexture 
<string UIWidget = "None"; string SasBindAddress = "Terrain.Shroud.Texture";>; 
sampler2D ShroudTextureSampler 
<string Texture = "ShroudTexture"; string UIWidget = "None"; string SasBindAddress = "Terrain.Shroud.Texture";>
= sampler_state
{
    Texture = <ShroudTexture>; 
    MinFilter = 1;
    MagFilter = 1;
    MipFilter = 2;
    AddressU = 3;
    AddressV = 3;
};

float Time : Time;  //so it does know time?

//from here, my own parameters for PBR

float MidG_CavityEnd
<string UIName = "MidG_CavityEnd"; string UIWidget = "Slider"; float UIMax = 0.5; float UIMin = 0; float UIStep = 0.025;> = { 0.125 };

float MidA_GlowMultiply  //glow color always HC, glow intensity inverted alpha !
<string UIName = "MidA_GlowMultiply"; string UIWidget = "Slider"; float UIMax = 2; float UIMin = 0; float UIStep = 0.1;> = { 1 };

float3 MetalAlbedoPreset  //aka metal f0
<string UIName = "MetalAlbedoPreset"; string UIWidget = "Color";> = { 1,1,1 };

//The square of the dot product represents the cosine squared of the angle between the two vectors.
//When parallel 0d, =1
//when 30deg, =0.75
//when 45deg, =0.5
//when 60deg, =0.25
//when 90deg, =0
//angel above perpendicular 90d must be clamped

float2 MinMaxRoughness_LRD  //reflect angle acos limit model
<string UIName = "Min-Max Roughness(LR-degree)"; //prevent pointlight and sunlight from really become point, when midR=1
string UIWidget = "Slider"; float UIMin = 0.5; float UIMax = 180; float UIStep = 0.5;> = { 1,90 };
//in PS, these two limits will lerp in between using midR^2
//REFLECT ANGLE MODEL: RL 0-180 d 

//float2 MinMaxRoughness_HNA  //microfacet halfway distribution model, now unused
//<string UIName = "Min-Max Roughness(microfacet distribution)"; 
//string UIWidget = "Slider"; float UIMin = 0.01; float UIMax = 1; float UIStep = 0.01;> = { 0.01, 1 };
//MICROFACET DISTRIBUTION MODEL: NH 0-90 d, but unused

float2 FresnelF0toSide  //spec brightness at vertcle view (smaller end) and at side (bigger end)
<string UIName = "FresnelF0toSide"; string UIWidget = "Slider"; float UIMax = 1; float UIMin = 0; float UIStep = 0.05;> = { 0.1,0.9 };
//remember, fresnel effect decide KS, and 100%-KS=KD goes to lambertian, so at verticle view KS=F0, lambertian has most energy
//basically replaced MaxPaintLambertianKD
//X=F0, Y=side spec brightness (aka. reflectivity for dielectric)

//int ShadowPCFlevel
//<string UIName = "ShadowPCFlevel"; int UIMin = 0; int UIMax = 5;> = {3}; //to 4 sides, actual sampled length*4+1 times

//end input parameters

//start VERTEX shader

//start High, no skin, VS
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

VS_H_Array_Shader_0_Output VS_H_Array_Shader_0(VS_H_Array_Shader_0_Input i)
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
    o.texcoord5.xyz = temp0.xzw * temp0.yyy + float3(0, 0, -0.0025); //0.0015

    return o;
}
//end High, no skin, VS

//start High, with skin, VS
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
    float4 texcoord  : TEXCOORD ;   //texture UV
    float3 texcoord1 : TEXCOORD1;   //
    float3 texcoord2 : TEXCOORD2;
    float3 texcoord3 : TEXCOORD3;   //world normal? maybe?
    float3 texcoord4 : TEXCOORD4;   //world position
    float4 texcoord5 : TEXCOORD5;   //shadow map projected
    float4 texcoord6 : TEXCOORD6;   //shroud and cloud UV (probably verticle projection)
    float4 color : COLOR;   //looks like vertex color?
};

VS_H_Array_Shader_1_Output VS_H_Array_Shader_1(VS_H_Array_Shader_1_Input i)
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
    o.texcoord5.xyz = temp1.xyz * temp0.yyy + float3(0, 0, -0.004); //0.0025

    return o;
}
//end high, has skin, VS

VertexShader VS_H_Array[2] = 
{
    compile vs_3_0 VS_H_Array_Shader_0(),  //NO SKIN MESH
    compile vs_3_0 VS_H_Array_Shader_1(),  //BONES SKIN
};
//end VERTEX shader



//start PIXEL shader
struct PS_H_Array_Shader_0_Input
{
    float2 texcoord  : TEXCOORD ;   //texture UV
    float3 texcoord1 : TEXCOORD1;   //matrix
    float3 texcoord2 : TEXCOORD2;   //matrix, tangent space to world space 3x3 matrix
    float3 texcoord3 : TEXCOORD3;   //matrix
    float3 texcoord4 : TEXCOORD4;   //world position
    float3 texcoord5 : TEXCOORD5;   //shadow map projected
    float4 texcoord6 : TEXCOORD6;   //shroud and cloud UV (probably verticle projection)
    float4 color : COLOR;
};

float4 PS_H_Array_Shader_0 (PS_H_Array_Shader_0_Input i) : COLOR
{  //lets register the needed valriablea first
    float4 out_color = (1,1,1,1);  //so it does have alpha?
    float3 FragmentPosition = i.texcoord4.xyz;
    float3 V = normalize(EyePosition.xyz - FragmentPosition.xyz);
    float3 Lsun = DirectionalLight[0].Direction.xyz;
//    float3 halfway_eyesun = normalize(V + Lsun);

    float4 texMID = tex2D(SpecMapSampler, i.texcoord.xy);  //material id as RGBA, R=matalness+glossiness, G=ao, B=hc, A=glow invert.
    //metalstart is now hardcoded to 0.5
    float3 HCoverride = RecolorColor.rgb;
    if (HasRecolorColors <= 0) {HCoverride = float3(1,1,1) ;}
    float map_metalness = saturate(texMID.r*2);
    float map_roughness_lerpw = saturate((1- texMID.r) *2) ;
    float map_cavity = saturate(texMID.g / MidG_CavityEnd);
    float map_ao = texMID.g ; 
    float3 map_glow = RecolorColor * (1- texMID.a) * MidA_GlowMultiply;
    float4 texPAINT = tex2D(DiffuseTextureSampler, i.texcoord.xy);  //sample the generic cameo paint texture
    float3 albedopaint = lerp(texPAINT.rgb, HCoverride, texMID.b);
    float3 albedometal = lerp(MetalAlbedoPreset, HCoverride, texMID.b);

    float roughness_LRangle = lerp( MinMaxRoughness_LRD.x, MinMaxRoughness_LRD.y, pow(map_roughness_lerpw, 2) ); 
    //the maximum angle in DRGREES "between R_ and Lsun" to see the outer ring of spec blur
    //will be compared with acos(dot(R,L))

    //float roughness_HNalpha = pow( lerp( MinMaxRoughness_HNA.x, MinMaxRoughness_HNA.y, map_roughness_lerpw )  ,2); 
    //traditional model is now unused

    //apply normal map, from tangent space to world space
    float3 texNRM = tex2D(NormalMapSampler, i.texcoord.xy);
    texNRM.xyz = texNRM.xyz * float3(2, 2, 0) + float3(-1, -1, 1);  //temp0.xyz, max normal 60 deg deviation
    texNRM.z = sqrt(texNRM.x*texNRM.x + texNRM.y*texNRM.y);
    float3 N; //define surface normal here
    N.x = dot(texNRM.xyz, i.texcoord1.xyz);
    N.y = dot(texNRM.xyz, i.texcoord2.xyz);
    N.z = dot(texNRM.xyz, i.texcoord3.xyz);
    N.xyz = normalize(N.xyz);  
    float cosNV = dot(N,V); //face right onto camera =1, side view =0
    if ( cosNV < 0 )  //avoid surface backface to camera
    { N = normalize(N - cosNV * V);  cosNV =0; }
    //now we get surface normal vector in world space

    float3 R = reflect(V, N) ;  //light trace back from eye to surface to source

    //start environmental BRDF (left out sun, only AO and skybox)
    float3 BRDFtotal ;
    float3 env2diff = AmbientLightColor * map_ao * saturate(1.5 + N.z); //gets darker from 30 deg downward, to half bright at bottom
    float  FresnelV = lerp( FresnelF0toSide.x, FresnelF0toSide.y, pow(1-cosNV, 4) ) ;  //schlick approximation BUT SOFTER

    float  skybox_miplevel = max(sqrt(roughness_LRangle *0.4)-1 ,0); //for 90d=mip5, 10d=mip1, 4d=mip0
    float3 env2spec = texCUBE(EnvironmentTextureSampler, (R.xyz , skybox_miplevel));

    float3 envtotal_ifpaint = env2spec * FresnelV + env2diff * albedopaint;
    float3 envtotal_ifmetal = env2spec * albedometal ;
    BRDFtotal += lerp(envtotal_ifpaint, envtotal_ifmetal, map_metalness) ;
    //end environmental BRDF

    //start sunlight BRDF
    float SunlightColor ;
    if (HasShadow <= 0) {SunlightColor =1 ; }
    else {
        SunlightColor= helper_shadowpcf(
            4,
            ShadowMapSampler,
            Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w, 
            i.texcoord5) ; 
    }
    SunlightColor = SunlightColor * DirectionalLight[0].Color.xyz ;
    //this is sunlight color and brightness after shadow, sunlight direction is Lsun
    //float Fresnel_sun = lerp( FresnelF0toSide.x, FresnelF0toSide.y, pow(1-cosNV, 4) ) ; //shit who cares 
    float3 sunlight_BRDF = helper_BRDF_reflectangle (
        Lsun, //float3 L,
        R, //float3 R,
        N, //float3 N,
        roughness_LRangle, //float  roughness_limitangleLR, //angle limit of this pixel
        map_metalness, //float  metalness,
        albedopaint, //float3 albedopaint,
        albedometal, //float3 albedometal,
        FresnelV     //float FresnelV
    );
    BRDFtotal += sunlight_BRDF * SunlightColor ;
    //end sunlight BRDF

    //start point lights BRDF
    float3 thisPL_relative, thisPL_L, thisPL_COLOR, thisPL_BRDF ; float thisPL_decay ;//variables within the loop
    for (int countPL = 0; countPL < NumPointLights; ++countPL)
	{
        thisPL_relative = PointLight[countPL].Position.xyz - FragmentPosition.xyz ;
        thisPL_L = normalize(thisPL_relative) ;
        thisPL_decay =( dot(thisPL_relative,thisPL_relative) )/ pow(( PointLight[countPL].Range_Inner_Outer.x ), 2) ;
        thisPL_COLOR =thisPL_decay * PointLight[countPL].Color.xyz ;
        thisPL_BRDF = helper_BRDF_reflectangle (
            thisPL_L, //float3 L,
            R, //float3 R,
            N, //float3 N,
            roughness_LRangle, //float  roughness_limitangleLR, //angle limit of this pixel
            map_metalness, //float  metalness,
            albedopaint, //float3 albedopaint,
            albedometal, //float3 albedometal,
            FresnelV     //float FresnelV
            );
        BRDFtotal += thisPL_BRDF * thisPL_COLOR ;
	}
    //end point lights BRDF

    //final mixing
    BRDFtotal = BRDFtotal * map_cavity ; 
    out_color = (BRDFtotal.rgb, 1) * tex2D(ShroudTextureSampler, i.texcoord6.xy) ;
    out_color = out_color + float4(map_glow.rgb , texPAINT.w); //glow and alphatest
    return out_color;
}


PixelShader PS_H_Array[1] = 
{
    compile ps_3_0 PS_H_Array_Shader_0(),  //i only use one, like vanilla PS_H_3, has shadow has HC
};
//end PIXEL shader

//helper codes:
//if dot(v_light, N_) <0  , discard this light source
//float l_skybox_lerpw = acos(R_.z) / d_specblur_anglelimit/90 + 0.5  ; // in this variable, 0=use ground color, 1=use sky color,
//env2spec = lerp(EarthColor, SkyColor, l_skybox_lerpw);
//SHIT ILL JUST USE REAL SKYBOX

//now some more hassle : shadow projection
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
//shadow ps

    float4 PSCreateShadowMap_Array_Shader_0(float texcoord1 : TEXCOORD1) : COLOR
    {
    float4 out_color;
    float4 temp0;
    temp0 = texcoord1.x;
    out_color = temp0;

    return out_color;
    }

PixelShader PSCreateShadowMap_Array[1] = {compile ps_2_0 PSCreateShadowMap_Array_Shader_0()}; 
//no alphatest! screw you

//begin expressionsm decide which VS PS to choose
float _CreateShadowMap_Expression21()
{ return 0;}

float _CreateShadowMap_Expression22()
{
    float1 expr0;
    expr0.x = min(NumJointsPerVertex.x, (1));
    return expr0;
}


float Default_Expression27()  //high pixel shader, choose ps index 0123
{return 0;}

float Default_Expression28()  //high vertex shader
{
    float1 expr0;
    expr0.x = min(NumJointsPerVertex.x, (1));
    return expr0; //0 noskin 1 skin
}

//technique that decide which expression to use

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

//i guess we are done here, finally