//this file need to be first

//#pragma warning(disable: 4008)
string DefaultParameterScopeBlock = "material"; 

//end static const==================

//这有什么用？
int _SasGlobal : SasGlobal  
<
    int3 SasVersion = int3(1, 0, 0);
    string SasEffectAuthor = "EALA, lanyi, Nordlicht, Himeko, badscheen";
    string UIWidget = "None";
    int MaxLocalLights = 8;
    int MaxSupportedInstancingMode = 1;
> = 0;
//先留着吧

//下面是引擎自己加的constant，按寄存器编号排序吧================


//阵营色
shared float3 RecolorColor 
: register(vs, c0) : register(ps, c0)
<bool unmanaged = true;> 
= float3(1, 1, 1);

//透明度整体修改
shared float OpacityOverride 
: register(vs, c1) : register(ps, c1)
<bool unmanaged = true;> 
= 1.0;

//谭雅炸弹的染色，还有鼠标点击变亮
shared float3 TintColor 
: register(vs, c2) : register(ps, c2)
<string SasBindAddress = "TintColor";    bool unmanaged = true;> 
= float3(1, 1, 1);

//据说是用来防止鼠标变红BUG的
shared float4 EdgeFadeOut 
: register(c3) 
<bool unmanaged = true;> 
= 0;

//地编环境光
shared float3 AmbientLightColor 
: register(vs, c4) : register(ps, c4)
<bool unmanaged = true;> 
= float3(0.3, 0.3, 0.3);

//阳光和两个accent light
shared struct SasDirectionalLight { float3 Color; float3 Direction;};
SasDirectionalLight DirectionalLight[3] 
: register(vs, c5) : register(ps, c5)
<bool unmanaged = true;> 
= { 1.0, 1.0, 1.0,   0, 0, 1, 
    0.5, 0.6, 0.7,   0, 1, 0, 
    0.3, 0.2, 0.1,   1, 0, 0 };

//用于设置战争迷雾坐标
struct ShroudSetup {float4 ScaleUV_OffsetUV;} 
Shroud 
: register(vs, c11)
<string UIWidget="None"; string SasBindAddress = "Terrain.Shroud";> 
= { 1, 1, 0, 0 };

//阴影图一个像素在阴影采样坐标里的长度，可用于模糊阴影边缘
float4 Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize 
: register(ps, c11)
<   string UIWidget ="None"; string SasBindAddress = "Sas.Shadow[0].Zero_Zero_OneOverMapSize_OneOverMapSize";>;

//可以接受最近8个武器特效的点光源
shared struct PointLightSetup {float3 Color; float3 Position; float2 Range_Inner_Outer;} 
PointLight[8] 
: register(c89)
<    bool unmanaged = true;>;

//世界空间到阴影空间的矩阵
shared column_major float4x4 ShadowMapWorldToShadow 
: register(c113)
<    bool unmanaged = true;>;

//用来设置云的UV
shared struct CloudSetup {float4 WorldPositionMultiplier_XYZZ; float2 CurrentOffsetUV;} 
Cloud 
: register(c117)
<    bool unmanaged = true;>;

//从world到view再到projection的矩阵，最后perspective division到clip space?
shared column_major float4x4 ViewProjection : ViewProjection 
: register(c119)
<    bool unmanaged = true;>;

//游戏里摄像机的世界坐标，用来算世界空间里的视线向量
shared float3 EyePosition 
: register(c123)
<    bool unmanaged = true;>;

//物体空间到世界空间矩阵，这个好像只能给没绑骨骼的mesh用
column_major float4x3 World : World 
: register(c124);

//骨骼在世界空间里的信息共64组，每两个float4记一个骨骼，按 4+3+1 记录旋转，位移，透明度
shared float4 WorldBones[128] 
: register(c128)
<    bool unmanaged = true;>; //调用骨骼时记得index x2


//===============================
//下面的constant没有写定的寄存器，不过也是引擎自动设的，大概看名字吧==================


//当前帧距离游戏开局的秒数，可以用来做呼吸灯和履带滚动
float Time : Time;

//0=无蒙皮，1=硬绑定，2=软绑定
int NumJointsPerVertex
<   string UIWidget="None"; string SasBindAddress = "Sas.Skeleton.NumJointsPerVertex";> = 0;

//当前帧要接收几个点光源。没这个会导致有些点光源删不掉
int NumPointLights
<   string UIWidget="None"; string SasBindAddress = "Sas.NumPointLights";> ;

