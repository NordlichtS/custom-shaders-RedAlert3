#include "PBR4-ps.FXH"


VertexShader VS_H_Array[2] = {
    compile vs_3_0 VS_H_Array_Shader_0(), 
    compile vs_3_0 VS_H_Array_Shader_1(), 
};


int VSchooser_Expression()  //0 no skin, 1 skin
{  
    int VSindex = clamp(NumJointsPerVertex, 0, 2) ;
    if(tangent_xy_multiply ==0) {VSindex += 3 ;};
    return (min(NumJointsPerVertex.x, 1));  
}

//start techniques

technique Default
{
    pass p0 <string ExpressionEvaluator = "Objects";>
    {
        VertexShader = VS_H_Array[VSchooser_Expression()]; 
        PixelShader  = compile ps_3_0 PS_H_MAIN();    
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        SrcBlend = 5;
        DestBlend = 6;
        AlphaFunc = 7;
        AlphaRef = 64;
        AlphaTestEnable = 0 ;
        AlphaBlendEnable = (OpacityOverride < 0.99) ;
    }
}
