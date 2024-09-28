//this file need to be first

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
<string UIName = "GlowPeriod"; float UIMax = 8; float UIMin = 0; float UIStep = 0.2; > 
={ 1 }; 

bool  use_irradiance_box //是否生成了用于环境光漫反射的辐照贴图
<    string UIName = "use_irradiance_box";> = 0;

bool AlphaTestEnable //贴图镂空
<    string UIName = "AlphaTestEnable";> = 1;

bool CullingEnable //好像是允许背面不渲染来优化？
<    string UIName = "CullingEnable";> = 1;

bool DepthWriteEnable //写入深度buffer
<    string UIName = "DepthWriteEnable";> = 1;




