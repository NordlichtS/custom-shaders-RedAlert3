/*
fxc.exe /O2 /T fx_2_0 /Fo   FXdeferredpointlight.fxo   FXdeferredpointlight.FX


*/



//this file is for simple point local lights 

#define DEFERRED_RENDER
#define FORBID_CLIPPING_CONSTANT
#define IGNORE_FOG_CLOUD_SHADOW


#define SPECIAL_SAS_HEADER

int _SasGlobal : SasGlobal  
<
    int3 SasVersion = int3(1, 0, 0);
    string UIWidget = "None";
    int MaxSupportedInstancingMode = 1;
    int MaxLocalLights = 0;
	string RenderBin = "StaticSort5"; //try if this can read post fx
> = 0;

//LIGHT PARAM  =======================
float Range
<
    string UIName = "Range"; 
    float UIMax = 1024; float UIMin = 32; float UIStep = 1; 
> = 100 ;

float4 ColorEmissive
<
	string UIName = "ColorEmissive(rgb+a*hc)";
    string UIWidget = "Color";
> = float4(0.5, 0.5, 0.5, 0.5);

float HDRMultiplier
<
	string UIName = "HDRMultiplier";  //this is a limit, not real multiplier
    float UIMax = 16; float UIMin = 0; float UIStep = 0.1; 
> = 3;  //default white light can peak to 3x core brightness 

float ZBias
<
    string UIName = "ZBias"; 
    float UIMax = 30; float UIMin = -30; float UIStep = 1; 
> = 6 ;

float FilmGrain
<
    string UIName = "FilmGrain"; 
    float UIMax = 2; float UIMin = -1; float UIStep = 0.1; 
> = 0.8 ;

bool ConsiderSurface
<   string UIName = "ConsiderSurface"; > = 1 ;

// helper functions no need
#include "head1-maxui.fxh"
//#include "head2-functions.FXH"







// new version ===============================


struct VSout_local2
{
	float4 Position     : POSITION; //clipspace
    float4 ClipSpacePos : TEXCOORD0;  // PERSPECTIVE DIVISION IN PS
    float3 ViewSpacePos : TEXCOORD1 ; 
    float3 Center2Eye   : TEXCOORD2 ; //light center in world space minus eye
};

// point light with sphere volume
VSout_local2 VSpointlight2(float3 Position : POSITION )
{
    VSout_local2 o;

    float3 objPos = Position * Range ;  //scale up
    float3 center2world = World[3].xyz ;
    center2world.z += (1- OpacityOverride) * ZBias;
    // move up at low opacity in case ground hide
    // point light only move, no rotation
    float4 worldPos4D = float4( float3(objPos + center2world), 1);

    o.ViewSpacePos = mul(worldPos4D , View).xyz ;
    o.ClipSpacePos = mul(worldPos4D, ViewProjection); ;
    o.Position = o.ClipSpacePos ;
    o.Center2Eye = center2world - EyePosition ;
    // World[3].xyz - ViewI[3].xyz ;

    return o;
}

struct PSin_local2
{
    float2 Vpos         : VPOS ;        //for pixel film grain
    float4 ClipSpacePos : TEXCOORD0 ;   // PERSPECTIVE DIVISION IN PS
    float3 ViewSpacePos : TEXCOORD1 ;   // z division in ps
    float3 Center2Eye   : TEXCOORD2 ;   //light center in world space minus eye
	// uniform int levelofdetail ;  // >=1 has film grain, >=2 has diffuse dot
};

