// #define _3DSMAX_
// #define IGNORE_NRM
// #define FORBID_PIPELINE_CONSTANT
// dont change any above

// #define SPMG_GLOWPULSE
//#pragma warning(disable: 3206)

/*
fxc.exe /O2 /T fx_2_0 /Fo   buildingsunderground.fxo   PBR5-9-underground.FX
fxc.exe /O1 /T fx_2_0 /Fo   buildingsundergroundMAX.fxo   PBR5-9-underground.FX

*/


float WellRadius //井口半径，其实是最小外接圆
<   string UIName = "WellRadius"; 
    float UIMax = 512; float UIMin = 1; float UIStep = 1; 
> = 32 ;

float MicroShadowBias //
<   string UIName = "MicroShadowBias(1/2048)"; 
    float UIMax = 9; float UIMin = -9; float UIStep = 1; 
> = 0 ;

/*
float SqueezFactor //地下部分深度 除以地上部分高度
<   string UIName = "SqueezFactor"; 
    float UIMax = 4096; float UIMin = 1; float UIStep = 1; 
> = 128 ;
*/

float GlowAmplitude //最大发光倍数，(如果写负数会怎样?)
<   string UIName = "GlowAmplitude"; 
    float UIMax = 8; float UIMin = -8; float UIStep = 0.25; 
> = 0 ; 


//1/512 = 0.0019，original = 0.0015

#include "head2-functions.FXH" //WILL INCLUDE EVERYTHING before vsps.FXH


struct VS_to_PS_H_UNDERGROUND
{
    float4 Position : POSITION;   //VS一定要输出的clip space渲染坐标
    //float2 vpos : VPOS ; //screen pixel 
    //float4 VertexColor : COLOR0;  //顶点颜色
    float2 MainTexUV  : TEXCOORD0; //XY是主帖图UV
    float4 ShadowCS : TEXCOORD1; //XYZ阴影空间投影, W弃用
    float4 FogCloudUV : TEXCOORD2; //迷雾和云的UV
    float3 WorldP : TEXCOORD3;  //世界空间位置
    float3 WorldN : TEXCOORD4; //世界法线Z
    float3 WorldT : TEXCOORD5; //世界切线Y
    float3 WorldB : TEXCOORD6; //世界切线X
    float4 HorizonRelative_eyeXY_sunXY : TEXCOORD7; // 世界空间里相对于中心的坐标，包括视觉和投影

};

struct VS_tmp_input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 tangent : TANGENT;
    float4 binormal : BINORMAL;
    float4 texcoord : TEXCOORD; float4 texcoordNEW : TEXCOORD1 ;
    //float4 color : COLOR;
};

VS_to_PS_H_UNDERGROUND  VS_H_UNDERGROUND (VS_tmp_input  i)  //no bone skin
{
    VS_to_PS_H_UNDERGROUND o; //声明下输出数组的结构缩写

    //o.ShadowPROJ = o.FogCloudUV = 0 ;
    //o.VertexColor = i.color ;  
    o.MainTexUV = i.texcoord.xy ; 

    float3 worldoffset = World._m30_m31_m32  ; //mul(float4(0,0,0,1) , World);
    float3x3 worldrotation = (float3x3)World ;
    float3 Lsun = DirectionalLight[0].Direction.xyz ;
    float3 camera_in_world = EyePosition ;
  #ifdef _3DSMAX_
    worldoffset = mul(float4(0,0,0,1) , MAXworld).xyz;
    worldrotation = (float3x3)MAXworld ;//float3x3(1,0,0, 0,1,0, 0,0,1) ; //
    Lsun = PV_SunlightDirection ;
    camera_in_world = ViewI[3].xyz ;
  #endif

    o.WorldP = mul(i.position.xyz, worldrotation) + worldoffset ; //世界坐标，用这个squeez
    o.WorldN = mul(i.normal.xyz, worldrotation);
    o.WorldT = mul(i.tangent.xyz, worldrotation);
    o.WorldB = mul(i.binormal.xyz, worldrotation);
    //已经到世界空间了

    float3 squeez2SUN = intersectOnHorizon( o.WorldP,(o.WorldP +Lsun), worldoffset.z) ;
    float3 squeez2EYE = intersectOnHorizon( o.WorldP, camera_in_world, worldoffset.z) ;
    squeez2EYE = lerp(squeez2EYE, o.WorldP, 1.0 / 256 ) ;
    //这两个都是在世界空间里的魔法
    o.ShadowPROJ = getShadowMapUV( float4(squeez2SUN, 1)) ;
    o.FogCloudUV.xy = getWarfogUV( float4(o.WorldP, 1)) ;
    o.FogCloudUV.zw = getCloudUV ( float4(o.WorldP, 1)) ;

    o.HorizonRelative_eyeXY_sunXY = float4(squeez2EYE.xy, squeez2SUN.xy) - worldoffset.xyxy;
    o.Position = mul(float4(squeez2EYE, 1), ViewProjection); //给rasterizer的clip space坐标
  #ifdef _3DSMAX_
    o.Position = mul( mul(float4(squeez2EYE, 1), MAXView) , MAXProjection );
  #endif

    return o;
};


