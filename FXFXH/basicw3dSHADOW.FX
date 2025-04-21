/*
fxc.exe /O2 /T fx_2_0 /Fo   basicw3dSHADOW.FXO   basicw3dSHADOW.FX


*/

#define FORBID_FACTION_COLOR

#include "head3-vsps.FXH" //WILL INCLUDE EVERYTHING



int VSchooserExpr() 
{ 
  int max_allowed_bone = 1 ;
  return clamp(NumJointsPerVertex, 0, max_allowed_bone) ; 
}


VertexShader VS_Shadow_Array[2] = {
    compile vs_2_0 VS_ShadowMaker_00skin(), 
    compile vs_2_0 VS_ShadowMaker_11skin(), 
};

technique _CreateShadowMap
{    pass p0    
  {
    VertexShader = VS_Shadow_Array[ VSchooserExpr()  ]; 
    PixelShader  = compile ps_2_0 PS_ShadowMaker_NoAlphaTest() ;
    ZEnable = 1;
    ZFunc = 4;
    ZWriteEnable = 1;
    CullMode = 1;
    AlphaBlendEnable = 0;
    AlphaTestEnable = 0;        
    //DepthBias = -1 /2048 ;
  } 
}