//全局画质是否有阴影，和每个MESH是否接受阴影
bool HasShadow //预览没有影子，默认值0
<   string UIWidget="None"; string SasBindAddress = "Sas.HasShadow";> = 0 ;

//有阵营色
bool HasRecolorColors 
<   string UIWidget="None"; string SasBindAddress = "WW3D.HasRecolorColors";> =1 ;

//世界坐标10单位长度为一个地编格，但建造格其实是 20x根号2 ，大约28.3
float2 MapCellSize
<   string UIWidget="None"; string SasBindAddress = "Terrain.Map.CellSize";>
= { 10, 10 };

//其他贴图与采样器========================================


// 阴影贴图，记录阳光投影空间的深度，或者说到天空的距离
texture ShadowMap
<
    string UIWidget = "None";
    string SasBindAddress = "Sas.Shadow[0].ShadowMap";
>;
sampler2D ShadowMapSampler
<
    string Texture = "ShadowMap";
    string UIWidget = "None";
    string SasBindAddress = "Sas.Shadow[0].ShadowMap";
> = sampler_state {
    Texture = < ShadowMap >;
    MinFilter = Point ; 
    MagFilter = Linear ; // 用线性可有效防止斜面锯齿
    MipFilter = None;
    AddressU = Clamp;
    AddressV = Clamp;
    AddressW = Clamp;
};


// 云的贴图（讲真我不打算用这个）
texture CloudTexture
<
    string UIWidget = "None";
    string SasBindAddress = "Terrain.Cloud.Texture";
    string ResourceName = "ShaderPreviewCloud.dds";
>;
sampler2D CloudTextureSampler
<
    string Texture = "CloudTexture";
    string UIWidget = "None";
    string SasBindAddress = "Terrain.Cloud.Texture";
    string ResourceName = "ShaderPreviewCloud.dds";
> = sampler_state {
    Texture = < CloudTexture >;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Wrap;
    AddressV = Wrap;
    AddressW = Clamp;
};


// 战争迷雾贴图
texture ShroudTexture
<
    string UIWidget = "None";
    string SasBindAddress = "Terrain.Shroud.Texture";
>;
sampler2D ShroudTextureSampler
<
    string Texture = "ShroudTexture";
    string UIWidget = "None";
    string SasBindAddress = "Terrain.Shroud.Texture";
> = sampler_state {
    Texture = < ShroudTexture >;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
};


// 岚依的Irradiance贴图，开局会被scrapeo生成一张，用于漫反射环境光
textureCUBE IrradianceTexture
<
    string SasBindAddress = "Lanyi.PbrIrradianceTexture";
    string UIWidget = "None";
    string ResourceType = "Cube";
>;
samplerCUBE IrradianceTextureSampler
<
    string Texture = "IrradianceTexture";
    string SasBindAddress = "Lanyi.PbrIrradianceTexture";
    string ResourceType = "Cube";
> = sampler_state {
    Texture = < IrradianceTexture >;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
    AddressW = Clamp;
};



//这个是环境反射图？真正的天空盒？那irradiance又是什么
#ifdef ENV_CUSTOM
    //  #define ENVMAP_NAME "Terrain.EnvironmentTexture"
        #define ENVMAP_NAME "Lanyi.EnvironmentTexture"
#else
    #ifdef ENV_WATER
        #define ENVMAP_NAME "Water.LightSpaceEnvironmentMap"
    #else
        #define ENVMAP_NAME "Objects.LightSpaceEnvironmentMap"
    #endif
#endif
//在要编译的FX文件里记得  #define ENV_CUSTOM


#if defined(_3DSMAX_) //预览天空盒
texture EnvironmentTexture 
<
    string UIName = "PV_EnvironmentTexture"; 
    string ResourceType = "Cube";
>; 
#else  //游戏内天空盒
texture EnvironmentTexture
<
    string SasBindAddress = ENVMAP_NAME;
    string UIWidget = "None";
    string ResourceType = "Cube";
>;
#endif

samplerCUBE EnvironmentTextureSampler
<
    string Texture = "EnvironmentTexture";
    string SasBindAddress = ENVMAP_NAME;
    string ResourceType = "Cube";
> = sampler_state {
    Texture = < EnvironmentTexture >;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
    AddressW = Clamp;
};


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

static const float dielectrics_roughness =  0.66 ; //非金属的恒定粗糙度
static const float MinRoughness =  0.125 ; //最低粗糙度，如果下面false会影响整个粗糙度的尺度
static const bool  SimpleRoughness = false ; //如果上面那个值非常小，可以再化简光滑度函数

*/