//#define _3DSMAX_
// #define IS_BASIC_W3D_SHADER
// #define IGNORE_NRM

texture FakeShadowMap
<    string UIName = "FakeShadowMap";>;

float FakeShadowmapTexels
<
  string UIName = "FakeShadowmapTexels"; 
  float UIMax = 512; float UIMin = 1; float UIStep = 1; 
> =  64 ;

//#pragma warning(disable: 3206)

#include "head3-vsps.FXH" //WILL INCLUDE EVERYTHING



// 阴影贴图，记录阳光投影空间的深度，或者说到天空的距离


sampler2D FakeShadowMapSampler
<
    string Texture = "FakeShadowMap";
> = sampler_state {
    Texture = < FakeShadowMap >;
    MinFilter = 1 ; 
    MagFilter = 1 ; // 原版的临近采样
    MipFilter = 0;
    AddressU = 4; //3=clamp, 4=border
    AddressV = 4;
    AddressW = 3;
};

sampler2D FakeShadowMapSamplerLinear
<
    string Texture = "FakeShadowMap";
> = sampler_state {
    Texture = < FakeShadowMap >;
    MinFilter = 2 ; 
    MagFilter = 2 ; // 用线性可防止斜面锯齿?
    MipFilter = 0;
    AddressU = 4;
    AddressV = 4;
    AddressW = 3;
};

struct PS_H_input
{
    float2 vpos : VPOS ; //screen pixel 
    float4 VertexColor : COLOR0;  //顶点颜色
    float4 MainTexUV  : TEXCOORD0; //XY是主帖图UV,ZW是建筑损伤图UV
    float4 ShadowCS : TEXCOORD1; //XYZ阴影空间投影, W弃用
    float4 FogCloudUV : TEXCOORD2; //迷雾和云的UV
    float3 WorldP : TEXCOORD3;  //世界空间位置
    float3 WorldN : TEXCOORD4_centroid; //世界法线Z
    float3 WorldT : TEXCOORD5_centroid; //世界切线Y
    float3 WorldB : TEXCOORD6_centroid; //世界切线X
};

float4 PS_H_SHADOWTEST (PS_H_input i) : COLOR 
{
  float4 outcolor =1;



  float3 SMUV = i.WorldP / 20 ;
  SMUV.z = 1- SMUV.z ;
  float sun_tilt = i.WorldN.z ;

    if(sun_tilt <= 0) {return 0;};



    float transition_range_mult = 4 ;
    float transition_start_bias_mult = 0 ;

    float2 SM01T = float2(0, 1.0 / FakeShadowmapTexels );
    float2 UVlerpw = frac(SMUV.xy / SM01T.y);
    float objdepth = SMUV.z;
    // objdepth + : more likely to have shadow

    float4 fourSamples = float4(   //shadowmap depth
        tex2D(FakeShadowMapSampler, (SMUV.xy + SM01T.xx)).x ,
        tex2D(FakeShadowMapSampler, (SMUV.xy + SM01T.xy)).x ,
        tex2D(FakeShadowMapSampler, (SMUV.xy + SM01T.yx)).x ,
        tex2D(FakeShadowMapSampler, (SMUV.xy + SM01T.yy)).x 
    );  // LU,LD,RU,RD (00,01,10,11) 

    // shadowmapdepth + : more likely to have sunlight
    fourSamples -= objdepth ;
    //shadowmapdepth - objdepth = sunlight likelyness
    fourSamples /= SM01T.y * transition_range_mult ; 
    //default transition range: 1/1024 (ooms)
    //divider smaller = sharper
    fourSamples +=  transition_start_bias_mult ;
    //increase sunlight likelyness, avoid self shadow
    //fourSamples = saturate(fourSamples); //???
    //bilinear 2x2 interpolate
    float2 bLR = lerp(fourSamples.xy , fourSamples.zw , UVlerpw.x);
    float  bUD = lerp(bLR.x   , bLR.y   , UVlerpw.y);
    float lightmid = bUD ;
    //lightmid = smoothstep(0 , 1 , bUD) ; //???




    /*

    float2 SM01T = float2(0, 1.0 / FakeShadowmapTexels);
    float2 UVlerpw = frac(SMUV.xy / SM01T.y);
    float object_depth = SMUV.z - SM01T.y * 2;//(3- 2* sun_tilt) ; //  1.0 / 512.0 ;
    //tbd : use suntilt to fix side offset

    float4 fourSamples = float4(   //四个角的阴影图深度
        tex2D(FakeShadowMapSampler, (SMUV.xy + SM01T.xx)).x ,
        tex2D(FakeShadowMapSampler, (SMUV.xy + SM01T.xy)).x ,
        tex2D(FakeShadowMapSampler, (SMUV.xy + SM01T.yx)).x ,
        tex2D(FakeShadowMapSampler, (SMUV.xy + SM01T.yy)).x 
    );  // LU,LD,RU,RD (00,01,10,11) 
    bool4 fourTests = (fourSamples > object_depth) ; //阴影比物体离阳光更远，则有阳光
    fourSamples = (float4)fourTests ;
    //双线性插值
    float2 bLR = lerp(fourSamples.xy , fourSamples.zw , UVlerpw.x);
    float  bUD = lerp(bLR.x   , bLR.y   , UVlerpw.y);
    float lightmid = bUD ; //* bUD;
    */

    //对斜边的额外抗锯齿修复
    
    /*
    float lightpixin4 = dot(fourSamples, 1);
    float lighthigh = (lightpixin4 < 2.5) ? lightmid : 1 ;
    float lightlow  = (lightpixin4 > 1.5) ? lightmid : 0 ;
    lightmid = lerp(lightlow, lighthigh, lightmid) ;
    */
    /*
    float lightpixin4 = dot(fourSamples, 1);
    float lighthigh = (lightpixin4 > 1.5) ? lightmid : 1 ;
    float lightlow  = (lightpixin4 < 2.5) ? lightmid : 0 ;
    lightmid = lerp(lightlow, lighthigh, lightmid) ;
    */
    /*
    lightmid = lightmid *2 -1 ;
    lightmid = lightmid * lightmid * lightmid ;
    lightmid = lightmid *0.5 + 0.5 ;
    */
    //cubic hermit ( (3.0 - 2 * inx) * inx * inx )
    /*
    float lightpixin4 = dot(fourSamples, 0.25)  ;
    lightmid = (lightmid - 0.5 )/2 ;
    lightmid = saturate( lightmid + lightpixin4 );
    */
    /*
    float lightpixin4 = (dot(fourSamples, 1) -1)/3 ;//01234 -> -1 0123 -> -0.33 0 0.33 0.66 1
    lightmid = lightmid /3 ;
    lightmid = saturate( lightmid + lightpixin4 );
    */
    
    //lightmid = (3.0 - 2 * lightmid) * lightmid * lightmid ;
    //lightmid = (lightmid < 0.5)? 0 : 1 ;
    

    outcolor.xyz = lightmid ; //is return
    //tex2D(FakeShadowMapSampler, SMUV.xy)
    return outcolor ;
};

//高画质PBR pixel shader结束====================



technique MAXTEST
{    pass p0 
    {
        VertexShader = compile vs_3_0 VSforMAX(); 
        PixelShader = compile ps_3_0 PS_H_SHADOWTEST();
        ZEnable = 1;
        ZFunc = 4;
        ZWriteEnable = 1;
        CullMode = 2;
        AlphaBlendEnable = 0 ;
        AlphaTestEnable = 0 ;
    }
}
