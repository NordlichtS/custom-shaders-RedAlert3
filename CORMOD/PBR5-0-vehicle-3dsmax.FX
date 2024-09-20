#include "PBR4-ps.FXH"

#define EXCHANGE_MAX_TANGENT
//start techniques

technique Default
{
    pass p0 <string ExpressionEvaluator = "Objects";>
    {
        VertexShader = compile vs_3_0 VSforMAX(); 
        PixelShader  = compile ps_3_0 PS_H_MAIN();    
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        SrcBlend = 5;
        DestBlend = 6;
        AlphaFunc = 7;
        AlphaRef = 64;
    }
}
