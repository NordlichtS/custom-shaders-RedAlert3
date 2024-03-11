//Electronic Arts 2008 Red Alert 3 player units shader BUT WITH PBR ENHANCE!
//--------------
//last modified by Nordlicht 
//https://github.com/NordlichtS/custom-shaders-RedAlert3
//based on Lanyi's decompiled HLSL code
//https://github.com/lanyizi/DXDecompiler
//improvements: (only on high quality pixel shaders)
//spec map red channel as glossiness (also metalness)
//PBR shading with microfacet distribution model
//up to 8 point light support, all BRDF
//multiple adjustable parameters to make sure your textures can fit the style
//can also use on vanilla units
//make sure your models have correct smooth groups!
//SOFT PCF SHADOWS 16 samples
//gamma correction set to 2
//----------

#pragma warning(disable: 4008)
//#include <helperfunctions.fxh>
string DefaultParameterScopeBlock = "material"; 

//adjustable parameters

texture DiffuseTexture 
<string UIName = "DiffuseTexture";>; 

texture NormalMap 
<string UIName = "NormalMap";>; 

texture SpecMap 
<string UIName = "SpecMap";>; 

float ambient_multiply
<string UIName = "ambient_multiply"; 
string UIWidget = "Slider"; float UIMax = 1; float UIMin = 0; float UIStep = 0.01 ;> = { 0.4 };

float diffuse_multiply
<string UIName = "diffuse_multiply"; 
string UIWidget = "Slider"; float UIMax = 4; float UIMin = 0; float UIStep = 0.01 ;> = { 0.8 };

float spec_multiply
<string UIName = "spec_multiply"; 
string UIWidget = "Slider"; float UIMax = 4; float UIMin = 0; float UIStep = 0.1 ;> = { 1.0 };

float glow_multiply
<string UIName = "glow_multiply"; 
string UIWidget = "Slider"; float UIMax = 4; float UIMin = 0; float UIStep = 0.1 ;> = { 0.0 };

float pointlight_multiply
<string UIName = "pointlight_multiply"; 
string UIWidget = "Slider"; float UIMax = 4; float UIMin = 0; float UIStep = 0.1 ;> = { 1.5 };

float pointlight_peak
<string UIName = "pointlight_peak"; 
string UIWidget = "Slider"; float UIMax = 8; float UIMin = 1; float UIStep = 0.1 ;> = { 1.2 };

float fix_saturation
<string UIName = "fix_saturation"; 
string UIWidget = "Slider"; float UIMax = 32; float UIMin = 0.1; float UIStep = 0.1 ;> = { 16 };

float roughness
<string UIName = "roughness(microfacet-distribution)"; 
string UIWidget = "Slider"; float UIMax = 1; float UIMin = 0.1; float UIStep = 0.01;> = { 0.2 };

float glassf0
<string UIName = "glassf0(fresnel-decay)"; 
string UIWidget = "Slider"; float UIMax = 1; float UIMin = 0.01; float UIStep = 0.01;> = { 0.25 };

bool AlphaTestEnable 
<string UIName = "AlphaTestEnable";> =1;

// bool AlphaBlendEnable <string UIName = "AlphaBlendEnable";> =1;

bool HCcorrection
<string UIName = "HCcorrection";> =1;  //extra brightness for HC

bool GAMMAcorrection
<string UIName = "GAMMAcorrection";> =1;  //gamma is always 2.0

bool invert_tangent
<string UIName = "invert_tangent(dxNRMfix)";> = 0;  //dx nrm fix

//other parameters ===================

float3 AmbientLightColor
: register(vs_2_0, c4) : register(vs_3_0, c4) <bool unmanaged = 1;> = { 0.3, 0.3, 0.3 };

struct{    float3 Color;    float3 Direction;} 
DirectionalLight[3] : register(vs_2_0, c5) : register(ps_3_0, c5) : register(vs_3_0, c5) <bool unmanaged = 1;> = 
{ 1.625198, 1.512711, 1.097048, 0.62914, -0.34874, 0.69465, 
0.5232916, 0.6654605, 0.7815244, -0.32877, 0.90329, 0.27563, 
0.4420466, 0.4102767, 0.4420466, -0.80704, -0.58635, 0.06975 };

int NumPointLights  // : register(ps_3_0, i0) 
<string SasBindAddress = "Sas.NumPointLights"; string UIWidget = "None";> =8;

