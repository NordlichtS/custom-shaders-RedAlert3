//pbr for corona mod
/*
CORONA MOD PBR
rewrite this from clean start
EXCEPT MAIN CONSTANTS
THIS FILE will include:
all textures and samplers
max sunlight preview
functions
VS 
PS
max preview
preview sunlight and point light
create shadow
alpha test always disable, no objection!
clipping constant bools will be allowed

*/

//  ========================

#include "head1-newvs.FXH"

//  ========================

// =====================
// SKYBOX AND IRRADIANCE
//======================



    #ifdef _3DSMAX_ //预览天空盒
    textureCUBE EnvironmentTexture SEMANTIC_3DSMAX(ReflectionMap)
        <
        string UIName = "PV_SKYBOX"; 
        string ResourceType = "Cube";
        bool ExportValue = false;
        >; 
    #else  //游戏内天空盒
    texture EnvironmentTexture  
        <
        string SasBindAddress = "Lanyi.EnvironmentTexture";
        string ResourceType = "Cube";
        >; 
    #endif
    samplerCUBE EnvironmentTextureSampler
        <   
        string Texture = "EnvironmentTexture";
        string SasBindAddress = "Lanyi.EnvironmentTexture";
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
    int MipLevels
    < string UIName = "MipLevels(of skybox)"; int UIMin = 1; > = 8;
    */

    // maybe we should use irradiance map but as vertex sampling ?

    // preview irradiance use ambient light
    /*
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
        string UIWidget = "None";
        string ResourceType = "Cube";
        > = sampler_state {
        Texture = < IrradianceTexture >;
        MinFilter = 2;
        MagFilter = 2;
        MipFilter = 1;
        AddressU = Clamp;
        AddressV = Clamp;
        AddressW = Clamp;
    };
    */

// =========END SKYBOX AND IRRADIANCE


//==================
// STYLE COEFFICIENT
//==================

/*

for non-metal, reflectivity is zero at max roughness. 
but metal still has it.
or does it?
metal F0 is the same as albedo, so usually non zero, but if black, zero
dielectric F0 always set to zero
we use a fresnel term clamper to limit F0 to 0 at extreme roughness (spm 0)
this applies to both metal and not


*/




// ==================
// main unit textures 
// ==================

texture DiffuseTexture 
<
    string UIName = "(BASE)DiffuseTexture";
    string ResourceMapType = "Normal";   
    string TextureColorSpace = "Linear"; 
>; 
//RGB为基础色，而不是漫反射。 alpha弃用
sampler2D DiffuseTextureSampler
<string Texture = "DiffuseTexture";> = sampler_state {
    Texture = < DiffuseTexture >;
    MinFilter = 2; //3
    MagFilter = 2;
    MipFilter = 2;
    MaxAnisotropy = 4;
    AddressU = Wrap;
    AddressV = Wrap;
    //AddressW = Clamp;
};

bool SRGB // 主帖图是不是用SRGB空间存的
< string UIName = "SRGB"; > =  1 ;

texture SpecMap 
<
    string UIName = "(SPM)SpecMap";
    string ResourceMapType = "Normal";   
    string TextureColorSpace = "Linear"; 
>; 
//R:光滑度（粗糙反转）G:金属度 B:阵营色浓度 A:发光（可反转）
sampler2D SpecMapSampler
<string Texture = "SpecMap";> = sampler_state {
    Texture = < SpecMap >;
    MinFilter = 2; //3
    MagFilter = 2;
    MipFilter = 2;
    MaxAnisotropy = 4;
    AddressU = Wrap;
    AddressV = Wrap;
    //MIPMAPLODBIAS = -1 ;
    //AddressW = Wrap;
};

float MinRoughness 
<   string UIName = "MinRoughness"; float UIMin = 0.01; float UIMax = 0.5; float UIStep = 0.01;
> = 0.25 ;  
// this is PERCEPTUAL roughness at spm.r = 1
// LINEAR roughness is square of this

float EmissiveMultiplier 
<   string UIName = "EmissiveMultiplier(glow)"; float UIMin = -9; float UIMax = 9; float UIStep = 0.1;
> = 0 ;
//  自发光， 写负数反转通道

