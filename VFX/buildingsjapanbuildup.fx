//Electronic Arts 2008 Red Alert 3 buildup scan shader
//double pass, vertex jump
//!!! this shader is used for those who dont want to edit vanilla textures !!!
//--------------
//last modified by Nordlicht 
//https://github.com/NordlichtS/custom-shaders-RedAlert3
//with help from Lanyi's tool
//https://github.com/lanyizi/DXDecompiler

//improvements: (only on high quality pixel shaders)


//----------
/*
// fxc.exe /T fx_2_0 /Fo   buildingsjapanbuildup.fxo   compatible_buildup_test.fx
*/
#define IS_BUILDING_SHADER 1
//CAN I USE IT?===================

#pragma warning(disable: 4008)
string DefaultParameterScopeBlock = "material"; 



//adjustable parameters

texture DiffuseTexture 
<string UIName = "DiffuseTexture";>; //主贴图

texture NormalMap 
<string UIName = "NormalMap";>; //法线贴图

texture SpecMap 
<string UIName = "SpecMap";>; //SPM贴图

#if defined(IS_BUILDING_SHADER)
texture DamagedTexture 
<string UIName = "DamagedTexture";>; //how does this work anyway
#endif

bool IgnoreDamageTex //忽略损伤破洞贴图。用于车辆1。建筑0。
<string UIName = "IgnoreDamageTex(vehicle=1,building=0)";> = 1 ; //!!!!!!!!!!!!!!!!!!!!!!!!

bool AlphaTestEnable //开启贴图镂空。此选项原版就有！
<string UIName = "AlphaTestEnable";> = 0 ; 

float GlowMAX  //发光 最大 亮度。发光颜色固定是阵营色
<string UIName = "GlowMAX(Brightness)"; float UIMax = 16; float UIMin = 0; float UIStep = 0.1; > = { 0 }; 

float GlowMIN  //发光 最小 亮度。（填负数可以有更大间隔的闪烁效果）
<string UIName = "GlowMIN(Brightness)"; float UIMax = 16; float UIMin = -16; float UIStep = 0.1; > = { 0 }; 

float GlowPeriod //发光呼吸周期，秒数，写0为禁止发光 
<string UIName = "GlowPeriod(sec,0=ForbidGlow)"; float UIMax = 10; float UIMin = 0; float UIStep = 0.2; > ={ 0 }; 

//原版车辆最好把发光相关都写0，因为那些SPM绿通道都是乱的。中立物体酌情考虑开启

texture ScreenSpaceTexture //循环天空贴图！！！记得在scrapeo里注册
<string SasBindAddress = "WW3D.FXstarrysky256quad";>; 
sampler2D ScreenSpaceTextureSampler //this should be starry sky
<string Texture = "ScreenSpaceTexture"; string SasBindAddress = "WW3D.FXstarrysky256quad";> =
sampler_state
{
    Texture = <ScreenSpaceTexture>; 
    MinFilter = 1;
    MagFilter = 1;
    MipFilter = 1;
    AddressU = 1;
    AddressV = 1;
};

// internal style parameters ======================
//MOVED TO LOCAL VARIABLES

//other param===================================


float3 RecolorColor
: register(ps_2_0, c0) : register(ps_3_0, c0) 
<string UIWidget="None"; bool ExportValue = false;> = {1,0,0};

bool HasRecolorColors 
<string UIWidget="None"; string SasBindAddress = "WW3D.HasRecolorColors"; bool ExportValue = 0;> =1 ;

float3 AmbientLightColor
: register(vs_2_0, c4) : register(vs_3_0, c4) 
<string UIWidget="None"; //string SasBindAddress = "Sas.AmbientLight[0].Color"; 
bool unmanaged = 1;> = { 0.3, 0.2, 0.1 };

struct{    float3 Color;    float3 Direction;} 
DirectionalLight[3] : register(vs_2_0, c5) : register(ps_3_0, c5) : register(vs_3_0, c5) <string UIWidget="None"; bool unmanaged = 1;> = 
{ 1.0, 1.0, 1.0,   0, 0, 1, 
  0.5, 0.6, 0.7,   0, 1, 0, 
  0.3, 0.3, 0.3,   1, 0, 0 };

int NumPointLights  // : register(ps_3_0, i0) 
<string UIWidget="None"; string SasBindAddress = "Sas.NumPointLights"; > =8;

struct{    float3 Color;    float3 Position;    float2 Range_Inner_Outer;} 
PointLight[8] : register(ps_3_0, c89) <string UIWidget="None"; bool unmanaged = 1;>;