float4 PSpointlight2(PSin_local2 i) : COLOR 
{   
    float2 screenUV = i.ClipSpacePos.xy / i.ClipSpacePos.w * float2(1, -1); 
    //ndc but flip, also add margin due to dx9
    screenUV = screenUV * 0.5 + 0.5 + (0.5 / 8192.0) ;

    float vpdepth = tex2D(DepthTextureSampler, screenUV).x; //DEPTH BUFFER?
    float3 vpPixel = i.ViewSpacePos.xyz / i.ViewSpacePos.z * vpdepth; 

    //now all calculation are in eye centered world space
    float3 wp2eye = mul( float4(vpPixel, 0)  , ViewI).xyz;
    float3 lightVec = (i.Center2Eye - wp2eye) /Range  ; //not normalized
    float distSq = dot(lightVec, lightVec) ;

    float3 worldN =  cross(ddy(wp2eye), ddx(wp2eye)) ;
    if(FilmGrain > 0) {
        worldN /= dot( abs(worldN), 1 ); //octa
        float2 nrmBias = frac(i.Vpos / 2) -0.25 ; //0,1-> 0,0.5-> -0.25,+0.25
        worldN.xy += nrmBias * FilmGrain;
    };

    if ( (distSq > 1) || ( dot(lightVec, worldN ) < 0) ) return 0 ; 
    // out of range   or  backfacing light

    // get light color 
    float3 realHC = (HasRecolorColors)? RecolorColor : 1 ;
    float3 lightColor = ColorEmissive.rgb + ColorEmissive.a * realHC ; //mix hc
    lightColor *= OpacityOverride ;

    float3 colorHere = 0 ;
    
    if(ConsiderSurface) { 
        //decay type : (1-r^2)/r and diffuse
        float diffusedecay = dot( float3(lightVec / distSq) , normalize(worldN)) ;
        diffusedecay *= (1- distSq) / 8 ;  //core 0.125, curve close to (x-1)^2
        colorHere = lightColor * diffusedecay ;
    } else {
        //decay type : (1- r^2)^n 
        float decayeasy = saturate(1 - distSq) ;
        decayeasy = pow(decayeasy, 4) ; // slow - fast - slow
        colorHere = lightColor * decayeasy ;
    };

    colorHere = clamp(colorHere, 0, HDRMultiplier.xxx); 
    // actually lower limit is not needed, we cut it off earlier

    return float4(colorHere , 1) ; 
}

// PREVIEW ======================

#if defined(_3DSMAX_) 

float4 VSmax(float3 Position : POSITION ) : POSITION 
{   
    float4 objPos = float4(Position * Range , 1) ;
    return  mul( objPos , MAXwvp )  ;
}

float4 PSmax() : COLOR
{   
    float3 lightColor = ColorEmissive.rgb + ColorEmissive.a * RecolorColor ;
    return float4(lightColor * 0.5 , 1) ;
}

technique MAXPREV
{    pass p0 
    {
    VertexShader = compile vs_3_0 VSmax(); 
    PixelShader  = compile ps_3_0 PSmax(); 
    ZEnable = 1;
    ZFunc = 4;
    ZWriteEnable = 0;
    CullMode = 1;
	AlphaTestEnable = 0;
	AlphaBlendEnable = 1; //additive
	SrcBlend =  D3DBLEND_ONE ;
	DestBlend = D3DBLEND_ONE ;
    } 
}

#endif  // #if defined(_3DSMAX_) 




//  techniques ===========================


