//for shader specific controls

#include "PBR0-COMMON.FXH"  //shader通用的

/*
// This is used by 3dsmax to load the correct parser
#if defined(_3DSMAX_)
    //string ParamID = "0x1";
    #define readonly
    #define SEMANTIC_3DSMAX(semantic) : semantic
#else 
    #define readonly const
    #define texture2D texture
    #define textureCUBE texture
    #define SEMANTIC_3DSMAX(semantic)
#endif
*/

//w3x里可以记录的参数=============================

texture DiffuseTexture 
<string UIName = "(BASE)DiffuseTexture";>; 
//RGB为基础色，控制
sampler2D DiffuseTextureSampler
<string Texture = "DiffuseTexture";> = sampler_state {
    Texture = < DiffuseTexture >;
    MinFilter = Anisotropic;
    MagFilter = Linear;
    MipFilter = Linear;
    MaxAnisotropy = 8;
    AddressU = Wrap;
    AddressV = Wrap;
    //AddressW = Clamp;
};

texture SpecMap 
<string UIName = "(SPM)SpecMap";>; 
//
sampler2D SpecMapSampler
<string Texture = "SpecMap";> = sampler_state {
    Texture = < SpecMap >;
    MinFilter = Anisotropic;
    MagFilter = Linear;
    MipFilter = Linear;
    MaxAnisotropy = 8;
    AddressU = Wrap;
    AddressV = Wrap;
    //AddressW = Wrap;
};

texture NormalMap SEMANTIC_3DSMAX(NormalMap)
<string UIName = "(NRM)NormalMap";>; 
//
sampler2D NormalMapSampler
<string Texture = "NormalMap";> = sampler_state {
    Texture = < NormalMap >;
    MinFilter = Anisotropic;
    MagFilter = Linear;
    MipFilter = Linear;
    MaxAnisotropy = 8;
    AddressU = Wrap;
    AddressV = Wrap;
    //AddressW = Wrap;
};


bool AlphaTestEnable //主贴图镂空
<    string UIName = "Alpha Test Enable";> = 0;

bool AlphaBlendEnable //半透明混合
<    string UIName = "Alpha Blend Enable";> = 0;

bool CullingEnable //好像是允许背面不渲染来优化？
<    string UIName = "Culling Enable";> = 1;

bool DepthWriteEnable //写入深度buffer
<    string UIName = "Depth Write Enable";> = 1;



float MinRoughness //最低粗糙度（要用倒数更精确吗？）
<   string UIName = "MinRoughness"; //MAXglossiness
    float UIMax = 0.50; float UIMin = 0.005; float UIStep = 0.005; 
> ={ 0.125 }; 

float reflectivity_cutoff //非金属反射度的梯度，生效范围阈值为此值倒数
<   string UIName = "reflectivity_cutoff"; 
    float UIMax = 8; float UIMin = 0; float UIStep = 0.25; 
> = { 2 }  ; //小于1则对所有非金属生效，大于1则仅对很粗糙部位生效。此值越大，生效范围越窄

float tangent_xy_multiply //如果法线图凹凸反了，写-1修正。完全无效化法线图，写0。
<   string UIName = "tangent_xy_multiply"; 
    float UIMax = 2; float UIMin = -2; float UIStep = 0.25; 
> ={ -1 };  //RA3默认是反的dx标准

float GlowAmplitude //最大发光倍数，(如果写负数会怎样?)
<   string UIName = "GlowAmplitude"; 
    float UIMax = 8; float UIMin = 0; float UIStep = 0.25; 
> ={ 0 }; 

float GlowPeriod //发光呼吸周期秒数，写0为恒定发光
<   string UIName = "GlowPeriod"; 
    float UIMax = 8; float UIMin = 0; float UIStep = 0.2; 
> ={ 1 }; 



/*

//为了弥补岚依提到的，部分玩家会在生成irradiance贴图时游戏崩溃，保留此选项
bool use_irradiance_box //是否使用自动生成的环境光漫反射的辐照贴图。
<    string UIName = "use_irradiance_box";> = 0; //关闭就读原版ambient色


float MAXglossiness //最低粗糙度的倒数，即最大光滑度，已经弃用
<   string UIName = "MAXglossiness"; 
    float UIMax = 32; float UIMin = 2; float UIStep = 1; 
> ={ 16 }; 
*/

#define ENV_CUSTOM

//这个是环境反射图？真正的天空盒？
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


#ifdef _3DSMAX_ //预览天空盒
textureCUBE EnvironmentTexture SEMANTIC_3DSMAX(ReflectionMap)
<
    string UIName = "PV_EnvironmentTexture"; 
    string ResourceType = "Cube";
	bool ExportValue = false;
>; 
#else  //游戏内天空盒
texture EnvironmentTexture  
<
    string SasBindAddress = ENVMAP_NAME;
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
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 2;
    AddressU = 3;
    AddressV = 3;
    AddressW = 3;
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
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 2;
    AddressU = 3;
    AddressV = 3;
    AddressW = 3;
};



//  #if defined(_3DSMAX_) 
//预览用 constant ===============================


float4x4 MAXwvp : WorldViewProjection;
float4x4 MAXworld : WORLD;
float4x4 ViewI : VIEWINVERSE; 


float3 PV_FactionColor 
<
	string UIName = "PV_FactionColor";
	string UIWidget = "Color";
	bool ExportValue = false;
> = {0, 0, 1};

float3 PV_AmbientLight 
<
	string UIName = "PV_AmbientLight";
	string UIWidget = "Color";
	bool ExportValue = false;
> = {0.25, 0.25, 0.25};

// sun light direction (world space)
float3 PV_SunlightDirection : Direction 
<  
	string UIName = "PV_SunlightDirection"; 
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
    string UIName = "PV_pointlightPOS";
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
    string UIName = "PV_pointlightRANGE"; 
    float UIMax = 800; float UIMin = 0; float UIStep = 10; 
    bool ExportValue = false;
> = 10 ;



//  #endif  
//预览用constant结束=============================

//=================================
//shader specific helper function

//灯光闪烁
float helper_timepulse()
{
    if(GlowPeriod <= 0){return 1;};

    float phase = frac( Time / GlowPeriod ) ; // 保留小数部分， mod 1
    phase = abs(phase *2 -1) ;//或者平方？
    return phase ;
};
