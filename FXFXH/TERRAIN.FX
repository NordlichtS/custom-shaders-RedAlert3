//welcome to headache
/*
fxc.exe /O2 /T fx_2_0 /Fo   terrain.fxo   TERRAIN.FX
fxc.exe /T fx_2_0 /Fo   newterrain.fxo   TERRAIN.FX

*/


#define FORBID_PIPELINE_CONSTANT
#define FORBID_FACTION_COLOR
#define MAX_POINT_LIGHT 8 // 6?
#define IS_TERRAIN
#undef TERRAIN_USE_MULTIPLE_STREAM



//#include "head0-COMMON.FXH"  //hope it works
//no, too much differences
//lets declare everything all over again

string DefaultParameterScopeBlock = "material"; 
#define readonly const
#define texture2D texture
#define textureCUBE texture
#define SEMANTIC_3DSMAX(semantic)


int _SasGlobal : SasGlobal 
<   
    string UIWidget = "None"; 
    int3 SasVersion = int3(1, 0, 0); 
    int MaxLocalLights = 8; //6
>;

//SHARED CONSTANT WITH REGISTERS ==============================

shared float3 RecolorColorDummy //HAHA
: register(vs, c0) : register(ps, c0) 
<bool unmanaged = 1;> = {1,1,1};

shared float OpacityOverride 
: register(vs, c1) : register(ps, c1)
<   bool unmanaged = true;> = 1;

shared float3 TintColor 
: register(vs, c2) : register(ps, c2)
<   string SasBindAddress = "TintColor"; bool unmanaged = true;> = float3(1, 1, 1);

shared float3 NoCloudMultiplier  
: register(vs, c3) : register(ps, c3)
<   bool unmanaged = true;> = 1;

shared float3 AmbientLightColor 
: register(vs, c4) : register(ps, c4)
<   bool unmanaged = true;> = float3(0.25, 0.25, 0.25);

// C5-C10
shared struct{ float3 Color; float3 Direction;} 
DirectionalLight[3] 
: register(vs, c5) : register(ps, c5) 
<   bool unmanaged = 1;> = { 
1.0, 1.0, 1.0,   0, 0, 1, 
0.4, 0.5, 0.6,   0, 1, 0, 
0.3, 0.2, 0.1,   1, 0, 0 };

//
struct ShroudSetup {float4 ScaleUV_OffsetUV;} Shroud //
: register(vs, c11)  //only VS !
< string SasBindAddress = "Terrain.Shroud";> 
= { 1, 1, 0, 0 };

//
float4 Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize 
: register(ps, c11)  //only PS !
< string SasBindAddress = "Sas.Shadow[0].Zero_Zero_OneOverMapSize_OneOverMapSize";>
= float4(0,0,1,1) /1024   ;

// 2X8 FLOAT4 , C89-C112
shared struct PointLightSetup {float3 Color; float3 Position; float2 Range_Inner_Outer;} 
PointLight[8] 
: register(c89)
<    bool unmanaged = true;>;

//  C113-116
shared column_major float4x4 ShadowMapWorldToShadow 
: register(c113)
<    bool unmanaged = true;>;

// C117-118
shared struct CloudSetup {float4 WorldPositionMultiplier_XYZZ; float2 CurrentOffsetUV;} Cloud 
: register(c117) 
<    bool unmanaged = true;>;

//C119-122
shared column_major float4x4 ViewProjection : ViewProjection 
: register(c119)
<    bool unmanaged = true;>;

//
shared float3 EyePosition 
: register(c123)
<    bool unmanaged = true;>;

//C124-C127  //TERRAIN DOESNT HAVE THIS ?
shared column_major float4x3 World : World 
: register(c124);

//C128-C255
float4 WorldBones[128] //shared  ? 
: register(vs, c128)
<    bool unmanaged = true;>; 

// other extern variables ========================================

//
int NumPointLights //: register(vs, i0) : register(ps, i0)
<   string UIWidget="None"; string SasBindAddress = "Sas.NumPointLights";> = 1 ; //预览一个

//
float Time : Time;

//
float2 MapCellSize
< string SasBindAddress = "Terrain.Map.CellSize";> = { 10, 10 };

//
bool HasShadow 
< string SasBindAddress = "Sas.HasShadow";> = 0 ;

//terrain specific
bool IsTerrainAtlasEnabled 
< string SasBindAddress = "Terrain.IsTerrainAtlasEnabled";>;

//textures and samplers =======================================================

texture MacroSampler 
<   string SasBindAddress = "Terrain.MacroTexture"; 
    string ResourceName = "ShaderPreviewMacro.dds";
>; 
sampler2D MacroSamplerSampler //: register(ps_3_0, s0) 
<   string Texture = "MacroSampler"; 
    string SasBindAddress = "Terrain.MacroTexture"; 
    string ResourceName = "ShaderPreviewMacro.dds";
> = sampler_state
{
    Texture = <MacroSampler>; 
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 2;
    AddressU = 1;
    AddressV = 1;
};

texture ShroudSampler 
<   string SasBindAddress = "Terrain.Shroud.Texture";>; 
sampler2D ShroudSamplerSampler //: register(ps_3_0, s3) 
<   string Texture = "ShroudSampler"; 
    string SasBindAddress = "Terrain.Shroud.Texture";
