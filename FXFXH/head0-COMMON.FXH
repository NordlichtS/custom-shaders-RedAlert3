//common shader global variables
//must be the very first

//#pragma warning(disable: 4008)
string DefaultParameterScopeBlock = "material"; 


// This is used by 3dsmax to load the correct parser
#if defined(_3DSMAX_)
    string ParamID = "0x1";
    #define readonly
    #define SEMANTIC_3DSMAX(semantic) : semantic
    static const bool INMAX = 1 ;
#else
    #define readonly const
    #define texture2D texture
    #define textureCUBE texture
    #define SEMANTIC_3DSMAX(semantic)
    static const bool INMAX = 0 ;
#endif


//这有什么用？看起来很重要
#ifndef SPECIAL_SAS_HEADER

int _SasGlobal : SasGlobal  
<
    int3 SasVersion = int3(1, 0, 0);
    string UIWidget = "None";
    int MaxSupportedInstancingMode = 1;
    int MaxLocalLights = 0;
> = 0;

#endif
//先留着吧
/*
#if defined(SUPPORT_FORMATIONPREVIEW)	
	string RenderBin = "StaticSort1";
#elif defined(SUPPORT_XRAY)
	string RenderBin = "PartiallyTransparentWall";
#elif defined(SUPPORT_REFLECTION)
	string RenderBin = "TerrainLikeGroundObject";
#endif
*/

//下面是引擎自己加的constant，按寄存器编号排序吧================


//阵营色，最前面的寄存器
#ifndef FORBID_FACTION_COLOR //默认有阵营色 除非专门禁用

shared float3 RecolorColor 
: register(vs, c0) : register(ps, c0)
<   bool unmanaged = true;
	string UIName = "PV_RecolorColor";
	string UIWidget = "Color";
	bool ExportValue = false;
> = { 
    #ifdef _3DSMAX_
    0 , 0.5 , 1 
    #else //MAX预览默认蓝色，游戏里默认白色
    1 , 1 , 1 
    #endif
    };
#else //如果专门禁用的话，还需要挤掉寄存器
    shared float3 RecolorColorDummy : register(vs, c0) : register(ps, c0) 
    <bool unmanaged = 1;> = {1,1,1};
#endif

//透明度整体修改
shared float OpacityOverride 
: register(vs, c1) : register(ps, c1)
<   bool unmanaged = true;
    string UIName = "PV_OpacityOverride"; 
    float UIMax = 1; float UIMin = 0; float UIStep = 0.1; 
    bool ExportValue = false;
> = 1;
// TODO : use SAS  constant to let expression read it

//谭雅炸弹的染色，还有鼠标点击变亮
shared float3 TintColor 
: register(vs, c2) : register(ps, c2)
<   bool unmanaged = true;> 
= float3(1, 1, 1);

//低画质没有云的时候模拟阴天用
shared float3 NoCloudMultiplier  
: register(vs, c3) : register(ps, c3)
<   bool unmanaged = true;> 
= 1 ;

//地编环境光
shared float3 AmbientLightColor 
: register(vs, c4) : register(ps, c4)
<   bool unmanaged = true;
	string UIName = "PV_AmbientLightColor";
	string UIWidget = "Color";
	bool ExportValue = false;
> = float3(0.25, 0.25, 0.25);

//阳光和两个accent light ,C5-C10
shared struct{ float3 Color; float3 Direction;} 
DirectionalLight[3] 
: register(vs, c5) : register(ps, c5) 
<   bool unmanaged = 1;> = { 
1.0, 1.0, 1.0,   0, 0, 1, 
0.4, 0.5, 0.6,   0, 1, 0, 
0.3, 0.2, 0.1,   1, 0, 0 };


//==== from here , sm 2.0 end, below can only used by sm 3.0 ====

//可以接受最近8个武器特效的点光源, 2X8 FLOAT4 , C89-C112
shared struct PointLightSetup {float3 Color; float3 Position; float2 Range_Inner_Outer;} 
PointLight[8] 
: register(c89)
<    bool unmanaged = true;>;

//世界空间到阴影空间的矩阵  C113-116
shared float4x4 ShadowMapWorldToShadow 
: register(c113)
<    bool unmanaged = true;>;

