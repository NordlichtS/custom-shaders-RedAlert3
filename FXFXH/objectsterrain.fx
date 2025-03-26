//for batch compiling



// #define FORBID_FACTION_COLOR //中立单位要禁止阵营色 generic on
// #define DYNAMIC_CLOUD_REF //允许动态云背景反射。对金属和玻璃质感很重要 仅玩家
// #define ALLOW_STEALTH //允许隐身时有特殊的全息投影特效, player object only ! 建筑和中立都关
// #define RENDER_BACKFACE //only for tengu, objectsjapan
#define FORBID_SHADOW_ALPHATEST  //for terrain like stuff


// #define OPACITY_OVERRIDE_CLIP  //仅玩家的OBJECT开? NO JUST TURN OFF ALL
// #define OPACITY_OVERRIDE_OUTPUT //玩家的OBJECT和BUILDING 开
 #define ALLOW_CLIP_TEXTURE_ALPHA //允许贴图alpha镂空。on for all
// #define FORCE_ENABLE_ALPHA_CLIP_BEFORE_RETURN //应该都关
// #define KEEP_ALPHA_TEXTURE_SAMPLER_SAME  //仅建筑
//  #define DAMAGE_BURNRED  //烧红效果看情况吧
 #define SHADOW_DITHER //just like terrain


//下面三个互相冲突的（顶点ALPHA功能）功能只能选一个
// #define ALLOW_CLIP_VERTEX_ALPHA //允许骨骼透明度隐藏零件。building不要。objects ? 
// #define IS_BUILDNG //仅building要。这是损伤破洞功能。与上下两者冲突 不可同时用
// #define IS_NANO_BUILDUP  //启用帝国建筑的建造动画。 与上两者冲突 不可同时用


#define FORBID_CLIPPING_CONSTANT
#define REPLACE_DEFAULT_TECHNIQUE 
static const bool AlphaTestEnable = 1 ;

#include "PBR5-10-objects-ARPBR.FX"




technique Default
{   pass p0
    {
        VertexShader = compile vs_3_0 VS_H_00skin();
        PixelShader = compile ps_3_0 PS_H_ARPBR();
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        AlphaBlendEnable = 0;
        AlphaTestEnable = 1;
        AlphaFunc = 7;
        AlphaRef = 95;
    }
}

technique Default_M
{   pass p0
    {
        VertexShader = compile vs_3_0 VS_L_00skin(); 
        PixelShader = compile ps_3_0 PS_LOW_ARPBR(); 
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        AlphaBlendEnable = 0;
        AlphaTestEnable = 1;
        AlphaFunc = 7;
        AlphaRef = 95;
    }
}


technique _CreateShadowMap
{   pass p0
    {
        VertexShader = compile vs_2_0 VS_ShadowMaker_00skin(); 
        PixelShader = compile ps_2_0 PS_ShadowMaker_NoAlphaTest(); 
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        AlphaBlendEnable = 0;
        AlphaTestEnable = 0;
    }
}



//this is : objects terrain