> = sampler_state
{
    Texture = <ShroudSampler>; 
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 1;
    AddressU = 3;
    AddressV = 3;
};

texture CloudSampler 
<   string SasBindAddress = "Terrain.Cloud.Texture"; 
    string ResourceName = "ShaderPreviewCloud.dds";
>; 
sampler2D CloudSamplerSampler // : register(ps_3_0, s4) 
<   string Texture = "CloudSampler"; 
    string SasBindAddress = "Terrain.Cloud.Texture"; 
    string ResourceName = "ShaderPreviewCloud.dds";
> = sampler_state
{
    Texture = <CloudSampler>; 
    MinFilter = 2;
    MagFilter = 2;
    MipFilter = 1;
    AddressU = 1;
    AddressV = 1;
};

texture ShadowMap 
<   string SasBindAddress = "Sas.Shadow[0].ShadowMap";>; 
sampler2D ShadowMapSampler // : register(ps_3_0, s5) 
<   string Texture = "ShadowMap";  
    string SasBindAddress = "Sas.Shadow[0].ShadowMap";
> = sampler_state
{
    Texture = <ShadowMap>;  //changed filter, 1 point  2 linear 3 aniso 6 PyramidQuad 7 GaussianQuad
    MinFilter = 1;
    MagFilter = 1;
    MipFilter = 0;
    AddressU = 3;
    AddressV = 3;
};  //ADDRESSUV: 1=WRAP 2=MIRROR 3=CLAMP 4=BORDER 5


// terrain textures =======================

texture BaseSamplerClamped 
<   string SasBindAddress = "Terrain.BaseTexture"; 
    int WW3DDynamicSet = 2;
>; 
sampler2D BaseSamplerClampedSampler 
<   string Texture = "BaseSamplerClamped"; 
    string SasBindAddress = "Terrain.BaseTexture"; 
    int WW3DDynamicSet = 2;
> = sampler_state
{
    Texture = <BaseSamplerClamped>; 
    MinFilter = 3;//3
    MagFilter = 2;
    MipFilter = 2;
    MaxAnisotropy = 4;
    AddressU = 3;
    AddressV = 3;
};


texture BaseSamplerWrapped 
<   string SasBindAddress = "Terrain.BaseTexture"; 
    int WW3DDynamicSet = 2;
>; 
sampler2D BaseSamplerWrappedSampler 
<   string Texture = "BaseSamplerWrapped"; 
    string SasBindAddress = "Terrain.BaseTexture"; 
    int WW3DDynamicSet = 2;
> = sampler_state
{
    Texture = <BaseSamplerWrapped>; 
    MinFilter = 3; //3
    MagFilter = 2;
    MipFilter = 2;
    MaxAnisotropy = 4;
    AddressU = 1;
    AddressV = 1;
};


texture NormalSamplerClamped 
<   string SasBindAddress = "Terrain.NormalTexture"; 
    int WW3DDynamicSet = 2;
>; 
sampler2D NormalSamplerClampedSampler 
<   string Texture = "NormalSamplerClamped"; 
    string SasBindAddress = "Terrain.NormalTexture"; 
    int WW3DDynamicSet = 2;
> = sampler_state
{
    Texture = <NormalSamplerClamped>; 
    MinFilter = 2; //3
    MagFilter = 2;
    MipFilter = 2;
    MaxAnisotropy = 4;
    AddressU = 3;
    AddressV = 3;
};

texture NormalSamplerWrapped 
<   string SasBindAddress = "Terrain.NormalTexture"; 
    int WW3DDynamicSet = 2;
>; 
sampler2D NormalSamplerWrappedSampler 
<   string Texture = "NormalSamplerWrapped"; 
    string SasBindAddress = "Terrain.NormalTexture"; 
    int WW3DDynamicSet = 2;
> = sampler_state
{
    Texture = <NormalSamplerWrapped>; 
    MinFilter = 2; //3
    MagFilter = 2;
    MipFilter = 2;
    MaxAnisotropy = 4;
    AddressU = 1;
    AddressV = 1;
};


//=================================================
//end global variables, start helper functions
//=================================================


//  The Blendweight is the alpha value at the corner
// 
//	0-----3
//  |     |
//  |     |
//	|     |
//  1-----2