//用来设置云的UV, C117-118
shared struct {float4 WorldPositionMultiplier_XYZZ; float2 CurrentOffsetUV;} Cloud 
: register(c117) 
<    bool unmanaged = true;>;

//从world到view再到projection的矩阵，最后perspective division到clip space? C119-122
shared float4x4 ViewProjection : ViewProjection 
: register(c119)
<    bool unmanaged = true;>;

//游戏里摄像机的世界坐标，用来算世界空间里的视线向量
shared float3 EyePosition 
: register(c123)
<    bool unmanaged = true;>;

//物体空间到世界空间矩阵，这个好像只能给没绑骨骼的mesh用, C124-C127
shared float4x3 World : World 
: register(c124);
// chatgpt said the function use it as row major standard,
// but decompiler say its column major?

//骨骼在世界空间里的信息共64组，每两个float4记一个骨骼，按 4+3+1 记录旋转，位移，透明度
float4 WorldBones[128] //shared  ? C128-C255
: register(vs, c128); //调用骨骼时记得index x2


//===============================





//下面的constant没有写定的寄存器，不过也是引擎看SAS和semantic注入的







//当前帧要接收几个点光源。// register i0 ?
int NumPointLights //: register(vs, i0) : register(ps, i0)
<   string UIWidget="None"; string SasBindAddress = "Sas.NumPointLights";> = 1 ; //预览一个

//0=无蒙皮，1=硬绑定，2=软绑定 // no register, needed by shader array
int NumJointsPerVertex
<   string UIWidget="None"; string SasBindAddress = "Sas.Skeleton.NumJointsPerVertex";> = 0;

//有阵营色  // register b0 ? shader array?
bool HasRecolorColors 
<   string UIWidget="None"; string SasBindAddress = "WW3D.HasRecolorColors";> =1 ;

//全局画质和每个MESH是否接受阴影 预览没有影子，默认值0 // register b1 ?  shader array?
bool HasShadow 
<   string UIWidget="None"; string SasBindAddress = "Sas.HasShadow";> = 0 ;

#ifndef FORBID_CLIPPING_CONSTANT
    //bool AlphaBlendEnable < string UIName = "Alpha Blend Enable";> ;//= 0;

    extern bool AlphaTestEnable //主贴图镂空
    <    string UIName = "Alpha Test Enable";> = 0;

    extern bool CullingEnable //好像是允许背面不渲染来优化？
    <    string UIName = "Culling Enable";> = 1;

    extern bool DepthWriteEnable //写入深度buffer 但好像是用阴影图制作器单独生成的屏幕空间深度？
    <    string UIName = "Depth Write Enable";> = 1;

#endif // FORBID_CLIPPING_CONSTANT ?

//当前帧距离游戏开局的秒数，可以用来做呼吸灯和履带滚动
float Time : Time;

// 我们依然不知道下面这两个到底要放什么寄存器里。
// 很奇怪，为什么云就有写定的寄存器？

//用于设置战争迷雾坐标
shared struct {float4 ScaleUV_OffsetUV;} Shroud 
//为什么它有struct而不是一整个float4？
//: register(vs, c11)  //只能用于VS ? 并没有！
<   string UIWidget="None"; string SasBindAddress = "Terrain.Shroud";> 
= { 1, 1, 0, 0 };

//阴影图一个像素在阴影采样坐标里的长度，可用于模糊阴影边缘
shared float4 Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize 
//: register(ps, c11) //只能用于PS ?  并没有！
<   string UIWidget ="None"; string SasBindAddress = "Sas.Shadow[0].Zero_Zero_OneOverMapSize_OneOverMapSize";>;
// #define  SMtexel  Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize //名字太长了换个短的！


//上面的都并没有直接记录在W3X的SHADER段，但引擎会分配


// ============ texture and sampler: fog cloud shadow

#ifndef IGNORE_FOG_CLOUD_SHADOW

