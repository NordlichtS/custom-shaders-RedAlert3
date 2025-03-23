//for batch compiling

// #define FORBID_FACTION_COLOR //中立单位要禁止阵营色 generic on
 #define DYNAMIC_CLOUD_REF //允许动态云背景反射。对金属和玻璃质感很重要 on for all
 #define ALLOW_STEALTH //允许隐身时有特殊的全息投影特效, player object only ! building off
// #define RENDER_BACKFACE //only for tengu, objectsjapan

//下面三个互相冲突的功能只能选一个
 #define ALLOW_CLIP_VERTEX_ALPHA //允许骨骼透明度隐藏零件。building不要。objects ? 
// #define IS_BUILDNG //仅building要。这是损伤破洞功能。与上下两者冲突 不可同时用
// #define IS_NANO_BUILDUP  //启用帝国建筑的建造动画。 与上两者冲突 不可同时用

#include "PBR5-10-objects-ARPBR.FX"

//this is : objectssoviet.fxo