// Since the values is normalize to be > 0, we need to add 1 so -1 become 0 in the lookup table
static const float4 BLENDWEIGHT_LUT[2][13] =
{
	// Normal
	{
		{  1,  1,  1,  1 },	// BLENDTYPE_NONE							
		{  1,  1,  2,  2 },	// BLENDTYPE_HORIZONTAL,
		{  2,  2,  1,  1 },	// BLENDTYPE_HORIZONTAL_INVERTED,
		{  2,  1,  1,  2 },	// BLENDTYPE_VERTICAL,
		{  1,  2,  2,  1 },	// BLENDTYPE_VERTICAL_INVERTED,
		{  1,  0,  1,  2 },	// BLENDTYPE_RIGHTDIAGONAL,
		{  0,  1,  2,  1 },	// BLENDTYPE_RIGHTDIAGONAL_INVERTED,
		{  2,  1,  2,  3 },	// BLENDTYPE_RIGHTDIAGONAL_LONG,
		{  1,  2,  3,  2 },	// BLENDTYPE_RIGHTDIAGONAL_LONG_INVERTED,
		{  2,  1,  0,  1 },	// BLENDTYPE_LEFTDIAGONAL,
		{  1,  2,  1,  0 },	// BLENDTYPE_LEFTDIAGONAL_INVERTED,
		{  3,  2,  1,  2 },	// BLENDTYPE_LEFTDIAGONAL_LONG,
		{  2,  3,  2,  1 },	// BLENDTYPE_LEFTDIAGONAL_LONG_INVERTED,
	},
	// Flipped (first column from Normal is moved to the last)
	{
		{  1,  1,  1,  1 },	// BLENDTYPE_NONE							
		{  1,  2,  2,  1 },	// BLENDTYPE_HORIZONTAL,
		{  2,  1,  1,  2 },	// BLENDTYPE_HORIZONTAL_INVERTED,
		{  1,  1,  2,  2 },	// BLENDTYPE_VERTICAL,
		{  2,  2,  1,  1 },	// BLENDTYPE_VERTICAL_INVERTED,
		{  0,  1,  2,  1 },	// BLENDTYPE_RIGHTDIAGONAL,
		{  1,  2,  1,  0 },	// BLENDTYPE_RIGHTDIAGONAL_INVERTED,
		{  1,  2,  3,  2 },	// BLENDTYPE_RIGHTDIAGONAL_LONG,
		{  2,  3,  2,  1 },	// BLENDTYPE_RIGHTDIAGONAL_LONG_INVERTED,
		{  1,  0,  1,  2 },	// BLENDTYPE_LEFTDIAGONAL,
		{  2,  1,  0,  1 },	// BLENDTYPE_LEFTDIAGONAL_INVERTED,
		{  2,  1,  2,  3 },	// BLENDTYPE_LEFTDIAGONAL_LONG,
		{  3,  2,  1,  2 },	// BLENDTYPE_LEFTDIAGONAL_LONG_INVERTED,
	}
};


// The vertex generated in the order is
// v3-----v2
//  |     |
//  |     |
//  |     |
// v0-----v1
//
// The 2 tri we are building is 0,1,3 and 3,1,2
// 0-----3  3-----2
// |   / |  |\    |
// |  /  |  |  \  |
// | /   |  |    \|
// 1-----2  0-----1
// Normal   Flipped
//
// The reference point for x,y is v0, the following table holds the adjustment of x and y depends on the index (0-3)
// For UV offset, the reference point is v3

static const float UVOSPC = 469 ; //UV_OFFSET_PER_CELL
static const float4 TERRAIN_CORNER_INDEX_OFFSET_LUT[2][4] =
{
//		float4(x, y, UV offset x (per cell), UV offset y (per cell) )
	// Normal
	{
		float4(	1, 0,      0,      0 ),
		float4(	0, 0,      0, UVOSPC ),
		float4(	0, 1, UVOSPC, UVOSPC ),
		float4(	1, 1, UVOSPC,      0 ),
	}
	, // Flipped
	{
		float4(	0, 0,      0,       0 ),
		float4(	0, 1, UVOSPC,       0 ),
		float4(	1, 1, UVOSPC, -UVOSPC ),
		float4(	1, 0,      0, -UVOSPC ),
	}
};


static const int RenderingMode_TerrainTile = 0;
static const int RenderingMode_Cliff = 1;
static const int RenderingMode_Road = 2;
static const int RenderingMode_Scorch = 3;
static const int RenderingMode_NumOf = 4;

/*
#if !HIZ_CULLING
#define SCORCHMARK_Z_BIAS -0.0002
#define ROAD_Z_BIAS -0.0004
#else
#define SCORCHMARK_Z_BIAS 0.0002
#define ROAD_Z_BIAS 0.0004
#endif
*/

// 
float2 getWarfogUV(float4 WorldPosition) 
{
    float2 temp = WorldPosition.xy + Shroud.ScaleUV_OffsetUV.zw ;
    temp *= Shroud.ScaleUV_OffsetUV.xy;
    return temp;
};
// 
float2 getCloudUV(float4 WorldPosition) 
{
    float4 multipliedCloudUV = WorldPosition.xyzz * Cloud.WorldPositionMultiplier_XYZZ;
    return multipliedCloudUV.xy - multipliedCloudUV.zw + Cloud.CurrentOffsetUV;
};
// this is not linear accurate ! obsolete
/*
float3 getShadowMapUV(float4 WorldPosition) 
{
    if(! HasShadow){return float3(0,0,-1);};
    float4 shadowMapCoordinates = mul(WorldPosition, ShadowMapWorldToShadow);
    shadowMapCoordinates.xyz /= shadowMapCoordinates.w;
    //shadowMapCoordinates.z -= 1.0/512 ; 
    return shadowMapCoordinates.xyz;
};
*/

float specdist(float ooa, float3 R, float3 L)
{
    float cosRL = dot(R,L) ;  //no need saturate
    float specdist = cosRL * ooa - ooa + 1 ;
    specdist = saturate(specdist);
    specdist = pow(specdist, 4) ; //smooth tail
    return specdist ;
};