// 战争迷雾贴图
texture ShroudTexture
    <
    string UIWidget = "None";
    string SasBindAddress = "Terrain.Shroud.Texture";
    >;
    sampler2D ShroudTextureSampler
    <
    string Texture = "ShroudTexture";
    string SasBindAddress = "Terrain.Shroud.Texture";
    > = sampler_state {
    Texture = < ShroudTexture >;
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 1;
    AddressU = 3; //clamp
    AddressV = 3;
};

// 云贴图
texture CloudTexture
    <
    string UIWidget = "None";
    string SasBindAddress = "Terrain.Cloud.Texture";
    string ResourceName = "ShaderPreviewCloud.dds";
    >;
    sampler2D CloudTextureSampler
    <
    string Texture = "CloudTexture";
    string SasBindAddress = "Terrain.Cloud.Texture";
    string ResourceName = "ShaderPreviewCloud.dds";
    > = sampler_state {
    Texture = < CloudTexture >;
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 1;
    AddressU = 1;
    AddressV = 1;
    //AddressW = 3;
}; 

// 阴影贴图，记录阳光投影空间的深度，或者说到天空的距离
texture ShadowMap
    <
    string UIWidget = "None";
    string SasBindAddress = "Sas.Shadow[0].ShadowMap";
    >;
    sampler2D ShadowMapSampler
    <
    string Texture = "ShadowMap";
    string SasBindAddress = "Sas.Shadow[0].ShadowMap";
    > = sampler_state {
    Texture = < ShadowMap > ;
    MinFilter = 1 ; 
    MagFilter = 1 ; 
    MipFilter = 0;
    AddressU = 4; //3=clamp, 4=bordercolor
    AddressV = 4;
    //AddressW = 3;
};

#endif //  IGNORE_FOG_CLOUD_SHADOW

// ============ 后处理和延迟渲染的局域光所需的信息（高画质才有）
#ifdef DEFERRED_RENDER

    texture DepthTexture 
        <   
        string UIWidget = "None";
        string SasBindAddress = "WW3D.DepthTexture";
        >; 
        sampler2D DepthTextureSampler //: register(ps_2_0, s1) 
        <
        string Texture = "DepthTexture"; 
        string SasBindAddress = "WW3D.DepthTexture";
        > = sampler_state {
        Texture = <DepthTexture>; 
        MinFilter = 1;  //nearest
        MagFilter = 1;
        MipFilter = 0;
        AddressU = 3;  //clamp
        AddressV = 3;
    };

    // 疑似屏幕大小
    float2 FrameBufferSize  
    <
        string UIWidget = "None";
        string SasBindAddress = "WW3D.FrameBufferSize";
    > = float2(1920, 1080);  //1.0f


    //  deferred shading use more matrix math
    float4x4 View           : View;
    float4x4 ViewI          : ViewInverse;
    float4x4 Projection     : Projection;
    float4x4 ProjectionI    : ProjectionInverse;


#endif //  DEFERRED_RENDER


//  ================ 预览和导出 ============


#ifdef _3DSMAX_

float4x4 MAXwvp : WorldViewProjection;
float4x4 MAXworld : WORLD;
float4x4 MAXviewinv : VIEWINVERSE; 
float4x4 MAXview : View;         
float4x4 MAXprojection : Projection; 