technique Default
{    pass p0 
    {
    VertexShader = compile vs_3_0 VSpointlight2(); 
    PixelShader  = compile ps_3_0 PSpointlight2(); 
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

// LOW ============

float4 VSnothing() : POSITION 
{   return  float4(0,0,-2,1)  ;}
float4 PSnothing() : COLOR
{   return 0 ;}

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

//================
// prepare for better deferred vfx

/*

// Input: float4x3 World (Rows 0-2 are Rotation, Row 3 is Translation)

// 1. Extract and invert the Rotation (Transpose)
float3x3 R = float3x3(World[0], World[1], World[2]);
float3x3 R_inv = transpose(R);

// 2. Extract and invert the Translation
float3 T = World[3];
float3 T_inv = mul(-T, R_inv);

// 3. Pack into 3 float4 interpolators (Building a 3x4 matrix by rows)
// We pack the translation into the 'w' component of each row.
// PRO-TIP: Use the 'nointerpolation' modifier if your engine supports it. 
// Since all 3 vertices of a rigid skinned triangle share the exact same bone, 
// this saves the rasterizer from doing useless interpolation math.
nointerpolation float4 InvMatrixRow0 : TEXCOORD4;
nointerpolation float4 InvMatrixRow1 : TEXCOORD5;
nointerpolation float4 InvMatrixRow2 : TEXCOORD6;

Out.InvMatrixRow0 = float4(R_inv[0], T_inv.x);
Out.InvMatrixRow1 = float4(R_inv[1], T_inv.y);
Out.InvMatrixRow2 = float4(R_inv[2], T_inv.z);

//===============================


// Inputs: 
// float4 InvMatrixRow0, InvMatrixRow1, InvMatrixRow2
// float3 pixelWorldPos

// Because we structured our 3 float4s as the rows of an inverted transform matrix, 
// we can execute the World-to-Bone space conversion using just 3 dot products.
// This is the absolute fastest way a GPU can process this in the PS.

float4 posW = float4(pixelWorldPos, 1.0);

float3 boneSpacePos;
boneSpacePos.x = dot(posW, In.InvMatrixRow0);
boneSpacePos.y = dot(posW, In.InvMatrixRow1);
boneSpacePos.z = dot(posW, In.InvMatrixRow2);



*/



//==============================


// other decay function
/*
    //decay factor type A: (1/r^2 - r^2)
    float distDecayFactor = 1 / distSq - distSq  ; //cheapest 
    float3 colorHereA = lightColor * distDecayFactor / 16 ; // CORE 0.25
    colorHereA = clamp(colorHereA, 0, HDRMultiplier.xxx) ;


    //decay factor type C: (1- r^2)^n
    float decaynew = saturate(1 - distSq) ;
    decaynew = pow(decaynew, 3) ; // slow - fast - slow
    float3 colorHereC = lightColor * decaynew ;

*/

// older version
/*

struct VSout_local
{
	float4 Position : POSITION; //clipspace
    //float2 vpos : VPOS ;
    float4 ClipSpacePos : TEXCOORD0;  // PERSPECTIVE DIVISION IN PS
	//float4 WP2eye_VPdepth : TEXCOORD1; //theory failed
    float3 ViewSpacePos : TEXCOORD1 ; 
    float4  Color_Radius : TEXCOORD2 ;  //half4 ?
};

// point light with sphere volume
VSout_local VSpointlight(float3 Position : POSITION )
{
    VSout_local o;

    //const float Range = 64 ; //also minimal range
    float3 realHC = (HasRecolorColors)? RecolorColor : 1 ;
    float3 lightColor = ColorEmissive.rgb + ColorEmissive.a * realHC ;  //mix hc
    float  lightRadius = max( max(lightColor.r, lightColor.g) , max(lightColor.b , 1) ) ; 
    lightRadius *=  Range ;
    
    float3 objPos = Position * lightRadius ;  //opacity control in ps
    o.Color_Radius = half4(lightColor, lightRadius);

    float3 worldP = mul(float4(objPos, 1) , World);
    float4 worldPos4D = float4(worldP, 1);

    //this theotry need proving

    o.ViewSpacePos = mul(worldPos4D , View).xyz ;

    o.ClipSpacePos = mul(worldPos4D, ViewProjection); ;
    o.Position = o.ClipSpacePos ;

    return o;
}
//old ps

float4 PSpointlight(VSout_local i) : COLOR 
{    
    //float3 ndc = i.ClipSpacePos.xyz / i.ClipSpacePos.w ;
    //float2 screenUV = (ndc.xy + 1.0 + (1.0 / 8192.0) ) /2 ;
    float2 screenUV = i.ClipSpacePos.xy / i.ClipSpacePos.w * float2(1, -1); //ndc but flip
    screenUV = screenUV * 0.5 + 0.5 + (0.5 / 8192.0) ;
    float vpdepth = tex2D(DepthTextureSampler, screenUV).x;
    //now all calculation are in eye centered world space
    //float3 wp2eye = i.WP2eye_VPdepth.xyz / i.WP2eye_VPdepth.w * vpdepth ; 
    //theory failed
    float3 vpPixel = i.ViewSpacePos.xyz / i.ViewSpacePos.z * vpdepth; 
    // get view pos , get world pos
    float3 wp2eye = mul( float4(vpPixel, 0)  , ViewI).xyz;
    
    float3 worldN =  cross(ddy(wp2eye), ddx(wp2eye)) ;
    //float3 center2eye = World[3].xyz - EyePosition; //shift light core to our space 
    float3 lightVec = (World[3].xyz - EyePosition) - wp2eye  ; //not normalized
    lightVec /= i.Color_Radius.a ;

    if ( dot(lightVec , worldN ) < 0) return 0 ; //back facing light

    float distSq = dot(lightVec, lightVec) ;

    //decay factor type one: (1/r^2 - r^2)
    float distDecayFactor = 1 / distSq - distSq  ; //cheapest 
    distDecayFactor *= OpacityOverride / 16 ;  //core 0.25
    float brightUpperLimit = dot(i.Color_Radius.rgb , 1) ;
    brightUpperLimit = max(brightUpperLimit, HDRMultiplier);
    float3 colorHereA = i.Color_Radius.rgb * distDecayFactor ;
    colorHereA = clamp(colorHereA, 0, brightUpperLimit.xxx) ;

    //decay factor type two: (1- r^2)^2
    float decaynew = saturate(1 - distSq) ;
    decaynew *= lerp( (decaynew * decaynew), 1, 0.25);
    float3 colorhereB = i.Color_Radius.rgb * decaynew;

    return float4(colorHereA , 1) ; 
}
*/


/*
//================================================
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
*/
//  well this is actualy useless