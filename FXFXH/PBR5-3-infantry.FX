

#define IS_BASIC_W3D_SHADER
#define ALLOW_STEALTH
//#define ALLOW_HC_INVERT
//#define ALLOW_CLIP_VERTEX_ALPHA //允许骨骼透明度隐藏零件。object要。building不要。
#define BONE_ALPHA_SHRINK //AFFECT VS. caution: still write vertex alpha
#define MAX_POINT_LIGHT 4


#include "head3-vsps.FXH"

#ifdef ALLOW_HC_INVERT
bool HC_invert <string UIName = "HC_invert";> = 0;
#else
static const bool HC_invert = 0 ;
#endif

/*
fxc.exe /O2 /T fx_2_0 /Fo   infantry.fxo   PBR5-3-infantry.FX
*/


/*
bool HC_glow //阵营色发光 
<string UIName = "HC_glow";> = 0;
*/          


struct PS_infantry_input
{
    float2 vpos : VPOS ; //screen pixel 
    float4 VertexColor : COLOR0;  //顶点颜色
    float2 MainTexUV  : TEXCOORD0; //XY是主帖图UV,ZW是建筑损伤图UV
    float4 ShadowCS : TEXCOORD1; //XYZ阴影空间投影, W弃用
    float4 FogCloudUV : TEXCOORD2; //迷雾和云的UV
    float3 WorldP : TEXCOORD3;  //世界空间位置 ( no use ?)
    float3 WorldN : TEXCOORD4; //世界法线Z
};

float4 PS_H_infantry (PS_infantry_input i) : COLOR 
{
    #ifdef ALLOW_CLIP_VERTEX_ALPHA
    clip(i.VertexColor.w - 0.375);
    #endif
    float4 OUTCOLOR = float4(0,0,0,1); 

    const float ambient_mult =  0.75 ; //环境光与天空盒diffuse
    //const float pointlight_mult =  1 ; //点光源整体亮度
    const float sunlight_mult =  1 ; //阳光亮度

    float3 N = normalize(i.WorldN) ; //!!!

    float4 texcolor = tex2D(Texture_0Sampler,  i.MainTexUV.xy );
    float3 albedo = texcolor.xyz ;

  //hc mix
    float HCchannel = texcolor.w ;
    HCchannel = (HC_invert)? (1 - texcolor.w) : texcolor.w ;
    HCchannel = (HasRecolorColors)? HCchannel : 0 ;
    float whiteHCpart = max(max(albedo.r, albedo.g), albedo.b);
    float3 hcmask = lerp( float3(1,1,1), RecolorColor, HCchannel);
    texcolor.xyz = lerp((albedo * albedo) , whiteHCpart.xxx , HCchannel); //gamma without hc
    texcolor.xyz *= hcmask * hcmask ; //squared hc mix

  #ifdef ALLOW_STEALTH
    if(OpacityOverride < 0.985){
        //float3 V = hp_ps_getViewVector(i.WorldP) ; //dot(V,N)
        return hp_stealthVFX(0.5, texcolor.xyz , 1, i.vpos.y, RecolorColor);
    };
  #endif

  //about ambient
    float3 groundcolor = AmbientLightColor;
    float3 skyupcolor  = AmbientLightColor + hp_getAccentLight() ;
    float3 ambientALL = hp_fake_irradiance(groundcolor, skyupcolor , N.z);

  //about sun
    float3 Lsun     = DirectionalLight[0].Direction.xyz ;
    float3 SUNcolor = DirectionalLight[0].Color.xyz ;
    #if defined(_3DSMAX_)  
    Lsun     = PV_SunlightDirection ; 
    SUNcolor = PV_SunlightColor ;
    #endif

    SUNcolor *= sunlight_mult ;
    SUNcolor *= saturate( dot(Lsun , N));
    #ifndef _3DSMAX_ //高画质都有云和影子，但预览没有
    if(HasShadow){
    SUNcolor *= hp_invshadow_easy(i.ShadowPROJ);
    float3 cloudcolor = tex2D(CloudTextureSampler, i.FogCloudUV.zw);
    SUNcolor *= cloudcolor * cloudcolor ;
    };
    #endif
    float3 sunALL = SUNcolor ;  //阳光BRDF

  //about point light
    float3 PLtotal = float3(0,0,0) ;

    for (int itpl = 0; itpl < min(4, NumPointLights); itpl++ ) 
    {
      //if(itpl >= NumPointLights ){break;};

      float3 PLpos = PointLight[itpl].Position - i.WorldP ;
      float3 PLcolor = PointLight[itpl].Color ;
      float  PLrangeMAX = PointLight[itpl].Range_Inner_Outer.y * 2 ;
      float  PLrangeMIN = PointLight[itpl].Range_Inner_Outer.x + 1 ;

      #ifdef _3DSMAX_ //读取预览点光源数据
      PLpos = PV_pointlightPOS - i.WorldP; // relative!
      PLcolor = PV_pointlightCOLOR ; 
      PLrangeMAX = PV_pointlightRANGE ;
      PLrangeMIN = 0 ;
      #endif

      if(PLrangeMAX < 1) {continue;}; //排除无用的点光源
      float  PLdist = length(PLpos) ;
      if(PLdist >= PLrangeMAX) {continue;}; //排除太远的点光源
      float3 PLL = PLpos / PLdist ; //normalized light vector
      float  PLtilt = dot(PLL, N) ;
      if(PLtilt < 0) {continue;}; //排除背光面

      //float decaymult = (PLdist - PLrangeMAX) / (PLrangeMIN - PLrangeMAX);
      //decaymult = saturate(decaymult * decaymult); //平方衰减看起来更自然

      float3 thisBRDF = PLcolor * PLtilt * PLdecayfactor(PLrangeMIN, PLrangeMAX, PLdist); ;

      PLtotal += thisBRDF ; //叠加所有点光源
    };
    PLtotal *= 2 ;

    OUTCOLOR.xyz = ambientALL + sunALL + PLtotal ; //ALL REFLECTION (DIFF)
    OUTCOLOR.xyz *= texcolor ; //!!!
    OUTCOLOR.xyz *= TintColor ;
    #ifndef _3DSMAX_ //预览没有迷雾
    OUTCOLOR.xyz *= tex2D(ShroudTextureSampler, i.FogCloudUV.xy) ;
    #endif
    OUTCOLOR.w = 1; //i.VertexColor.w ; // OpacityOverride * i.VertexColor.w ;

    return OUTCOLOR;
}



