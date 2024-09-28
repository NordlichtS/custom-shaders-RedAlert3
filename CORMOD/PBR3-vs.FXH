
//#include "PBR1-constants.FXH"
#include "PBR2-functions.FXH"


//standard structures =================

//高画质下VS输出 都用这个数组结构 （但PS输入最好不要用）
struct VS_H_output
{
    float4 Position : POSITION;   //VS一定要输出的clip space渲染坐标
    float4 VertexColor : COLOR0;  //顶点颜色
    float4 MainTexUV  : TEXCOORD0; //XY是主帖图UV,ZW是建筑损伤图UV
    float3 ShadowPROJ : TEXCOORD1; //阴影空间投影
    float4 FogCloudUV : TEXCOORD2; //迷雾和云的UV
    float3 WorldP : TEXCOORD3;  //世界空间位置
    float3 WorldN : TEXCOORD4_centroid; //世界法线Z
    float3 WorldT : TEXCOORD5_centroid; //世界切线Y
    float3 WorldB : TEXCOORD6_centroid; //世界切线X
};
//如果PS不接受position或者需要别的变量比如VPOS，就在PS文件里新建一个结构
//另外，_centroid modifier会导致贴图采样时gradient不准确，此处影响天空盒，可能得删了
//好吧其实法线图也影响，不用删了+


#ifdef USE_TANGENT_FRAME //macro条件编译 是否启用切线框架（支持法线图）
//这里是vs的切线框架计算 或ps的nrm采样
#endif

struct VS_H_noskin_input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 tangent : TANGENT;
    float4 binormal : BINORMAL;
    float4 texcoord : TEXCOORD;
    float4 color : COLOR;
};

VS_H_output  VS_H_noskin (VS_H_noskin_input  i)  //no bone skin
{
    VS_H_output o;

    float4 WorldPosition = float4(0,0,0,1);
    o.ShadowPROJ = o.FogCloudUV = 0 ;
    o.VertexColor = i.color ;  //顶点颜色，opacity 放ps里去吧

    // 从object space 到 world space===========

    // float4 WorldP = float4(mul(i.position , World), 1); //输入的W难道不是1吗
    o.WorldP = mul(float4(i.position.xyz, 1), World);
    o.WorldN = mul(i.normal.xyz, (float3x3)World);
    o.WorldT = mul(i.tangent.xyz, (float3x3)World);
    o.WorldB = mul(i.binormal.xyz, (float3x3)World);

    WorldPosition.xyz = o.WorldP ; //世界坐标
    //以上要换成骨骼相关的代码，以下保留======

    o.MainTexUV = i.texcoord ; //直接转存贴图UV
    if(HasWarfog) { o.FogCloudUV.xy = getWarfogUV( WorldPosition) ;};
    if(HasCloud)  { o.FogCloudUV.zw = getCloudUV ( WorldPosition) ;};
    if(HasShadow) { o.ShadowPROJ = getShadowMapUV( WorldPosition) ;};

    o.Position = mul(WorldPosition, ViewProjection); //给rasterizer的clip space坐标

    return o;
};

struct VS_H_hardskin_input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 tangent : TANGENT;
    float4 binormal : BINORMAL;
    float4 blendindices : BLENDINDICES;
    float4 texcoord : TEXCOORD;
    float4 color : COLOR;
};

VS_H_output  VS_H_hardskin (VS_H_hardskin_input  i)  //1 bone skin
{
    VS_H_output o;

    float4 WorldPosition = float4(0,0,0,1);
    o.ShadowPROJ = o.FogCloudUV = 0 ;
    o.VertexColor = i.color ;  

    // 从object space 到 world space===========

    //我是不是应该用  D3DCOLORtoUBYTE4 或者 trunc 或者 floor 或者 (int)
    //但 HLSL 支持直接用 float 当作array序号去查
    float4 This_Quaternion   = WorldBones[i.blendindices.x * 2 ];
    float4 This_offset_alpha = WorldBones[i.blendindices.x * 2 + 1];

    o.WorldP = Quaternion_R( This_Quaternion , i.position.xyz) + This_offset_alpha.xyz ;
    o.WorldN = Quaternion_R( This_Quaternion , i.normal.xyz);
    o.WorldT = Quaternion_R( This_Quaternion , i.tangent.xyz);
    o.WorldB = Quaternion_R( This_Quaternion , i.binormal.xyz);
    o.VertexColor.w *= This_offset_alpha.w ; //顶点颜色乘以骨骼透明度

    //以上要换成双骨骼软绑定相关的代码，以下保留======

    WorldPosition.xyz = o.WorldP  ; //四维世界坐标
    o.MainTexUV = i.texcoord ; //直接转存贴图UV
    if(HasWarfog) { o.FogCloudUV.xy = getWarfogUV( WorldPosition) ;};
    if(HasCloud)  { o.FogCloudUV.zw = getCloudUV ( WorldPosition) ;};
    if(HasShadow) { o.ShadowPROJ = getShadowMapUV( WorldPosition) ;};

    o.Position = mul(WorldPosition, ViewProjection); //给rasterizer的clip space坐标

    return o;
};


