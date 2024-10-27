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

    WorldPosition = mul(i.position, MAXworld);
    o.WorldN = mul(i.normal.xyz, (float3x3)MAXworld);
    o.WorldT = mul(MAXtangent, (float3x3)MAXworld);
    o.WorldB = mul(MAXbinormal, (float3x3)MAXworld);
    // #ifdef USE_TANGENT_FRAME //macro条件编译 是否启用切线框架（支持法线图）
    // #endif
    
    o.WorldP = WorldPosition.xyz ; //世界坐标
    o.MainTexUV = i.texcoord ; //直接转存贴图UV
    o.Position = mul(i.position , MAXwvp); //给rasterizer的clip space坐标



    return o; 
};


//start techniques

technique Default3DSMAX
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

/*

typedef enum D3DBLEND 
  D3DBLEND_ZERO             = 1,
  D3DBLEND_ONE              = 2,
  D3DBLEND_SRCCOLOR         = 3,
  D3DBLEND_INVSRCCOLOR      = 4,
  D3DBLEND_SRCALPHA         = 5,
  D3DBLEND_INVSRCALPHA      = 6,
  D3DBLEND_DESTALPHA        = 7,
  D3DBLEND_INVDESTALPHA     = 8,
  D3DBLEND_DESTCOLOR        = 9,
  D3DBLEND_INVDESTCOLOR     = 10,
  D3DBLEND_SRCALPHASAT      = 11,
  D3DBLEND_BOTHSRCALPHA     = 12,
  D3DBLEND_BOTHINVSRCALPHA  = 13,
  D3DBLEND_BLENDFACTOR      = 14,
  D3DBLEND_INVBLENDFACTOR   = 15,
  D3DBLEND_SRCCOLOR2        = 16,
  D3DBLEND_INVSRCCOLOR2     = 17,
  D3DBLEND_FORCE_DWORD      = 0x7fffffff
source color is the color of the pixel that is being drawn,
destination color is the color of the pixel that was behind the one drawn.

typedef enum D3DCULL 
  D3DCULL_NONE         = 1, Do not cull back faces.
  D3DCULL_CW           = 2, Cull back faces with clockwise vertices.
  D3DCULL_CCW          = 3, Cull back faces with counterclockwise vertices.
default cullmode = 2



*/