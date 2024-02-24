float helper_shadowpcf (    //CROSS SHAPE SAMPLED
    int ShadowPCFlevel,         //replace with needed blur radius
    sampler2D ShadowMapSampler, //replace with the sampler you used in pixel shader
    float OneOverMapSize,       //replace with "Shadowmap_Zero_Zero_OneOverMapSize_OneOverMapSize.w"
    float3 ShadowProjection )   //should be an input texcoord, XY being sampling coord, Z being distance to skylight
{
    ShadowPCFlevel = clamp(ShadowPCFlevel, 1,4);
    float ShadowDensity = 0; float ShadowDepth; float2 ThisShiftUV; int countSAMPLES; //merely local variabels
    for (float countSHIFT = 0.5- ShadowPCFlevel; countSHIFT < ShadowPCFlevel; countSHIFT ++)
    {
        ThisShiftUV = ShadowProjection.xy + float2 (OneOverMapSize * countSHIFT , 0); //LEFT TO RIGHT
        ShadowDepth = tex2D(ShadowMapSampler, ThisShiftUV);
        ShadowDensity = (ShadowDepth < ShadowProjection.z) ? ShadowDensity+1 : ShadowDensity+0;

        ThisShiftUV = ShadowProjection.xy + float2 (0, OneOverMapSize * countSHIFT);  //UP TO DOWN
        ShadowDepth = tex2D(ShadowMapSampler, ThisShiftUV);
        ShadowDensity = (ShadowDepth < ShadowProjection.z) ? ShadowDensity+1 : ShadowDensity+0;

        countSAMPLES +=2 ;
    }
    ShadowDensity = saturate (ShadowDensity / countSAMPLES) ;  //TOTAL SAMPLE 4*LEVEL+2
    //float sunlight = 1-ShadowDensity;
    //return sunlight*sunlight ;  //sunlight brightness
    return 1- ShadowDensity;
}

float3 helper_BRDF_microfacet (
    float3 L,
    float3 V,
    float3 N,
    float  roughness_alpha, //rough"alpha" in microfacet model
    float  metalness,
    float3 albedopaint,
    float3 albedometal,
    float2 FresnelF0toSide )
{
    if ( dot(L,N)<0 ) {return 0;} else {
    float3 totallight;
    float3 H = normalize(L+V); //halfway vector, also the nrm of microfacet mirror
    return totallight;}
}

float3 helper_BRDF_simple (  //with fixed roughness, microfacet model, blinn specular
    float3 L,
    float3 V,
    float3 N,
    float  metalness,
    float4 bothF0, //RGB metal F0, W paint F0
    float3 albedo_diffuse) //only work on paint, cameo color
{
    float cosLN = dot(L,N) ;
    if ( cosLN<0 ) {return 0;} else {
    float3 H = normalize(L+V); //halfway vector, also the nrm of microfacet mirror
    float  fresnel = lerp( bothF0.w , 1, pow(1-dot(H,V) , 4) ) ; //schlick approx fresnel but softer
    float  lambertian = (1-fresnel) * cosLN * 0.3 ;  //0.3 as 1/pie
    float  distribution = pow( dot(H,N) , 4) ; //square cos, increase power to more glossiness
    //can also be:  pow( dot(H,N) , specexp) 
    float3 color_ifmetal = bothF0.rgb * distribution ;
    float3 color_ifpaint = float3(1,1,1) * distribution * fresnel + lambertian * albedo_diffuse;
    float3 totallight = lerp(color_ifpaint, color_ifmetal, metalness);
    return totallight;}
}

float3 helper_BRDF_simple_detailed (  //with adjustable roughness on both material
    float3 L,
    float3 V,
    float3 N,
    float  metalness,
    float4 bothF0, //RGB metal F0, W paint F0
    float3 albedo_diffuse,
    float4 OtherReflectionData  )  //X=paint spec expo, Y=metal spec expo, Z=lambertian brightness, W=paint F90
{
    float cosLN = dot(L,N) ;
    if ( cosLN<0 ) {return 0;} else {
    float3 H = normalize(L+V); //halfway vector, also the nrm of microfacet mirror
    float  fresnel = lerp( bothF0.w , 1, pow(1-dot(H,V) , 4) ) ; //schlick approx fresnel but softer
    float  lambertian = (1-fresnel) * cosLN * 0.3 ;  //0.3 as 1/pie
    float  distribution = pow( dot(H,N) , 4) ; //square cos, increase power to more glossiness
    //can also be:  pow( dot(H,N) , specexp) 
    float3 color_ifmetal = bothF0.rgb * distribution ;
    float3 color_ifpaint = float3(1,1,1) * distribution * fresnel + lambertian * albedo_diffuse;
    float3 totallight = lerp(color_ifpaint, color_ifmetal, metalness);
    return totallight;}
}

float3 helper_BRDF_reflectangle ( //assume: light is white, but albedo still influence color
    float3 L,
    float3 R,
    float3 N,
    float  roughness_limitangleLR, //angle limit of this pixel
    float  metalness,
    float3 albedopaint,
    float3 albedometal,
    float  FresnelV )
{
    float cosLN = dot(L,N) ;
    if ( cosLN<0 ) {return 0;} else {
    float cosLR = dot(L,R);
    float angleLR = degrees(acos(cosLR));
    float specblur_peakbrightness = 1/ pow( (roughness_limitangleLR /90) ,2); 
    //assume: when roughness make angle limit =90, peak brightness is 1.0 baseline
    float specblur_gradient = specblur_peakbrightness *(1- saturate(angleLR / roughness_limitangleLR) );
    float3 spec_ifmetal = specblur_gradient * albedometal ;
    float3 spec_ifpaint = float3(1,1,1)* specblur_gradient * FresnelV ;
    float3 paint_specplusdiff = spec_ifpaint + albedopaint * cosLN * 0.25; //LAMBERTIAN
    float3 totallight = lerp( paint_specplusdiff , spec_ifmetal , metalness) ;
    return totallight*0.25 ;}
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
        float4 Xside = tex2D(WRAPsampler, worldposition.yz*0.0125);
        float4 Yside = tex2D(WRAPsampler, worldposition.xz*0.0125);
        resultcolor = (worldnrm.x > worldnrm.y) ? Xside : Yside ;
    }
    return resultcolor;
}

float4 helper_cliffcolorfold (
    sampler ORIGINALsampler, 
    sampler WRAPsampler,
    float2 originaluv,
    float3 worldnrm,
    float worldZ ) 
{
    float4 resultcolor;
    if (worldnrm.z > 0.7)
    {resultcolor = tex2D(ORIGINALsampler, originaluv);}
    else
    {
        float4 Xside = tex2D(WRAPsampler, (originaluv.y , worldZ*0.0125) );
        float4 Yside = tex2D(WRAPsampler, (originaluv.x , worldZ*0.0125) );
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
    ShadowDensity = saturate (ShadowDensity / countSAMPLES) ;  //TOTAL SAMPLE 8*LEVEL+1
    //float sunlight = 1-ShadowDensity;
    //return sunlight*sunlight ;  //sunlight brightness
    return 1- ShadowDensity;
}