struct{    float3 Color;    float3 Position;    float2 Range_Inner_Outer;} 
PointLight[8] : register(ps_3_0, c89) <bool unmanaged = 1;>;

struct{    float4 WorldPositionMultiplier_XYZZ;    float2 CurrentOffsetUV;} 
Cloud : register(vs_3_0, c117) <bool unmanaged = 1;>;

float3 NoCloudMultiplier 
<bool unmanaged = 1;> = { 1, 1, 1 };

bool HasRecolorColors 
<string UIWidget = "None"; string SasBindAddress = "WW3D.HasRecolorColors"; bool ExportValue = 0;>;

float3 RecolorColor 
: register(ps_2_0, c0) : register(ps_3_0, c0) <bool unmanaged = 1;>;

column_major float4x4 ShadowMapWorldToShadow 
: register(vs_3_0, c113) <bool unmanaged = 1;>;

float OpacityOverride 
: register(vs_2_0, c1) : register(vs_3_0, c1) <bool unmanaged = 1;> = { 1 };

float3 TintColor 
: register(ps_2_0, c2) : register(ps_3_0, c2) <bool unmanaged = 1;> = { 1, 1, 1 };

float3 EyePosition 
: register(vs_3_0, c123) : register(ps_3_0, c123) <bool unmanaged = 1;>;

column_major float4x4 ViewProjection 
: register(vs_2_0, c119) : register(vs_3_0, c119) <bool unmanaged = 1;>;

float4 WorldBones[128] 
: register(vs_2_0, c128) : register(vs_3_0, c128) <bool unmanaged = 1;>;

bool HasShadow 
<string UIWidget = "None"; string SasBindAddress = "Sas.HasShadow";>;

texture ShadowMap 
<string UIWidget = "None"; string SasBindAddress = "Sas.Shadow[0].ShadowMap";>; 
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

float4 Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize 
: register(ps_3_0, c11) <string UIWidget = "None"; string SasBindAddress = "Sas.Shadow[0].Zero_Zero_OneOverMapSize_OneOverMapSize";>;

float2 MapCellSize 
<string UIWidget = "None"; string SasBindAddress = "Terrain.Map.CellSize";> = { 10, 10 };

texture MacroSampler 
<string UIWidget = "None"; string SasBindAddress = "Terrain.MacroTexture"; string ResourceName = "ShaderPreviewMacro.dds";>; 

sampler2D MacroSamplerSampler 
<string Texture = "MacroSampler"; string UIWidget = "None"; string SasBindAddress = "Terrain.MacroTexture"; string ResourceName = "ShaderPreviewMacro.dds";> =
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
<string UIWidget = "None"; int3 SasVersion = int3(1, 0, 0); int MaxLocalLights = 8; int MaxSupportedInstancingMode = 1;>;

int NumJointsPerVertex 
<string UIWidget = "None"; string SasBindAddress = "Sas.Skeleton.NumJointsPerVertex";>;

column_major float4x3 World : World 
: register(vs_2_0, c124) : register(vs_3_0, c124);

texture CloudTexture 
<string UIWidget = "None"; string SasBindAddress = "Terrain.Cloud.Texture"; string ResourceName = "ShaderPreviewCloud.dds";>; 
sampler2D CloudTextureSampler 
<string Texture = "CloudTexture"; string UIWidget = "None"; string SasBindAddress = "Terrain.Cloud.Texture"; string ResourceName = "ShaderPreviewCloud.dds";> =
sampler_state
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


sampler2D DiffuseTextureSampler : register(ps_2_0, s0) <string Texture = "DiffuseTexture"; string UIName = "DiffuseTexture";> =
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


sampler2D NormalMapSampler 
<string Texture = "NormalMap"; string UIName = "NormalMap";> =
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


sampler2D SpecMapSampler : register(ps_2_0, s1) <string Texture = "SpecMap"; string UIName = "SpecMap";> =
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



struct{    float4 ScaleUV_OffsetUV;} 
Shroud 
: register(vs_2_0, c11) : register(vs_3_0, c11) <string UIWidget = "None"; string SasBindAddress = "Terrain.Shroud";> = { 1, 1, 0, 0 };