texture NormalMap // SEMANTIC_3DSMAX(NormalMap)
<
    string UIName = "(NRM)NormalMap";
    string ResourceMapType = "Normal";   // Flags the data type as a normal map
    string TextureColorSpace = "Linear"; // DXSAS standard flag to bypass sRGB/Gamma
>; 
//RG 法线, B 没用, A 环境AO
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
<   string UIName = "BumpScale"; 
    string UIWidget = "Slider"; 
    float UIMin = -8; float UIMax = 8; float UIStep = 0.1;
> =  1.5 ;



float K_diffuse 
<   string UIName = "K_diffuse"; float UIMin = 0; float UIMax = 1; float UIStep = 0.01;
> = 0.8 ; 
// will multiply after dotNL. in real pbr this should be 1/pie

float K_specular
<   string UIName = "K_specular";  float UIMin = 0; float UIMax = 1; float UIStep = 0.01;
> = 0.2 ; 
// specular peak multiplier on  roughness =1
// greater spm value will have brighter multiplier
// this is before fresnel term clamping

float K_ambient
<   string UIName = "K_ambient"; float UIMin = 0; float UIMax = 1; float UIStep = 0.01;
> = 0.4 ;
// only affect irradiance diffuse, and only dielectrics has it
// consist ambient light color + accent light vertex illumiate

float K_skybox
<   string UIName = "K_skybox"; float UIMin = 0; float UIMax = 1; float UIStep = 0.01;
> = 0.7 ;
// multiplier on the whole "ambient specular" right after skybox sampling
// close to rim light brightness at roughness = 0 . metal or not, f90 is the same.
// if use cubemap, this should ignore accent light


float K_extraHC
<   string UIName = "K_extraHC"; float UIMin = 0; float UIMax = 2; float UIStep = 0.1;
> = 0 ;
// house color extra brightness, is actually self glow (not extra bright on albedo !)


// F0 is no longer a constant. completely controlled by metalness
/*
float K_fresnel
<   string UIName = "K_fresnel"; float UIMin = 0; float UIMax = 1; float UIStep = 0.01;
> = 0.6 ;
*/
// actually similar to G-term , at spm.r=0 or low, this is used to darken rim by CLAMP fresnel term 
// actual clamper value: lerp( 1, K_fresnel, realRoughness)
// clamper is , applied after dotNH or dotVL and exponent, before lerp with F0
// for both metal and dielectric, both sunlight and skybox.
// because in all dielectric and pure-black metal, F0 = 0



// ==================
// vertex shader already referenced 
// ==================

// ==================
// pixel shader : main, low, shadow
// ==================

struct PS_H_input
{
    //float vface : VFACE ; // -  camera, + backface ? 
    //float2 vpos : VPOS ; 
    float4 VertexColor : COLOR0;  //顶点颜色(IRRAD,ALPHA)
    //float3 CoordOBJ  : COLOR1; 
    float4 MainTexUV  : TEXCOORD0; //XY主帖图UV,ZW建筑损伤图
    float4 ShadowCS : TEXCOORD1; // XYZ/W
    float4 FogCloudUV : TEXCOORD2; //迷雾和云的UV
    float3 WorldPE : TEXCOORD3;  //世界空间相对于相机位置
    float3 WorldN : TEXCOORD4; //世界法线Z
    float3 WorldT : TEXCOORD5; //世界切线Y
    float3 WorldB : TEXCOORD6; //世界切线X
};

float4 PS_H_CORONAPBR (PS_H_input i) : COLOR 
{
  float4 OUTCOLOR = float4(0,0,0,1); //安全起见先initialize
  
  // 主贴图 (corona mod)
    float4 dif = tex2D(DiffuseTextureSampler,  i.MainTexUV.xy );
    float4 spm = tex2D(SpecMapSampler,         i.MainTexUV.xy );
    float4 nrm = tex2D(NormalMapSampler,       i.MainTexUV.xy );




return OUTCOLOR ;
}
