#define IS_BASIC_W3D_SHADER

#include "PBR3-vsps.FXH"


/*
fxc.exe /O2 /T fx_2_0 /Fo   basicw3dholographic.fxo   PBR5-7-holographic.FX
*/



struct PS_infantry_input
{
    float2 vpos : VPOS ; //screen pixel 
    float4 VertexColor : COLOR0;  //顶点颜色
    float4 MainTexUV  : TEXCOORD0; //XY是主帖图UV,ZW是建筑损伤图UV
    float3 ShadowPROJ : TEXCOORD1; //XYZ阴影空间投影, W弃用
    float4 FogCloudUV : TEXCOORD2; //迷雾和云的UV
    float3 WorldP : TEXCOORD3;  //世界空间位置 ( no use ?)
    float3 WorldN : TEXCOORD4_centroid; //世界法线Z
};

float4 PS_H_bubble (PS_infantry_input i) : COLOR 
{
    float4 OUTCOLOR = float4(0,0,0,0); 

    float3 N = normalize(i.WorldN);
    float3 V = hp_ps_getViewVector(i.WorldP) ;
    float3 realHC = (HasRecolorColors)? RecolorColor : 1 ;
    float fresnel = 1 - dot(N,V);

    float3 gridcoord = i.WorldP;
    gridcoord.xy = mul(gridcoord.xy , float2x2(1,-1,1,1));
    gridcoord.z *= 1.5 ;
    gridcoord = frac(gridcoord /4) *2 -1 ;
    gridcoord = abs(gridcoord) ; //instead of abs
    float dist2grid = max(gridcoord.z, max(gridcoord.x, gridcoord.y)); 

    float scanline = frac(i.WorldP.z /32 - Time  );
    scanline = pow(scanline, 16);

    float alpha = i.VertexColor.w * OpacityOverride ;
    //alpha = lerp(0.125, 0.875, alpha);
    alpha = max(alpha, scanline)  ;
    alpha = min(alpha, (1- dist2grid));
    alpha *= lerp((scanline *0.25 + 0.25), 1, saturate(fresnel));
    alpha = saturate(alpha);

    OUTCOLOR.rgb = lerp(realHC , 1, (fresnel * fresnel)  )  ;
    OUTCOLOR.a = alpha ;

    return OUTCOLOR;
}






int VSchooserExpr() 
{ return clamp(NumJointsPerVertex, 0, 2) ; }


VertexShader VS_infantry_Array[3] = {
    compile vs_3_0 VS_L_00skin(), 
    compile vs_3_0 VS_L_11skin(), 
    compile vs_3_0 VS_L_22skin(), 
};


technique Default
{    pass P0 <string ExpressionEvaluator = "BasicW3D";>
    {
        VertexShader = VS_infantry_Array[ VSchooserExpr() ]; 
        PixelShader  = compile ps_3_0 PS_H_bubble(); 
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1; //
        CullMode = 2;
        AlphaFunc = 7;
        AlphaTestEnable = 0;
        AlphaBlendEnable = 1 ;
        //AlphaRef = 64;
        DepthBias = 1.0f / 4096 ;
    }
}