// preview variables ==================

    // sun light direction (world space)
    float3 PV_SunlightDirection : Direction 
    <  
        #ifndef IGNORE_FOG_CLOUD_SHADOW
        string UIName = "PV_SunlightDirection"; 
        #else 
        string UIWidget = "None";
        #endif 
        string Object = "TargetLight";
        string Space  = "World";   
        int refID = 0; //这是用来联系光颜色的？
        bool ExportValue = false;
    > = {0, 0, 1};

    float3 PV_SunlightColor : LIGHTCOLOR 
    <
        int LightRef = 0; //这是用来联系光颜色的？
        string UIWidget = "None";
        bool ExportValue = false;
    > = {1, 1, 1};

    /// Point Light vfx
    float3 PV_pointlightPOS : POSITION 
    <
        #ifndef IGNORE_FOG_CLOUD_SHADOW
        string UIName = "PV_pointlightPOS";
        #else 
        string UIWidget = "None";
        #endif 
        string Object = "PointLight0";
        string Space  = "World";
        int refID = 1;
        bool ExportValue = false;
    > = {0,0,40};

    float3 PV_pointlightCOLOR : LIGHTCOLOR 
    <
        int LightRef = 1;
        string UIWidget = "None";
        bool ExportValue = false;
    > = {0, 0, 0};

    float PV_pointlightRANGE
    <
        #ifndef IGNORE_FOG_CLOUD_SHADOW
        string UIName = "PV_pointlightRANGE"; 
        #else 
        string UIWidget = "None";
        #endif 
        float UIMax = 800; float UIMin = 0; float UIStep = 10; 
        bool ExportValue = false;
    > = 100 ;

    // two secondary light
    float3 PV_accentlight 
    < 
        #ifndef IGNORE_FOG_CLOUD_SHADOW
        string UIName = "PV_accentlight";
        #else 
        string UIWidget = "None";
        #endif 
        string UIWidget = "Color";
        bool ExportValue = false;
    > = { 0.2, 0.3, 0.4 };

    float PV_vertexALPHA
    <
        string UIName = "PV_vertexALPHA"; 
        float UIMax = 1; float UIMin = 0; float UIStep = 0.1; 
        bool ExportValue = false;
    > = 1 ;

    bool PV_SRGB
    <
        string UIName = "PV_SRGB"; 
        bool ExportValue = false;
    > = 0 ;

// end preview variables  =============

#endif  // ==============  _3DSMAX_  =============




// ============= 自动获取预览参数切换

float3 getEYEpos() {   
    #ifdef _3DSMAX_
    return MAXviewinv[3].xyz ;
    #else
    return EyePosition ;
    #endif
}

float4x4 getVPmatrix(){  
    #ifdef _3DSMAX_
    return mul(MAXview, MAXprojection) ;
    #else
    return ViewProjection ;
    #endif
}

// 阳光方向 指向太阳且单位化
float3 getSUNdir(){
    #ifdef _3DSMAX_
    return PV_SunlightDirection ;
    #else
    return DirectionalLight[0].Direction ;
    #endif
}

// 阳光颜色
float3 getSUNcolor(){
    #ifdef _3DSMAX_
    return PV_SunlightColor ;
    #else
    return DirectionalLight[0].Color ;
    #endif
}

// 两个氛围光以及融合方式
float3 getAccentLight (float3 nrm){
    #ifdef _3DSMAX_
    return PV_accentlight ;
    #else

    float3 skybox1 = DirectionalLight[1].Color ;
    skybox1 *= dot(DirectionalLight[1].Direction, nrm) * 0.5 + 0.5 ;
    float3 skybox2 = DirectionalLight[2].Color ;
    skybox2 *= dot(DirectionalLight[2].Direction, nrm) * 0.5 + 0.5 ;
    return (skybox1 + skybox2) ; //already double bright
    #endif
}


// 计算战争迷雾贴图的 UV 坐标
float2 getWarfogUV(float4 WorldPosition) 
{
    return (WorldPosition.xy + Shroud.ScaleUV_OffsetUV.zw) * Shroud.ScaleUV_OffsetUV.xy;
};
// 计算云的贴图的 UV 坐标
float2 getCloudUV(float4 WorldPosition) 
{
    float4 multipliedCloudUV = WorldPosition.xyzz * Cloud.WorldPositionMultiplier_XYZZ;
    return multipliedCloudUV.xy - multipliedCloudUV.zw + Cloud.CurrentOffsetUV;
};

// 一些通用函数 =========================

// 通过四元数来计算旋转的函数，来自 CNC3 的 Skinning.fxh
float3 QuaternionRotate(float4 rotation, float3 position) 
{
	float4 a
	= rotation.wwwx * position.xyzx 
    + rotation.yzxy * position.zxyy;
	a.w = -a.w;
	a -= rotation.zxyz * position.yzxz;
    float3 finalvector 
    = rotation.www * a.xyz 
    - rotation.xyz * a.www 
    + rotation.yzx * a.zxy 
    - rotation.zxy * a.yzx;
	return finalvector;
}; 


