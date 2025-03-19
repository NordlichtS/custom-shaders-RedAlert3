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
    int MaxLocalLights = 8;
> = 0;
#endif
//先留着吧
/*
#ifdef MAX_POINT_LIGHT
    int MaxLocalLights = MAX_POINT_LIGHT; 
#else
    int MaxLocalLights = 8;
#endif

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
	string UIName = "PV_(Faction)RecolorColor";
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

//谭雅炸弹的染色，还有鼠标点击变亮
shared float3 TintColor 
: register(vs, c2) : register(ps, c2)
<   string SasBindAddress = "TintColor";    bool unmanaged = true;> 
= float3(1, 1, 1);

//也是个占位的
shared float3 NoCloudMultiplier  //EdgeFadeOut ？
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

//用于设置战争迷雾坐标
struct ShroudSetup {float4 ScaleUV_OffsetUV;} 
Shroud //为什么它有struct而不是一整个float4？
: register(vs, c11)  //只能用于VS ！
<   string UIWidget="None"; string SasBindAddress = "Terrain.Shroud";> 
= { 1, 1, 0, 0 };

//阴影图一个像素在阴影采样坐标里的长度，可用于模糊阴影边缘
float4 Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize 
: register(ps, c11) //只能用于PS ！
<   string UIWidget ="None"; string SasBindAddress = "Sas.Shadow[0].Zero_Zero_OneOverMapSize_OneOverMapSize";>;
// #define  SMtexel  Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize //名字太长了换个短的！

//可以接受最近8个武器特效的点光源, 2X8 FLOAT4 , C89-C112
shared struct PointLightSetup {float3 Color; float3 Position; float2 Range_Inner_Outer;} 
PointLight[8] 
: register(c89)
<    bool unmanaged = true;>;

//世界空间到阴影空间的矩阵  C113-116
shared column_major float4x4 ShadowMapWorldToShadow 
: register(c113)
<    bool unmanaged = true;>;

//用来设置云的UV, C117-118
shared struct CloudSetup {float4 WorldPositionMultiplier_XYZZ; float2 CurrentOffsetUV;} 
Cloud 
: register(c117) 
<    bool unmanaged = true;>;

//从world到view再到projection的矩阵，最后perspective division到clip space? C119-122
shared column_major float4x4 ViewProjection : ViewProjection 
: register(c119)
<    bool unmanaged = true;>;

//游戏里摄像机的世界坐标，用来算世界空间里的视线向量
shared float3 EyePosition 
: register(c123)
<    bool unmanaged = true;>;

//物体空间到世界空间矩阵，这个好像只能给没绑骨骼的mesh用, C124-C127
shared column_major float4x3 World : World 
: register(c124);

//骨骼在世界空间里的信息共64组，每两个float4记一个骨骼，按 4+3+1 记录旋转，位移，透明度
float4 WorldBones[128] //shared  ? C128-C255
: register(vs, c128)
<    bool unmanaged = true;>; //调用骨骼时记得index x2


//===============================


/*
// Integer constant registers
#define IREGISTER_NUM_POINT_LIGHTS                  0
#define IREGISTER_NUM_SHADOWS                       1
// Boolean constant registers
#define BREGISTER_HAS_RECOLOR_COLORS                0
#define BREGISTER_HAS_SHADOW                        1
*/



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

//世界坐标10单位长度为一个地编格，但建造格其实是 20x根号2 ，大约28.3
float2 MapCellSize
<   string UIWidget="None"; string SasBindAddress = "Terrain.Map.CellSize";>
= { 10, 10 };

//当前帧距离游戏开局的秒数，可以用来做呼吸灯和履带滚动
float Time : Time;






//贴图与采样器========================================
//除了很重要的，别的都放其它文件了


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
    Texture = < ShadowMap >;
    MinFilter = 1 ; 
    MagFilter = 1 ; // 原版的临近采样
    MipFilter = 0;
    AddressU = 4; //3=clamp, 4=border
    AddressV = 4;
    AddressW = 3;
};

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

*/

/*
废弃代码

float RoughnessOverride //手动规定非金属的粗糙度，<=0 则取用SPM贴图的红色反转
<string UIName = "RoughnessOverride(0=SPM)"; float UIMax = 1; float UIMin = -1; float UIStep = 0.05; > 
={ 0.5 }; 

float ReflectivityOverride //手动规定非金属的反光度，<=0 则取用SPM贴图的红色
<string UIName = "ReflectivityOverride(0=SPM)"; float UIMax = 1; float UIMin = -1; float UIStep = 0.05; > 
={ 0 }; 


float  dielectric_roughness = (RoughnessOverride <=0)? metal_roughness : RoughnessOverride ;
float  dielectric_reflectivity = (ReflectivityOverride <=0)? spm.x : ReflectivityOverride ;
float  roughness = lerp( dielectric_roughness , metal_roughness , metalness) ;

const float dielectrics_roughness =  0.66 ; //非金属的恒定粗糙度
const float MinRoughness =  0.125 ; //最低粗糙度，如果下面false会影响整个粗糙度的尺度
const bool  SimpleRoughness = false ; //如果上面那个值非常小，可以再化简光滑度函数

*/