struct{    float4 WorldPositionMultiplier_XYZZ;    float2 CurrentOffsetUV;} 
Cloud : register(vs_3_0, c117) <string UIWidget="None"; bool unmanaged = 1;>;

float3 NoCloudMultiplier 
<string UIWidget="None"; bool unmanaged = 1;> = { 1, 1, 1 };

column_major float4x4 ShadowMapWorldToShadow 
: register(vs_3_0, c113) <string UIWidget="None"; bool unmanaged = 1;>;

float OpacityOverride 
: register(vs_2_0, c1) : register(vs_3_0, c1) <string UIWidget="None"; bool unmanaged = 1;> = { 1 };

float3 TintColor 
: register(ps_2_0, c2) : register(ps_3_0, c2) <string UIWidget="None"; bool unmanaged = 1;> = { 1, 1, 1 };

float3 EyePosition 
: register(vs_3_0, c123) : register(ps_3_0, c123) <string UIWidget="None"; bool unmanaged = 1;> = {0,0,0};

column_major float4x4 ViewProjection 
: register(vs_2_0, c119) : register(vs_3_0, c119) <string UIWidget="None"; bool unmanaged = 1;>;

float4 WorldBones[128] 
: register(vs_2_0, c128) : register(vs_3_0, c128) <string UIWidget="None"; bool unmanaged = 1;>;

bool HasShadow 
<string UIWidget="None"; string SasBindAddress = "Sas.HasShadow";> =0;

float4 Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize 
: register(ps_3_0, c11) <string UIWidget="None"; string SasBindAddress = "Sas.Shadow[0].Zero_Zero_OneOverMapSize_OneOverMapSize";>;

float2 MapCellSize 
<string UIWidget="None"; string SasBindAddress = "Terrain.Map.CellSize";> = { 10, 10 };

int _SasGlobal : SasGlobal 
<string UIWidget="None"; int3 SasVersion = int3(1, 0, 0); int MaxLocalLights = 8; int MaxSupportedInstancingMode = 1;>;

int NumJointsPerVertex 
<string UIWidget="None"; string SasBindAddress = "Sas.Skeleton.NumJointsPerVertex";> =0 ;

column_major float4x3 World : World 
: register(vs_2_0, c124) : register(vs_3_0, c124);

struct{    float4 ScaleUV_OffsetUV;} 
Shroud 
: register(vs_2_0, c11) : register(vs_3_0, c11) <string UIWidget="None"; string SasBindAddress = "Terrain.Shroud";> = { 1, 1, 0, 0 };

float Time : Time;



//============== OTHER TEXTURE AND SAMPLERS

sampler2D DamagedTextureSampler //
<string Texture = "DamagedTexture"; > = sampler_state
{
    Texture = <DamagedTexture>; 
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 2;
    AddressU = 1;
    AddressV = 1;
};

texture ShadowMap 
<string UIWidget="None"; string SasBindAddress = "Sas.Shadow[0].ShadowMap";>; 
sampler2D ShadowMapSampler : register(ps_3_0, s0) 
<string Texture = "ShadowMap";  string SasBindAddress = "Sas.Shadow[0].ShadowMap";> =
sampler_state
{
    Texture = <ShadowMap>; 
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 0;
    AddressU = 3;
    AddressV = 3;
};


texture CloudTexture 
<string UIWidget="None"; string SasBindAddress = "Terrain.Cloud.Texture"; string ResourceName = "ShaderPreviewCloud.dds";>; 
sampler2D CloudTextureSampler 
<string Texture = "CloudTexture"; string SasBindAddress = "Terrain.Cloud.Texture"; string ResourceName = "ShaderPreviewCloud.dds";> =
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
<string UIWidget="None"; string SasBindAddress = "Objects.LightSpaceEnvironmentMap"; string ResourceType = "Cube";>; 
samplerCUBE EnvironmentTextureSampler 
<string Texture = "EnvironmentTexture";  string SasBindAddress = "Objects.LightSpaceEnvironmentMap"; string ResourceType = "Cube";> =
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


