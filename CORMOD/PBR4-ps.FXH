//这个文件用来存放所有像素计算器
//#include "PBR1-constants.FXH"
//#include "PBR2-functions.FXH"
#include "PBR3-vs.FXH" //防止同时引用两个导致重定义




/*
// MAIN PBR PIXEL SHADER with tangent frame support
支持法线图，物理渲染，阴影柔和，8点光源全BRDF，天空盒，MAX预览
岚依的源码没看懂，不过里面留下的教程链接还是很好的，我重写吧
参考教程：
freya holmer
acerola
知乎
油管
*/

//输入数组直接拿VS输出好了
float4 PS_H_PBR_CORONA (VS_H_output i) : COLOR 
{
  float4 OUTCOLOR = i.VertexColor; //安全起见先initialize

  //拿出主贴图
    float4 dif = tex2D(DiffuseTextureSampler,  i.MainTexUV.xy );
    float4 nrm = tex2D(NormalMapSampler,       i.MainTexUV.xy );
    float4 spm = tex2D(SpecMapSampler,         i.MainTexUV.xy );

  //初步整理下信息
    if(AlphaTestEnable) {
      clip(dif.w - 0.5); 
      clip(i.VertexColor.w - 0.25); 
    };    
    if(base_texture_gamma) {dif.xyz = pow(dif.xyz, 2) ;}; 
    if(HasRecolorColors)   {dif.xyz = mixHC(dif.xyz, spm.z) ;};
 
    float  metalness = spm.y ;
    
    float  roughness = lerp(1, (1 / MAXglossiness) , spm.x ) ; //  (1 / MAXglossiness)  //MinRoughness
    float  glossiness = (1 / roughness) ; //OOA? SPECPEAK?

    float  dielectric_reflectivity = saturate(spm.x / reflectivity_cutoff) ;
    
    float3 speccolor = lerp( dielectric_reflectivity.xxx, dif.xyz, metalness);
    float  F0 = lerp(FresnelF0 , FresnelMetalF0, metalness);
    float3 difcolor = dif.xyz * (1 - metalness) ;
    //float3 speccolor = (metalness < 0.5 )? dielectric_reflectivity.xxx : dif.xyz ;
    //float  F0 = (metalness < 0.5 )? FresnelF0 : FresnelMetalF0 ;
    //float3  difcolor = (metalness < 0.5 )? dif.xyz : float3(0,0,0) ;

    float  AOchannel = nrm.w ;
    float  GLOWchannel = spm.w ; 
    float  CAVITYchannel = 1 ;
    // if(GlowAmplitude != 0)
    //GLOWchannel = (GlowAmplitude > 0)? spm.w : (1- spm.w) ;
    //CAVITYchannel = 1 - GLOWchannel ;
    float3 GlowMapRGB = dif.xyz * GLOWchannel ; //发光图层，可能要加个闪烁. abs(GlowAmplitude) 


  //世界法线
    float3 N = i.WorldN ;
    if(tangent_xy_multiply != 0) //是否从nrm贴图获取
    {
    N.xyz = helper_normalmapper(nrm.xy) ;
    float3x3 TangentSpaceToWorldMatrix = float3x3(i.WorldB, i.WorldT, i.WorldN) ;
    N = mul(N, TangentSpaceToWorldMatrix) ;
    };
    N = normalize(N); //长度单位化，这一步很重要

  //世界空间的view vector，与目光反射
    float3 V = helper_ps_getViewVector(i.WorldP) ;
    float  EYEtilt = dot(V , N) ; //1= perpendicular view, 0= side view , -1=back
    float3 R = reflect(-V , N) ; //input light vector is towards fragment!
    if(EYEtilt <0) {R = -V ;} ; //SHOULD I FIX IT ?

  //环境光相关 
    float3 skybox_color = getSKYBOXcolor(R, roughness, glossiness, AOchannel);
    float3 irradiance_color = getIRRADIANCEcolor(N, AOchannel);

    float3 ambientALL = float3(0,0,0) ; //环境光BRDF
    //ambient DIFF
    ambientALL += irradiance_color * difcolor * ambient_diff_multiply ; 
    //ambient SPEC
    ambientALL += skybox_color * speccolor * ambient_spec_multiply * helper_fresnel(R, V, F0); 

  //阳光相关 
    float3 Lsun     = DirectionalLight[0].Direction.xyz ;
    float3 SUNcolor = DirectionalLight[0].Color.xyz ;
    #if defined(_3DSMAX_)  //MAX预览阳光方向与颜色覆盖
    Lsun     = PV_SunlightDirection ; 
    SUNcolor = PV_SunlightColor ;
    #endif

    SUNcolor *= sunlight_multiply ;
    float  sun_tilt  = dot(N,Lsun) ;
    SUNcolor *= helper_invert_shadow_density_cross(i.ShadowPROJ , sun_tilt);
    //shadow helper also return 0 for backface, 1 for no shadow
    if(HasCloud) { SUNcolor *= tex2D(CloudTextureSampler, i.FogCloudUV.zw); };

    float3 sunALL = float3(0,0,0) ;  //阳光BRDF
    //sun diff
    sunALL += difcolor * sun_tilt * diffuse_multiply ;//helper_newdiffuse(sun_tilt, dielectric_reflectivity);
    //sun spec
    sunALL += speccolor * helper_specdist(glossiness, R, Lsun) * helper_fresnel(Lsun, V, F0) ;
    sunALL *= SUNcolor ;

  //点光源BRDF
    float3 PLtotal = float3(0,0,0) ;
    //int maxPLcount = clamp(NumPointLights, 0, 8); //JUST IN CASE

    for (int countpl = 0; countpl < NumPointLights ; countpl++ ) 
    {
      float3 PLpos = PointLight[countpl].Position - i.WorldP ;
      float3 PLcolor = PointLight[countpl].Color ;
      float  PLrangeMAX = PointLight[countpl].Range_Inner_Outer.y ;
      float  PLrangeMIN = PointLight[countpl].Range_Inner_Outer.x ;

      #ifdef _3DSMAX_ //读取预览点光源数据
      PLpos = PV_pointlightPOS ;
      PLcolor = PV_pointlightCOLOR ; 
      PLrangeMAX = PV_pointlightRANGE ;
      PLrangeMIN = 0 ;
      #endif

      if(PLrangeMAX < 1) {continue;}; //排除无用的点光源
      float  PLdist = length(PLpos) ;
      if(PLdist >= PLrangeMAX) {continue;}; //排除太远的点光源
      float3 PLL = PLpos / PLdist ; //normalized light vector
      float  PLtilt = dot(PLL, N) ;
      if(PLtilt <= 0) {continue;}; //排除背光面

      float decaymult = (PLdist - PLrangeMAX) / (PLrangeMIN - PLrangeMAX);
      // decaymult = clamp(decaymult, 0, 2); //SATURATE ?

      float3 thisBRDF = float3(0,0,0) ;
      //pl diff
      thisBRDF += difcolor * PLtilt * diffuse_multiply ; 
      //pl spec
      thisBRDF += speccolor * helper_specdist(glossiness, R, PLL) * helper_fresnel(PLL, V, F0) ;
      //pl color
      thisBRDF *= PLcolor * decaymult;

      PLtotal += thisBRDF ; //叠加所有点光源
    };
    PLtotal *= pointlight_multiply ;

  //最终混色
    OUTCOLOR.xyz = ambientALL + sunALL + PLtotal ; //BRDF
    OUTCOLOR.xyz *= CAVITYchannel ;
    if(HasWarfog){OUTCOLOR.xyz *= tex2D(ShroudTextureSampler, i.FogCloudUV.xy) ;};
    OUTCOLOR.xyz += GlowMapRGB * helper_glowpulse() * GlowAmplitude ;
    OUTCOLOR.xyz *= TintColor ;

    OUTCOLOR.w *= OpacityOverride * dif.w ;

    if(final_output_gamma){OUTCOLOR.xyz *= OUTCOLOR.xyz ;};

    return OUTCOLOR;
};

//高画质PBR pixel shader结束