struct VS_H_softskin_input
{
    float4 blendindices : BLENDINDICES;
    float4 blendweight : BLENDWEIGHT;
    float4 position0 : POSITION0;
    float4 position1 : POSITION1;
    float4 normal0 : NORMAL0;
    float4 normal1 : NORMAL1;
    float4 tangent0 : TANGENT0;
    float4 tangent1 : TANGENT1;
    float4 binormal0 : BINORMAL0;
    float4 binormal1 : BINORMAL1;
    float4 texcoord : TEXCOORD;
    float4 color : COLOR;
};



VS_H_output  VS_H_softskin (VS_H_softskin_input  i)  //2 bone skin, with tangentframe
{
    VS_H_output o;
    float4 WorldPosition = float4(0,0,0,1);
    o.ShadowPROJ = o.FogCloudUV = 0 ;
    o.VertexColor = i.color ;  

    //先算第一骨骼
    float4 This_Quaternion   = WorldBones[i.blendindices.x * 2];
    float4 This_offset_alpha = WorldBones[i.blendindices.x * 2 + 1];
    //     this                        this             .x         0.       this
    float3 this_WorldP = Quaternion_R( This_Quaternion , i.position0.xyz) + This_offset_alpha.xyz ;
    float3 this_WorldN = Quaternion_R( This_Quaternion , i.normal0.xyz);
    float3 this_WorldT = Quaternion_R( This_Quaternion , i.tangent0.xyz);
    float3 this_WorldB = Quaternion_R( This_Quaternion , i.binormal0.xyz);

    /*
    // 不需要第二骨骼时，直接存第一骨骼的变换结果
    o.WorldP = this_WorldP ; o.WorldN = this_WorldN ;
    o.WorldT = this_WorldT ; o.WorldB = this_WorldB ;
    o.VertexColor.w *= This_offset_alpha.w ;
    //如果检查到权重可以启用第二骨骼
    if(i.blendweight.y > 0) 
    */

    float4 That_Quaternion   = WorldBones[i.blendindices.y * 2 ];
    float4 That_offset_alpha = WorldBones[i.blendindices.y * 2 + 1];
    //     that                        that             .y         1.       that
    float3 that_WorldP = Quaternion_R( That_Quaternion , i.position1.xyz) + That_offset_alpha.xyz ;
    float3 that_WorldN = Quaternion_R( That_Quaternion , i.normal1.xyz);
    float3 that_WorldT = Quaternion_R( That_Quaternion , i.tangent1.xyz);
    float3 that_WorldB = Quaternion_R( That_Quaternion , i.binormal1.xyz);
    //混合结果，lerpw越大越靠近第一骨骼，所以左 that 右 this
    o.WorldP = lerp( that_WorldP , this_WorldP , i.blendweight.x) ;
    o.WorldN = lerp( that_WorldN , this_WorldN , i.blendweight.x) ;
    o.WorldT = lerp( that_WorldT , this_WorldT , i.blendweight.x) ;
    o.WorldB = lerp( that_WorldB , this_WorldB , i.blendweight.x) ;
    o.VertexColor.w *= lerp(That_offset_alpha.w , This_offset_alpha.w , i.blendweight.x) ; 
    o.WorldN = normalize(o.WorldN); //插值后向量会变短要拉回来

    //以上是物体到世界空间相关的代码，以下保留======

    WorldPosition.xyz = o.WorldP  ; //四维世界坐标
    o.MainTexUV = i.texcoord ; //直接转存贴图UV
    if(HasWarfog) { o.FogCloudUV.xy = getWarfogUV( WorldPosition) ;};
    if(HasCloud)  { o.FogCloudUV.zw = getCloudUV ( WorldPosition) ;};
    if(HasShadow) { o.ShadowPROJ = getShadowMapUV( WorldPosition) ;};

    o.Position = mul(WorldPosition, ViewProjection); //给rasterizer的clip space坐标
    return o;
};