texture ShroudTexture 
<string UIWidget = "None"; string SasBindAddress = "Terrain.Shroud.Texture";>; 
sampler2D ShroudTextureSampler <string Texture = "ShroudTexture"; string UIWidget = "None"; string SasBindAddress = "Terrain.Shroud.Texture";> =
sampler_state
{
    Texture = <ShroudTexture>; 
    MinFilter = 2;  //2
    MagFilter = 2;  //2
    MipFilter = 2;
    AddressU = 3;
    AddressV = 3;
};

float Time : Time;

//end parameters==========================

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
    temp0.xyz = temp0.xxx ;//* DirectionalLight[2].Color.xyz;
    temp1.z = float1(0.1);
    temp0.xyz =  temp1.zzz + temp0.xyz; //amb
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
    o.texcoord5.xyz = temp0.xzw * temp0.yyy + float3(0, 0, -0.002); //0.0015

    o.color.xyz = AmbientLightColor.xyz ;

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
    temp3.xyz = temp2.www ;//* DirectionalLight[2].Color.xyz;
    temp2.w = float1(0.1);
    temp3.xyz =  temp2.www + temp3.xyz; //amb
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
    o.texcoord5.xyz = temp1.xyz * temp0.yyy + float3(0, 0, -0.002); //0.0015

    o.color.xyz = AmbientLightColor.xyz ;

    return o;
}

VertexShader VS_H_Array[2] = {
    compile vs_3_0 VS_H_Array_Shader_0(), 
    compile vs_3_0 VS_H_Array_Shader_1(), 
};

//VS END===============================

float helper_notshadow_inside (int ShadowPCFlevel, float3 ShadowProjection )  
{
    if(!HasShadow){return 1;};
    float OneTexel = Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w ;
    float ShadowDensity = 0; float ShadowDepth; float2 ThisShiftUV; int countSAMplES; 
    for (float countSHIFT = 0.5- ShadowPCFlevel; countSHIFT < ShadowPCFlevel; countSHIFT +=1 )
    {
        ThisShiftUV = ShadowProjection.xy + float2 (OneTexel * countSHIFT , 0); //LEFT TO RIGHT
        ShadowDepth = tex2D(ShadowMapSampler, ThisShiftUV);
        ShadowDensity += (ShadowDepth < ShadowProjection.z) ? +1 : +0;

        ThisShiftUV = ShadowProjection.xy + float2 (0, OneTexel * countSHIFT);  //UP TO DOWN
        ShadowDepth = tex2D(ShadowMapSampler, ThisShiftUV);
        ShadowDensity += (ShadowDepth < ShadowProjection.z) ? +1 : +0;

        countSAMplES +=2 ;
    }
    ShadowDensity = saturate (ShadowDensity / countSAMplES) ;
    return 1- ShadowDensity;
}

float helper_pointlight ()
{
    return 0;
}

//ps start

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

