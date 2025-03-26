

// #define IS_BASIC_W3D_SHADER
// #define FORBID_CLIPPING_CONSTANT


#include "head3-vsps.FXH"

#define USE_HOLO_GRID

/*
fxc.exe /O2 /T fx_2_0 /Fo   BasicW3dHolographic.fxo   PBR5-7-holographic.FX
fxc.exe /O2 /T fx_2_0 /Fo   InfantryFormationPreview.fxo   PBR5-7-holographic.FX
fxc.exe /O2 /T fx_2_0 /Fo   ObjectsFormationPreview.fxo   PBR5-7-holographic.FX

*/



struct PS_infantry_input
{
    float2 vpos : VPOS ; //screen pixel 
    //float4 VertexColor : COLOR0;  //顶点颜色
    float3 WorldP : TEXCOORD3;  //世界空间位置 
    float3 WorldN : TEXCOORD4; //世界法线Z
};



float4 PS_H_bubble (PS_infantry_input i) : COLOR 
{
    float4 OUTCOLOR = float4(0,0,0,0); 

    float3 N = normalize(i.WorldN);
    float3 V = hp_ps_getViewVector(i.WorldP) ;
    float3 realHC = (HasRecolorColors)? RecolorColor : abs(N.rgb) ;
    float eyetilt = saturate( dot(N,V)) ;
    float fresnel = 1- eyetilt;

    float3 gridcoord = i.WorldP;
    gridcoord.xy = mul(gridcoord.xy , float2x2(1,-1,1,1));
    gridcoord.z *= 1.5 ;
    gridcoord = frac(gridcoord /4) *2 -1 ;
    gridcoord = abs(gridcoord) ; //or square?
    float dist2grid = 1; //1  at grid lines, 0 at block center
    #ifdef USE_HOLO_GRID
        dist2grid = max(gridcoord.z, max(gridcoord.x, gridcoord.y)); 
        //dist2grid = dot(gridcoord, 1);
        dist2grid *= (HasRecolorColors)? 1 : eyetilt ;
    #endif

    float scanline = frac(i.WorldP.z /32 - Time  );
    scanline = pow(scanline, 16);
    //scanline = scanline *0.5 + 0.25;

    float alpha = OpacityOverride ; // * i.VertexColor.w
    //alpha = lerp(0.125, 0.875, alpha);
    alpha = max(alpha, scanline)  ;
    alpha = min(alpha, (1- dist2grid));
    alpha *= lerp((scanline *0.5 ), 1, fresnel ); //why f0 is like this
    
    float3 extrasaturation = lerp(RecolorColor , 1, scanline ) ;

    OUTCOLOR.rgb += lerp(realHC , 1, fresnel )  ;
    OUTCOLOR.rgb *= (HasRecolorColors)? extrasaturation : 1 ;
    OUTCOLOR.a = saturate(alpha) ; //min alpha 0.25

    return OUTCOLOR;
}






int VSchooserExpr() 
{ return clamp(NumJointsPerVertex, 0, 2) ; }


VertexShader VS_infantry_Array[3] = {
    compile vs_3_0 VS_L_00skin(), 
    compile vs_3_0 VS_L_11skin(), 
    compile vs_3_0 VS_L_22skin(), 
};

#ifdef _3DSMAX_ //预览
technique MAXPREV
{    pass p0 
    {
        VertexShader = compile vs_3_0 VSforMAX(); 
        PixelShader  = compile ps_3_0 PS_H_bubble(); 
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1; //?
        CullMode = 2;
        AlphaFunc = 7;
        AlphaTestEnable = 0;
        AlphaBlendEnable = 1 ;
        SrcBlend = 5;
        DestBlend = 6;
        AlphaRef = 16;
    }
}
#endif


technique Default
{    pass P0 //<string ExpressionEvaluator = "BasicW3D";>
    {
        VertexShader = VS_infantry_Array[ VSchooserExpr() ]; 
        PixelShader  = compile ps_3_0 PS_H_bubble(); 
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1; //?
        CullMode = 2;
        AlphaFunc = 7;
        AlphaTestEnable = 0;
        AlphaBlendEnable = 1 ;
        SrcBlend = 5;
        DestBlend = 6;
        AlphaRef = 16;
        DepthBias = pow(0.5 , 13) ;
    }
}

/*
technique Default
{
    pass P0 <string ExpressionEvaluator = "BasicW3D";>
    {
        VertexShader = VS_Array[Default_Expression29()]; 
        PixelShader = PS_Array[Default_Expression28()]; 
        ZEnable = 1;
        ZFunc = 4;
        AlphaFunc = 7;
        AlphaRef = 96;
    }
}
*/