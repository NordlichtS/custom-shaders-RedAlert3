//Electronic Arts 2008 Red Alert 3 player units shader 
//--------------
//last modified by Nordlicht 
//https://github.com/NordlichtS/custom-shaders-RedAlert3
//with help from Lanyi's tool
//https://github.com/lanyizi/DXDecompiler
//improvements: (only on high quality pixel shaders)
//diffuse use screen space sky texture
//gamma correction set to 2
//----------

#pragma warning(disable: 4008)
//#include <helperfunctions.fxh>
string DefaultParameterScopeBlock = "material"; 

//adjustable parameters

texture DiffuseTexture 
<string UIName = "DiffuseTexture";>; //暂时无用

texture NormalMap 
<string UIName = "NormalMap";>; //法线贴图

texture SpecMap 
<string UIName = "SpecMap";>; //暂时无用

texture ScreenSpaceTexture 
<string SasBindAddress = "WW3D.FXstarrysky256quad";>; //循环天空贴图！！！记得在scrapeo里注册

bool ignore_vertex_alpha
<string UIName = "ignore_vertex_alpha";> =0 ; //仅原版建筑开启！强制忽略顶点透明度，避免建筑损坏时破洞贴图错误，但会让车辆损失隐身半透明效果

bool AlphaTestEnable 
<string UIName = "AlphaTestEnable";> =1 ; //贴图镂空。与上一个选项不冲突。此选项原版就有！

bool HCenhance
<string UIName = "HCenhance";> =1 ;  //提升原版阵营色的饱和度（而不是亮度）也影响发光梯度

float4 GLOWcolor 
<string UIName = "GLOWcolor(Alpha=HC)"; string UIWidget = "Color"; > = {0, 0, 0, 0}; //发光颜色为 (此值RGB+A*阵营色)*SPM绿通道*2 !

float4 sidelight_color 
<string UIName = "sidelight_color"; string UIWidget = "Color"; > = {0, 0, 0, 1.1};

float starry_multiply
<string UIName = "starry_multiply"; 
string UIWidget = "Slider"; float UIMax = 4; float UIMin = 0; float UIStep = 0.1 ;> = { 1.25 };

float tangent_xy_multiply
<string UIName = "tangent_xy_multiply"; float UIMax = 1; float UIMin = -1; float UIStep = 0.1; > ={ 1 };  //如果法线图凹凸反了，写-1修正。完全无效化法线图，写0。

float sidelight_width
<string UIName = "sidelight_width"; float UIMax = 4; float UIMin = 0; float UIStep = 0.01; > ={ 0.5 };

float SSSpixel 
<string UIName = "SSSpixel(TextureSize)"; string UIWidget = "Slider"; float UIMin = 1; float UIMax = 1024; float UIStep = 1;> = 256 ;


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
: register(ps_2_0, c0) : register(ps_3_0, c0) <bool unmanaged = 1;> = {1,1,1};

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

float4 Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize 
: register(ps_3_0, c11) <string UIWidget = "None"; string SasBindAddress = "Sas.Shadow[0].Zero_Zero_OneOverMapSize_OneOverMapSize";>;

float2 MapCellSize 
<string UIWidget = "None"; string SasBindAddress = "Terrain.Map.CellSize";> = { 10, 10 };

int _SasGlobal : SasGlobal 
<string UIWidget = "None"; int3 SasVersion = int3(1, 0, 0); int MaxLocalLights = 8; int MaxSupportedInstancingMode = 1;>;

int NumJointsPerVertex 
<string UIWidget = "None"; string SasBindAddress = "Sas.Skeleton.NumJointsPerVertex";>;

column_major float4x3 World : World 
: register(vs_2_0, c124) : register(vs_3_0, c124);

struct{    float4 ScaleUV_OffsetUV;} 
Shroud 
: register(vs_2_0, c11) : register(vs_3_0, c11) <string UIWidget = "None"; string SasBindAddress = "Terrain.Shroud";> = { 1, 1, 0, 0 };

float Time : Time;

//============== OTHER TEXTURE AND SAMPLERS

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
    MinFilter = 2;
    MagFilter = 1;
    MipFilter = 1;
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


texture ShroudTexture 
<string UIWidget = "None"; string SasBindAddress = "Terrain.Shroud.Texture";>; 
sampler2D ShroudTextureSampler <string Texture = "ShroudTexture"; string SasBindAddress = "Terrain.Shroud.Texture";> =
sampler_state
{
    Texture = <ShroudTexture>; 
    MinFilter = 2;  //2
    MagFilter = 2;  //2
    MipFilter = 2;
    AddressU = 3;
    AddressV = 3;
};

sampler2D ScreenSpaceTextureSampler //this should be starry sky
<string Texture = "ScreenSpaceTexture"; string SasBindAddress = "WW3D.FXstarrysky256quad";> =
sampler_state
{
    Texture = <ScreenSpaceTexture>; 
    MinFilter = 2;
    MagFilter = 1;
    MipFilter = 1;
    AddressU = 1;
    AddressV = 1;
};

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
    temp0.w = 1;//dot(temp0.xyz, DirectionalLight[2].Direction.xyz);
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
    temp0 = i.position.xyzw * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
    temp1.x = dot(temp0, (World._m00_m10_m20_m30));
    temp1.y = dot(temp0, (World._m01_m11_m21_m31));
    temp1.z = dot(temp0, (World._m02_m12_m22_m32));
    temp1.w = float1(1);
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
    o.texcoord5.xyz = temp0.xzw * temp0.yyy + float3(0, 0, -0.004); //0.0015

    o.color.xyz = o.position.xyz / o.position.w; //clip space shrink into NDC

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
    float4 position  : POSITION;
    float4 texcoord  : TEXCOORD;
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
    temp2.w =1;// dot(temp2.xyz, DirectionalLight[2].Direction.xyz);
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
    o.texcoord5.xyz = temp1.xyz * temp0.yyy + float3(0, 0, -0.004); //0.0015

    o.color.xyz = o.position.xyz / o.position.w; //clip space shrink into NDC

    return o;
}

