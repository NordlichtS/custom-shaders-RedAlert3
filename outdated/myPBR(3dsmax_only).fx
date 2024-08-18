//input parameters, some are placeholders
float3 HCpreviewRGB 
<string UIName = "HCpreviewRGB(PlayerColor)"; string UIWidget = "Color"; string UIWidgetParams = "noalpha";> = {1, 1, 1};
//上面这个只是用来在max里预览的，游戏里没用

texture DiffuseTexture 
<string UIName = "DiffuseTexture";>; //主贴图

texture NormalMap 
<string UIName = "NormalMap";>; //法线贴图

texture SpecMap 
<string UIName = "SpecMap";>; //SPM贴图

float ambient_multiply
<string UIName = "ambient_multiply"; string SasBindAddress = "Sas.pbr_ambient_multiply";
string UIWidget = "Slider"; float UIMax = 4; float UIMin = 0; float UIStep = 0.01 ;> = { 0.33 }; //环境光与天空亮度

float diffuse_multiply
<string UIName = "diffuse_multiply"; 
string UIWidget = "Slider"; float UIMax = 4; float UIMin = 0; float UIStep = 0.01 ;> = { 1.0 }; //漫反射亮度，影响阳光与点光源

float spec_multiply
<string UIName = "spec_multiply"; 
string UIWidget = "Slider"; float UIMax = 4; float UIMin = 0; float UIStep = 0.01 ;> = { 2.8 }; //高光（镜面反射）亮度，影响阳光与点光源

float pointlight_multiply
<string UIName = "pointlight_multiply"; 
string UIWidget = "Slider"; float UIMax = 4; float UIMin = 0; float UIStep = 0.1 ;> = { 1.4 }; //点光源反射整体亮度

float fix_saturation
<string UIName = "fix_saturation"; 
string UIWidget = "Slider"; float UIMax = 32; float UIMin = 0.1; float UIStep = 0.1 ;> = { 16 }; //反射光谱的饱和度修复

float roughness
<string UIName = "roughness(microfacet-distribution)"; 
string UIWidget = "Slider"; float UIMax = 1; float UIMin = 0.1; float UIStep = 0.01;> = { 0.16 }; //金属的最低粗糙度（太阳倒影的模糊光斑尺寸）

float glassf0
<string UIName = "glassf0(fresnel-decay)"; 
string UIWidget = "Slider"; float UIMax = 1; float UIMin = 0.01; float UIStep = 0.01;> = { 0.12 }; //玻璃窗反射的菲涅尔效应，此值越暗效果越强烈

bool ignore_vertex_alpha
<string UIName = "ignore_vertex_alpha";> =0 ; //仅原版建筑开启！强制忽略顶点透明度，避免建筑损坏时破洞贴图错误，但会让车辆损失隐身半透明效果

bool AlphaTestEnable 
<string UIName = "AlphaTestEnable";> =1 ; //贴图镂空。与上一个选项不冲突

// bool AlphaBlendEnable <string UIName = "AlphaBlendEnable";> =1; //可能导致基洛夫变半透明，暂时去掉

bool HCenhance
<string UIName = "HCenhance";> =1 ;  //提升原版阵营色的饱和度（而不是亮度）也影响发光梯度

bool GAMMAcorrection
<string UIName = "GAMMAcorrection";> =1 ;  //SRGB颜色修正

float4 GLOWcolor 
<string UIName = "GLOWcolor(Alpha=HC)"; string UIWidget = "Color"; > = {0, 0, 0, 0}; //发光颜色为 (此值RGB+A*阵营色)*SPM绿通道 !

float tangent_xy_multiply
<string UIName = "tangent_xy_multiply"; float UIMax = 1; float UIMin = -1; float UIStep = 0.1; > ={ 1 };  //如果法线图凹凸反了，写-1修正。完全无效化法线图，写0。

int SKY_index
<string UIName = "SKY_index";
string UIWidget = "Slider"; int UIMax = 10; int UIMin = 0;> ={ 10 }; //选择哪个颜色为 “天空”反射色

int GROUND_index
<string UIName = "GROUND_index";
string UIWidget = "Slider"; int UIMax = 10; int UIMin = 0;> ={ 7  }; //选择哪个颜色为 “地面”反射色

/*
天空色和地面色的 INDEX :
0= 阳光颜色
1= 地编补光1
2= 地编补光2 
3= 补光二者最大值
4= 补光二者最小值
5= 纯黑
6= 纯白
7= 地编环境光颜色
8= 两个地编补光相加
9= 补光最大值与环境光相加
10= 两个补光与环境光相加
*/

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

sampler SpecSampler = sampler_state 
{
    Texture = <SpecMap>; 
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

    return output;
}

// Pixel shader
struct PS_INPUT
{
    float2 TexCoord : TEXCOORD0;
};

float4 PS_Main(PS_INPUT input) : COLOR
{
    // Sample the texture
    float4 texcolor = tex2D(DiffuseSampler, input.TexCoord);
    float4 spm = tex2D(SpecSampler, input.TexCoord);

    if (GAMMAcorrection) { texcolor.xyz *= texcolor.xyz ;};

    // Lerp between HCpreviewRGB and DiffuseColor based on hcweight
    float3 out_color = texcolor.xyz ;//lerp( diffuseColor.rgb, HCpreviewRGB.rgb * diffuseColor.rgb , SPMcolor.b);



    float3 actualHC = lerp( float3(1,1,1) , HCpreviewRGB.xyz , spm.z) ;
    if (HCenhance) { actualHC *= actualHC ;}; //HC enhance density and saturation
    out_color.xyz *= actualHC ; 

    float3 tempglow = (GLOWcolor.xyz + GLOWcolor.w * HCpreviewRGB.xyz) * spm.y *2 ;
    if (HCenhance) { tempglow *= tempglow ;};
    out_color.xyz += tempglow ; //glow!

    // Alpha test: Discard pixels with alpha below a threshold
    clip (AlphaTestEnable && texcolor.a < 0.5);

    return float4(out_color.xyz , 1.0);  // or return float4(finalColor, finalColor.a);
}


technique MainTechnique
{
    pass Pass1
    {
        vertexShader = compile vs_3_0 VS_Main();
        pixelShader = compile ps_3_0 PS_Main();
    }
}
