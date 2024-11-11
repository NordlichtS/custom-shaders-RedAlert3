//input parameters, some are placeholders
string ParamID = "0x1";


float SomeParam01 
<string UIName = "SomeParam01"; float UIStep = 0.125;> = { 2 };

float diffuse_mult 
<string UIName = "diffuse_mult"; float UIMax = 2; float UIMin = 0; float UIStep = 0.05; > = 0 ;

float curve_width 
<string UIName = "curve_width"; float UIMax = 32; float UIMin = 1; float UIStep = 1; > = 8 ;

bool flipUV_Y <string UIName = "flipUV_Y";> = 1 ;

texture DiffuseTexture 
<string UIName = "DiffuseTexture";>; 
//the useful samplers
sampler DiffuseSampler = sampler_state 
{
    Texture = <DiffuseTexture>; 
    MinFilter = 3;
    MagFilter = 2;
    MipFilter = 2;
    MaxAnisotropy = 8;
    AddressU = 1;
    AddressV = 1;
};

// Default transformations
float4x4 WorldViewProjection : WorldViewProjection;

// Vertex shader
struct VS_INPUT
{
    float4 Position : POSITION;
    float3 Normal   : NORMAL;
    float2 TexCoord : TEXCOORD0;
};
struct VS_OUTPUT
{
    float4 Position : POSITION;
    float2 TexCoord : TEXCOORD0;
};
VS_OUTPUT VS_Main(VS_INPUT input)
{
    VS_OUTPUT output;

    output.Position = mul(input.Position, WorldViewProjection);
    output.TexCoord = input.TexCoord;
    if(flipUV_Y) //这就很讨厌
    {output.TexCoord.y =  - input.TexCoord.y ;};

    return output;
}

//函数就放这里吧=================

float drawcurve(float Yresult, float CurrentY)
{
    float dist = abs(Yresult - CurrentY);
    dist *= 1024 / curve_width ;
    dist = saturate( 1 - dist);
    return dist ;
}

float2 f_quadpara(float xi )
{
    float2 a = float2(xi , (1 - xi) );
    a = pow(a , 2) ; 
    a.y = (1 - a.y) ;
    return a ;
}

float2 f_straight2x(float xi )
{
    float2 aa; 
    aa = float2(1,1) * xi * 2 ;
    aa.x -=  1;
    aa = saturate(aa);
    return aa ;
}




//函数结束=======================

// Pixel shader
struct PS_INPUT { float2 TexUV : TEXCOORD0; };
float4 PS_Main(PS_INPUT i) : COLOR
{
    float4 diffuseColor = tex2D(DiffuseSampler, i.TexUV);
    float3 finalColor = diffuseColor ;
    //可以开始加各种函数了=================

    finalColor += drawcurve(i.TexUV.x , i.TexUV.y) * float3 (0.1, 0.1, 0.1); // y = x

    float2 quadpara = f_quadpara(i.TexUV.x);
    //finalColor += drawcurve(quadpara.x , i.TexUV.y) * float3 (0.3, 0, 0);
    //finalColor += drawcurve(quadpara.y , i.TexUV.y) * float3 (0, 0.3, 0);

    float hermit = lerp(quadpara.x , quadpara.y, i.TexUV.x);
    finalColor += drawcurve(hermit , i.TexUV.y) * float3 (0, 0, 1); 

    float2 straight2x = f_straight2x(i.TexUV.x);
    finalColor += drawcurve(straight2x.x , i.TexUV.y) * float3 (0.1, 0, 0);
    finalColor += drawcurve(straight2x.y , i.TexUV.y) * float3 (0, 0.1, 0);

    float straighthermit = lerp(straight2x.x , straight2x.y, i.TexUV.x);
    finalColor += drawcurve(straighthermit , i.TexUV.y) * float3 (0, 1, 0); 
    float straightagain  = lerp(straight2x.x , straight2x.y, straighthermit);
    finalColor += drawcurve(straightagain  , i.TexUV.y) * float3 (0.5, 0.5, 0); 



    float intrinsic_smoothstep = smoothstep(0,1, i.TexUV.x);
    finalColor += drawcurve(intrinsic_smoothstep , i.TexUV.y) * float3 (1, 0, 0); 


    //float hermitagain = lerp(quadpara.x, quadpara.y, hermit) ;
    //finalColor += drawcurve(hermitagain , i.TexUV.y) * float3 (1, 0, 1); 



    //最后颜色都加到一起=====================
    return float4(finalColor, 1);  // or return float4(finalColor, finalColor.a);
}


technique MainTechnique
{
    pass Pass1
    {
        vertexShader = compile vs_3_0 VS_Main();
        pixelShader  = compile ps_3_0 PS_Main();
    }
}
