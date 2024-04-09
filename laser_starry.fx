//NEED A STARRY SKY SCREEN SPACE TEXTURE

string DefaultParameterScopeBlock = "material"; 

//float3 RecolorColorDummy <bool unmanaged = 1;>;
float3 RecolorColor : register(ps_2_0, c0) : register(ps_3_0, c0) <bool unmanaged = 1;> ={1,1,1};
bool HasRecolorColors <string SasBindAddress = "WW3D.HasRecolorColors";> =1;

float3 AmbientLightColor <bool unmanaged = 1;> = { 0.3, 0.3, 0.3 };
struct { float3 Color; float3 Direction;} DirectionalLight[3] <bool unmanaged = 1;> = { 0,0,0,0,0,1, 0,0,0,0,0,1, 0,0,0,0,0,1, };
struct { float3 Color; float3 Position; float2 Range_Inner_Outer;} PointLight[8] <bool unmanaged = 1;>;
struct { float4 WorldPositionMultiplier_XYZZ; float2 CurrentOffsetUV;} Cloud <bool unmanaged = 1;>;
float3 NoCloudMultiplier <bool unmanaged = 1;> = { 1, 1, 1 };
row_major float4x4 ShadowMapWorldToShadow <bool unmanaged = 1;>;
float  OpacityOverride <bool unmanaged = 1;> = { 1 };
float3 TintColor <bool unmanaged = 1;> = { 1, 1, 1 };
float3 EyePosition  <bool unmanaged = 1;>;  //: register(ps_3_0, c123)
row_major float4x4 ViewProjection <bool unmanaged = 1;>;
// float4 WorldBones[128] <bool unmanaged = 1;>;
column_major float4x4 World : World : register(vs_2_0, c15) : register(vs_3_0, c15);
column_major float4x4 WorldViewProjection : WorldViewProjection : register(vs_2_0, c11) : register(vs_3_0, c11); 
struct{ float4 ScaleUV_OffsetUV;} Shroud : register(vs_2_0, c17) : register(vs_3_0, c17)
<string SasBindAddress = "Terrain.Shroud";> = { 1, 1, 0, 0 };

// (RGB+ A*HC)*(1-alpha)
float4 MainColorLaser <string UIWidget = "MainColorLaser";> = {1,1,1,0} ;  
float4 MainColorEdge  <string UIWidget = "MainColorEdge";>  = {0,0,0,1} ;
float4 MainColorSky   <string UIWidget = "MainColorSky";>   = {1,1,1,0} ;
//以上是三个激光主色调，分别控制激光贴图，边缘加亮，星空颜色。前三个分量是RGB，第四个分量都是阵营色浓度

float SSSpixel //星空贴图的大小，填边长像素数量
<string UIName = "SSSpixel(SkyTextureSize)"; float UIMin = 1; float UIMax = 1024; float UIStep = 1;> = 256 ;

float TempAlphaMultiply //让透明度变得更锐利
<string UIName = "TempAlphaMultiply"; float UIMin = 0; float UIMax = 8; float UIStep = 0.5;> = 1 ; 

bool LumineAlphaFix  //just for compatibility with vanilla laser
<string UIName = "LumineAlphaFix";> = 1 ;  
//开启此值为使用原版贴图的亮度为alpha，用于兼容原版激光素材。会使MainColorLaser失效，且不读取贴图自身alpha

//set render state, maybe not working
/*
bool AlphaBlendEnable <string UIName = "AlphaBlendEnable";> = 1 ;
bool AlphaTestEnable  <string UIName = "AlphaTestEnable" ;> = 1 ;
int SrcBlend  <string UIName = "SrcBlend" ;> = 5 ;
int DestBlend <string UIName = "DestBlend";> = 6 ; //6=alpha, 2=additive
*/

//=====================

texture Texture1 <string UIWidget = "Texture1(Laser)";>; 
sampler2D Texture1Sampler : register(ps_2_0, s0) : register(vs_3_0, s0)
<string Texture = "Texture1";> =
sampler_state
{
    Texture = <Texture1>; 
    MinFilter = 3;
    MagFilter = 2;
    MipFilter = 2;
    MaxAnisotropy = 8;
    AddressU = 3;
    AddressV = 1;
};

texture Texture2 <string UIWidget = "Texture2(Laser)";>; 
sampler2D Texture2Sampler : register(ps_2_0, s1) : register(vs_3_0, s1)
<string Texture = "Texture2";> =
sampler_state
{
    Texture = <Texture2>; 
    MinFilter = 3;
    MagFilter = 2;
    MipFilter = 2;
    MaxAnisotropy = 8;
    AddressU = 3;
    AddressV = 1;
};

texture Texture3 //如果不想每次手动设置星空贴图，请务必在scrapeo里给你要用的贴图注册SasBindAddress，然后这里直接引用
<string UIWidget = "Texture3(ScreenSpaceSky)"; string SasBindAddress = "WW3D.FXstarrysky256quad";>; 
sampler2D Texture3Sampler //无想一刀！
<string Texture = "Texture3"; string SasBindAddress = "WW3D.FXstarrysky256quad";> =
sampler_state
{
    Texture = <Texture3>; 
    MinFilter = 2;
    MagFilter = 1;
    MipFilter = 1;
    AddressU = 1;
    AddressV = 1;
};

texture ShroudTexture <string UIWidget = "None"; string SasBindAddress = "Terrain.Shroud.Texture"; string ResourceName = "ShaderPreviewShroud.dds";>; 
sampler2D ShroudTextureSampler : register(ps_2_0, s2) : register(vs_3_0, s2)
<string Texture = "ShroudTexture"; string UIWidget = "None"; string SasBindAddress = "Terrain.Shroud.Texture"; string ResourceName = "ShaderPreviewShroud.dds";> =
sampler_state
{
    Texture = <ShroudTexture>; 
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 1;
    AddressU = 3;
    AddressV = 3;
};