float4 PS_BASICW3D_NOLIGHT(PS_infantry_input i)
{
    float4 texcolor = tex2D(Texture_0Sampler,  i.MainTexUV.xy );
    texcolor *= i.VertexColor ;
    texcolor.rgb *= (HasRecolorColors)? RecolorColor : 1 ;
    texcolor.rgb *= TintColor ;
    texcolor.a *= OpacityOverride ;
    return texcolor ;
}


int VSchooserExpr() 
{ return clamp(NumJointsPerVertex, 0, 2) ; }



VertexShader VS_infantry_Array[3] = {
    compile vs_3_0 VS_L_00skin(), 
    compile vs_3_0 VS_L_11skin(), 
    compile vs_3_0 VS_L_22skin(), 
};

VertexShader VS_Shadow_Array[3] = {
    compile vs_2_0 VS_ShadowMaker_00skin(), 
    compile vs_2_0 VS_ShadowMaker_11skin(), 
    compile vs_2_0 VS_ShadowMaker_22skin(), 
};

int PSchooserExpr() 
{ return clamp(BlendMode, 0, 1) ; }

PixelShader PS_infantry_array[2] = {
    compile ps_3_0 PS_H_infantry(),
    compile ps_3_0 PS_BASICW3D_NOLIGHT(),
};

/*
int PSstealthExpr()
{  return (OpacityOverride < 0.985 )? 1 : 0 ; }

PixelShader PS_infantry_Array[2] = {
    compile ps_3_0 PS_H_infantry(),
    compile ps_3_0 PS_vfx_stealth(),
};  
*/



#ifdef _3DSMAX_ //预览
technique INFANTRYmax
{    pass p0 //<string ExpressionEvaluator = "BasicW3D";>
    {
        VertexShader = compile vs_3_0 VSforMAX(); 
        PixelShader  = compile ps_3_0 PS_H_infantry(); 
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        AlphaBlendEnable = 0 ;
        AlphaTestEnable = 0 ;
    }
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

}
#endif


technique Default
{    pass P0 <string ExpressionEvaluator = "BasicW3D";>
    {
        VertexShader = VS_infantry_Array[ VSchooserExpr() ]; 
        PixelShader  = PS_infantry_array[ PSchooserExpr()];
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1; //
        CullMode = 2;
        AlphaFunc = 7;
        AlphaTestEnable = 0;
        //AlphaBlendEnable = 1;
        AlphaRef = 64;
    }
}

technique _Default_M
{    pass P0 <string ExpressionEvaluator = "BasicW3D";>
    {
        VertexShader = VS_infantry_Array[ VSchooserExpr() ]; 
        PixelShader  = compile ps_3_0 PS_LOW_INFANTRY(); 
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1; //
        CullMode = 2;
        AlphaFunc = 7;
        AlphaTestEnable = 0;
        //AlphaBlendEnable = 1;
        AlphaRef = 64;
    }
}

technique _CreateShadowMap
{    pass p0    
    {
    VertexShader = VS_Shadow_Array[ VSchooserExpr()  ]; 
    PixelShader  = compile ps_2_0 PS_ShadowMaker_NoTexture();
    ZEnable = 1;
    ZFunc = 4;
    ZWriteEnable = 1;
    CullMode = 2 ; //must cull front face, used to make depth buffer!
    AlphaBlendEnable = 0;
    AlphaTestEnable = 0;
    } 
}