sampler2D DiffuseTextureSampler //: register(ps_2_0, s0) 
<string Texture = "DiffuseTexture"; string UIName = "DiffuseTexture";> =
sampler_state
{
    Texture = <DiffuseTexture>; 
    MinFilter = 3; //3
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


sampler2D SpecMapSampler //
<string Texture = "SpecMap"; string UIName = "SpecMap";> =
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
<string UIWidget="None"; string SasBindAddress = "Terrain.Shroud.Texture";>; 
sampler2D ShroudTextureSampler 
<string Texture = "ShroudTexture"; string SasBindAddress = "Terrain.Shroud.Texture";> =
sampler_state
{
    Texture = <ShroudTexture>; 
    MinFilter = 2;  //2
    MagFilter = 2;  //2
    MipFilter = 2;
    AddressU = 3;
    AddressV = 3;
};


// fxc.exe /T fx_2_0 /Fo   buildingsjapanbuildup.fxo   compatible_buildup_test.fx

//end parameters==========================

//vs helper function

float2 helper_vertextweak(float texUVY, float old_alpha)
{
    float addheight ; float newalpha;
    float scan_interval = 0.05 ; float print_height = 512 ;
    float scanline_in_uv = lerp( 1, -scan_interval, old_alpha) ; //old alpha 0->1, scanline 1->0
    newalpha = (texUVY - scanline_in_uv) / scan_interval ;
    newalpha = clamp(newalpha , 0, 1) ;
    addheight = (1 - newalpha) * print_height;
    float2 height_and_alpha = float2(addheight, newalpha) ;
    return height_and_alpha;
};



/*
    float2 vertextweak = helper_vertextweak(i.texcoord.y , o.color.w); 
    //x= add height, y= new alpha
    temp1.z += vertextweak.x ;
    o.color.w = vertextweak.y ;
    //clip(o.color.w);
*/

float3 helper_vertexjump(float texUVY, float old_alpha)
{
    float newalpha = 0; float is_on_top =0;
    float interval = 0.05 ; 
    float scanline_in_uv = lerp( 1.01, -interval, old_alpha) ; 
    newalpha = (texUVY - scanline_in_uv) / interval ;
    if(newalpha < 0){is_on_top = 1 ;};
    float starrypass_readyness = saturate(newalpha +1);
    float objectpass_finished = saturate(newalpha); //1 means no brighten

    return float3(is_on_top, starrypass_readyness, objectpass_finished) ;
};

//vs============

struct VS_H_Array_Shader_0_Input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 tangent : TANGENT;
    float4 binormal : BINORMAL;
    float4 texcoord : TEXCOORD;
        float4 texcoord1 : TEXCOORD1;
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
    float3 printindex : TEXCOORD7;

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
    temp1.z = float1(0);
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

o.printindex.xyz = helper_vertexjump(i.texcoord.y , o.color.w); 
//float3(is_on_top, starrypass_readyness, objectpass_finished)
    temp1.z += o.printindex.x * 512;

    o.position.x = dot(temp1, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp1, (ViewProjection._m01_m11_m21_m31));
    o.position.z = dot(temp1, (ViewProjection._m02_m12_m22_m32));
    o.position.w = dot(temp1, (ViewProjection._m03_m13_m23_m33));
    temp0.xy = temp1.xy + Shroud.ScaleUV_OffsetUV.zw;
    o.texcoord6.xy = temp0.xy * Shroud.ScaleUV_OffsetUV.xy;
    temp0.xy = temp1.zz * Cloud.WorldPositionMultiplier_XYZZ.zw;
    temp0.xy = temp1.xy * Cloud.WorldPositionMultiplier_XYZZ.xy + -temp0.xy;
    o.texcoord6.zw = Cloud.CurrentOffsetUV.xy; //temp0.xy + 
    o.texcoord.xy = i.texcoord.xy;
    o.texcoord.zw = i.texcoord1.yx; //for damage
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
    o.texcoord5.xyz = temp0.xzw * temp0.yyy + float3(0, 0, -0.0025); 

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
        float4 texcoord1 : TEXCOORD1;
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
    float3 printindex : TEXCOORD7;

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
    temp2.w = float1(0);
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

o.printindex.xyz = helper_vertexjump(i.texcoord.y , o.color.w); 
//float3(is_on_top, starrypass_readyness, objectpass_finished)
    temp0.z += o.printindex.x * 512;

    o.position.x = dot(temp0, (ViewProjection._m00_m10_m20_m30));
    o.position.y = dot(temp0, (ViewProjection._m01_m11_m21_m31));
    o.position.z = dot(temp0, (ViewProjection._m02_m12_m22_m32));
    o.position.w = dot(temp0, (ViewProjection._m03_m13_m23_m33));
    temp1.xy = temp0.xy + Shroud.ScaleUV_OffsetUV.zw;
    o.texcoord6.xy = temp1.xy * Shroud.ScaleUV_OffsetUV.xy;
    temp1.xy = temp0.zz * Cloud.WorldPositionMultiplier_XYZZ.zw;
    temp1.xy = temp0.xy * Cloud.WorldPositionMultiplier_XYZZ.xy + -temp1.xy;
    o.texcoord6.zw =  Cloud.CurrentOffsetUV.xy; //temp1.xy +
    o.texcoord.xy = i.texcoord.xy;
    o.texcoord.zw = i.texcoord1.yx; //for damage
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
    o.texcoord5.xyz = temp1.xyz * temp0.yyy + float3(0, 0, -0.0025);

    o.color.xyz = AmbientLightColor.xyz ;

    return o;
}

