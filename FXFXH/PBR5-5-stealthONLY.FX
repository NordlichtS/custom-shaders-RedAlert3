//#define _3DSMAX_

// #define IGNORE_NRM
/*
fxc.exe /O2 /T fx_2_0 /Fo   buildingsgeneric.fxo   PBR5-2-vehicle-GEN2MOD.FX
*/
#pragma warning(disable: 3206)

#include "head3-vsps.FXH" //WILL INCLUDE EVERYTHING

/*
float maxgloss // one over min roughness
<
    string UIName = "maxgloss"; 
    float UIMax = 16; float UIMin = 1; float UIStep = 0.25; 
> = 8 ;

float maxglow // one over min roughness
<
    string UIName = "maxglow"; 
    float UIMax = 5; float UIMin = 0; float UIStep = 0.25; 
> = 4 ;
*/

// #define BUILDING_DAMAGE
// const bool building_damage = 0 ; 
//用这个控制编译时是否需要建筑损伤？

struct PS_H_input
{
    float2 vpos : VPOS ; //screen pixel 
    float4 VertexColor : COLOR0;  //顶点颜色
    float4 MainTexUV  : TEXCOORD0; //XY是主帖图UV,ZW是建筑损伤图UV
    float4 ShadowCS : TEXCOORD1; //XYZ阴影空间投影, W弃用
    float4 FogCloudUV : TEXCOORD2; //迷雾和云的UV
    float3 WorldP : TEXCOORD3;  //世界空间位置
    float3 WorldN : TEXCOORD4_centroid; //世界法线Z
    float3 WorldT : TEXCOORD5_centroid; //世界切线Y
    float3 WorldB : TEXCOORD6_centroid; //世界切线X
};

float4 PS_H_GEN2MOD_SKETCH (PS_H_input i) : COLOR 
{
  float4 OUTCOLOR = i.VertexColor; //安全起见先initialize

  //风格常数，编译前确定

    const float ambient_diff_mult =  0.5 ; //环境光与天空盒diffuse
    const float ambient_spec_mult =  1 ; //环境光与天空盒specular
    const float tangent_mult = -2 ; 
    const float maxglow = 4 ;

    float  temp1 ;
    float2 temp2 ;
    float3 temp3 ;
    float4 temp4 ;
    /*
    const float pointlight_mult =  1 ; //点光源整体亮度
    const float sunlight_mult =  1 ; //阳光亮度
    const float diffuse_mult =  1 ; //漫反射亮度，影响阳光与点光源
    */


  //拿出主贴图 (GEN 2 MOD )
    float4 dif = tex2D(DiffuseTextureSampler,  i.MainTexUV.xy );
    float4 nrm = tex2D(NormalMapSampler,       i.MainTexUV.xy );
    float4 spm = tex2D(SpecMapSampler,         i.MainTexUV.xy );
    clip(dif.w - 0.5); 
    #ifdef IGNORE_NRM
    nrm = float4(0,0,1,1);
    #endif

  //兼容原版


  //有用的向量
    float3 N = float3(0,0,1); //i.WorldN ;
    N.xy = (nrm.xy * 2 - 1 ) * tangent_mult ;
    float3x3 TangentSpaceToWorldMatrix = float3x3(i.WorldB, i.WorldT, i.WorldN) ; //T B exchanged!
    N = mul(N, TangentSpaceToWorldMatrix) ;
    N = normalize(N); //长度单位化，这一步很重要
    #ifdef IGNORE_NRM
    N = normalize(i.WorldN);
    #endif

    float3 V = hp_ps_getViewVector(i.WorldP) ;
    float3 R = reflect(-V , N) ; //input light vector is towards fragment!
    float  EYEtilt = dot(V , N) ;
    if(EYEtilt <0) {R = -V ;} ;


  //初步整理下信息 (GEN 2 MOD )
    float HCchannel = (HasRecolorColors)? spm.b : 0 ;
    float3 hcmask = lerp( float3(1,1,1), RecolorColor, HCchannel);
    dif.xyz *= lerp(dif.xyz , 1 , HCchannel); //gamma without hc
    dif.xyz *= hcmask ;//* hcmask ; //squared hc mix


    return hp_stealthVFX(EYEtilt, dif.xyz , 1, i.vpos.y, RecolorColor);

};

//高画质PBR pixel shader结束====================

int VSchooserExpr() 
{ return clamp(NumJointsPerVertex, 0, 2) ; }


VertexShader VS_infantry_Array[3] = {
    compile vs_3_0 VS_H_00skin(), 
    compile vs_3_0 VS_H_11skin(), 
    compile vs_3_0 VS_L_22skin(), //soft no tgt
};


#ifdef _3DSMAX_ //预览
technique GEN2max
{    pass p0 <string ExpressionEvaluator = "Objects";>
    {
        VertexShader = compile vs_3_0 VSforMAX(); 
        PixelShader = compile ps_3_0 PS_H_GEN2MOD_SKETCH();
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        AlphaBlendEnable = 0 ;
        AlphaTestEnable = 0 ;
    }
}
#endif

technique Default
{    pass p0 <string ExpressionEvaluator = "Objects";>
  {
    VertexShader = VS_H_Array[ VSchooserExpr() ]; 
    PixelShader  = compile ps_3_0 PS_H_GEN2MOD_SKETCH(); 
    ZEnable = 1;
    ZFunc = 4;
    ZWriteEnable = 1;
    CullMode = 2;
    AlphaFunc = 7;
    AlphaRef = 64;
    //AlphaBlendEnable = (AlphaBlendEnable);
    AlphaTestEnable = 0;
  } 
}



//
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

    pass p1 //outline
    {
        VertexShader = compile vs_3_0 VS_outline_3dsmax(); 
        PixelShader  = compile ps_3_0 PS_outline();    
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 0;
        CullMode = 3; // reverse
        AlphaBlendEnable = 1 ;
        AlphaTestEnable = 1 ;
    }


*/