float fresnel(float3 L, float3 V, float F0, int exponent)
{
    float lerpw = dot( L , -V ) * 0.5 + 0.5 ;
    lerpw = pow(lerpw, exponent); //8 ? 6?
    float fresnelLV = lerp(F0, 1, lerpw);
    return fresnelLV ;
};

float bilinearShadow(float3 ShadowMapUV)
{
    float2 SMUV = ShadowMapUV.xy ;
    float2 SM01T = float2(0, Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w);
    float2 UVlerpw = frac(SMUV.xy / SM01T.y);
    float objectdepth = ShadowMapUV.z - SM01T.y; //depth bias is ooms

    float4 fourSamples = float4(   //四个角的阴影图深度
            tex2D(ShadowMapSampler, (SMUV.xy + SM01T.xx)).x ,
            tex2D(ShadowMapSampler, (SMUV.xy + SM01T.xy)).x ,
            tex2D(ShadowMapSampler, (SMUV.xy + SM01T.yx)).x ,
            tex2D(ShadowMapSampler, (SMUV.xy + SM01T.yy)).x 
        );  // LU,LD,RU,RD (00,01,10,11) 
        bool4 fourTests = (fourSamples > objectdepth) ; 
        fourSamples = (float4)fourTests ;
        float2 bLR = lerp(fourSamples.xy , fourSamples.zw , UVlerpw.x);
        float  bUD = lerp(bLR.x   , bLR.y   , UVlerpw.y);
        float lightmid = (3.0 - 2 * bUD) * bUD * bUD ; //cubic hermit;
        return bUD ;
}

float3 fakeskybox(float3 vectype)
{
    float3 skybox1 = DirectionalLight[1].Color ;
    skybox1 *= dot(DirectionalLight[1].Direction, vectype) +1 ;
    float3 skybox2 = DirectionalLight[2].Color ;
    skybox2 *= dot(DirectionalLight[2].Direction, vectype) +1;
    //already double bright
    return (skybox1 + skybox2) /2 ; 
}

//=================================================
// end helper functions, begin vertex shader
//=================================================


struct VSOutputDefault
{
	float4 Position : POSITION; //clip space
	float4 Color_Accent_Blend : COLOR0; 
    float1 Color_Shroud : COLOR1 ;
 	float4 BaseTexCoord_BlendWeight : TEXCOORD0;
 	float4 BlendTex1Coord_BlendTex2Coord : TEXCOORD1;
    float4 ShroudCloudUV : TEXCOORD2;
	float4 ShadowMapClipSpace : TEXCOORD3 ; //
    float3 WorldP : TEXCOORD4 ;
	float3 WorldN : TEXCOORD5 ;
	float3 WorldT : TEXCOORD6 ;
	float3 WorldB : TEXCOORD7 ;
	//float4 MISC_shroud_shadow_fog_cliff : TEXCOORD10 ;
	//float4 MainLightDirection_Falloff : TEXCOORD4;
	//float3 MainHalfEyeLightDirection : TEXCOORD5; //_CENTROID;
    //RGBA shroud, shadow, macro, blend
	//float  Fog : COLOR1;
};

// other vs will depend on her
VSOutputDefault VS_Default(  
    //this is input array for vs
	float3 Position : POSITION, //already in world space
	float3 Normal : NORMAL,
	float4 Color : COLOR0, //only A needed
    float2 BaseTexCoord : TEXCOORD0,
	float3 Tangent : TANGENT,
	float3 Binormal : BINORMAL,
	uniform int renderingMode,
	uniform bool isTextureAtlasEnabled
)
{
	VSOutputDefault o;
	
    float4 worldPosition = float4(Position.xyz, 1) ; //HOMOGENIZED
	o.Position = mul(worldPosition, ViewProjection);

    float3 irradiance_color = fakeskybox(Normal) /2; 
    //irradiance_color *= (Normal.z +1)/2 ; 
    //irradiance_color += AmbientLightColor ;
    //moved to ps

    o.Color_Accent_Blend.rgb = irradiance_color ;
    o.Color_Accent_Blend.w = Color.w;

	o.WorldP = Position;
	o.WorldN = Normal;
	o.WorldT = 0 ;
	o.WorldB = 0 ;
	if(renderingMode == RenderingMode_Scorch)	{
		o.WorldT = Tangent;
		o.WorldB = Binormal;
	}	else	{
		o.WorldT = cross(Normal, float3(-1, 0, 0));
		o.WorldB = cross(Normal, float3( 0, 1, 0));
	};

    // Output texture information
    o.BaseTexCoord_BlendWeight.xy = BaseTexCoord;
	// Initialize terrain tile only data
    o.BaseTexCoord_BlendWeight.zw = float2(0, 0);
    o.BlendTex1Coord_BlendTex2Coord = float4(0, 0, 0, 0);

	o.ShroudCloudUV.xy = getWarfogUV(worldPosition);
    o.ShroudCloudUV.zw = getCloudUV(worldPosition);
    o.ShadowMapClipSpace = mul(worldPosition, ShadowMapWorldToShadow);
    //vertex shroud
    o.Color_Shroud = tex2Dlod(ShroudSamplerSampler, float4(o.ShroudCloudUV.xy, 0,0)).x;
    //vertex shadow, tbd
    //o.Color_Shroud_Shadow.y = 1 ;

	return o;
}