VertexShader VS_H_Array[2] = {
    compile vs_3_0 VS_H_Array_Shader_0(), 
    compile vs_3_0 VS_H_Array_Shader_1(), 
};

//VS END===============================

float helper_notshadow_inside ( float3 ShadowProjection )  
{
    if(! HasShadow){return 1;};
    int ShadowPCFlevel = 2 ;
    float OneTexel = Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w ;
    float ShadowDensity = 0; float ShadowDepth; float2 ThisShiftUV; int countSAMPLES; 
    for (float countSHIFT = 0.5- ShadowPCFlevel; countSHIFT < ShadowPCFlevel; countSHIFT += 1 )
    {
        ThisShiftUV = ShadowProjection.xy + float2 (OneTexel * countSHIFT , 0); //LEFT TO RIGHT
        ShadowDepth = tex2D(ShadowMapSampler, ThisShiftUV);
        ShadowDensity += (ShadowDepth < ShadowProjection.z) ? +1 : +0;

        ThisShiftUV = ShadowProjection.xy + float2 (0 , OneTexel * countSHIFT); //UP TO DOWN
        ShadowDepth = tex2D(ShadowMapSampler, ThisShiftUV);
        ShadowDensity += (ShadowDepth < ShadowProjection.z) ? +1 : +0;

        countSAMPLES +=2 ;
    }
    ShadowDensity = saturate (ShadowDensity / countSAMPLES) ;
    return 1- ShadowDensity;
};

float helper_specdist(float glossiness, float3 R, float3 L)
{
    float cosRL = dot(R,L);
    cosRL = saturate(cosRL);
    float OOA = glossiness * glossiness ; //one over alpha
    //square function is similar to cosine within half period
    float specdist = cosRL * OOA - OOA +1 ;
    specdist = saturate(specdist);
    specdist = pow(specdist , 4 ); //smooth tails
    float peakbrightness = glossiness ;//* specbase_multiply ;
    specdist *= peakbrightness ;
    return specdist ;
};

float helper_fresnel(float3 L, float3 V, float F0)
{
    float cosRV = dot( L , V ) ;
    float lerpw = (1- cosRV)/2 ;
    lerpw = pow (lerpw, 8);
    float fresnelLV = lerp(F0, 1, lerpw);
    return fresnelLV ;
};

float3 helper_color_decider (float4 InputColor, float3 actualHC)  
{   return (InputColor.xyz + InputColor.w * actualHC) ;  };

float3 helper_normalmapper(float2 TEXtangent) 
{
    float3 nrm = float3(TEXtangent ,1 ) ;
    nrm.xy = nrm.xy * 2 -1 ;
    //nrm.xy *= tangent_xy_multiply ;//
    nrm.z = saturate(1 - dot(nrm.xy, nrm.xy)) *2; //sqrt
    return nrm ;
};

float helper_glowpulse()
{
    if(GlowPeriod ==0){return 0;};
    float phase = frac( Time / GlowPeriod ) ;
    phase = abs(phase *2 -1) ;
    float LumineMult = lerp(GlowMIN, GlowMAX, phase) ;
    LumineMult = clamp(LumineMult, 0, 4);
    return LumineMult ;
}

float3 helper_fakeskybox_noise (int index, float3 EVC, float3 R, float2 cloudoffset, float sharpness)  
{
    float2 cloudUV = ( R.xy / R.z ) + cloudoffset ;
    float3 cloudnoise = tex2D(CloudTextureSampler, cloudUV);
    cloudnoise = clamp(((0.5- cloudnoise) * sharpness), -1,1 ); // or cloudnoise - 0.5
    float3 cloudds = saturate(R.z *2) * cloudnoise;  //avoid horizon, reduce noise below 30 degrees
    float3 EVCMAX = float3(1,1,1)* max(EVC.z, max(EVC.x, EVC.y));
    float3 EVCMIN = float3(1,1,1)* min(EVC.z, min(EVC.x, EVC.y));
    float3 EVCAVG = float3(1,1,1)* ( EVC.x + EVC.y + EVC.z )/3 ;
    float3 mixedcolor ;
    if (index==0) { mixedcolor= cloudnoise ;};
    if (index==1) { mixedcolor= EVC + cloudds ;};
    if (index==2) { mixedcolor= EVC - cloudds ;};
    if (index==3) { mixedcolor= EVC * cloudds ;};
    if (index==4) { mixedcolor= lerp(EVC, EVCMAX, cloudds) ;};
    if (index==5) { mixedcolor= lerp(EVC, EVCMIN, cloudds) ;};
    if (index==6) { mixedcolor= lerp(EVC, EVCAVG, cloudds) ;};

    return mixedcolor ;
};