//stylized
float4 PS_H_Array_Shader_3(PS_H_Array_Shader_3_Input i) : COLOR 
{
    float4 out_color = i.color.xyzw;

//get textures
    float4 texcolor = tex2D(DiffuseTextureSampler, i.texcoord.xy);
    float3 nrm      = tex2D(NormalMapSampler,      i.texcoord.xy);
    float4 spm      = tex2D(SpecMapSampler,        i.texcoord.xy);

    out_color.w = i.color.w * texcolor.w;
    if (AlphaTestEnable && texcolor.w <0.2 ) {discard ;};
    if (! HasRecolorColors) {spm.z =0 ;};

    float insulentf0 = max(texcolor.b , max(texcolor.r , texcolor.g)) ;  //glass judge before gamma
    insulentf0 = saturate (insulentf0 + glassf0);

    if (GAMMAcorrection) { texcolor.xyz *= texcolor.xyz ;};

    float spec_howsmall = spm.x / (roughness*roughness) ; //one over alpha, aka glossiness

    float3 albedo_color = texcolor.xyz; 
    if (HCcorrection) {albedo_color = saturate(albedo_color + texcolor.xyz*spm.z ); }; //HC enhance
    
    float3 satfix = albedo_color.rgb + (float3(1,1,1) / fix_saturation) ; //avoid zero
    satfix.rgb /= max(satfix.b , max(satfix.r , satfix.g));
    satfix = pow(satfix , 2) ;
    float3 f0spectrum = lerp ( float3(1,1,1) , satfix.rgb , spm.x ); //for metal


    float3 glowcolor = satfix.rgb * glow_multiply * spm.y ; //it's additive
    glowcolor = pow(glowcolor, 2) ; //extra gradient

    float3 real_diffusecolor = albedo_color.xyz * (1- spm.x) ; //diffuse lost at metal =1

//tangent space to world normal
    nrm = nrm.xyz * float3(2, 2, 0) + float3(-1, -1, 1) ;
    if (invert_tangent) {nrm.xy *= -1 ;};
    nrm.z = sqrt(1 - dot(nrm.xy, nrm.xy));
    float3 N ;
    N.x = dot(nrm, i.texcoord1.xyz);
    N.y = dot(nrm, i.texcoord2.xyz);
    N.z = dot(nrm, i.texcoord3.xyz);
    N.xyz = normalize (N);

//about sun and eye, also nrm backface fix

    float3 V = normalize (EyePosition.xyz - i.texcoord4.xyz);
    float  EYEtilt = dot(V,N) ; //1= perpendicular view, 0= side view
    EYEtilt = saturate(EYEtilt);
    // if ( EYEtilt < 0 )  //avoid surface backface to camera
    // { N = normalize(N - EYEtilt * V);  EYEtilt =0; };

    float3 R = reflect( (V * -1) , N ); //input light vector is towards fragment!

    float3 Lsun      = DirectionalLight[0].Direction.xyz ;
    float3 sun_color = DirectionalLight[0].Color.xyz ;
    float  sun_tilt  = saturate(dot(N,Lsun)) ;
    float3 Hsun = normalize(V + Lsun) ;

//ambient light diffuse //DO NOT USE "AmbientLightColor" this thing only exist in VS register!
    float  ground_sky_lerpw = saturate(N.z + 1)  ; // (N.z * sharpness + 1)
    //float3 ground_color = min (DirectionalLight[1].Color.xyz , DirectionalLight[2].Color.xyz) ;
    float3 ground_color = i.color.xyz ;
    float3 sky_color = max (DirectionalLight[1].Color.xyz , DirectionalLight[2].Color.xyz) ;
    sky_color = sky_color * sky_color * ambient_multiply + i.color.xyz ;
    float  skyAOcolor = lerp ( ground_color , sky_color , ground_sky_lerpw ) ;
    float3 diffuse_ambient = real_diffusecolor.xyz * skyAOcolor * ambient_multiply ; //* diffuse_multiply; 

//sunlight diffuse
    float3 diffuse_sunlight = real_diffusecolor.xyz * sun_tilt * diffuse_multiply;

//sunlight spec
    float  spec_dist = saturate( dot(Hsun,N) );
    spec_dist = saturate(spec_dist * spec_howsmall - spec_howsmall +1 ); //spec light blur within radius
    if (sun_tilt <= 0) {spec_dist = 0 ;};
    spec_dist = pow(spec_dist, 4) ; //simulate standard distribution
    float  FresnelS = lerp( insulentf0 , 1 , pow((1- dot(Hsun,V)), 3) ) ; //not accurate but worth a try
    float3 spec_sunlight = spec_dist * FresnelS * spm.x * f0spectrum.xyz * spec_multiply ; //(spm.x*spm.x)
    
//environmental mirror reflection
    float3 fake_skybox_lerpw = R.z * 0.5 * spm.x / roughness   ;
    fake_skybox_lerpw = saturate (fake_skybox_lerpw +0.5);
    float3 fake_skybox_color = lerp(ground_color, sky_color, fake_skybox_lerpw);
    float  FresnelV = lerp( insulentf0 , 1 , pow((1- EYEtilt), 3) ) ; //f0 is metalness
    float3 spec_ambient = fake_skybox_color * FresnelV * spm.x * f0spectrum.xyz *ambient_multiply ; //no spec multiply
    //make sure it's float3 or it will turn grey!

//shadow
    float not_shadow_density = helper_notshadow_inside (4, i.texcoord5.xyz) ;
    not_shadow_density *= not_shadow_density ; //gamma shadow
    float3 total_sunlight_influence = ( diffuse_sunlight + spec_sunlight ) * sun_color.xyz * not_shadow_density ;

//point lights
    float3 pl_total = float3(0,0,0) ;
    int maxPLcount = NumPointLights;

    for (int countpl = 0; countpl < maxPLcount; ++countpl ) {

        //if (thispl_COLOR.x + thispl_COLOR.y + thispl_COLOR.z ==0 ) {continue;};
        if ( PointLight[countpl].Range_Inner_Outer.y <1) {continue;};

        float3 thispl_relative = PointLight[countpl].Position.xyz - i.texcoord4.xyz ;
        float  thispl_distance = length(thispl_relative) ;
        float3 thispl_L = normalize(thispl_relative) ;
        float thispl_tilt = dot(thispl_L , N) ;
        if (thispl_tilt <=0) {continue;};

        float rangemin = PointLight[countpl].Range_Inner_Outer.x ; 
        float rangemax = PointLight[countpl].Range_Inner_Outer.y ; 
        float thispl_decaymult = (rangemax - thispl_distance)/(rangemax - rangemin) ;
        thispl_decaymult = clamp(thispl_decaymult , 0, pointlight_peak);
        thispl_decaymult *= thispl_decaymult ;
        float3 thispl_COLOR = PointLight[countpl].Color.xyz * thispl_decaymult  ;

        float3 diffuse_pl = real_diffusecolor.xyz * saturate(thispl_tilt) * diffuse_multiply;

        float3 H_pl = normalize(V + thispl_L) ;
        float  pl_specdist = saturate( dot(H_pl ,N) );
        pl_specdist = saturate(pl_specdist * spec_howsmall - spec_howsmall +1); 
        pl_specdist = pow(pl_specdist, 4) ;
        float3 spec_pl = spec_multiply * spm.x * pl_specdist * f0spectrum.xyz ; 

        float3 thispl_total = (diffuse_pl + spec_pl) * thispl_COLOR.xyz ;
        pl_total += thispl_total.rgb ;
    }
    pl_total.rgb *= pointlight_multiply ;

//final color modify
    out_color.xyz = diffuse_ambient + spec_ambient + total_sunlight_influence + pl_total ;
    float3 warfog = tex2D(ShroudTextureSampler, i.texcoord6.xy);
    out_color.xyz *= warfog ;
    float blackbody = saturate(spm.y * glow_multiply) ;
    out_color.xyz *= 1- blackbody ;
    out_color.xyz += glowcolor ;
    out_color.xyz = lerp( out_color.xyz, (out_color.xyz * RecolorColor), spm.z); //haha i put HC here
    out_color.xyz = lerp( (out_color.xyz * TintColor.xyz) , out_color.xyz  , (EYEtilt*EYEtilt) ); //use fresnel side light

    return out_color;
}



