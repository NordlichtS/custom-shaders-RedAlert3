//this is actually basic w3d holographic

#define SPECIAL_SAS_HEADER

int _SasGlobal : SasGlobal  
<
    int3 SasVersion = int3(1, 0, 0);
    string UIWidget = "None";
    int MaxSupportedInstancingMode = 1;
    int MaxLocalLights = 8;
    
	string RenderBin = "StaticSort1";

> = 0;

















#include "PBR5-7-holographic.FX"

/*
fxc.exe /O2 /T fx_2_0 /Fo   BasicW3dHolographic.fxo   PBR5-7-holographic.FX
fxc.exe /O2 /T fx_2_0 /Fo   InfantryFormationPreview.fxo   PBR5-7-holographic.FX
fxc.exe /O2 /T fx_2_0 /Fo   ObjectsFormationPreview.fxo   PBR5-7-holographic.FX

*/
