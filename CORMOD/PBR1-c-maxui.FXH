//MUST BE FIRST INCLUDED

//#pragma warning(disable: 4008)
string DefaultParameterScopeBlock = "material"; 


// This is used by 3dsmax to load the correct parser
#if defined(_3DSMAX_)
    string ParamID = "0x1";
    #define readonly
    #define SEMANTIC_3DSMAX(semantic) : semantic
#else
    #define readonly const
    #define texture2D texture
    #define textureCUBE texture
    #define SEMANTIC_3DSMAX(semantic)
#endif

//END MAX PREVIEW



#if defined(_3DSMAX_) //预览用 constant

    float3 PV_FactionColor <
	string UIName = "PV_FactionColor";
	string UIWidget = "Color";
	bool ExportValue = false;
    > = {0, 0, 1};

    //预览用的自定义天空盒扔到文件尾部去了

    // sun light direction (world space)
    float3 PV_SunlightDirection : Direction <  
	string UIName = "PV_SunlightDirection"; 
    string Space = "World";   
	string Object = "TargetLight";
	bool ExportValue = false;
	> = {0, 0, 1};

    //能不能把颜色和方向合并在一起啊
    float3 PV_SunlightColor : LightColor <
	string UIName = "PV_SunlightColor";
	string Object = "TargetLight";
	bool ExportValue = false;
    > = {1, 1, 1};

    //获取MAX场景里点光源位置和颜色不会装了，预览还是需要一个点光源的，谁来救一下

    /*
    float3 PV_PointLight_Position : Position <  
	string UIName = "PV_PointLightPosition"; 
	string Object = "OmniLight";
	bool ExportValue = false;
	> = {0, 0, 10};

    float PV_PointLight_Range <
	string UIName = "PV_PointLight_Range";
	bool ExportValue = false;
    > = 30 ;

    */

#endif

//w3x里可以记录的参数=============================

texture DiffuseTexture 
<string UIName = "DiffuseTexture(BASE)";>; 
//
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
<string UIName = "SpecMap(SPM)";>; 
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
<string UIName = "NormalMap(NRM)";>; 
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



float tangent_xy_multiply //如果法线图凹凸反了，写-1修正。完全无效化法线图，写0。
<string UIName = "tangent_xy_multiply"; float UIMax = 2; float UIMin = -2; float UIStep = 0.25; > 
={ -1.25 }; 

float GlowAmplitude //最大发光倍数
<string UIName = "GlowAmplitude"; float UIMax = 8; float UIMin = -1; float UIStep = 0.25; > 
={ 2 }; 

float GlowPeriod //发光呼吸周期，写0为恒定发光
<string UIName = "GlowPeriod"; float UIMax = 8; float UIMin = -1; float UIStep = 0.2; > 
={ 1 }; 

bool  use_irradiance_box //是否生成了用于环境光漫反射的辐照贴图
<    string UIName = "use_irradiance_box";> = 0;

bool AlphaTestEnable //贴图镂空
<    string UIName = "AlphaTestEnable";> = 1;

bool CullingEnable //好像是允许背面不渲染来优化？
<    string UIName = "CullingEnable";> = 1;

bool DepthWriteEnable //写入深度buffer
<    string UIName = "DepthWriteEnable";> = 1;