float4 PS_H_UNDERGROUND (VS_to_PS_H_UNDERGROUND i) : COLOR 
{
    float3 worldoffset = World._m30_m31_m32  ; 
  #ifdef _3DSMAX_
    worldoffset = mul(float4(0,0,0,1) , MAXworld).xyz;
  #endif
    float wellradius_square = WellRadius * WellRadius ;
    float distsquareEYE = dot(i.HorizonRelative_eyeXY_sunXY.xy, i.HorizonRelative_eyeXY_sunXY.xy) ;
    float distsquareSUN = dot(i.HorizonRelative_eyeXY_sunXY.zw, i.HorizonRelative_eyeXY_sunXY.zw) ; 
    clip( wellradius_square - distsquareEYE ); //well rad small -> negative -> clip
    bool welledgeNoSunlight = bool(distsquareSUN > wellradius_square) ;

    float4 OUTCOLOR = float4(0,0,0,1); //安全起见先initialize

  //拿出主贴图 (GEN 2 MOD )
    float4 dif = tex2D(DiffuseTextureSampler,  i.MainTexUV.xy );
    float4 nrm = tex2D(NormalMapSampler,       i.MainTexUV.xy );
    float4 spm = tex2D(SpecMapSampler,         i.MainTexUV.xy );

  //有用的向量
    float3 N = float3(0,0,1); 
    N.xy = (nrm.xy * 2 - 1 )  ;
    N.xy *= - BumpScale ;
    float3x3 TangentSpaceToWorldMatrix = float3x3(i.WorldB, i.WorldT, i.WorldN) ; //T B exchanged!
    N = mul(N, TangentSpaceToWorldMatrix) ;
    N = normalize(N); //长度单位化，这一步很重要

    float3 V = hp_ps_getViewVector(i.WorldP) ;
    float3 R = reflect(-V , N) ; //input light vector is towards fragment!
    float  EYEtilt = dot(V , N) ;
    R = (EYEtilt <0) ? -V : R ;

    float3 Lsun     = DirectionalLight[0].Direction.xyz ;
    float3 SUNcolor = DirectionalLight[0].Color.xyz ;
  #ifdef _3DSMAX_  //MAX预览阳光方向与颜色覆盖
    Lsun     = PV_SunlightDirection ; 
    SUNcolor = PV_SunlightColor ;
  #endif

  //整理通道
    float3 realHC = (HasRecolorColors)? RecolorColor : 1 ;
    dif.xyz *= lerp(dif.xyz , realHC , spm.b); //gamma without hc

    float glossiness = spm.r * 8 + 1  ; //
    float specbase_mult = 0.125 ;
    float  AOchannel = nrm.w ;
    //float horizon_extra_sharp = 0.5 ;

    float3 diffcolor = dif.xyz ;
    float3 speccolor = 1 ;
    float f0_dir = spm.r ;
    float f0_env = 0 ;

    float  GLOWchannel = (GlowAmplitude > 0)? spm.w : ( 1- spm.w) ;
    float3 glowmapRGB = RecolorColor ;
    glowmapRGB *= GLOWchannel * abs(GlowAmplitude) ;
    float GlowAmplitude = Time + i.MainTexUV.y ;
    GlowAmplitude = frac(GlowAmplitude) * 2 -1 ;
    glowmapRGB *= pow(GlowAmplitude, 4); 

  //环境光相关 
    const float ambient_diff_mult =  0.5 ; //环境光与天空盒diffuse
    const float ambient_spec_mult =  1 ; //环境光与天空盒specular
    float3 skycolor = DirectionalLight[1].Color.xyz + DirectionalLight[2].Color.xyz ;
    float3 irradi_color = hp_fake_irradiance(0, skycolor , N.z) + AmbientLightColor;
    float3 skybox_color = hp_fake_skybox(0 , skycolor , R.z , glossiness ) ; 

    float env_f_term = hp_fresnel(R, V, f0_env, 6);  
 
    float3 ambientALL = float3(0,0,0) ; //环境光BRDF
    //ambient DIFF
    ambientALL += irradi_color * diffcolor * ambient_diff_mult * AOchannel ; 
    //ambient SPEC
    ambientALL += skybox_color * speccolor * ambient_spec_mult * env_f_term * spm.r ; 

  //阳光相关
    float  sun_tilt  = dot(N,Lsun) ;
    SUNcolor *= hp_invshadow_underground ( i.ShadowPROJ , sun_tilt, (MicroShadowBias /2048) , welledgeNoSunlight ) ;

  #ifndef _3DSMAX_ //高画质都有云，但预览没有
    float3 cloudcolor = tex2D(CloudTextureSampler, i.FogCloudUV.zw);
    SUNcolor *= cloudcolor * cloudcolor ;
  #endif

    float3 sunALL = float3(0,0,0) ;  //阳光BRDF
    //sun diff
    sunALL += diffcolor * sun_tilt ; //* diffuse_mult ;
    //sun spec
    sunALL += speccolor * hp_specdist(glossiness, R, Lsun) * specbase_mult * hp_fresnel(Lsun, V, f0_dir, 4);
    sunALL *= SUNcolor ; //*= sunlight_mult ;

  //点光源BRDF
    float3 PLtotal = float3(0,0,0) ;
    for (int itpl = 0; itpl < min(8, NumPointLights); itpl++ ) 
    {

      float3 PLpos = PointLight[itpl].Position - i.WorldP ;
      float3 PLcolor = PointLight[itpl].Color ;
      float  PLrangeMAX = PointLight[itpl].Range_Inner_Outer.y *2 ;
      float  PLrangeMIN = PointLight[itpl].Range_Inner_Outer.x  ;

    #ifdef _3DSMAX_ //读取预览点光源数据
      PLpos = PV_pointlightPOS - i.WorldP; // relative!
      PLcolor = PV_pointlightCOLOR ; 
      PLrangeMAX = PV_pointlightRANGE ;
      PLrangeMIN = 0 ;
    #endif

      //我要不要排除掉井口外缘的点光源？不管了暂时

      if(PLrangeMAX < 1) {continue;}; //排除无用的点光源
      float  PLdist = length(PLpos) ;
      if(PLdist > PLrangeMAX) {continue;}; //排除太远的点光源
      float3 PLL = PLpos / PLdist ; //normalized light vector
      float  PLtilt = dot(PLL, N) ;
      if(PLtilt < 0) {continue;}; //排除背光面

      float3 thisBRDF = float3(0,0,0) ;
      //pl diff
      thisBRDF += diffcolor * PLtilt  ; 
      //pl spec  
      thisBRDF += speccolor * hp_specdist(glossiness, R, PLL) * specbase_mult ;//* hp_fresnel(PLL, V, f0_dir, 2) ;
      //pl colo
      thisBRDF *= PLcolor * PLdecayfactor(PLrangeMIN, PLrangeMAX, PLdist);

      PLtotal += thisBRDF ; //叠加所有点光源
    };

  //最终混色
    OUTCOLOR.xyz += ambientALL + sunALL ; //BRDF
    OUTCOLOR.xyz *= TintColor ;
    OUTCOLOR.xyz += PLtotal ; //thus pl unaffected
    OUTCOLOR.xyz += glowmapRGB ; //原版可能要删了这个

  #ifndef _3DSMAX_ //预览没有迷雾
    OUTCOLOR.xyz *= tex2D(ShroudTextureSampler, i.FogCloudUV.xy) ;
  #endif

    OUTCOLOR.w = dif.w * OpacityOverride ;

    return OUTCOLOR ;
};