//  2x2x2 Percentage-Closer Filtering on a shadow map
float TrilinearShadowPCF(sampler2D shadowSampler, float3 SMUV, float oneOverMapSize)
{
    //  Calculate bilinear interpolation weights based on fractional texel coordinates
    float2 fractionalUV = frac(SMUV.xy / oneOverMapSize);
    float2 offset = float2(0, oneOverMapSize);
    
    // Sample the 4 nearest texels. In DX9 tex2Dlod requires float4 : (u, v, 0, miplevel).
    float4 samples;
    samples.x = tex2Dlod(shadowSampler, float4(SMUV.xy + offset.xx, 0, 0)).x; // LU (0,0)
    samples.y = tex2Dlod(shadowSampler, float4(SMUV.xy + offset.xy, 0, 0)).x; // LD (0,1)
    samples.z = tex2Dlod(shadowSampler, float4(SMUV.xy + offset.yx, 0, 0)).x; // RU (1,0)
    samples.w = tex2Dlod(shadowSampler, float4(SMUV.xy + offset.yy, 0, 0)).x; // RD (1,1)

    // Perform depth comparison and apply bias mathematically across all 4 samples at once
    float4 sunlightquad = saturate((samples - SMUV.z) * 255.0 + 0.25);
    // transition range : 1/255 , begin offset 0.25/255
    // 1/255 = 0.04 , 1/1024= 0.001  . original: 0.0015

    // Bilinear interpolation
    float2 bLR = lerp(sunlightquad.xy, sunlightquad.zw, fractionalUV.x);
    float  bUD = lerp(bLR.x, bLR.y, fractionalUV.y);
    return bUD ;  //  1 for full sun, 0 for full dark shadow
}












// worth trying?  


/*
#if !defined(EA_PLATFORM_PS3) && !defined(_3DSMAX_)
	#define USE_INDIRECT_CONSTANT
#endif // !defined(_3DSMAX_)

// aka:only windows use indirect constant, thats hard register, not sas

#if !defined(USE_INDIRECT_CONSTANT)
float OpacityOverride
<
	string UIWidget = "None";
	string SasBindAddress = "WW3D.OpacityOverride";
> = 1.0;

float3 TintColor
<
	string UIWidget = "None";
	string SasBindAddress = "WW3D.TintColor";
> = float3(1, 1, 1);
#endif // #if !defined(USE_INDIRECT_CONSTANT)
*/

//TODO: 四元数旋转 ，加上顶点的PNTB 做成 FLOAT3[4] 做一个统一的辅助函数

//贴图与采样器========================================
//除了很重要的，别的都放其它文件了





/*
// FROM OFFICIAL  "REGISTERMAP.FXH"
// Float constant registers

// Why are these register numbers all over the place? Why not just declare them starting with 0 upwards?
// There is a problem with PS2.0 shaders: They can only support 32 constant registers.
// In total we have much more than that, but our PS2.0 shaders themselves use less than 32 registers.
// By moving all the registers we need in PS2.0 into the range of 0-31 these shaders compile.
// All registers that are not used there then can be put into the range above 32 without problems.
// To leave the largest possible "unmapped" area in the middle, let's assign those registers backwards from 255.

//  唉你们为了兼容只有shader model 2.0的老硬件真是煞费苦心

// Skinning
#define MaxSkinningBones 64 // Every bone uses 2 registers each, ie 128 registers total
#define REGISTER_SKINNING_BONE_TRANSFORMS           128 // up to 255
#define REGISTER_NON_SKINNING_WORLD_MATRIX_FIRST    124
#define REGISTER_NON_SKINNING_WORLD_MATRIX_LAST     127

// Camera related
#define REGISTER_CAMERA_POSITION                    123
#define REGISTER_VIEWPROJECTION_MATRIX_FIRST        119
#define REGISTER_VIEWPROJECTION_MATRIX_LAST         122

// Color
#define REGISTER_RECOLOR_COLOR                      0
#define REGISTER_OPACITY_OVERRIDE                   1
#define REGISTER_TINT_COLOR                         2

// Cloud related
#define REGISTER_CLOUD_SETUP                        117 // 2 registers used
#define REGISTER_NO_CLOUD_MULTIPLIER                3

// Shadowmap
#define REGISTER_MAT_WORLD_TO_SHADOW                113 // 4 registers

// Lighting
#define REGISTER_AMBIENT_LIGHT_COLOR                4
#define REGISTER_DIRECTIONAL_LIGHTS_FIRST           5 // 6 registers
#define REGISTER_DIRECTIONAL_LIGHTS_LAST            10
#define REGISTER_POINT_LIGHTS_FIRST                 89 // 24 registers
#define REGISTER_POINT_LIGHTS_LAST                  112

// Integer constant registers
#define IREGISTER_NUM_POINT_LIGHTS                  0
#define IREGISTER_NUM_SHADOWS                       1

// Boolean constant registers
#define BREGISTER_HAS_RECOLOR_COLORS                0
#define BREGISTER_HAS_SHADOW                        1


*/


