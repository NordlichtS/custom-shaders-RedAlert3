//#define _3DSMAX_
#pragma warning(disable: 3206)



//WILL INCLUDE EVERYTHING
#include "PBR4-ps.FXH"


// MAX预览用的============================
VS_H_output VSforMAX(VS_H_noskin_input i)  
{ 
    VS_H_output  o;

    float4 WorldPosition = float4(0,0,0,1);
    o.ShadowPROJ = o.FogCloudUV = 0 ;
    o.VertexColor = i.color ;  //顶点颜色，opacity 放ps里去吧

    float3 MAXtangent = i.tangent.xyz ;
    float3 MAXbinormal = i.binormal.xyz ;

    if(1){  //exchange max tangent and binormal
    MAXtangent = i.binormal.xyz ;
    MAXbinormal = i.tangent.xyz ;  
    };

    // 从object space 到 world space===========

    o.WorldP = mul(i.position.xyzw, (float4x3)MAXworld);
    o.WorldN = mul(i.normal.xyz, (float3x3)MAXworld);
    o.WorldT = mul(MAXtangent, (float3x3)MAXworld);
    o.WorldB = mul(MAXbinormal, (float3x3)MAXworld);
    // #ifdef USE_TANGENT_FRAME //macro条件编译 是否启用切线框架（支持法线图）
    // #endif
    
    WorldPosition.xyz = o.WorldP ; //世界坐标
    o.MainTexUV = i.texcoord ; //直接转存贴图UV
    o.Position = mul(i.position , MAXwvp); //给rasterizer的clip space坐标

    return o;
};


//start techniques

technique Default
{
    pass p0 <string ExpressionEvaluator = "Objects";>
    {
        VertexShader = compile vs_3_0 VSforMAX(); 
        PixelShader  = compile ps_3_0 PS_H_PBR_CORONA();    
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
    }
}