VertexShader VS_H_Array[2] = {
    compile vs_3_0 VS_H_Array_Shader_0(), 
    compile vs_3_0 VS_H_Array_Shader_1(), 
};

//VS END===============================



//ps start

struct PS_H_Array_Shader_3_Input
{
    float2 vpos : VPOS;  //screen space position
    float2 texcoord  : TEXCOORD;  //basic texture uv
    float3 texcoord1 : TEXCOORD1; //tangent space to world maxtrix 
    float3 texcoord2 : TEXCOORD2; //tangent space to world maxtrix 
    float3 texcoord3 : TEXCOORD3; //tangent space to world maxtrix 
    float3 texcoord4 : TEXCOORD4; //fragment world position
    float3 texcoord5 : TEXCOORD5; //shadow projection, z is depth (distance to sun)
    float4 texcoord6 : TEXCOORD6; //xy warfog , zw cloud
    float4 color : COLOR;  //xyz are camera space? position, w is vertex alpha
};

//stylized
float4 PS_H_Array_Shader_3(PS_H_Array_Shader_3_Input i) : COLOR 
{
    float4 out_color ; 

//get textures
    float4 texcolor = tex2D(ScreenSpaceTextureSampler, (i.vpos / SSSpixel)); //is now screen space
    float3 nrm      = tex2D(NormalMapSampler,      i.texcoord.xy);
    float3 spm = float3(0,0,0);   //  = tex2D(SpecMapSampler,        i.texcoord.xy);

    out_color.w = texcolor.w;
    texcolor.xyz *= texcolor.xyz ;  //gamma

    if (! ignore_vertex_alpha) { out_color.w *= i.color.w ;};
    float3 actualHC = RecolorColor ;
    if (! HasRecolorColors) { spm.z =0 ; actualHC = float3(1,1,1) ;}; 
    
    float3 starry_color = texcolor.xyz * starry_multiply ;

//tangent space to world normal
    nrm = nrm.xyz * float3(2, 2, 0) + float3(-1, -1, 1) ;
    nrm.xy *= tangent_xy_multiply ;//
    nrm.z = (1 - dot(nrm.xy, nrm.xy));  //sqrt
    float3 N ;
    N.x = dot(nrm, i.texcoord1.xyz);
    N.y = dot(nrm, i.texcoord2.xyz);
    N.z = dot(nrm, i.texcoord3.xyz);
    N.xyz = normalize (N);

//about sun and eye, 

    float3 V = normalize (EyePosition.xyz - i.texcoord4.xyz);
    float  EYEtilt = dot(V,N) ; //1= perpendicular view, 0= side view
    EYEtilt = saturate(EYEtilt);

//point lights
    float3 pl_total = float3(0,0,0) ;
    int maxPLcount = min(NumPointLights, 8); //JUST IN CASE

    for (int countpl = 0; countpl < maxPLcount; ++countpl ) {

        float rangemax = PointLight[countpl].Range_Inner_Outer.y ;
        if (rangemax <1) {continue;};

        float3 thispl_relative = PointLight[countpl].Position.xyz - i.texcoord4.xyz ;
        float  thispl_distance = length(thispl_relative) ;
        if (thispl_distance > rangemax) {continue;};

        float3 thispl_L = normalize(thispl_relative) ;
        float thispl_tilt = dot(thispl_L , N) ;
        if (thispl_tilt <0) {continue;};

        float thispl_decaymult = (rangemax - thispl_distance) /rangemax  ;
        thispl_decaymult = saturate(thispl_decaymult) ; //saturate must be done before square
        thispl_decaymult *= thispl_decaymult ; //square decay
        float3 thispl_COLOR = PointLight[countpl].Color.xyz * thispl_decaymult  ;

        float3 H_pl = normalize(V + thispl_L) ;
        float pl_specdist = saturate( dot(H_pl ,N) );
        pl_specdist = pow(pl_specdist, 64) ;  //BLINN

        float3 thispl_total = pl_specdist * thispl_COLOR.xyz ;
        pl_total += thispl_total.rgb ;
    };
    pl_total.rgb *= 1.2 ;

//side light glow and texture glow

    float sidelight_lumine = 1- saturate(EYEtilt / sidelight_width) ;
    float3 tempglow = (GLOWcolor.xyz + GLOWcolor.w * actualHC) * spm.y *2 ;
    tempglow += (sidelight_color.xyz + sidelight_color.w * actualHC) * sidelight_lumine ;
    if (HCenhance) { tempglow *= tempglow ;};

//final color modify
    out_color.xyz = starry_color ;
    out_color.xyz += pl_total ;
    out_color.xyz += tempglow ; //both glow
    out_color.xyz *= TintColor; 

    //float3 warfog = tex2D(ShroudTextureSampler, i.texcoord6.xy);
    //out_color.xyz *= warfog ;

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
        AlphaRef = 64;
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
        AlphaRef = 64;
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
        AlphaRef = 64;
    }
}



//END?