/*

typedef enum D3DTEXTUREFILTERTYPE { 
  D3DTEXF_NONE             = 0,
  D3DTEXF_POINT            = 1,
  D3DTEXF_LINEAR           = 2,
  D3DTEXF_ANISOTROPIC      = 3,
  D3DTEXF_PYRAMIDALQUAD    = 6,
  D3DTEXF_GAUSSIANQUAD     = 7,
  D3DTEXF_CONVOLUTIONMONO  = 8,
  D3DTEXF_FORCE_DWORD      = 0x7fffffff
} D3D TEXTURE FILTER TYPE, *LP;

typedef enum D3DTEXTUREADDRESS { 
  D3DTADDRESS_WRAP         = 1,
  D3DTADDRESS_MIRROR       = 2,
  D3DTADDRESS_CLAMP        = 3,
  D3DTADDRESS_BORDER       = 4,
  D3DTADDRESS_MIRRORONCE   = 5,
  D3DTADDRESS_FORCE_DWORD  = 0x7fffffff
} D3D TEXTURE ADDRESS, *LP;


#define RGB		7
#define RGBA	15

*/

// RENDERSTATE ENUMS

// Taken from d3d9types.h D3DBLEND enum
#define D3DBLEND_ZERO               1
#define D3DBLEND_ONE                2
#define D3DBLEND_SRCCOLOR           3
#define D3DBLEND_INVSRCCOLOR        4
#define D3DBLEND_SRCALPHA           5
#define D3DBLEND_INVSRCALPHA        6
#define D3DBLEND_DESTALPHA          7
#define D3DBLEND_INVDESTALPHA       8
#define D3DBLEND_DESTCOLOR          9
#define D3DBLEND_INVDESTCOLOR       10
#define D3DBLEND_SRCALPHASAT        11
#define D3DBLEND_BOTHSRCALPHA       12
#define D3DBLEND_BOTHINVSRCALPHA    13
// Only supported if D3DPBLENDCAPS_BLENDFACTOR is on 
#define D3DBLEND_BLENDFACTOR        14 
#define D3DBLEND_INVBLENDFACTOR     15 

// Taken from d3d9types.h D3DCULL enum
#define D3DCULL_NONE                1
#define D3DCULL_CW                  2  //standard
#define D3DCULL_CCW                 3

// Taken from d3d9types.h D3DCMPFUNC enum
#define D3DCMP_NEVER                1
#define D3DCMP_LESS                 2
#define D3DCMP_EQUAL                3
#define D3DCMP_LESSEQUAL            4
#define D3DCMP_GREATER              5
#define D3DCMP_NOTEQUAL             6
#define D3DCMP_GREATEREQUAL         7
#define D3DCMP_ALWAYS               8

// Taken from d3d9types.h. Flags to construct D3DRS_COLORWRITEENABLE
#define D3DCOLORWRITEENABLE_RED     1 //(1L<<0)
#define D3DCOLORWRITEENABLE_GREEN   2 //(1L<<1)
#define D3DCOLORWRITEENABLE_BLUE    4 //(1L<<2)
#define D3DCOLORWRITEENABLE_ALPHA   8 //(1L<<3)
#define D3DCOLORWRITEENABLE_ALL     0xf     
// Xbox 360 extension [LLatta 2006-09-06: Copied to Windows version too]

