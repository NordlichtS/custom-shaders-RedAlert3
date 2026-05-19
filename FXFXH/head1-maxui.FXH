//for shader specific controls

#include "head0-COMMON.FXH"  //shader通用的

/*
// This is used by 3dsmax to load the correct parser
#if defined(_3DSMAX_)

#endif
*/





//w3x里可以记录的参数=============================






#ifdef IS_BASIC_W3D_SHADER  //!!!

texture Texture_0 
<string UIName = "Texture_0";>; 
sampler2D Texture_0Sampler   //: register(ps, s1) 
<string Texture = "Texture_0"; > = sampler_state {
    Texture = <Texture_0>; 
    MinFilter = 3;
    MagFilter = 2;
    MipFilter = 2;
    MaxAnisotropy = 8;
    AddressU = 1;
    AddressV = 1;
};

int BlendMode //WTF IS THIS
<string UIName = "BlendMode(0=opaque,1=alpha,2=add)"; int UIMin = 0; int UIMax = 2;> = 0 ;

float3 ColorAmbient 
<string UIName = "ColorAmbient"; string UIWidget = "Color";> = { 1, 1, 1 };

float3 ColorDiffuse 
<string UIName = "ColorDiffuse"; string UIWidget = "Color";> = { 1, 1, 1 };

float3 ColorSpecular 
<string UIName = "ColorSpecular"; string UIWidget = "Color";> = { 0, 0, 0 };

float  Shininess  
<string UIName = "Shininess"; string UIWidget = "Slider"; float UIMax = 64;> = { 1 };

float3 ColorEmissive 
<string UIName = "ColorEmissive"; string UIWidget = "Color";> = { 0, 0, 0 };

#endif
// infantry and glow shader
//==================================
// objects and building shader
#ifdef IS_OBJECT_BUILDING_SHADER  

texture DiffuseTexture 
<string UIName = "(BASE)DiffuseTexture";>; 
//RGB为基础色，控制
sampler2D DiffuseTextureSampler
<string Texture = "DiffuseTexture";> = sampler_state {
    Texture = < DiffuseTexture >;
    MinFilter = 3; //Anisotropic
    MagFilter = 2;
    MipFilter = 2;
    MaxAnisotropy = 8;
    AddressU = Wrap;
    AddressV = Wrap;
    //AddressW = Clamp;
};
sampler2D DiffuseEasySampler //给阴影图用的简便版
<string Texture = "DiffuseTexture";> = sampler_state {
    Texture = < DiffuseTexture >;
    MinFilter = 1;
    MagFilter = 2;
    MipFilter = 1;
    MIPMAPLODBIAS = -1 ;
    AddressU = Wrap;
    AddressV = Wrap;
};

texture SpecMap 
<string UIName = "(SPM)SpecMap";>; 
//
sampler2D SpecMapSampler
<string Texture = "SpecMap";> = sampler_state {
    Texture = < SpecMap >;
    MinFilter = 3; //Anisotropic
    MagFilter = 2;
    MipFilter = 2;
    MaxAnisotropy = 4;
    AddressU = Wrap;
    AddressV = Wrap;
    //MIPMAPLODBIAS = -1 ;
    //AddressW = Wrap;
};

texture NormalMap SEMANTIC_3DSMAX(NormalMap)
<string UIName = "(NRM)NormalMap";>; 
//
sampler2D NormalMapSampler
<string Texture = "NormalMap";> = sampler_state {
    Texture = < NormalMap >;
    MinFilter = 2; //3 
    MagFilter = 2;
    MipFilter = 2;
    //MaxAnisotropy = 4;
    AddressU = Wrap;
    AddressV = Wrap;
};

float BumpScale //如果法线图凹凸反了，写-1修正。完全无效化法线图，写0。
<   string UIName = "BumpScale(NRMstrength)"; 
    string UIWidget = "Slider"; 
    float UIMin = -8; float UIMax = 8; 
    float UIStep = 0.05;
> =  2 ;

#endif //IS_OBJECT_BUILDING_SHADER ?

#ifdef IS_BUILDNG
texture DamagedTexture //建筑损伤图
<string UIWidget ="None";>; 
sampler2D DamagedTextureSampler 
<string Texture = "DamagedTexture";> =
sampler_state{
    Texture = <DamagedTexture>; 
    MinFilter = 1;
    MagFilter = 2;
    MipFilter = 2;
    AddressU = 1;
    AddressV = 1;
};
#endif  //IS_BUILDNG ?



#ifdef ALLOW_CUBE_MAP_SAMPLER //====================================
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

//#ifdef ENV_CUSTOM
#ifdef _3DSMAX_ //预览天空盒
textureCUBE EnvironmentTexture SEMANTIC_3DSMAX(ReflectionMap)
<
#ifdef ENV_CUSTOM
    string UIName = "PV_EnvironmentTexture"; 
    string ResourceType = "Cube";
	bool ExportValue = false;
#endif
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



#ifdef USE_IRRADIANCE_BOX
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
#endif

#endif  //ALLOW_CUBE_MAP_SAMPLER  ?
//=================================