float3 helper_mapcolor_chooser (int index, float3 vertexcolorab)  
{
    float3 chosenone ;
    if (index==0) {chosenone= DirectionalLight[0].Color.xyz ;};
    if (index==1) {chosenone= DirectionalLight[1].Color.xyz ;};
    if (index==2) {chosenone= DirectionalLight[2].Color.xyz ;};
    if (index==3) {chosenone= max (DirectionalLight[1].Color.xyz , DirectionalLight[2].Color.xyz) ;};
    if (index==4) {chosenone= min (DirectionalLight[1].Color.xyz , DirectionalLight[2].Color.xyz) ;};
    if (index==5) {chosenone= float3(0,0,0) ;};
    if (index==6) {chosenone= float3(1,1,1) ;};
    if (index==7) {chosenone= vertexcolorab ;};
    if (index==8) {chosenone= (DirectionalLight[1].Color.xyz + DirectionalLight[2].Color.xyz) ;};
    if (index==9) {chosenone= (max(DirectionalLight[1].Color.xyz , DirectionalLight[2].Color.xyz) + vertexcolorab) ;};
    if (index==10){chosenone= (DirectionalLight[1].Color.xyz + DirectionalLight[2].Color.xyz + vertexcolorab) ;};
    if (index==11){chosenone= float3(0.4 , 0.5 , 0.6) ;};
    if (index==12){chosenone= float3(0.3 , 0.2 , 0.1) ;};

    return chosenone ;
};

/*
天空色和地面色的 INDEX :
0= 阳光颜色
1= 地编补光1
2= 地编补光2 
3= 补光二者最大值
4= 补光二者最小值
5= 纯黑
6= 纯白
7= 地编环境光颜色
8= 两个地编补光相加
9= 补光最大值与环境光相加
10= 两个补光与环境光相加
*/ 


//ps start



struct PS_H_MAIN_INPUT
{
    float2 vpos : VPOS;  //screen space position
    float4 MainTexUV  : TEXCOORD;  //xy basic texture, wz building damage
    float3 texcoord1  : TEXCOORD1; //tangent space to world maxtrix 1
    float3 texcoord2  : TEXCOORD2; //tangent space to world maxtrix 2
    float3 texcoord3  : TEXCOORD3; //tangent space to world maxtrix 3
    float3 FragWpos   : TEXCOORD4; //fragment world position
    float3 ShadowPROJ : TEXCOORD5; //shadow projection, z is depth (distance to sun)
    float4 FogCloudUV : TEXCOORD6; //xy warfog , zw cloud (now only offset)
    float4 color : COLOR;  //vertex color (now ambient color, and transparency)
    float3 printindex : TEXCOORD7; //(is_on_top, starrypass_readyness, objectpass_finished)

};
//for second pass
float4 PS_starry(PS_H_MAIN_INPUT i) : COLOR 
{
    clip(0.9999 - i.printindex.x);
    clip(i.printindex.x - 0.0001);
    float4 specialoutput = tex2D(ScreenSpaceTextureSampler , (i.vpos / 256));
    specialoutput.w *= pow(i.printindex.y , 2) ; //逐渐出现
    specialoutput *= pow(specialoutput , 2) ;  //gamma，顺便再让光束透明度多两次方
    specialoutput.w = min((1 - i.printindex.x), specialoutput.w); //确保柔和过渡

    return specialoutput;
}