// now for the real thing


// ---------------------------------------------------------------------------
VSOutputDefault VS_TerrainTile(
	float4 Position_BlendWeight1 : POSITION, 
	float4 Normal_BlendWeight2 : NORMAL0,
    float2 BaseTexCoord : TEXCOORD0,
    float2 BlendTex1Coord : TEXCOORD1,
    float2 BlendTex2Coord : TEXCOORD2,
	float3 Tangent : TANGENT,
	float3 Binormal : BINORMAL,
	uniform bool isTextureAtlasEnabled
)
{
	VSOutputDefault Out;
	float3 Position	= Position_BlendWeight1.xyz;
	float3 Normal	= Normal_BlendWeight2.xyz;
    float BlendWeight1 = 0.0;
    float BlendWeight2 = 0.0;

	if (isTextureAtlasEnabled)		
	{		// Unpack vertex data
		Normal = (Normal_BlendWeight2.xyz / 100.0) - 1.0;

		BaseTexCoord   = (BaseTexCoord   / 30000.0);
		BlendTex1Coord = (BlendTex1Coord / 30000.0);
		BlendTex2Coord = (BlendTex2Coord / 30000.0);
	    BlendWeight1 = Position_BlendWeight1.w - 1.0;
	    BlendWeight2 = Normal_BlendWeight2.w - 1.0;
	}

	// Delegate main computations to VS-Default
	Out = VS_Default(
        Position, 
        Normal, 
        float4(1, 1, 1, 1), 
        BaseTexCoord, 
        Tangent, 
        Binormal, 
        RenderingMode_TerrainTile, 
        isTextureAtlasEnabled
    );
	
	if (isTextureAtlasEnabled)		
	{    	// Note: intentionally switch 1 and 2
    	Out.BaseTexCoord_BlendWeight.z  = BlendWeight2;
    	Out.BaseTexCoord_BlendWeight.w  = BlendWeight1;
    	Out.BlendTex1Coord_BlendTex2Coord.xy = BlendTex1Coord.xy;
    	Out.BlendTex1Coord_BlendTex2Coord.zw = BlendTex2Coord.yx;
	}
	
	return Out;
}


// ---------------------------------------------------------------------------
VSOutputDefault VS_TerrainScorch(
    float4 Position_BlendWeight1 : POSITION, 
    float4 Normal_unpack : NORMAL0,
    float4 Color : COLOR0, 
    float2 BaseTexCoord : TEXCOORD0,
    float4 Tangent_unpack : TANGENT,
    float4 Binormal_unpack : BINORMAL
)
{
    VSOutputDefault Out;
    float3 Position = Position_BlendWeight1.xyz;

	// Unpack vertex data
	float3 Normal = (Normal_unpack.xyz * 255 / 100.0) - 1.0;
	float3 Tangent = (Tangent_unpack.xyz * 255 / 100.0) - 1.0;
	float3 Binormal = (Tangent_unpack.xyz * 255 / 100.0) - 1.0;

    BaseTexCoord = (BaseTexCoord / 30000.0);

    // Delegate main computations to VS-Default
    return VS_Default(
        Position, 
        Normal, 
        Color, 
        BaseTexCoord, 
        Tangent, 
        Binormal, 
        RenderingMode_Scorch, 
        false
    );
}

//=========================================
// end vs, hopefully, start ps
//=========================================