//高画质PBR pixel shader结束====================




technique Default
{    pass p0 <string ExpressionEvaluator = "Objects";>
  {
    VertexShader = compile vs_3_0 VS_H_UNDERGROUND(); 
    PixelShader  = compile ps_3_0 PS_H_UNDERGROUND();
    ZEnable = 1;
    ZFunc = 4;
    ZWriteEnable = 1;
    CullMode = 2;
    AlphaFunc = 7;
    AlphaRef = 64; //96
    AlphaBlendEnable = 0;
    AlphaTestEnable = 0;
  } 
}



//
/*

typedef enum D3DBLEND 
  D3DBLEND_ZERO             = 1,
  D3DBLEND_ONE              = 2,
  D3DBLEND_SRCCOLOR         = 3,
  D3DBLEND_INVSRCCOLOR      = 4,
  D3DBLEND_SRCALPHA         = 5,
  D3DBLEND_INVSRCALPHA      = 6,
  D3DBLEND_DESTALPHA        = 7,
  D3DBLEND_INVDESTALPHA     = 8,
  D3DBLEND_DESTCOLOR        = 9,
  D3DBLEND_INVDESTCOLOR     = 10,
  D3DBLEND_SRCALPHASAT      = 11,
  D3DBLEND_BOTHSRCALPHA     = 12,
  D3DBLEND_BOTHINVSRCALPHA  = 13,
  D3DBLEND_BLENDFACTOR      = 14,
  D3DBLEND_INVBLENDFACTOR   = 15,
  D3DBLEND_SRCCOLOR2        = 16,
  D3DBLEND_INVSRCCOLOR2     = 17,
  D3DBLEND_FORCE_DWORD      = 0x7fffffff
source color is the color of the pixel that is being drawn,
destination color is the color of the pixel that was behind the one drawn.

typedef enum D3DCULL 
  D3DCULL_NONE         = 1, Do not cull back faces.
  D3DCULL_CW           = 2, Cull back faces with clockwise vertices.
  D3DCULL_CCW          = 3, Cull back faces with counterclockwise vertices.
default cullmode = 2

    pass p1 //outline
    {
        VertexShader = compile vs_3_0 VS_outline_3dsmax(); 
        PixelShader  = compile ps_3_0 PS_outline();    
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 0;
        CullMode = 3; // reverse
        AlphaBlendEnable = 1 ;
        AlphaTestEnable = 1 ;
    }


*/

