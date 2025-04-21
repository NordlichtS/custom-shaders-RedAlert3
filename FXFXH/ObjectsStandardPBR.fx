//for batch compiling


// #define _3DSMAX_ 


// #define FORBID_CLIPPING_CONSTANT //只有强制开 ALPHA TEST 的可以开
  #define USE_SPECIAL_PBR_W3X_CONSTANT
// #define REPLACE_DEFAULT_TECHNIQUE //only for objects terrain
 #define COMPILE_SOFTSKIN_VS //USUALLY OFF


//#define NRM_BLUE_CAVITY
#define NRM_BLUE_AO
//#define NRM_ALPHA_AO


// #define FORBID_FACTION_COLOR //中立单位要禁止阵营色 generic on
 #define DYNAMIC_CLOUD_REF //允许动态云背景反射。对金属和玻璃质感很重要 仅玩家
 #define ALLOW_STEALTH //允许隐身时有特殊的全息投影特效, player object only ! 建筑和中立都关
// #define RENDER_BACKFACE //only for tengu, objectsjapan
// #define FORBID_SHADOW_ALPHATEST  //for terrain like stuff


// #define OPACITY_OVERRIDE_CLIP  //仅玩家的OBJECT开
 #define OPACITY_OVERRIDE_OUTPUT //玩家的OBJECT和BUILDING 开
 #define ALLOW_CLIP_TEXTURE_ALPHA //允许贴图alpha镂空。on for all
// #define FORCE_ENABLE_ALPHA_CLIP_BEFORE_RETURN //应该都关
// #define KEEP_ALPHA_TEXTURE_SAMPLER_SAME  //仅建筑
//  #define DAMAGE_BURNRED  //烧红效果看情况吧
// #define SHADOW_DITHER //just like terrain


//下面三个互相冲突的（顶点ALPHA功能）功能只能选一个
 #define ALLOW_CLIP_VERTEX_ALPHA //允许骨骼透明度隐藏零件。building不要。objects ? 
// #define IS_BUILDNG //仅building要。这是损伤破洞功能。与上下两者冲突 不可同时用
// #define IS_NANO_BUILDUP  //启用帝国建筑的建造动画。 与上两者冲突 不可同时用

static const float4 SPM_threshold = { 1, 0.5, 0.125, 0.985 }; //careful gen evo values

#define DEDICATED_METAL_CHANNEL //HAHAHA

static const float MinRoughness = 0.125 ;
static const float SpecBaseMultiply = 0.125 ; 


/*
float MinRoughness //最低粗糙度（要用倒数更精确吗？）
<   string UIName = "MinRoughness"; //MAXglossiness
    float UIMax = 0.5; float UIMin = 0.005; float UIStep = 0.005; 
> = 0.125 ; 

float SpecBaseMultiply //最低粗糙度（要用倒数更精确吗？）
<   string UIName = "SpecBaseMultiply"; //MAXglossiness
    float UIMax = 0.5; float UIMin = 0.005; float UIStep = 0.005; 
> = 0.125 ; 
*/

bool InfantrySkin //当作步兵  允许软绑定  同时关闭法线图
<    string UIName = "InfantrySkin";> = 0;



#include "PBR5-10-objects-ARPBR.FX"

//this is : objectsARPBR.fxo
/*
fxc.exe /O2 /T fx_2_0 /Fo   ObjectsStandardPBR.fxo   ObjectsStandardPBR.fx

fxc.exe /O1 /T fx_2_0 /Fo   ObjectsStandardPBR_3DSMAX.fx   ObjectsStandardPBR.fx  /D _3DSMAX_ 

fxc.exe /T fx_2_0 /Fh   ObjectsStandardPBR.TXT   ObjectsStandardPBR.fx


*/