float4 PS_Default(   //HIGH QUALITY PS ALL USE THIS
	VSOutputDefault i, 
    float2 vpos : VPOS ,
	uniform int renderingMode,
	uniform sampler2D baseSampler, 
	uniform sampler2D normalSampler,
	//uniform bool hasShadow, 
	uniform bool isTextureAtlasEnabled
) : COLOR 
{
    float2 BaseTexCoord = i.BaseTexCoord_BlendWeight.xy;
	float4 baseTextureValue = tex2D(baseSampler, BaseTexCoord);

    // Doing first and second blend
    float2 blendWeight = saturate(i.BaseTexCoord_BlendWeight.wz);

    if(renderingMode == RenderingMode_TerrainTile && isTextureAtlasEnabled)
    {
        float4 texColor1 = tex2D(baseSampler, i.BlendTex1Coord_BlendTex2Coord.xy);
        float4 texColor2 = tex2D(baseSampler, i.BlendTex1Coord_BlendTex2Coord.wz);
        baseTextureValue = lerp(baseTextureValue, texColor1, blendWeight[0]) ;
        baseTextureValue = lerp(baseTextureValue, texColor2, blendWeight[1]) ;
    }
    
	float3 baseColor = baseTextureValue.xyz ;
    baseColor *= baseColor ; //GAMMA

	float opacity = i.Color_Accent_Blend.w;

	if (renderingMode == RenderingMode_Road || renderingMode == RenderingMode_Scorch)
	{	opacity *= baseTextureValue.w;	}

	// Add normal mapping lighting with main light source
	float2 normalmap = 0;
	float specmap = 0;
	
	if (renderingMode == RenderingMode_Road || renderingMode == RenderingMode_Scorch)
	{
		float4 normal_specular = tex2D(normalSampler, BaseTexCoord);
		normalmap = normal_specular.xy * 2 - 1;

		if (renderingMode != RenderingMode_Scorch)
        {specmap = normal_specular.w;}
	}
	else
	{
		float3 normal_specular = tex2D(normalSampler, BaseTexCoord);

        if(renderingMode == RenderingMode_TerrainTile && isTextureAtlasEnabled)
        {
            float3 normal_specular1 = tex2D(normalSampler, i.BlendTex1Coord_BlendTex2Coord.xy);
            float3 normal_specular2 = tex2D(normalSampler, i.BlendTex1Coord_BlendTex2Coord.wz);
			specmap = baseTextureValue.w;
            normal_specular = lerp(normal_specular, normal_specular1, blendWeight[0]) ;
            normal_specular = lerp(normal_specular, normal_specular2, blendWeight[1]) ;
        }
		else
		{   specmap = normal_specular.z;	};

        normalmap = normal_specular.xy * 2 - 1;
	}
	
	//now we get our tangent to world matrix !!!
    float normalintensity = saturate(dot(normalmap, normalmap));
    normalmap *= -4 * normalintensity; //bumpscale
	float3 N = i.WorldN ; 
    N += normalmap.x * i.WorldB + normalmap.y * i.WorldT ;
	N = normalize(N);

    float3 V = normalize(EyePosition - i.WorldP);
    float3 R = reflect( -V, N);

    float3 diffcolor = baseColor.rgb ;
    float3 speccolor = specmap.xxx ; //also spec peak color

    float glossiness = specmap *5 +1 ; //min roughness 1/6
    float ooa = glossiness * glossiness ;
    float fresnelf0 = 1- dot(baseTextureValue.xyz, 0.3) ;

    float specAO = saturate(dot(R, i.WorldN) +1) ;
    float diffAO = N.z *0.5 + 0.5 ; //1- normalintensity;

    //ambient BRDF
    float3 skybox_color = i.Color_Accent_Blend.rgb ; //fakeskybox(R) /2; 
    float3 irradi_color = i.Color_Accent_Blend.rgb + AmbientLightColor;

    float env_f_term = pow(saturate(1- dot(V,N)) , 4) ;

    float3 ambientALL = 0 ; 
    ambientALL += irradi_color * diffcolor * diffAO ; 
    ambientALL += skybox_color * speccolor * specAO * env_f_term; 


    //sun BRDF
	float3 sunColor = DirectionalLight[0].Color;
	float3 sunDir = DirectionalLight[0].Direction ;

	float suntilt = dot(sunDir, N); //no saturate yet
    float sunspecdist = specdist(ooa, R, sunDir) ;

	float shadowterm = (suntilt > 0)? 1 : 0 ;
	if (HasShadow) // not the uniform bool hasShadow
    {   
        float3 ShadowMapUV = i.ShadowMapClipSpace.xyz / i.ShadowMapClipSpace.w;
        bool2 dither = frac(vpos /2) < 0.3 ;
        float2 smbias = float2(0, Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w);
        smbias = (dither.x)? smbias.xy : smbias.yx ; //x to flip axis
        smbias = (dither.y)? smbias    : - smbias  ; //y to flip direction     
        ShadowMapUV.xy += smbias  ;
        shadowterm *= bilinearShadow(ShadowMapUV); 
    }
    //tbd: modify shadowterm with vertex shadow? better not
	sunColor *= shadowterm ;

    float3 cloudColor = tex2D(CloudSamplerSampler, i.ShroudCloudUV.zw) ;
    sunColor *= cloudColor * cloudColor;

    float3 sunALL = float3(0,0,0) ;  
    sunALL += diffcolor * suntilt ; 
    sunALL += speccolor * sunspecdist * fresnel(sunDir, V, fresnelf0, 4);
    sunALL *= sunColor ; //* shadowterm * cloudColor; 


	// Compute point lights
    float3 plALL = 0;
	for (int itpl = 0; itpl < NumPointLights; itpl++) //min(NumPointLights, 8)
	{
        float3 PLpos = PointLight[itpl].Position - i.WorldP ;
        float3 PLcolor = PointLight[itpl].Color ;
        float  PLrangeMAX = PointLight[itpl].Range_Inner_Outer.y  ;
        float  PLrangeMIN = PointLight[itpl].Range_Inner_Outer.x  ;

        if(PLrangeMAX < 1) {continue;}; //排除无用的点光源
        float  PLdist = length(PLpos) ;
        if(PLdist > PLrangeMAX) {PLcolor = 0;}; //排除太远的点光源
        float3 PLL = PLpos / PLdist ; //normalized light vector
        float  PLtilt = dot(PLL, N) ;
        if(PLtilt < 0) {PLcolor = 0;}; //排除背光面

        float decay = (PLdist - PLrangeMAX) / (PLrangeMIN - PLrangeMAX) ;
        decay = saturate(decay);
        decay *= decay ;
        float PLfresnel = fresnel(PLL, V, fresnelf0, 2) ;

        float3 thisBRDF = float3(0,0,0) ;
        thisBRDF += diffcolor * PLtilt  ; 
        thisBRDF += (speccolor + 0.25) * specdist(ooa, R, PLL) * PLfresnel ;
        thisBRDF *= PLcolor * decay;

		plALL += thisBRDF;
	}
    plALL *= 2 ;

    //float shroudColor = i.Color_Shroud ;
    ////RGBA shroud, shadow, macro, blend  //no more

    float3 OUTCOLOR = ambientALL + sunALL  ;
    OUTCOLOR *= i.Color_Shroud ;

    if(1)  //(renderingMode != RenderingMode_Scorch)
    {OUTCOLOR += plALL ;};
    
	
	return float4(OUTCOLOR, opacity);
}