//the main ps ========================
float4 PS_H_MAIN(PS_H_MAIN_INPUT i) : COLOR 
{
clip(0.00001 - i.printindex.x);
    float3 build_tri_dif = float3(0.4, 0.8, 1.0); //tbd
    float3 build_tri_spm = float3(0.9, 0, 0); //tbd
    float3 build_tri_fixed = float3(0, 2, 1);
    float build_tri_lerpw = pow(i.printindex.z , 4) ; 
    //(is_on_top, starrypass_readyness, objectpass_finished)
    //lerpw being: 0 = build color, 1 = object color

//fake global variables

    float MINroughness =  0.125 ; //最低粗糙度
    float ambient_multiply =  0.25 ; //环境光与天空亮度 
    float sunlight_multiply =  1 ; //阳光亮度
    float diffuse_multiply =  1 ; //漫反射亮度，影响阳光与点光源
    float specbase_multiply =  1 ; //高光在最大粗糙度下的基础峰值亮度，影响阳光与点光源
    float pointlight_multiply =  1.25 ; //点光源反射整体亮度
    float MetalSaturation = 1.5 ; //金属反射光谱的饱和度倍增

    //END fake global variables

//get textures
    float4 dif = tex2D(DiffuseTextureSampler,  i.MainTexUV.xy);
    float4 nrm = tex2D(NormalMapSampler,       i.MainTexUV.xy);
    float4 spm = tex2D(SpecMapSampler,         i.MainTexUV.xy);

    float3 actualHC = (HasRecolorColors)? RecolorColor : float3(1,1,1) ;


    float  greyscale = (dif.x + dif.y + dif.z)/3 ;
    float3 satfix = (dif.xyz +0.01) / (greyscale +0.01); 
    satfix = lerp(float3(1,1,1), satfix, MetalSaturation);
    satfix = clamp(satfix, 0, 2);
    float3 HCchannelMult = lerp (float3(1,1,1) , actualHC , spm.z);
    float  Reflectivity = spm.x ;  //mult on spec
    float3 speccolor = lerp(float3(1,1,1), satfix, (spm.x * spm.x) ) * Reflectivity ; //(spm.x * spm.x)
    float  glossgradient = (spm.x * spm.x) ;
    float  roughness = lerp(1, MINroughness, glossgradient);
    float  glossiness = 1 / roughness ; //one over roughness, not alpha
    //float  metalness = helper_metalness (spm.x) ;
    float3 difcolor = (dif.xyz * dif.xyz) * (1- Reflectivity) * HCchannelMult; //(spm.x * spm.x)
    float  difAO = saturate(dif.x + dif.y + dif.z ) ;  //mult on env dif
    float  mirAO = saturate(difAO + spm.x ) ;  //mult on env spec
    //float  F0 = lerp(FresnelF0 , 1, metalness);
    //float  blackbody = saturate(dif.x + dif.y + dif.z + spm.x) ;

//tangent space to world normal
    nrm.xyz = helper_normalmapper(nrm.xy) ;
    float3 N ;
    N.x = dot(nrm.xyz, i.texcoord1.xyz);
    N.y = dot(nrm.xyz, i.texcoord2.xyz);
    N.z = dot(nrm.xyz, i.texcoord3.xyz);
    N.xyz = normalize (N);

//about eye and sun
    float3 V = (EyePosition.xyz - i.FragWpos.xyz);

    V = normalize(V) ;

    float  EYEtilt = dot(V , N) ; //1= perpendicular view, 0= side view , -1=back
    float3 R = reflect(-V , N); //input light vector is towards fragment!
    if(EYEtilt <0){R = -V ;}; //SHOULD I FIX IT ?

    float3 Lsun      = DirectionalLight[0].Direction.xyz ;
    float3 sun_color = DirectionalLight[0].Color.xyz ;


    sun_color *= helper_notshadow_inside(i.ShadowPROJ);


    float  sun_tilt  = dot(N,Lsun) ;
    if(sun_tilt <= 0) {sun_color = 0 ;};


//所有BRDF：自身光谱 x 分布方程或AO x (spec菲涅尔) x [光源色] x 风格multiply
//environmental stuff
    float3 sky_color    = max(DirectionalLight[1].Color.xyz , DirectionalLight[2].Color.xyz) + i.color.xyz ;
    float3 ground_color = i.color.xyz ;

    float3 fake_skybox_upper = sky_color ;
    float3 fake_skybox_lower = ground_color ;

    float  ground_sky_lerpw = saturate(R.z * glossiness +0.5) ;
    float3 fake_skybox_color = lerp(fake_skybox_lower, fake_skybox_upper, ground_sky_lerpw);
    float3 EVspec = speccolor *  fake_skybox_color * mirAO ;//* helper_fresnel(R, V, F0)  ;
    //              自身光谱,     , 光源色,                            
    float3 EVambientlight = lerp(ground_color, sky_color, (N.z +1)/2 );
    float3 EVdiff = difcolor  * EVambientlight * difAO;
    //              自身光谱,    光源色
    float3 EVtotal = (EVspec + EVdiff) * ambient_multiply ; //所属风格multiply

//sunlight BRDF
    float3 SUNdiff =  difcolor * sun_tilt * diffuse_multiply;
    float3 SUNspec = speccolor * helper_specdist(glossiness, R, Lsun) * specbase_multiply;//* helper_fresnel(Lsun, V, F0);
    float3 SUNtotal = sun_color * (SUNdiff + SUNspec) * sunlight_multiply; //光源色

//point lights
    float3 PLtotal = float3(0,0,0) ;


    int maxPLcount = clamp(NumPointLights, 0, 8); //JUST IN CASE

    for (int countpl = 0; countpl < maxPLcount; ++countpl ) 
    {
        float PLrange = PointLight[countpl].Range_Inner_Outer.y ;
        if ( PLrange <1) {continue;};

        float3 PLpos = PointLight[countpl].Position.xyz - i.FragWpos.xyz ;
        float  PLdistSquare = dot(PLpos, PLpos) ;
        float  PLrangeSquare = dot(PLrange, PLrange) ;
        if ( PLdistSquare > PLrangeSquare) {continue;};

        float3 PLL = normalize(PLpos);
        float  PLtilt = dot(PLL, N) ;
        if ( PLtilt < 0 ) {continue;};

        float  decaymult = 1- saturate(PLdistSquare / PLrangeSquare) ;
        decaymult = pow(decaymult , 3) ;
        float3 PLcolor = PointLight[countpl].Color.xyz * decaymult;

        float3 PLdiff = difcolor * PLtilt * diffuse_multiply;
        float3 PLspec = speccolor * helper_specdist(glossiness, R, PLL) * specbase_multiply;//* helper_fresnel(PLL, V, F0);
        
        PLtotal += PLcolor * (PLdiff + PLspec) ;
    };
    PLtotal *= pointlight_multiply ;


//final color modify
    float4 out_color = float4(1,1,1,1);
    out_color.w = dif.w ;
    out_color.xyz = EVtotal + SUNtotal + PLtotal ;
    out_color.xyz *= TintColor ;
    out_color.xyz *= HCchannelMult;



    float3 warfog = tex2D(ShroudTextureSampler, i.FogCloudUV.xy) ;
    out_color.xyz *= warfog ;  


    if(HasRecolorColors)
    {out_color.xyz += spm.y * RecolorColor * helper_glowpulse();}; 

out_color.xyz = lerp(build_tri_fixed, out_color.xyz, build_tri_lerpw);
    //lerpw being: 0 = build color, 1 = object color

    return out_color;
};

