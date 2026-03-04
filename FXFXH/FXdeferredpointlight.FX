/*
fxc.exe /O2 /T fx_2_0 /Fo   FXdeferredpointlight.fxo   FXdeferredpointlight.FX


*/



//this file is for local lights and post process

#define DEFERRED_RENDER

#define SPECIAL_SAS_HEADER

int _SasGlobal : SasGlobal  
<
    int3 SasVersion = int3(1, 0, 0);
    string UIWidget = "None";
    int MaxSupportedInstancingMode = 1;
    int MaxLocalLights = 0;
    
	string RenderBin = "StaticSort5"; //try if this can read post fx
> = 0;


// helper functions are still in head 2
#include "head2-functions.FXH"

// copied from original UnderwaterDeferred.fx
struct VSOutput
{
	float4 Position : POSITION;
	float3 WorldEyeDir : TEXCOORD1;
};

VSOutput DefaultVS(float3 Position : POSITION )
{
	VSOutput Out;
	Out.Position = float4(Position, 1);
	
	// We need to convert the view space depth values from the depth texture to world space positions.
	// First build a ray "through" the pixel in question
	float4 screenFarPlanePosition = float4(Position.xy, 1, 1);
	float4 viewFarPlanePosition4 = mul(screenFarPlanePosition, ProjectionI);
	float3 viewFarPlanePosition = viewFarPlanePosition4.xyz / viewFarPlanePosition4.w;
	
	// We don't really want a vector to the far plane. We want the vector with a z length of 1,
	// so that we know how much in x-y we need to step per z-depth that we get from the depth texture.
	float3 viewEyeDir = viewFarPlanePosition / viewFarPlanePosition.z;

	float3 worldEyeDir = mul(viewEyeDir, ViewI);
	
	Out.WorldEyeDir = worldEyeDir;
	
	return Out;
}
//  well this is actualy useless

//==============================

struct VSout_local
{
	float4 Position : POSITION; //clipspace
    //float2 vpos : VPOS ;
    float4 ClipSpacePos : TEXCOORD0;  // PERSPECTIVE DIVISION IN PS
	float4 WP2eye_VPdepth : TEXCOORD1; //xyz = world pos from eye, w = view pos z aka view depth
    half4  Color_Radius : TEXCOORD2;
};

// point light with sphere volume
VSout_local VSpointlight(float3 Position : POSITION )
{
    VSout_local o;

    const float RangeMult = 64 ; //also minimal range
    float3 lightColor = (HasRecolorColors)? RecolorColor : 1 ;
    float  lightRadius = max( max(lightColor.r, lightColor.g) , max(lightColor.b , 1) ) ; 
    lightRadius *=  RangeMult ;
    float3 objPos = Position * lightRadius ;  //opacity control in ps
    o.Color_Radius = half4(lightColor, lightRadius);

    float3 worldP = mul(float4(objPos, 1) , World);
    float4 worldPos4D = float4(worldP, 1);

    //this theotry need proving
    float3 wp2eye = worldP - EyePosition ;
    float vpdepth = mul(worldPos4D , View).z ;
    o.WP2eye_VPdepth = float4(wp2eye, vpdepth);

    o.ClipSpacePos = mul(worldPos4D, ViewProjection); ;
    o.Position = o.ClipSpacePos ;

    return o;
}

// try putting ps here

float4 PSpointlight(VSout_local i) : COLOR 
{    
    float3 ndc = i.ClipSpacePos.xyz / i.ClipSpacePos.w ;
    float2 screenUV = (ndc.xy + 1.0 + (1.0 / 8192.0) ) /2 ;
    float vpdepth = tex2D(DepthTextureSampler, screenUV).x;
    //now all calculation are in eye centered world space
    float3 wp2eye = i.WP2eye_VPdepth.xyz / i.WP2eye_VPdepth.w * vpdepth ; //core theory

    float3 worldN =  cross(ddy(wp2eye), ddx(wp2eye)) ;
    //float3 center2eye = World[3].xyz - EyePosition; //shift light core to our space 
    float3 lightVec = World[3].xyz - EyePosition - wp2eye  ; //not normalized
    lightVec /= i.Color_Radius.a ;

    if ( dot(lightVec , worldN ) < 0) return 0 ; //back facing light

    float distSq = dot(lightVec, lightVec) ;
    float distDecayFactor = 1 / distSq - distSq  ; //cheapest 
    distDecayFactor *= OpacityOverride / 16 ;

    float brightUpperLimit = dot(i.Color_Radius.rgb , 1) ;
    float3 colorHere = i.Color_Radius.rgb * distDecayFactor ;
    colorHere = clamp(colorHere, 0, brightUpperLimit.xxx) ;

    return float4(colorHere , 1) ; 
}

// placeholder for low 

float4 VSnothing() : POSITION 
{   return  float4(0,0,-2,1)  ;}

float4 PSnothing() : COLOR
{   return 0 ;}


// time for techniques 


technique Default
{    pass p0 
  {
    VertexShader = compile vs_3_0 VSpointlight(); 
    PixelShader  = compile ps_3_0 PSpointlight(); 
    ZEnable = 1;
    ZFunc = D3DCMP_GREATEREQUAL ;  //hidden only
    ZWriteEnable = 0;
    CullMode = D3DCULL_CCW ; //backface only
	AlphaTestEnable = 0;
	AlphaBlendEnable = 1; //additive
	SrcBlend =  D3DBLEND_ONE ;
	DestBlend = D3DBLEND_ONE ;
  } 
}

technique Default_M  //actually nothing
{    pass p0 
  {
    VertexShader = compile vs_2_0 VSnothing(); 
    PixelShader  = compile ps_2_0 PSnothing(); 
    ZEnable = 0;
    ZWriteEnable = 0;
    CullMode = 1 ; 
	AlphaTestEnable = 0;
	AlphaBlendEnable = 0; 
  } 
}

// also no shadow