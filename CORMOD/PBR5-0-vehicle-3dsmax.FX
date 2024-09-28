//#define _3DSMAX_
#pragma warning(disable: 3206)


//#if defined(_3DSMAX_) //预览用 constant

    float3 PV_FactionColor <
	string UIName = "PV_FactionColor";
	string UIWidget = "Color";
	bool ExportValue = false;
    > = {0, 0, 1};

    //预览用的自定义天空盒扔到文件尾部去了

    // sun light direction (world space)
    float3 PV_SunlightDirection : Direction <  
	string UIName = "PV_SunlightDirection"; 
    string Space = "World";   
	string Object = "TargetLight";
	bool ExportValue = false;
	> = {0, 0, 1};

    //能不能合并在一起啊
    float3 PV_SunlightColor : LightColor <
	string UIName = "PV_SunlightColor";
	string Object = "TargetLight";
	bool ExportValue = false;
    > = {1, 1, 1};

    //获取MAX场景里点光源位置和颜色不会装了，预览还是需要一个点光源的，谁来救一下

    /*
    float3 PV_PointLight_Position : Position <  
	string UIName = "PV_PointLightPosition"; 
	string Object = "OmniLight";
	bool ExportValue = false;
	> = {0, 0, 10};

    float PV_PointLight_Range <
	string UIName = "PV_PointLight_Range";
	bool ExportValue = false;
    > = 30 ;

    */

    float4x4 MAXwvp : WorldViewProjection;
    float4x4 MAXworld : WORLD;
    float4x4 ViewI : VIEWINVERSE; //3dsmax give you that ?

//#endif


//WILL INCLUDE EVERYTHING
#include "PBR4-ps.FXH"

#define EXCHANGE_MAX_TANGENT


// MAX预览用的============================
VS_H_output VSforMAX(VS_H_noskin_input i)  
{ 
    VS_H_output  o;

    float4 WorldPosition = float4(0,0,0,1);
    o.ShadowPROJ = o.FogCloudUV = 0 ;
    o.VertexColor = i.color ;  //顶点颜色，opacity 放ps里去吧

    float3 MAXtangent = i.tangent.xyz ;
    float3 MAXbinormal = i.binormal.xyz ;

    #ifdef EXCHANGE_MAX_TANGENT
    MAXtangent = i.binormal.xyz ;
    MAXbinormal = i.tangent.xyz ;  
    #endif

    // 从object space 到 world space===========

    o.WorldP = mul(i.position.xyzw , (float4x3)MAXworld);
    o.WorldN = mul(i.normal.xyz, (float3x3)MAXworld);
    o.WorldT = mul(MAXtangent, (float3x3)MAXworld);
    o.WorldB = mul(MAXbinormal, (float3x3)MAXworld);
    //#ifdef USE_TANGENT_FRAME //macro条件编译 是否启用切线框架（支持法线图）
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
        SrcBlend = 5;
        DestBlend = 6;
        AlphaFunc = 7;
        AlphaRef = 32 ;
    }
}