/*
fxc.exe /O1 /T fx_2_0 /Fo   objects_comp.fxo   objectsworkflow_compatible.fx
fxc.exe /O1 /T fx_2_0 /Fo  comp_objects.fxo  objectsworkflow_compatible.fx
fxc.exe /O1 /T fx_2_0 /Fo  comp_building.fxo  objectsworkflow_compatible.fx
*/

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

float3 printindex = helper_vertexjump(i.texcoord.y , o.color); 
//float3(is_on_top, starrypass_readyness, objectpass_finished)
o.color = 1- printindex.x ;


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

float3 printindex = helper_vertexjump(i.texcoord.y , o.color); 
//float3(is_on_top, starrypass_readyness, objectpass_finished)
o.color = 1- printindex.x ;

    return o;
}

VertexShader VSCreateShadowMap_Array[2] = {
    compile vs_2_0 VSCreateShadowMap_Array_Shader_0(), 
    compile vs_2_0 VSCreateShadowMap_Array_Shader_1(), 
};

float4 PSCreateShadowMap_Array_Shader_0(float texcoord1 : TEXCOORD1, float color : COLOR ) : COLOR
{
    float4 out_color = texcoord1.x;
    clip(color - 0.9999);
    return out_color;
}


PixelShader PSCreateShadowMap_Array[1] = {    compile ps_2_0 PSCreateShadowMap_Array_Shader_0(), };

//FOR MAX PREVIEW ===================================
#if defined(_3DSMAX_) 

struct VSforMAX_Input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 tangent : TANGENT;
    float4 binormal : BINORMAL;
    //float4 texcoord : TEXCOORD;
    float4 color : COLOR;
    float2 TexCoord0 : TEXCOORD0 ;
};

struct VSforMAX_Output
{
    float4 Position : POSITION;   //
    float2 MainTexUV  : TEXCOORD;  //basic texture uv