//======================================
//finally PS end, begin technique (high quality)
//======================================

/*
WE ALREADY HAVE:

VS_Default
VS_TerrainTile
VS_TerrainScorch

PS_Default

*/

technique TerrainTile
{	pass P0
	{
		VertexShader = compile vs_3_0 VS_TerrainTile(true);
		PixelShader  = compile ps_3_0 PS_Default(RenderingMode_TerrainTile, 
            BaseSamplerClampedSampler, 
            NormalSamplerClampedSampler,
            true
        );
		ZEnable = true;
		ZWriteEnable = true;
		ZFunc = 4;
		CullMode = 2;
		AlphaTestEnable = false;
		AlphaBlendEnable = false;
	}
}

technique Cliff
{    pass P0
    {
        VertexShader = compile vs_3_0 VS_Default(RenderingMode_Cliff, false);
		PixelShader  = compile ps_3_0 PS_Default(RenderingMode_Cliff, 
            BaseSamplerWrappedSampler, 
            NormalSamplerWrappedSampler,
            false
        );
        ZEnable = 1;
        ZWriteEnable = 0;
        ZFunc = 4; //#define ZFUNC_INFRONT LessEqual
        CullMode = 2; //CW
        AlphaTestEnable = 0;
        AlphaBlendEnable = 1;
		SrcBlend = 5; //SrcAlpha
		DestBlend = 6; //InvSrcAlpha
    }
}

technique Road
{   pass P0
    {
        VertexShader = compile vs_3_0 VS_Default(RenderingMode_Road, false);
		PixelShader  = compile ps_3_0 PS_Default(RenderingMode_Road, 
            BaseSamplerWrappedSampler, 
            NormalSamplerWrappedSampler,
            false
        );
        ZEnable = 1;
        ZWriteEnable = 0;
        ZFunc = 4;
        CullMode = 2;
        AlphaTestEnable = 0;
        AlphaBlendEnable = 1;
        SrcBlend = 5;
        DestBlend = 6;
        DepthBias = -1.0f / 2048; // -0.0004 = -1 / 2500
    }
}

technique Scorch
{   pass P0
    {
        VertexShader = compile vs_3_0 VS_TerrainScorch();
		PixelShader  = compile ps_3_0 PS_Default(RenderingMode_Scorch, 
            BaseSamplerClampedSampler, 
            NormalSamplerClampedSampler,
            false
        );
        ZEnable = 1;
        ZWriteEnable = 0;
        ZFunc = 4;
        CullMode = 2;
        AlphaTestEnable = 0;
        AlphaBlendEnable = 1;
        SrcBlend = 5;
        DestBlend = 6;
        DepthBias = -1.0f / 4096; //-0.0002
    }
}

//===============================
// low quality PS and technique. vs are the same
//===============================



float4 PS_DefaultLOW(   //LOW QUALITY PS . 
	VSOutputDefault i, 
    float2 vpos : VPOS ,
	uniform int renderingMode,
	uniform sampler2D baseSampler, 
	uniform sampler2D normalSampler,
	//uniform bool hasShadow, 
	uniform bool isTextureAtlasEnabled
) : COLOR 
{
    float2 BaseTexCoord = i.BaseTexCoord_BlendWeight.xy;
	float4 baseTextureValue = tex2D(baseSampler, BaseTexCoord);

    // Doing first and second blend
    float2 blendWeight = saturate(i.BaseTexCoord_BlendWeight.wz);

    if(renderingMode == RenderingMode_TerrainTile && isTextureAtlasEnabled)
    {
        float4 texColor1 = tex2D(baseSampler, i.BlendTex1Coord_BlendTex2Coord.xy);
        float4 texColor2 = tex2D(baseSampler, i.BlendTex1Coord_BlendTex2Coord.wz);
        baseTextureValue = lerp(baseTextureValue, texColor1, blendWeight[0]) ;
        baseTextureValue = lerp(baseTextureValue, texColor2, blendWeight[1]) ;
    }
    
	float3 baseColor = baseTextureValue.xyz ; //no gamma
	float opacity = i.Color_Accent_Blend.w;

	if (renderingMode == RenderingMode_Road || renderingMode == RenderingMode_Scorch)
	{	opacity *= baseTextureValue.w;	}

	//no normalmap
	float3 N = normalize(i.WorldN) ; 

    float3 diffcolor = baseColor.rgb ;

    //ambient BRDF

    float3 irradi_color = i.Color_Accent_Blend.rgb ;
    irradi_color *= N.z *0.5 + 0.5 ;
    irradi_color += AmbientLightColor ;

    float3 ambientALL = 0 ; 
    ambientALL += irradi_color * diffcolor  ; 

    //sun BRDF
	float3 sunColor = DirectionalLight[0].Color;
	float3 sunDir = DirectionalLight[0].Direction ;

	float suntilt = dot(sunDir, N); //no saturate yet
    float diffterm = 1- pow( (1- suntilt) , 2 );

	float shadowterm = (suntilt > 0)? 1 : 0 ; //replace saturate
	if (HasShadow) // not the uniform bool hasShadow
    {   
        float3 ShadowMapUV = i.ShadowMapClipSpace.xyz / i.ShadowMapClipSpace.w;
        shadowterm *= bilinearShadow(ShadowMapUV); 
        shadowterm = saturate(shadowterm *3 -1) ;
    }
	sunColor *= shadowterm ;

    float3 cloudColor = NoCloudMultiplier ;//also no cloud
    sunColor *= cloudColor;//no gamma

    float3 sunALL = float3(0,0,0) ;  
    sunALL += diffcolor * diffterm ; 
    sunALL *= sunColor ; //* shadowterm * cloudColor; 

    float3 OUTCOLOR = ambientALL + sunALL  ;
    OUTCOLOR *= i.Color_Shroud ;

	return float4(OUTCOLOR, opacity);
}
//end low ps, begin low technique