//下面的是多用途VS实验型，可以根据全局constant自动开关第二骨骼和切线框架，或许能优化（或许不能,IF太多了）
VS_H_output  VS_H_skincomplex (VS_H_softskin_input  i)  //1-2 bone skin, with or no tangentframe
{
    VS_H_output o;
    float4 WorldPosition = float4(0,0,0,1);
    o.ShadowPROJ = o.FogCloudUV = 0 ;
    o.VertexColor = i.color ;  
    float3 that_WorldT , that_WorldB , this_WorldT , this_WorldB ;
    this_WorldT = this_WorldB = that_WorldT = that_WorldB = 0 ; //initialize for safety

    //int2 BoneIndex = i.blendindices.xy * 2; 
    bool use_second_bone = bool(NumJointsPerVertex > 1) && bool(i.blendweight.y > 0);

    //先算第一骨骼
    float4 This_Quaternion   = WorldBones[i.blendindices.x * 2];
    float4 This_offset_alpha = WorldBones[i.blendindices.x * 2 + 1];

    float3 this_WorldP = Quaternion_R( This_Quaternion , i.position0.xyz) + This_offset_alpha.xyz ;
    float3 this_WorldN = Quaternion_R( This_Quaternion , i.normal0.xyz);
    o.WorldP = this_WorldP ;  
    o.WorldN = this_WorldN ;
    o.VertexColor.w = This_offset_alpha.w ;
    if(tangent_xy_multiply != 0) { //启用切线框架
        this_WorldT = Quaternion_R( This_Quaternion , i.tangent0.xyz);
        this_WorldB = Quaternion_R( This_Quaternion , i.binormal0.xyz);
        o.WorldT = this_WorldT ;  
        o.WorldB = this_WorldB ;  
    };

    //如果检查到权重可以启用第二骨骼
    if(use_second_bone) 
    {
    float4 That_Quaternion   = WorldBones[i.blendindices.y * 2 ];
    float4 That_offset_alpha = WorldBones[i.blendindices.y * 2 + 1];
    float3 that_WorldP = Quaternion_R( That_Quaternion , i.position1.xyz) + That_offset_alpha.xyz ;
    float3 that_WorldN = Quaternion_R( That_Quaternion , i.normal1.xyz);
    o.WorldP = lerp( that_WorldP , this_WorldP , i.blendweight.x) ;
    o.WorldN = lerp( that_WorldN , this_WorldN , i.blendweight.x) ;
    o.VertexColor.w = lerp(That_offset_alpha.w , This_offset_alpha.w , i.blendweight.x) ; 
    if(tangent_xy_multiply != 0) { //启用切线框架
        that_WorldT = Quaternion_R( That_Quaternion , i.tangent1.xyz);
        that_WorldB = Quaternion_R( That_Quaternion , i.binormal1.xyz);
        o.WorldT = lerp( that_WorldT , this_WorldT , i.blendweight.x) ;
        o.WorldB = lerp( that_WorldB , this_WorldB , i.blendweight.x) ;
    };

    };
    //以上是物体到世界空间相关的代码，以下保留======

    WorldPosition.xyz = o.WorldP  ; //四维世界坐标
    o.MainTexUV = i.texcoord ; //直接转存贴图UV
    if(HasWarfog) { o.FogCloudUV.xy = getWarfogUV( WorldPosition) ;};
    if(HasCloud)  { o.FogCloudUV.zw = getCloudUV ( WorldPosition) ;};
    if(HasShadow) { o.ShadowPROJ = getShadowMapUV( WorldPosition) ;};

    o.Position = mul(WorldPosition, ViewProjection); //给rasterizer的clip space坐标
    return o;
};  //以上这个VS是实验性代码模板，我也不知道会有什么效果，套了两层if 有可能负优化也说不定

#if defined(_3DSMAX_)

#endif


//=============================================



// 不启用切线空间的VS，可以用作中低画质的
// 但无法线图的高画质或许并不能用这个output，semantic对不上
// 说不定能用？编译一个试试
struct VS_notgt_output  //
{
    float4 Position : POSITION;   //VS一定要输出的clip space渲染坐标
    float4 VertexColor : COLOR0;  //顶点颜色
    float4 MainTexUV  : TEXCOORD0; //XY是主帖图UV,ZW是建筑损伤图UV
    float3 ShadowPROJ : TEXCOORD1; //阴影空间投影
    float4 FogCloudUV : TEXCOORD2; //迷雾和云的UV
    float3 WorldP : TEXCOORD3;  //世界空间位置    
    float3 WorldN : TEXCOORD4;  //_centroid; //世界法线
};


