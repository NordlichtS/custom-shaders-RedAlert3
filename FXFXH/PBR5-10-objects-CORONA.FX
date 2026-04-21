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
clipping constant will be allowed

*/

#include "head0-common.fxh"


//first we need the SKYBOX textures

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
<   string Texture = "EnvironmentTexture";
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


int MipLevels
< string UIName = "MipLevels(of skybox)"; int UIMin = 1; > = 8;


//  FOG CLOUD SHADOW ========================================


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
      #ifdef SHADOW_LINEAR_FILTER
      MinFilter = 2 ; 
      MagFilter = 2 ; 
      #else
      MinFilter = 1 ; 
      MagFilter = 1 ; 
      #endif
      MipFilter = 0;
      AddressU = 4; //3=clamp, 4=bordercolor
      AddressV = 4;
      //AddressW = 3;
  };

  // 云的贴图
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

// END : FOG CLOUD SHADOW =========================================

//style constant

/*

for non-metal, reflectivity is zero at max roughness. but metal still has it.
thus we use glossiness = 1 / roughness
and give a new multiplier called reflectivity

*/

float K_diffuse 
<   string UIName = "K_diffuse"; float UIMin = 0; float UIMax = 1; float UIStep = 0.01;
> = 0.8 ; 
// will multiply after dotNL. in real pbr this should be 1/pie

float K_specular
<   string UIName = "K_specular"; float UIMin = 0; float UIMax = 1; float UIStep = 0.01;
> = 0.2 ; 
// specular peak multiplier on lowest glossiness = 1

float K_ambient
<   string UIName = "K_ambient"; float UIMin = 0; float UIMax = 1; float UIStep = 0.01;
> = 0.5 ;
// only affect ambient diffuse for dielectrics

float K_skybox
<   string UIName = "K_skybox"; float UIMin = 0; float UIMax = 1; float UIStep = 0.01;
> = 0.6 ;
// actually rim light brightness at spm.r=1 . metal or not, f90 is the same.

float K_reflectivity
<   string UIName = "K_reflectivity"; float UIMin = 0; float UIMax = 1; float UIStep = 0.01;
> = 0.5 ;
// at spm.r=0 , this is used to darken metal rim (dielectric always 0 skybox at spm.r=0)

float K_fresnel
<   string UIName = "K_fresnel"; float UIMin = 0; float UIMax = 0.5; float UIStep = 0.01;
> = 0.1 ; 
// dielectric f0 . metal will simply use albedo. will multiply with k_skybox and k_ref

float K_housecolor
<   string UIName = "K_housecolor"; float UIMin = 0; float UIMax = 2; float UIStep = 0.1;
> = 1 ;
// house color extra brightness, 

//albedo brightness is max among rgb

/*
array meaning: diffuse sun, diffuse ambient, spec sun, spec ambient, f0, f90
mat type:                    metal                 dielec
min rough               [0,0,1,1,rgb,1 ]          [rgb, rgb, ]
max rough               [0,0,]

*/





texture DiffuseTexture 
<string UIName = "(BASE)DiffuseTexture";>; 
//RGB为基础色，而不是漫反射。 alpha弃用
sampler2D DiffuseTextureSampler
<string Texture = "DiffuseTexture";> = sampler_state {
    Texture = < DiffuseTexture >;
    MinFilter = 3; //Anisotropic
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
<string UIName = "(SPM)SpecMap";>; 
//R:光滑度（粗糙反转）G:金属度 B:阵营色浓度 A:发光（可反转）
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

float MinRoughness 
<   string UIName = "MinRoughness"; float UIMin = 0.01; float UIMax = 0.5; float UIStep = 0.01;
> = 0.25 ;

float EmissiveMultiplier 
<   string UIName = "EmissiveMultiplier"; float UIMin = -9; float UIMax = 9; float UIStep = 0.1;
> = 0 ;
//  自发光， 写负数反转通道

texture NormalMap SEMANTIC_3DSMAX(NormalMap)
<string UIName = "(NRM)NormalMap";>; 
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
> =  2 ;