technique TerrainTile_M
{	pass P0
	{
		VertexShader = compile vs_3_0 VS_TerrainTile(true);
		PixelShader  = compile ps_3_0 PS_DefaultLOW(RenderingMode_TerrainTile, 
            BaseSamplerClampedSampler, 
            NormalSamplerClampedSampler,
            true
        );
		ZEnable = true;
		ZWriteEnable = true;
		ZFunc = 4;
		CullMode = 2;
		AlphaTestEnable = false;
		AlphaBlendEnable = false;
	}
}

technique Cliff_M
{    pass P0
    {
        VertexShader = compile vs_3_0 VS_Default(RenderingMode_Cliff, false);
		PixelShader  = compile ps_3_0 PS_DefaultLOW(RenderingMode_Cliff, 
            BaseSamplerWrappedSampler, 
            NormalSamplerWrappedSampler,
            false
        );
        ZEnable = 1;
        ZWriteEnable = 0;
        ZFunc = 4; //#define ZFUNC_INFRONT LessEqual
        CullMode = 2; //CW
        AlphaTestEnable = 0;
        AlphaBlendEnable = 1;
		SrcBlend = 5; //SrcAlpha
		DestBlend = 6; //InvSrcAlpha
    }
}

technique Road_M
{   pass P0
    {
        VertexShader = compile vs_3_0 VS_Default(RenderingMode_Road, false);
		PixelShader  = compile ps_3_0 PS_DefaultLOW(RenderingMode_Road, 
            BaseSamplerWrappedSampler, 
            NormalSamplerWrappedSampler,
            false
        );
        ZEnable = 1;
        ZWriteEnable = 0;
        ZFunc = 4;
        CullMode = 2;
        AlphaTestEnable = 0;
        AlphaBlendEnable = 1;
        SrcBlend = 5;
        DestBlend = 6;
        DepthBias = -1.0f / 2048; // -0.0004 = -1 / 2500
    }
}

technique Scorch_M
{   pass P0
    {
        VertexShader = compile vs_3_0 VS_TerrainScorch();
		PixelShader  = compile ps_3_0 PS_DefaultLOW(RenderingMode_Scorch, 
            BaseSamplerClampedSampler, 
            NormalSamplerClampedSampler,
            false
        );
        ZEnable = 1;
        ZWriteEnable = 0;
        ZFunc = 4;
        CullMode = 2;
        AlphaTestEnable = 0;
        AlphaBlendEnable = 1;
        SrcBlend = 5;
        DestBlend = 6;
        DepthBias = -1.0f / 4096; //-0.0002
    }
}


//===============================
//special technique about shadow and depth 
//so you have differed rendering pipeline?
//===============================

struct VSOutput_CreateShadowMap
{
	float4 Position : POSITION;
	float4 ClipSpace : TEXCOORD0;
};
VSOutput_CreateShadowMap VS_CreateShadowMap(float4 Position : POSITION)
{
	VSOutput_CreateShadowMap Out;
	Out.Position = mul(float4(Position.xyz, 1), ViewProjection);
    Out.ClipSpace = Out.Position ;
	//Out.Depth = Out.Position.z / Out.Position.w;
	return Out;
}
float4 PS_CreateShadowMap(VSOutput_CreateShadowMap In) : COLOR
{
	return (In.ClipSpace.z / In.ClipSpace.w) ;
}
//this is now linear correct
//matrix mult is always linear operation, but division is not


technique _CreateShadowMap
{    pass P0
    {
        VertexShader = compile vs_2_0 VS_CreateShadowMap(); 
        PixelShader  = compile ps_2_0 PS_CreateShadowMap(); 
        ZEnable = 1;
        ZWriteEnable = 1;
        ZFunc = 4;
        CullMode = 2;
        AlphaTestEnable = 0;
        AlphaBlendEnable = 0;
    }
}

technique _CreateDepthMap
{    pass P0
    {
        VertexShader = compile vs_2_0 VS_CreateShadowMap(); 
        PixelShader  = compile ps_2_0 PS_CreateShadowMap(); 
        ZEnable = 1;
        ZWriteEnable = 1;
        ZFunc = 4;
        CullMode = 2;
        AlphaTestEnable = 0;
        AlphaBlendEnable = 0;
    }
}