PixelShader PS_H_Array[1] = {compile ps_3_0 PS_H_Array_Shader_3() };

//END HIGH SHADERS================================
//DELETED M L SHADERS


//start shadow projection============

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
{   //shadow, no skin
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
{   //shadow, has skin
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



PixelShader PSCreateShadowMap_Array[1] = {    compile ps_2_0 PSCreateShadowMap_Array_Shader_0(), };


//expressions==========================

int VSchooser_Expression()  //0 no skin, 1 skin
{
    int whichVS = min(NumJointsPerVertex.x, (1));
    return whichVS;
}


//start techniques

technique Default
{
    pass p0 <string ExpressionEvaluator = "Objects";>
    {
        VertexShader = VS_H_Array[VSchooser_Expression()]; 
        PixelShader  = PS_H_Array[0];    
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        SrcBlend = 5;
        DestBlend = 6;
        AlphaFunc = 7;
        AlphaRef = 96;
        // AlphaBlendEnable = (AlphaBlendEnable) ;
    }
}

technique _CreateShadowMap
{
    pass p0
    {
        VertexShader = VSCreateShadowMap_Array[VSchooser_Expression()]; 
        PixelShader  = PSCreateShadowMap_Array[0];
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        AlphaBlendEnable = 0;
        AlphaTestEnable = 0;
    }
}


//RE-ROUTED TO HIGH SHADERS
technique Default_M
{
    pass p0 <string ExpressionEvaluator = "Objects";>
    {
        VertexShader = VS_H_Array[VSchooser_Expression()]; 
        PixelShader  = PS_H_Array[0];             
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
        VertexShader = VS_H_Array[VSchooser_Expression()]; 
        PixelShader  = PS_H_Array[0];             
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



//END?