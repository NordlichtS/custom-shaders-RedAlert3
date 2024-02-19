float helper_shadowpcf (
    int ShadowPCFlevel,         //replace with needed blur radius
    sampler2D ShadowMapSampler, //replace with the sampler you used in pixel shader
    float OneOverMapSize,       //replace with "Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w"
    float3 ShadowProjection )   //should be an input texcoord, XY being sampling coord, Z being distance to skylight
{
    float ShadowDensity = 0; float ShadowDepth; float2 ThisShiftUV; int countSAMPLES; //merely local variabels
    for (int countSHIFT = - ShadowPCFlevel; countSHIFT <= ShadowPCFlevel; countSHIFT ++)
    {
        ThisShiftUV = ShadowProjection.xy + float2 (OneOverMapSize * countSHIFT , 0); //LEFT TO RIGHT
        ShadowDepth = tex2D(ShadowMapSampler, ThisShiftUV);
        ShadowDensity = (ShadowDepth < ShadowProjection.z) ? ShadowDensity+1 : ShadowDensity+0;

        ThisShiftUV = ShadowProjection.xy + float2 (0, OneOverMapSize * countSHIFT);  //UP TO DOWN
        ShadowDepth = tex2D(ShadowMapSampler, ThisShiftUV);
        ShadowDensity = (ShadowDepth < ShadowProjection.z) ? ShadowDensity+1 : ShadowDensity+0;

        countSAMPLES +=2 ;
    }
    ShadowDensity = saturate (ShadowDensity / countSAMPLES) ;
    //float sunlight = 1-ShadowDensity;
    //return sunlight*sunlight ;  //sunlight brightness
    return 1- ShadowDensity;
}

float helper_BRDF_microfacet (
    float3 L,
    float3 V,
    float3 N,
    float  roughness_alpha, //rough"alpha" in microfacet model
    float  metalmap,
    float2 FresnelF0toSide )
{
    if ( dot(L,N)<0 ) {return 0;} else {
    float resultbrightness;
    float3 H = normalize(L+V); //halfway vector, also the nrm of microfacet mirror
    return resultbrightness;}
}

float helper_BRDF_reflectangle (
    float3 L,
    float3 R,
    float3 N,
    float  roughness_limitdegLR, //angle limit of this pixel
    float  metalmap,
    float2 FresnelV )
{
    if ( dot(L,N)<0 ) {return 0;} else {
    float resultbrightness;
    float cosLR = dot(L,R);
    float arcangleLR = degrees(acos(cosLR));
    float specblur_peakbrightness = 1/ pow( (roughness_limitdegLR/90) ,2); 
    //assume when roughness make angle limit =90, peak brightness is 100% baseline
    return resultbrightness;}
}

float4 helper_cliffcolor (
    sampler ORIGINALsampler, 
    sampler WRAPsampler,
    float2 originaluv,
    float3 worldnrm,
    float3 worldposition ) 
{
    float4 resultcolor;
    if (worldnrm.z > 0.7)
    {resultcolor = tex2D(ORIGINALsampler, originaluv);}
    else
    {
        float4 Xside = tex2D(WRAPsampler, worldposition.yz/80);
        float4 Yside = tex2D(WRAPsampler, worldposition.xz/80);
        resultcolor = (worldnrm.x > worldnrm.y) ? Xside : Yside ;
    }
    return resultcolor;
}

float4 helper_cliffnormal (
    sampler ORIGINALsampler, 
    float2 originaluv,
    float3 worldnrm ) //no need position or multiply, no tangentspace
{
    float4 resultcolor = tex2D(ORIGINALsampler, originaluv);
    if (worldnrm.z < 0.7)
    {resultcolor.xy = float2 (0.5 , 0.5);}
    return resultcolor;
}


float helper_OCTAshadowpcf (
    int ShadowPCFlevel,         //replace with needed blur radius
    sampler2D ShadowMapSampler, //replace with the sampler you used in pixel shader
    float OneOverMapSize,       //replace with "Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w"
    float3 ShadowProjection )   //should be an input texcoord, XY being sampling coord, Z being distance to skylight
{
    float ShadowDensity = 0; float ShadowDepth; float2 ThisShiftUV; int countSAMPLES =0; //merely local variabels
    ShadowDepth = tex2D(ShadowMapSampler, ShadowProjection.xy);
    ShadowDensity = (ShadowDepth < ShadowProjection.z) ? ShadowDensity+1 : ShadowDensity+0;
    countSAMPLES +=1 ;
    for (int countSHIFT = 1; countSHIFT <= ShadowPCFlevel; countSHIFT ++)
    {
        ThisShiftUV = ShadowProjection.xy + float2(1,0)*OneOverMapSize*countSHIFT; //RIGHT
        ShadowDepth = tex2D(ShadowMapSampler, ThisShiftUV);
        ShadowDensity = (ShadowDepth < ShadowProjection.z) ? ShadowDensity+1 : ShadowDensity+0;

        ThisShiftUV = ShadowProjection.xy + float2(1,1)*OneOverMapSize*countSHIFT; //RIGHT UP
        ShadowDepth = tex2D(ShadowMapSampler, ThisShiftUV);
        ShadowDensity = (ShadowDepth < ShadowProjection.z) ? ShadowDensity+1 : ShadowDensity+0;

        ThisShiftUV = ShadowProjection.xy + float2(0,1)*OneOverMapSize*countSHIFT;  //UP
        ShadowDepth = tex2D(ShadowMapSampler, ThisShiftUV);
        ShadowDensity = (ShadowDepth < ShadowProjection.z) ? ShadowDensity+1 : ShadowDensity+0;

        ThisShiftUV = ShadowProjection.xy + float2(-1,1)*OneOverMapSize*countSHIFT; //LEFT UP
        ShadowDepth = tex2D(ShadowMapSampler, ThisShiftUV);
        ShadowDensity = (ShadowDepth < ShadowProjection.z) ? ShadowDensity+1 : ShadowDensity+0;

        ThisShiftUV = ShadowProjection.xy + float2(-1,0)*OneOverMapSize*countSHIFT; //LEFT
        ShadowDepth = tex2D(ShadowMapSampler, ThisShiftUV);
        ShadowDensity = (ShadowDepth < ShadowProjection.z) ? ShadowDensity+1 : ShadowDensity+0;

        ThisShiftUV = ShadowProjection.xy + float2(-1,-1)*OneOverMapSize*countSHIFT; //LEFT DOWN
        ShadowDepth = tex2D(ShadowMapSampler, ThisShiftUV);
        ShadowDensity = (ShadowDepth < ShadowProjection.z) ? ShadowDensity+1 : ShadowDensity+0;

        ThisShiftUV = ShadowProjection.xy + float2(0,-1)*OneOverMapSize*countSHIFT; //DOWN
        ShadowDepth = tex2D(ShadowMapSampler, ThisShiftUV);
        ShadowDensity = (ShadowDepth < ShadowProjection.z) ? ShadowDensity+1 : ShadowDensity+0;

        ThisShiftUV = ShadowProjection.xy + float2(1,-1)*OneOverMapSize*countSHIFT; //RIGHT DOWN
        ShadowDepth = tex2D(ShadowMapSampler, ThisShiftUV);
        ShadowDensity = (ShadowDepth < ShadowProjection.z) ? ShadowDensity+1 : ShadowDensity+0;

        countSAMPLES +=8 ;
    }
    ShadowDensity = saturate (ShadowDensity / countSAMPLES) ;
    //float sunlight = 1-ShadowDensity;
    //return sunlight*sunlight ;  //sunlight brightness
    return 1- ShadowDensity;
}