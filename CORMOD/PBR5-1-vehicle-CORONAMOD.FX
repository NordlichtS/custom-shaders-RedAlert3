#include "PBR4-ps.FXH"


VertexShader VS_H_Array[3] = {
    compile vs_3_0 VS_H_noskin(), 
    compile vs_3_0 VS_H_hardskin(), 
    compile vs_3_0 VS_H_softskin(), 
};



int VSchooserExpr()  //0 noskin, 1 skin, 2 softskin
{  
    int VSindex = clamp(NumJointsPerVertex, 0, 2) ;
    // if(tangent_xy_multiply ==0) {VSindex += 3 ;};
    return VSindex ;  
}

//start techniques

technique Default
{
    pass p0 <string ExpressionEvaluator = "Objects";>
    {
        VertexShader = VS_H_Array[VSchooserExpr()]; 
        PixelShader  = compile ps_3_0 PS_H_PBR_CORONA();    
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        SrcBlend = 5;
        DestBlend = 6;
        AlphaFunc = 7;
        AlphaRef = 32;
        //AlphaTestEnable = 0 ;
        //AlphaBlendEnable = (OpacityOverride < 0.99) ;
    }
}