//====================
//mid shaders deleted
//====================

//helper functions

float3 helper_decider (float4 DeciderColor)  
{
    float3 actualHC = (HasRecolorColors)? RecolorColor : float3(1,1,1) ;
    return (DeciderColor.xyz + DeciderColor.w * actualHC) ;
};

//ps the most important

struct Default_PixelShader3_Input
{
    float2 vpos : VPOS ;  //screen space pixel position
    float2 texcoord  : TEXCOORD;   //tex1
    float2 texcoord1 : TEXCOORD1;  //tex2
    float2 texcoord2 : TEXCOORD2;  //shroud
    float4 color : COLOR;  //xyz are clip space position, w is vertex alpha
};

float4 Default_PixelShader3(Default_PixelShader3_Input i) : COLOR
{
    float4 out_color = float4(0,0,0,1);

    float4 tex1color = tex2D(Texture1Sampler,  i.texcoord.xy  );
    float4 tex2color = tex2D(Texture2Sampler,  i.texcoord1.xy );
    float4 SSScolor  = tex2D(Texture3Sampler,  (i.vpos.xy / SSSpixel) );

    out_color = tex1color * tex2color ;

    if (LumineAlphaFix) {
    out_color.w = (out_color.x + out_color.y + out_color.z) ;
    out_color.xyzw *= float4 (0,0,0,2) ;
    };

    out_color.xyz *= helper_decider(MainColorLaser) ;
    SSScolor.xyz  *= helper_decider(MainColorSky) ;
    out_color.xyz += SSScolor.xyz ;

    out_color.w   *= SSScolor.w ;
    out_color.w   *= i.color.w ;
    out_color.w   *= TempAlphaMultiply ;  
    out_color.w = saturate(out_color.w) ;

    float3 edgelight = helper_decider(MainColorEdge) ;
    edgelight *= 1- out_color.w ;
    edgelight *= edgelight ;
    out_color.xyz += edgelight ;

    out_color.xyz *= out_color.xyz ; //gamma correction

    return out_color;
}

//===============

struct Default_VertexShader4_Input
{
    float4 position : POSITION;    //world space vertex position
    float4 texcoord : TEXCOORD;    //tex1
    float4 texcoord1 : TEXCOORD1;  //tex2
    float4 color : COLOR;  //present in laser.fx but not in laseralpha.fx
};

struct Default_VertexShader4_Output
{
    float4 position  : POSITION;   //view space maybe ?
    float2 texcoord  : TEXCOORD;   //tex1
    float2 texcoord1 : TEXCOORD1;  //tex2
    float2 texcoord2 : TEXCOORD2;  //shroud
    float4 color : COLOR;  //dont use xyz. w is vertex alpha
};

Default_VertexShader4_Output Default_VertexShader4(Default_VertexShader4_Input i)
{
    Default_VertexShader4_Output o;
    float4 temp0;
    float2 temp1;
    temp0 = i.position.xyzw * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
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
    o.color.w = i.color.x;  //present in laser.fx but not in laseralpha.fx
    o.color.xyz = o.position.xyz / o.position.w ; //maybe useless

    return o;
}

//=====================

technique Default
{
    pass pass0
    {
        VertexShader = compile vs_3_0 Default_VertexShader4(); 
        PixelShader  = compile ps_3_0 Default_PixelShader3(); 
        ZEnable = 1;
        ZWriteEnable = 0;
        ZFunc = 4;
        CullMode = 1;
        AlphaBlendEnable = 1; //(AlphaBlendEnable) ;// 1;
        AlphaTestEnable  = 1; //(AlphaTestEnable)  ;// 
        AlphaFunc = 7 ; //
        AlphaRef = 64 ; //
        SrcBlend  = 5; //(SrcBlend) ; //5;
        DestBlend = 6; //(DestBlend) ; //6; //6=alpha, 2=additive
    }
}

/*

SrcBlend and DestBlend:
D3DBLEND_ZERO (0): Multiply by zero.
D3DBLEND_ONE (1): Multiply by one.
D3DBLEND_SRCCOLOR (2): Multiply by the source color.
D3DBLEND_INVSRCCOLOR (3): Multiply by the inverse of the source color.
D3DBLEND_SRCALPHA (4): Multiply by the source alpha.
D3DBLEND_INVSRCALPHA (5): Multiply by the inverse of the source alpha.
D3DBLEND_DESTALPHA (6): Multiply by the destination alpha.
D3DBLEND_INVDESTALPHA (7): Multiply by the inverse of the destination alpha.
D3DBLEND_DESTCOLOR (8): Multiply by the destination color.
D3DBLEND_INVDESTCOLOR (9): Multiply by the inverse of the destination color.
D3DBLEND_SRCALPHASAT (10): Multiply by the source alpha, clamped between zero and one.

AlphaFunc:
D3DCMP_NEVER (1): Never pass the comparison.
D3DCMP_LESS (2): Pass if the source value is less than the destination value.
D3DCMP_EQUAL (3): Pass if the source value is equal to the destination value.
D3DCMP_LESSEQUAL (4): Pass if the source value is less than or equal to the destination value.
D3DCMP_GREATER (5): Pass if the source value is greater than the destination value.
D3DCMP_NOTEQUAL (6): Pass if the source value is not equal to the destination value.
D3DCMP_GREATEREQUAL (7): Pass if the source value is greater than or equal to the destination value.
D3DCMP_ALWAYS (8): Always pass the comparison.

*/