    float3 texcoord1  : TEXCOORD1; //tangent  matrix 1
    float3 texcoord2  : TEXCOORD2; //tangent  matrix 2
    float3 texcoord3  : TEXCOORD3; //tangent  matrix 3
    float3 FragWpos   : TEXCOORD4; //fragment  position

    float3 ShadowPROJ : TEXCOORD5; //shadow , useless
    float4 FogCloudUV : TEXCOORD6; //xy warfog , zw cloud , useless

    float4 color : COLOR;  //vertex color (now ambient color, and transparency)
    //float3 SSnormal : TEXCOORD8 ;
};

VSforMAX_Output VSforMAX(VSforMAX_Input i)  // 
{ 
    VSforMAX_Output  o;
    o.Position = mul(float4(i.position), WorldViewProjection); //projection space
    //o.SSnormal = mul(float4(i.normal  ), WorldViewProjection);

    o.texcoord1.z = dot(i.normal.xyz, (MAXworld._m00_m10_m20_m30).xyz);
    o.texcoord2.z = dot(i.normal.xyz, (MAXworld._m01_m11_m21_m31).xyz);
    o.texcoord3.z = dot(i.normal.xyz, (MAXworld._m02_m12_m22_m32).xyz);
    float4 temp0 ;  //3dsmax 的切线空间似乎是互换binormal 和tangent
    o.texcoord1.y = 0- dot(i.binormal.xyz, (MAXworld._m00_m10_m20_m30).xyz);
    o.texcoord1.x = 0- dot(i.tangent.xyz, (MAXworld._m00_m10_m20_m30).xyz);
    o.texcoord2.y = 0- dot(i.binormal.xyz, (MAXworld._m01_m11_m21_m31).xyz);
    o.texcoord2.x = 0- dot(i.tangent.xyz, (MAXworld._m01_m11_m21_m31).xyz);
    o.texcoord3.y = 0- dot(i.binormal.xyz, (MAXworld._m02_m12_m22_m32).xyz);
    o.texcoord3.x = 0- dot(i.tangent.xyz, (MAXworld._m02_m12_m22_m32).xyz);

    o.ShadowPROJ = float3(0,0,-1) ;
    o.FogCloudUV = float4(2,2,2,2) ;
    o.FragWpos = mul(i.position.xyz, (float3x3)MAXworld);
    o.MainTexUV.xy = i.TexCoord0 ;
    o.color.w = 1 ;
    o.color.xyz = AmbientLightColor ;
    return o;
};

#endif
#if defined(_3DSMAX_) 

technique MAXpreview
{
    pass p0 
    {
        VertexShader = compile vs_3_0 VSforMAX(); 
        PixelShader  = compile ps_3_0 PS_H_MAIN();    
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        SrcBlend = 5;
        DestBlend = 6;
        AlphaFunc = 7;
        AlphaRef = 64;
        AlphaTestEnable = (AlphaTestEnable) ;
        AlphaBlendEnable = 0 ;
    }
}

#endif

//end max preview

//expressions==========================


int VSchooser_Expression()  //0 no skin, 1 skin
{  return clamp(NumJointsPerVertex.x, 0, 1)  ;  }

//start techniques

technique Default
{
    pass p0 <string ExpressionEvaluator = "Objects";>
    {
        VertexShader = VS_H_Array[VSchooser_Expression()]; 
        PixelShader  = compile ps_3_0 PS_H_MAIN();    
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        SrcBlend = 5;
        DestBlend = 6;
        AlphaFunc = 7;
        AlphaRef = 127;
        AlphaTestEnable = 1 ;//
        AlphaBlendEnable = 0 ; //
        StencilEnable = 1;
    }
    pass p1 
    {
        VertexShader = VS_H_Array[VSchooser_Expression()]; 
        PixelShader  = compile ps_3_0 PS_starry();    
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;

        SrcBlend = 5;
        DestBlend = 2; //2=add, 6=blend
        //BlendOp = Add;
        AlphaFunc = 7;
        AlphaRef = 1;
        AlphaTestEnable = 0;
        AlphaBlendEnable = 1 ; //
        StencilEnable = 0;
    }
}

// Color = TexelColor x SourceBlend + CurrentPixelColor x DestBlend

//fxc.exe /T fx_2_0 /Fo   buildingsjapanbuildup.fxo   compatible_buildup_test.fx

technique _CreateShadowMap
{
    pass p0
    {
        VertexShader = VSCreateShadowMap_Array[VSchooser_Expression()]; 
        PixelShader  = compile ps_2_0 PSCreateShadowMap_Array_Shader_0();
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        AlphaBlendEnable = 0;
        AlphaTestEnable = 0;
    }
}


//END?