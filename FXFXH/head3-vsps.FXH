
//#include "PBR1-constants.FXH"
#include "head2-functions.FXH"


//standard structures =================






//高画质下VS输出 都用这个数组结构 （但PS输入最好不要直接用）
struct VS_H_output
{
    float4 Position : POSITION;   //VS一定要输出的clip space渲染坐标
    float4 VertexColor : COLOR0;  //顶点颜色
    float3 CoordOBJ  : TEXCOORD7;   //物体或骨骼空间坐标， w= index
    //float4 CoordCLIP : TEXCOORD8;
    float4 MainTexUV  : TEXCOORD0; //XY是主帖图UV, ZW是建筑损伤图 (并没有反)
    float3 ShadowPROJ : TEXCOORD1; //XYZ阴影空间投影, W弃用
    float4 FogCloudUV : TEXCOORD2; //迷雾和云的UV
    float3 WorldP : TEXCOORD3;  //世界空间位置
    float3 WorldN : TEXCOORD4_centroid; //世界法线Z
    float3 WorldT : TEXCOORD5_centroid; //世界切线Y
    float3 WorldB : TEXCOORD6_centroid; //世界切线X

};
//如果PS不接受position或者需要别的变量比如VPOS，就在PS文件里新建一个结构
//另外，_centroid modifier会导致贴图采样时gradient不准确，此处影响天空盒，可能得删了
//好吧其实法线图也影响，不用删了+

//    o.texcoord.xy = i.texcoord.xy;
//    o.texcoord.zw = i.texcoord1.yx;
//    temp1 = tex2D(DamagedTextureSampler, i.texcoord.wz);


// MAX预览用的============================ 

struct VS_3dsmax_input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 tangent : TANGENT;
    float4 binormal : BINORMAL;
    float4 texcoord : TEXCOORD; 
    float4 texcoordNEW : TEXCOORD1 ;
    float4 color : COLOR;
};
#ifdef _3DSMAX_ 
VS_H_output VSforMAX(VS_3dsmax_input i)  
{ 
    VS_H_output  o;

    float4 WorldPosition = float4(0,0,0,1);
    o.ShadowPROJ = o.FogCloudUV = 0 ;
    o.VertexColor = i.color ;  //顶点颜色，opacity 放ps里去吧
    o.VertexColor.w = PV_vertexALPHA ; //!!!
    o.CoordOBJ.xyz = i.position.xyz; //o.CoordOBJ.w = -1;

    float3 MAXtangent = i.tangent.xyz ;
    float3 MAXbinormal = i.binormal.xyz ;

    if(1){  //exchange max tangent and binormal
    MAXtangent = i.binormal.xyz ;
    MAXbinormal = i.tangent.xyz ;  
    };

    // 从object space 到 world space===========

    WorldPosition = mul(i.position, MAXworld);
    o.WorldN = mul(i.normal.xyz, (float3x3)MAXworld);
    o.WorldT = mul(MAXtangent, (float3x3)MAXworld);
    o.WorldB = mul(MAXbinormal, (float3x3)MAXworld);
    
    o.WorldP = WorldPosition.xyz ; //世界坐标
    o.MainTexUV = float4(i.texcoord.xy , i.texcoordNEW.xy) ; //直接转存贴图UV
    o.Position = mul(i.position , MAXwvp); //给rasterizer的clip space坐标

    return o; 
};

#endif // 3dsmax end

//======================
// 下面是高画质有切线框架的

struct VS_H_00skin_input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 tangent : TANGENT;
    float4 binormal : BINORMAL;
    float4 texcoord : TEXCOORD; float4 texcoordNEW : TEXCOORD1 ;
    float4 color : COLOR;
};
VS_H_output  VS_H_00skin (VS_H_00skin_input  i)  //no bone skin
{
    VS_H_output o; //声明下输出数组的结构缩写

    float4 WorldPosition = float4(0,0,0,1);
    o.ShadowPROJ = o.FogCloudUV = 0 ;
    o.VertexColor = i.color ;  
    o.MainTexUV = float4(i.texcoord.xy , i.texcoordNEW.xy) ; //直接转存贴图UV
    o.CoordOBJ.xyz = i.position.xyz; //o.CoordOBJ.w = -1;


    // 从object space 到 world space===========

    //float3 offset = mul(float4(0,0,0,1) , World);
    o.WorldP = mul(float4(i.position.xyz, 1), World);
    o.WorldN = mul(i.normal.xyz, (float3x3)World);
    o.WorldT = mul(i.tangent.xyz, (float3x3)World);
    o.WorldB = mul(i.binormal.xyz, (float3x3)World);
    //以上要换成骨骼相关的代码，以下保留======

    WorldPosition.xyz = o.WorldP ; //世界坐标
    o.WorldN = normalize(o.WorldN);
    o.VertexColor.rgb = hp_getAccentLight(o.WorldN)/2;
    //if(HasShadow) 
    o.ShadowPROJ = getShadowMapUV( WorldPosition) ;
    o.FogCloudUV.xy = getWarfogUV( WorldPosition) ;
    o.FogCloudUV.zw = getCloudUV ( WorldPosition) ;

    o.Position = mul(WorldPosition, ViewProjection); //给rasterizer的clip space坐标

    return o;
};

struct VS_H_11skin_input
{
    float4 position : POSITION;
    float4 normal : NORMAL;
    float4 tangent : TANGENT;
    float4 binormal : BINORMAL;
    float4 blendindices : BLENDINDICES;
    float4 texcoord : TEXCOORD; float4 texcoordNEW : TEXCOORD1 ;
    float4 color : COLOR;
}; 
VS_H_output  VS_H_11skin (VS_H_11skin_input  i)  //1 bone skin
{
    VS_H_output o; //声明下输出数组的结构缩写

    float4 WorldPosition = float4(0,0,0,1);
    o.ShadowPROJ = o.FogCloudUV = 0 ;
    o.VertexColor = i.color ;  
    o.MainTexUV = float4(i.texcoord.xy , i.texcoordNEW.xy) ; //直接转存贴图UV
    o.CoordOBJ.xyz = i.position.xyz; //o.CoordOBJ.w = i.blendindices.x;


    // 从object space 到 world space===========

    //我是不是应该用  D3DCOLORtoUBYTE4 或者 trunc 或者 floor 或者 (int)
    //但 HLSL 支持直接用 float 当作array序号去查
    int BoneIndex = floor(i.blendindices.x * 2 );
    float3x3 bone3x3matrix = Quaternion2Matrix( WorldBones[BoneIndex] ) ;
    float4 bone_offset_alpha = WorldBones[BoneIndex + 1];
    o.VertexColor.w *= bone_offset_alpha.w ; //顶点颜色乘以骨骼透明度

    o.WorldP = mul(i.position.xyz, bone3x3matrix) + bone_offset_alpha.xyz ;
    o.WorldN = mul(i.normal.xyz, bone3x3matrix);
    o.WorldT = mul(i.tangent.xyz, bone3x3matrix);
    o.WorldB = mul(i.binormal.xyz, bone3x3matrix);

    /* 
        float4 This_Quaternion   = WorldBones[i.blendindices.x * 2 ];
        o.WorldP = QuaternionRotate( This_Quaternion , i.position.xyz) + This_offset_alpha.xyz ;
        o.WorldN = QuaternionRotate( This_Quaternion , i.normal.xyz);
        o.WorldT = QuaternionRotate( This_Quaternion , i.tangent.xyz);
        o.WorldB = QuaternionRotate( This_Quaternion , i.binormal.xyz);
    */

    //以上要换成双骨骼软绑定相关的代码，以下保留======

    WorldPosition.xyz = o.WorldP  ; //四维世界坐标
    o.WorldN = normalize(o.WorldN);
    o.VertexColor.rgb = hp_getAccentLight(o.WorldN)/2;
    //if(HasShadow) 
    o.ShadowPROJ = getShadowMapUV( WorldPosition) ;
    o.FogCloudUV.xy = getWarfogUV( WorldPosition) ;
    o.FogCloudUV.zw = getCloudUV ( WorldPosition) ;

    o.Position = mul(WorldPosition, ViewProjection); //给rasterizer的clip space坐标

    return o;
};


struct VS_H_22skin_input
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
    float4 texcoord : TEXCOORD; float4 texcoordNEW : TEXCOORD1 ;
    float4 color : COLOR;
};

VS_H_output  VS_H_22skin (VS_H_22skin_input  i)  //2 bone skin, with tangentframe
{
    VS_H_output o; //声明下输出数组的结构缩写

    float4 WorldPosition = float4(0,0,0,1);
    o.ShadowPROJ = o.FogCloudUV = 0 ;
    o.VertexColor = i.color ;  
    o.MainTexUV = float4(i.texcoord.xy , i.texcoordNEW.xy) ; //直接转存贴图UV


    int2 BoneIndex = floor(i.blendindices.xy * 2)  ;

    float3x3 bone_matrix_0 = Quaternion2Matrix( WorldBones[BoneIndex.x] ) ;
    float3x3 bone_matrix_1 = Quaternion2Matrix( WorldBones[BoneIndex.y] ) ;
    float4 bone_offset_alpha_0 = WorldBones[BoneIndex.x + 1];
    float4 bone_offset_alpha_1 = WorldBones[BoneIndex.y + 1];

    float3 worldP0 = mul(i.position0.xyz, bone_matrix_0) + bone_offset_alpha_0.xyz ;
    float3 worldP1 = mul(i.position1.xyz, bone_matrix_1) + bone_offset_alpha_1.xyz ;
    float3 worldN0 = mul(i.normal0.xyz, bone_matrix_0) ;
    float3 worldN1 = mul(i.normal1.xyz, bone_matrix_1) ;
    float3 worldT0 = mul(i.tangent0.xyz, bone_matrix_0) ;
    float3 worldT1 = mul(i.tangent1.xyz, bone_matrix_1) ;
    float3 worldB0 = mul(i.binormal0.xyz, bone_matrix_0) ;
    float3 worldB1 = mul(i.binormal1.xyz, bone_matrix_1) ;

    o.WorldP = lerp( worldP1 , worldP0 , i.blendweight.x) ;
    o.WorldN = lerp( worldN1 , worldN0 , i.blendweight.x) ;
    o.WorldT = lerp( worldT1 , worldT0 , i.blendweight.x) ;
    o.WorldB = lerp( worldB1 , worldB0 , i.blendweight.x) ;
    o.VertexColor.w *= lerp(bone_offset_alpha_1.w , bone_offset_alpha_0.w , i.blendweight.x) ; 
    //o.WorldN = normalize(o.WorldN);

    //以上是物体到世界空间相关的代码，以下保留======

    WorldPosition.xyz = o.WorldP  ; //四维世界坐标
    o.WorldN = normalize(o.WorldN);
    o.VertexColor.rgb = hp_getAccentLight(o.WorldN)/2;
    o.ShadowPROJ = getShadowMapUV( WorldPosition) ;
    o.FogCloudUV.xy = getWarfogUV( WorldPosition) ;
    o.FogCloudUV.zw = getCloudUV ( WorldPosition) ;

    o.Position = mul(WorldPosition, ViewProjection); //给rasterizer的clip space坐标
    o.CoordOBJ.xyz = WorldPosition.xyz - WorldBones[1].xyz ; //o.CoordOBJ.w = -1;

    return o;
};


//高画质的 PS 在每个technique自己里面


#if defined(_3DSMAX_)

#endif


//=============================================



// 不启用切线空间的VS，可以用作步兵的？
// 但无法线图的高画质或许并不能用这个output，semantic对不上
// 说不定能用？编译一个试试
struct VS_notgt_output  //
{
    float4 Position : POSITION;   //VS一定要输出的clip space渲染坐标
    float4 VertexColor : COLOR0;  //顶点颜色 
    float3 CoordOBJ  : COLOR1;
    //float4 CoordCLIP : COLOR2;
    float4 MainTexUV  : TEXCOORD0; //XY是主帖图UV,ZW是建筑损伤图UV
    float3 ShadowPROJ : TEXCOORD1; //XYZ阴影空间投影, （W 是顶点阴影的阳光？还是用Z存）
    float4 FogCloudUV : TEXCOORD2; //迷雾和云的UV
    float3 WorldP : TEXCOORD3;  //世界空间位置    
    float3 WorldN : TEXCOORD4;//_centroid; //世界法线

};

//下面是没有切线空间的高画质VS。用uniform切换要不要阴影和云。
//步兵可以用，车辆也行


struct VS_00skin_notgt_input
{
    float4 position : POSITION;
    float4 normal : NORMAL;

    float4 texcoord : TEXCOORD; 
    float4 texcoordNEW : TEXCOORD1 ;
    float4 color : COLOR;
};

struct VS_11skin_notgt_input
{
    float4 position : POSITION;
    float4 normal : NORMAL;

    float4 blendindices : BLENDINDICES;
    float4 texcoord : TEXCOORD; 
    float4 texcoordNEW : TEXCOORD1 ;
    float4 color : COLOR;
}; 

struct VS_22skin_notgt_input
{
    float4 blendindices : BLENDINDICES;
    float4 blendweight : BLENDWEIGHT;
    float4 position0 : POSITION0;
    float4 position1 : POSITION1;
    float4 normal0 : NORMAL0;
    float4 normal1 : NORMAL1;

    float4 texcoord : TEXCOORD; 
    float4 texcoordNEW : TEXCOORD1 ;
    float4 color : COLOR;
};


VS_notgt_output  VS_L_00skin (VS_00skin_notgt_input  i)//, uniform bool UseShadowAndCloud )  //用这个切换要不要影子和云
{
    VS_notgt_output o; //声明下输出数组的结构缩写

    float4 WorldPosition = float4(0,0,0,1);
    o.ShadowPROJ = o.FogCloudUV = 0 ;
    o.VertexColor = i.color ;  //顶点颜色，opacity 放ps里去吧
    o.CoordOBJ.xyz = i.position.xyz; //o.CoordOBJ.w = i.blendindices.x;
    o.MainTexUV = float4(i.texcoord.xy , i.texcoordNEW.xy) ; //直接转存贴图UV

    // 从object space 到 world space===========
    o.WorldP = mul(float4(i.position.xyz, 1), World);
    o.WorldN = mul(i.normal.xyz, (float3x3)World);
    //以上要换成骨骼相关的代码，以下保留======

    WorldPosition.xyz = o.WorldP ; //世界坐标
    o.WorldN = normalize(o.WorldN);
    o.VertexColor.rgb = hp_getAccentLight(o.WorldN)/2;
    o.FogCloudUV.xy = getWarfogUV( WorldPosition) ;
    o.FogCloudUV.zw = getCloudUV ( WorldPosition) ;
    o.ShadowPROJ = getShadowMapUV( WorldPosition) ;
    
    o.Position = mul(WorldPosition, ViewProjection); //给rasterizer的clip space坐标

    return o;
};

VS_notgt_output  VS_L_11skin (VS_11skin_notgt_input  i)//, uniform bool UseShadowAndCloud)  
{
    VS_notgt_output o; //声明下输出数组的结构缩写

    float4 WorldPosition = float4(0,0,0,1);
    o.ShadowPROJ = o.FogCloudUV = 0 ;
    o.VertexColor = i.color ;  
    o.CoordOBJ.xyz = i.position.xyz; //o.CoordOBJ.w = i.blendindices.x;
    o.MainTexUV = float4(i.texcoord.xy , i.texcoordNEW.xy) ; //直接转存贴图UV

    // 从object space 到 world space===========
    int BoneIndex = floor(i.blendindices.x * 2)  ;

    float4 bone_Quaternion   = WorldBones[BoneIndex.x];
    float4 bone_offset_alpha = WorldBones[BoneIndex.x + 1];

    //shrink vertex pos here 
    float bonescale = 1 ;
    #ifdef BONE_ALPHA_SHRINK
    bonescale = bone_offset_alpha.w ;
    #endif

    o.WorldP = QuaternionRotate( bone_Quaternion , (i.position.xyz * bonescale)) + bone_offset_alpha.xyz ;
    o.WorldN = QuaternionRotate( bone_Quaternion , i.normal.xyz);

    //以上要换成双骨骼软绑定相关的代码，以下保留======

    WorldPosition.xyz = o.WorldP  ; //四维世界坐标
    o.WorldN = normalize(o.WorldN);
    o.VertexColor.rgb = hp_getAccentLight(o.WorldN)/2;
    o.FogCloudUV.xy = getWarfogUV( WorldPosition) ;
    o.FogCloudUV.zw = getCloudUV ( WorldPosition) ;
    o.ShadowPROJ = getShadowMapUV( WorldPosition) ;
    
    o.Position = mul(WorldPosition, ViewProjection); //给rasterizer的clip space坐标

    return o;
};

VS_notgt_output  VS_L_22skin (VS_22skin_notgt_input  i)//, uniform bool UseShadowAndCloud)  
{
    VS_notgt_output o; //声明下输出数组的结构缩写

    float4 WorldPosition = float4(0,0,0,1);
    o.ShadowPROJ = o.FogCloudUV = 0 ;
    o.VertexColor = i.color ;  
    o.MainTexUV = float4(i.texcoord.xy , i.texcoordNEW.xy) ; //直接转存贴图UV

    int2 BoneIndex = floor(i.blendindices.xy * 2)  ;

    /*
        // 一个四元数旋转似乎是8个指令，而制造矩阵至少9个，矩阵乘法3个
        float3x3 bone_matrix_0 = Quaternion2Matrix( WorldBones[BoneIndex.x] ) ;
        float3x3 bone_matrix_1 = Quaternion2Matrix( WorldBones[BoneIndex.y] ) ;
        float4 bone_offset_alpha_0 = WorldBones[BoneIndex.x + 1];
        float4 bone_offset_alpha_1 = WorldBones[BoneIndex.y + 1];
        float3 worldP0 = mul(i.position0.xyz, bone_matrix_0) + bone_offset_alpha_0.xyz ;
        float3 worldP1 = mul(i.position1.xyz, bone_matrix_1) + bone_offset_alpha_1.xyz ;
        float3 worldN0 = mul(i.normal0.xyz, bone_matrix_0) ;
        float3 worldN1 = mul(i.normal1.xyz, bone_matrix_1) ;
    */

    float4 bone_Quaternion_0   = WorldBones[BoneIndex.x];
    float4 bone_Quaternion_1   = WorldBones[BoneIndex.y];
    float4 bone_offset_alpha_0 = WorldBones[BoneIndex.x + 1];
    float4 bone_offset_alpha_1 = WorldBones[BoneIndex.y + 1];

    //shrink vertex pos here 
    float2 bonescale = 1 ;
    #ifdef BONE_ALPHA_SHRINK
    bonescale = float2(bone_offset_alpha_0.w , bone_offset_alpha_1.w ) ;
    #endif

    float3 worldP0 = QuaternionRotate( bone_Quaternion_0 , (i.position0.xyz * bonescale.x)) + bone_offset_alpha_0.xyz ;
    float3 worldP1 = QuaternionRotate( bone_Quaternion_1 , (i.position1.xyz * bonescale.y)) + bone_offset_alpha_1.xyz ;
    float3 worldN0 = QuaternionRotate( bone_Quaternion_0 , i.normal0.xyz);
    float3 worldN1 = QuaternionRotate( bone_Quaternion_1 , i.normal1.xyz);

    o.WorldP = lerp( worldP1 , worldP0 , i.blendweight.x) ;
    o.WorldN = lerp( worldN1 , worldN0 , i.blendweight.x) ;
    o.VertexColor.w *= lerp(bone_offset_alpha_1.w , bone_offset_alpha_0.w , i.blendweight.x) ; 

    //以上是物体到世界空间相关的代码，以下保留======

    WorldPosition.xyz = o.WorldP  ; //四维世界坐标
    o.WorldN = normalize(o.WorldN);
    o.VertexColor.rgb = hp_getAccentLight(o.WorldN)/2;
    o.FogCloudUV.xy = getWarfogUV( WorldPosition) ;
    o.FogCloudUV.zw = getCloudUV ( WorldPosition) ;
    o.ShadowPROJ = getShadowMapUV( WorldPosition) ;

    o.CoordOBJ.xyz = WorldPosition.xyz - WorldBones[1].xyz ; //o.CoordOBJ.w = -1;
    
    o.Position = mul(WorldPosition, ViewProjection); //给rasterizer的clip space坐标
    return o;
};

//中低画质的PS ====================
struct PS_LOW_input
{
    float4 VertexColor : COLOR0;  //顶点颜色
    float3 CoordOBJ  : COLOR1; //物体空间
    float4 MainTexUV  : TEXCOORD0; //XY是主帖图UV
    float2 FogCloudUV : TEXCOORD2; //迷雾UV
    float3 WorldP : TEXCOORD3;  //世界空间位置
    float3 WorldN : TEXCOORD4;//_centroid; //世界法线Z
};


float4 PS_LOW_INFANTRY (PS_LOW_input i) : COLOR 
{
    float3 N = i.WorldN;
    float3 Lsun     = DirectionalLight[0].Direction.xyz ;
    float3 SUNcolor = DirectionalLight[0].Color.xyz ;
    float sun_tilt = dot(N, Lsun);
    float3 surfacediffuselight = (sun_tilt > 0)? SUNcolor : i.VertexColor.rgb ;

    float3 albedocolor = 1 ;
    float  alpha = 1 ;
    alpha = i.VertexColor.w ; //ALLOW_CLIP_VERTEX_ALPHA
    float  HCchannel = 0 ;

  #ifdef IS_BASIC_W3D_SHADER 
    float4 tmp0 = tex2D(Texture_0Sampler,  i.MainTexUV.xy );
    albedocolor = tmp0.xyz ;
    alpha = i.VertexColor.w ;
    HCchannel = tmp0.w ;
  #else 
    float4 dif = tex2D(DiffuseTextureSampler,  i.MainTexUV.xy );
    albedocolor = dif.xyz ;
    alpha = dif.w ;
    HCchannel = tex2D(SpecMapSampler, i.MainTexUV.xy).b ;
  #endif

  #ifndef FORBID_FACTION_COLOR
    float3 realHC = (HasRecolorColors)? RecolorColor : 1 ; ;
    albedocolor *= lerp(1, realHC, HCchannel) ;
  #endif

    float3 allcolors = 0;
    allcolors += surfacediffuselight + AmbientLightColor ;
    allcolors *= albedocolor ;
    allcolors *= tex2D(ShroudTextureSampler, i.FogCloudUV.xy).xyz ;
    allcolors *= TintColor ;

    return float4(allcolors.rgb ,  (OpacityOverride * alpha) );
};


//===========================================
//制造阴影图的  VS + PS
//===========================================

struct VS_ShadowMaker_output  //
{
    float4 Position : POSITION;   //VS一定要输出的clip space渲染坐标
    float  Valpha : COLOR1;  //顶点alpha
    float4 MainTexUV : TEXCOORD0; //XY是主帖图UV,ZW是建筑损伤图UV
    float4 ClipSpace : TEXCOORD1;  // PERSPECTIVE DIVISION IN PS
};


struct VS_ShadowMaker_00skin_input
{
    float4 position : POSITION;
    float4 texcoord : TEXCOORD; 
    float4 texcoordNEW : TEXCOORD1 ;
    float4 color : COLOR;
};

struct VS_ShadowMaker_11skin_input
{
    float4 position : POSITION;
    float4 blendindices : BLENDINDICES;
    float4 texcoord : TEXCOORD; 
    float4 texcoordNEW : TEXCOORD1 ;
    //float4 color : COLOR;
}; 

struct VS_ShadowMaker_22skin_input
{
    float4 blendindices : BLENDINDICES;
    float4 blendweight : BLENDWEIGHT;
    float4 position0 : POSITION0;
    float4 position1 : POSITION1;
    float4 texcoord : TEXCOORD; 
    float4 texcoordNEW : TEXCOORD1 ;
    //float4 color : COLOR;
};

VS_ShadowMaker_output VS_ShadowMaker_00skin(VS_ShadowMaker_00skin_input i)
{
    VS_ShadowMaker_output  o;
    float4 WorldPosition = float4(0,0,0,1);
    o.MainTexUV = float4(i.texcoord.xy , i.texcoordNEW.xy) ;

    WorldPosition.xyz = mul(float4(i.position.xyz, 1), World);
    o.Valpha = 1;//(OpacityOverride < 0.375)? 0 : 1 ;

    o.Position = mul(WorldPosition, ViewProjection);
    o.ClipSpace = o.Position ;
    //o.Sdepth = o.Position.z / o.Position.w;
    return o ;
}

VS_ShadowMaker_output VS_ShadowMaker_11skin(VS_ShadowMaker_11skin_input i)
{
    VS_ShadowMaker_output  o;
    float4 WorldPosition = float4(0,0,0,1);
    o.MainTexUV = float4(i.texcoord.xy , i.texcoordNEW.xy) ;

    float4 bone_Quaternion   = WorldBones[i.blendindices.x * 2 ];
    float4 bone_offset_alpha = WorldBones[i.blendindices.x * 2 + 1];
    float bonescale = 1 ;
    #ifdef BONE_ALPHA_SHRINK
    bonescale = bone_offset_alpha.w ;
    #endif
    WorldPosition.xyz = QuaternionRotate( bone_Quaternion , (i.position.xyz * bonescale)) + bone_offset_alpha.xyz ;
    o.Valpha = bone_offset_alpha.w;// * OpacityOverride ;
    //以下是阴影空间投影
    o.Position = mul(WorldPosition, ViewProjection);
    o.ClipSpace = o.Position ;
    //o.Sdepth = o.Position.z / o.Position.w;
    return o ;
}

VS_ShadowMaker_output VS_ShadowMaker_22skin(VS_ShadowMaker_22skin_input i)
{
    VS_ShadowMaker_output  o;
    float4 WorldPosition = float4(0,0,0,1);
    o.MainTexUV = float4(i.texcoord.xy , i.texcoordNEW.xy) ;

    int2 BoneIndex = floor(i.blendindices.xy * 2 );
    float4 bone_Quaternion_0   = WorldBones[BoneIndex.x];
    float4 bone_offset_alpha_0 = WorldBones[BoneIndex.x + 1];
    float4 bone_Quaternion_1   = WorldBones[BoneIndex.y];
    float4 bone_offset_alpha_1 = WorldBones[BoneIndex.y + 1];

    float2 bonescale = 1 ;
    #ifdef BONE_ALPHA_SHRINK
    bonescale = float2(bone_offset_alpha_0.w , bone_offset_alpha_1.w ) ;
    #endif

    float3 worldP0 = QuaternionRotate( bone_Quaternion_0 , (i.position0.xyz * bonescale.x)) + bone_offset_alpha_0.xyz ;
    float3 worldP1 = QuaternionRotate( bone_Quaternion_1 , (i.position1.xyz * bonescale.y)) + bone_offset_alpha_1.xyz ;
    WorldPosition.xyz = lerp( worldP1 , worldP0 , i.blendweight.x) ;
    o.Valpha = lerp(bone_offset_alpha_1.w , bone_offset_alpha_0.w , i.blendweight.x) ;//* OpacityOverride ; 
    //以下是阴影空间投影
    o.Position = mul(WorldPosition, ViewProjection);
    o.ClipSpace = o.Position ;
    //o.Sdepth = o.Position.z / o.Position.w;
    return o ;
}

//==阴影图VS结束，下面是阴影图PS  =============

float4 PS_ShadowMaker_NoAlphaTest(VS_ShadowMaker_output i) : COLOR 
{    return (i.ClipSpace.z / i.ClipSpace.w) ; }

#ifndef IS_BASIC_W3D_SHADER

float4 PS_ShadowMaker_AlphaTest(VS_ShadowMaker_output i) : COLOR 
{  
    float realalpha = 1 ;

    #ifdef ALLOW_CLIP_VERTEX_ALPHA
    realalpha *= i.Valpha;
    #endif

    #ifdef ALLOW_CLIP_TEXTURE_ALPHA
    realalpha *= tex2D(DiffuseEasySampler , i.MainTexUV.xy).w ;
    #endif

    #ifdef IS_BUILDNG
    float dmgalpha = tex2D(DamagedEasySampler , i.MainTexUV.zw).w ;
    dmgalpha = (i.Valpha < 0.375)? dmgalpha : 1;
    realalpha *= dmgalpha ;
    #endif

  #ifdef IS_NANO_BUILDUP
    realalpha = hp_nano_build(i.Valpha, i.MainTexUV.xy);
  #endif

    clip(realalpha - 0.375);
    return (i.ClipSpace.z / i.ClipSpace.w) ; 
}

#endif 

// 二次元描边=======================================
#ifdef _3DSMAX_ 
float4 VS_outline_3dsmax (VS_3dsmax_input  i) : POSITION 
{
    float3 ObjSpaceLine = i.position.xyz + i.normal.xyz ;
    //  物体空间到世界空间，再投影到clip space
    float4 ClipMesh = mul(float4(i.position.xyz , 1) , MAXwvp); 
    float4 ClipLine = mul(float4(ObjSpaceLine   , 1) , MAXwvp); 
    ClipMesh.xyz /= ClipMesh.w ;
    ClipLine.xyz /= ClipLine.w ;
    float2 outline = normalize(ClipLine.xy  - ClipMesh.xy )  ;
    ClipMesh.xy += outline / 128 ;
    ClipMesh.xyz *= ClipMesh.w ; //从NDC空间转回clip space

    return ClipMesh;
};
#endif

/*
    float2 outline = normalize(ClipLine - ClipMesh) * ClipMesh.w ;
    ClipMesh.xy += outline / 512 ;
*/

float4 VS_outline_00skin (VS_00skin_notgt_input  i) : POSITION 
{
    // 从object space 到 world space===========
    float3 WorldP = mul(float4(i.position.xyz, 1), World);
    float3 WorldN = mul(i.normal.xyz, (float3x3)World);
    //以上要换成骨骼相关的代码，以下保留======

    float3 WorldLine = WorldP + WorldN ;
    float4 ClipMesh = mul(float4(WorldP   , 1) , ViewProjection); 
    float4 ClipLine = mul(float4(WorldLine, 1) , ViewProjection); 
    ClipMesh.xyz /= ClipMesh.w ;
    ClipLine.xyz /= ClipLine.w ;
    float2 outline = normalize(ClipLine.xy  - ClipMesh.xy )  ;
    ClipMesh.xy += outline / 128 ;
    ClipMesh.xyz *= ClipMesh.w ;

    return ClipMesh;
};



float4 VS_outline_11skin (VS_11skin_notgt_input  i) : POSITION 
{
    // 从object space 到 world space===========
    float4 This_Quaternion   = WorldBones[i.blendindices.x * 2 ];
    float4 This_offset_alpha = WorldBones[i.blendindices.x * 2 + 1];
    float3 WorldP = QuaternionRotate( This_Quaternion , i.position.xyz) + This_offset_alpha.xyz ;
    float3 WorldN = QuaternionRotate( This_Quaternion , i.normal.xyz);
    //以上要换成双骨骼软绑定相关的代码，以下保留======

    float3 WorldLine = WorldP + WorldN ;
    float4 ClipMesh = mul(float4(WorldP   , 1) , ViewProjection); 
    float4 ClipLine = mul(float4(WorldLine, 1) , ViewProjection); 
    ClipMesh.xyz /= ClipMesh.w ;
    ClipLine.xyz /= ClipLine.w ;
    float2 outline = normalize(ClipLine.xy  - ClipMesh.xy )  ;
    ClipMesh.xy += outline / 128 ;
    ClipMesh.xyz *= ClipMesh.w ;

    return ClipMesh;
};


float4 VS_outline_22skin (VS_22skin_notgt_input  i) : POSITION 
{
    int2 BoneIndex = floor(i.blendindices.xy) * 2 ;
    //第一骨骼
    float4 This_Quaternion   = WorldBones[BoneIndex.x];
    float4 This_offset_alpha = WorldBones[BoneIndex.x + 1];
    float3 this_WorldP = QuaternionRotate( This_Quaternion , i.position0.xyz) + This_offset_alpha.xyz ;
    float3 this_WorldN = QuaternionRotate( This_Quaternion , i.normal0.xyz);
    //第二骨骼
    float4 That_Quaternion   = WorldBones[BoneIndex.y];
    float4 That_offset_alpha = WorldBones[BoneIndex.y + 1];
    float3 that_WorldP = QuaternionRotate( That_Quaternion , i.position1.xyz) + That_offset_alpha.xyz ;
    float3 that_WorldN = QuaternionRotate( That_Quaternion , i.normal1.xyz);
    //混合
    float3 WorldP = lerp( that_WorldP , this_WorldP , i.blendweight.x) ;
    float3 WorldN = lerp( that_WorldN , this_WorldN , i.blendweight.x) ;
    //o.WorldN = normalize(o.WorldN); //插值后向量会变短要拉回来

    float3 WorldLine = WorldP + WorldN ;
    float4 ClipMesh = mul(float4(WorldP   , 1) , ViewProjection); 
    float4 ClipLine = mul(float4(WorldLine, 1) , ViewProjection); 
    ClipMesh.xyz /= ClipMesh.w ;
    ClipLine.xyz /= ClipLine.w ;
    float2 outline = normalize(ClipLine.xy  - ClipMesh.xy )  ;
    ClipMesh.xy += outline / 128 ;
    ClipMesh.xyz *= ClipMesh.w ;

    return ClipMesh;
};

float4 PS_outline() : COLOR 
{
    float4 outlinecolor = float4(0,0,0,1);
    #ifndef FORBID_FACTION_COLOR
    outlinecolor.xyz = (HasRecolorColors)? RecolorColor : 0 ;
    #endif
    outlinecolor.w = 0.5 ;
    return outlinecolor ;
}


//==废弃代码==========================


/*
    // 不需要第二骨骼时，直接存第一骨骼的变换结果
    o.WorldP = this_WorldP ; o.WorldN = this_WorldN ;
    o.WorldT = this_WorldT ; o.WorldB = this_WorldB ;
    o.VertexColor.w *= This_offset_alpha.w ;
    //如果检查到权重可以启用第二骨骼
    if(i.blendweight.y > 0) 
*/

/*

//下面的是实验型，可以根据全局constant自动开关第二骨骼和切线框架（但是IF太多了）
VS_H_output  VS_H_skincomplex (VS_H_22skin_input  i)  //1-2 bone skin, with or no tangentframe
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

    float3 this_WorldP = QuaternionRotate( This_Quaternion , i.position0.xyz) + This_offset_alpha.xyz ;
    float3 this_WorldN = QuaternionRotate( This_Quaternion , i.normal0.xyz);
    o.WorldP = this_WorldP ;  
    o.WorldN = this_WorldN ;
    o.VertexColor.w = This_offset_alpha.w ;
    if(tangent_xy_mult != 0) { //启用切线框架
        this_WorldT = QuaternionRotate( This_Quaternion , i.tangent0.xyz);
        this_WorldB = QuaternionRotate( This_Quaternion , i.binormal0.xyz);
        o.WorldT = this_WorldT ;  
        o.WorldB = this_WorldB ;  
    };

    //如果检查到权重可以启用第二骨骼
    if(use_second_bone) 
    {
    float4 That_Quaternion   = WorldBones[i.blendindices.y * 2 ];
    float4 That_offset_alpha = WorldBones[i.blendindices.y * 2 + 1];
    float3 that_WorldP = QuaternionRotate( That_Quaternion , i.position1.xyz) + That_offset_alpha.xyz ;
    float3 that_WorldN = QuaternionRotate( That_Quaternion , i.normal1.xyz);
    o.WorldP = lerp( that_WorldP , this_WorldP , i.blendweight.x) ;
    o.WorldN = lerp( that_WorldN , this_WorldN , i.blendweight.x) ;
    o.VertexColor.w = lerp(That_offset_alpha.w , This_offset_alpha.w , i.blendweight.x) ; 
    if(tangent_xy_mult != 0) { //启用切线框架
        that_WorldT = QuaternionRotate( That_Quaternion , i.tangent1.xyz);
        that_WorldB = QuaternionRotate( That_Quaternion , i.binormal1.xyz);
        o.WorldT = lerp( that_WorldT , this_WorldT , i.blendweight.x) ;
        o.WorldB = lerp( that_WorldB , this_WorldB , i.blendweight.x) ;
    };

    };
    //以上是物体到世界空间相关的代码，以下保留======

    WorldPosition.xyz = o.WorldP  ; //四维世界坐标
    o.MainTexUV = float4(i.texcoord.xy , i.texcoordNEW.xy) ; //直接转存贴图UV
    if(HasWarfog) { o.FogCloudUV.xy = getWarfogUV( WorldPosition) ;};
    if(HasCloud)  { o.FogCloudUV.zw = getCloudUV ( WorldPosition) ;};
    if(HasShadow) { o.ShadowPROJ = getShadowMapUV( WorldPosition) ;};

    o.Position = mul(WorldPosition, ViewProjection); //给rasterizer的clip space坐标
    return o;
};  //以上这个VS是实验性代码模板，我也不知道会有什么效果，套了两层if 有可能负优化也说不定



float4 PS_Objects_Low(PS_notgt_input i, uniform bool UseShadowAndCloud) : COLOR 
{  
    //拿出主贴图
    float4 dif = tex2D(DiffuseTextureSampler,  i.MainTexUV.xy );
    float4 spm = tex2D(SpecMapSampler,         i.MainTexUV.xy );

    //初步整理下信息
    //if(AlphaTestEnable) { clip(dif.w - 0.5);  clip(i.VertexColor.w - 0.25); };    
    clip(dif.w - 0.5);  
    clip(i.VertexColor.w - 0.25);
    //force enable main texture alpha
    float  HCchannel = (HasRecolorColors)? spm.b : 0 ;
    dif.xyz *= lerp(1 , RecolorColor , HCchannel);

    bool ismetal = bool(spm.g > 0.25);
    float3 reflectSpectrum = max(dif.xyz , spm.xxx );
    float3 diffcolor = (ismetal)? 0 : dif.xyz ;
    float3 speccolor = (ismetal)? reflectSpectrum : spm.xxx ;

    //发光层，//原版，日冕，将军，这个会不一样
    float3 GLOWchannel = (ismetal)? dif.xyz : 0 ; 
    // (ismetal)? dif.xyz : 0 ; //将军
    // spm.w * dif.xyz ; //日冕



    //一些有用的向量
    float3 V = hp_ps_getViewVector(i.WorldP) ;
    float3 N = normalize(i.WorldN);
    float3 R = reflect(-V , N) ;
    float Fterm = saturate(1- dot(V, N));

    //sun
    float3 Lsun     = DirectionalLight[0].Direction ;
    float3 SUNcolor = DirectionalLight[0].Color ;
    float  sun_tilt  = dot(N,Lsun) ;
    SUNcolor *= (sun_tilt > 0)? 1 : 0 ;
    if(UseShadowAndCloud)
    {
    SUNcolor *= hp_invshadow_easy(i.ShadowPROJ);
    SUNcolor *= tex2D(CloudTextureSampler, i.FogCloudUV.zw);
    };
    float sun_specdist = saturate(dot(R, Lsun )) ;
    sun_specdist = pow(sun_specdist , 8);

    float3 sunALL = float3(0,0,0) ;  //阳光BRDF
    sunALL += diffcolor * sun_tilt  ;
    sunALL += speccolor * sun_specdist ;
    sunALL *= SUNcolor ;

    //ambient
    float3 ambientALL = float3(0,0,0) ; //环境光BRDF
    ambientALL += diffcolor ; 
    ambientALL += speccolor * Fterm * Fterm; 
    ambientALL *= AmbientLightColor ;

    float4 OUTCOLOR = i.VertexColor ;
    OUTCOLOR.w = dif.w * i.VertexColor.w ;
    OUTCOLOR.xyz = ambientALL + sunALL ;
    OUTCOLOR.xyz *= tex2D(ShroudTextureSampler, i.FogCloudUV.xy).x ;
    OUTCOLOR.xyz += GLOWchannel ;
    OUTCOLOR.xyz *= TintColor ;

    return OUTCOLOR ; 
}

// stealth vfx =======================

struct PS_VFX_input
{
    float2 vpos : VPOS ; //screen pixel 
    float4 VertexColor : COLOR0;  //顶点颜色
    float4 MainTexUV  : TEXCOORD0; //XY是主帖图UV,ZW是建筑损伤图UV
    //float3 ShadowPROJ : TEXCOORD1; //XYZ阴影空间投影, W弃用
    //float4 FogCloudUV : TEXCOORD2; //迷雾和云的UV
    float3 WorldP : TEXCOORD3;  //世界空间位置
    float3 WorldN : TEXCOORD4_centroid; //世界法线Z
};

float4 PS_vfx_stealth (PS_VFX_input i) : COLOR 
{
    float3 N = normalize(i.WorldN);
    float3 V = hp_ps_getViewVector(i.WorldP) ;

    float scanline = frac(i.vpos.y / 3);
    float EYEtilt = dot(N , V);
    EYEtilt = saturate(1- EYEtilt);
    EYEtilt *= (scanline < 0.25)? 1 : EYEtilt ; // pow(EYEtilt, 2)
    float3 hcmask = (HasRecolorColors)? RecolorColor : 1 ;
    hcmask *= EYEtilt * 0.75 ;

    float4 texcolor = 0 ;
    #ifdef IS_BASIC_W3D_SHADER
    texcolor = tex2D(Texture_0Sampler,  i.MainTexUV.xy );
    #else
    texcolor = tex2D(DiffuseTextureSampler,  i.MainTexUV.xy );
    clip(texcolor.w - 0.5);
    #endif
    texcolor.xyz *= TintColor * 0.5 ;

    float4 OUTCOLOR = 0 ;
    OUTCOLOR.xyz = hcmask + texcolor.xyz ;
    OUTCOLOR.w = OpacityOverride * i.VertexColor.w ;
    return OUTCOLOR ;
}

        //先算第一骨骼
        float4 This_Quaternion   = WorldBones[BoneIndex.x];
        float4 This_offset_alpha = WorldBones[BoneIndex.x + 1];
        float3 this_WorldP = QuaternionRotate( This_Quaternion , i.position0.xyz) + This_offset_alpha.xyz ;
        float3 this_WorldN = QuaternionRotate( This_Quaternion , i.normal0.xyz);
        //第二骨骼
        float4 That_Quaternion   = WorldBones[BoneIndex.y];
        float4 That_offset_alpha = WorldBones[BoneIndex.y + 1];
        float3 that_WorldP = QuaternionRotate( That_Quaternion , i.position1.xyz) + That_offset_alpha.xyz ;
        float3 that_WorldN = QuaternionRotate( That_Quaternion , i.normal1.xyz);
        //混合结果，lerpw越大越靠近第一骨骼，所以左 that 右 this
        o.WorldP = lerp( that_WorldP , this_WorldP , i.blendweight.x) ;
        o.WorldN = lerp( that_WorldN , this_WorldN , i.blendweight.x) ;
        o.VertexColor.w *= lerp(That_offset_alpha.w , This_offset_alpha.w , i.blendweight.x) ; 
        //o.WorldN = normalize(o.WorldN); //插值后向量会变短要拉回来



*/

    /*
        int2 BoneIndex = floor(i.blendindices.xy * 2 );
        //先算第一骨骼
        float4 This_Quaternion   = WorldBones[BoneIndex.x];
        float4 This_offset_alpha = WorldBones[BoneIndex.x + 1];
        //     this                        this             .x         0.       this
        float3 this_WorldP = QuaternionRotate( This_Quaternion , i.position0.xyz) + This_offset_alpha.xyz ;
        float3 this_WorldN = QuaternionRotate( This_Quaternion , i.normal0.xyz);
        float3 this_WorldT = QuaternionRotate( This_Quaternion , i.tangent0.xyz);
        float3 this_WorldB = QuaternionRotate( This_Quaternion , i.binormal0.xyz);

        //第二骨骼
        float4 That_Quaternion   = WorldBones[BoneIndex.y ];
        float4 That_offset_alpha = WorldBones[BoneIndex.y + 1];
        //     that                        that             .y         1.       that
        float3 that_WorldP = QuaternionRotate( That_Quaternion , i.position1.xyz) + That_offset_alpha.xyz ;
        float3 that_WorldN = QuaternionRotate( That_Quaternion , i.normal1.xyz);
        float3 that_WorldT = QuaternionRotate( That_Quaternion , i.tangent1.xyz);
        float3 that_WorldB = QuaternionRotate( That_Quaternion , i.binormal1.xyz);
        //混合结果，lerpw越大越靠近第一骨骼，所以左 that 右 this
        o.WorldP = lerp( that_WorldP , this_WorldP , i.blendweight.x) ;
        o.WorldN = lerp( that_WorldN , this_WorldN , i.blendweight.x) ;
        o.WorldT = lerp( that_WorldT , this_WorldT , i.blendweight.x) ;
        o.WorldB = lerp( that_WorldB , this_WorldB , i.blendweight.x) ;
        o.VertexColor.w *= lerp(That_offset_alpha.w , This_offset_alpha.w , i.blendweight.x) ; 
        o.WorldN = normalize(o.WorldN); //插值后向量会变短要拉回来
    */

/*





float4 PS_LOW_ANIME (PS_LOW_input i) : COLOR 
{
    float3 N = normalize(i.WorldN);
    float3 IV = normalize(i.WorldP - EyePosition);
    float3 R = reflect( IV, N);
    float3 Lsun     = DirectionalLight[0].Direction.xyz ;
    float3 SUNcolor = DirectionalLight[0].Color.xyz ;
    float3 accentlight = max(DirectionalLight[1].Color , DirectionalLight[2].Color);
    float sun_tilt = dot(N, Lsun);
    sun_tilt = saturate(sun_tilt *2 +0.5);
    float3 surfacediffuselight = lerp(accentlight, SUNcolor, sun_tilt) ;

    float3 albedocolor = 1 ;
    float  specchannel = 0 ; 
    float  HCchannel = 0 ;
    float  alpha = 1;
  #ifdef IS_BASIC_W3D_SHADER //but dont use this for infantry !
    float4 tmp0 = tex2D(Texture_0Sampler,  i.MainTexUV.xy );
    albedocolor = tmp0.xyz ;
    HCchannel = tmp0.w ;
  #else //above is placeholder, under is used object shader
    float4 dif = tex2D(DiffuseTextureSampler,  i.MainTexUV.xy );
    float4 spm = tex2D(SpecMapSampler,         i.MainTexUV.xy );
    albedocolor = dif.xyz ;
    alpha *= dif.w ;
    HCchannel = spm.z ;
    specchannel = spm.x + spm.y ;
  #endif
    HCchannel = (HasRecolorColors)? HCchannel : 0 ;
    albedocolor *= lerp(1, RecolorColor, HCchannel) ;

    surfacediffuselight *= albedocolor ;
    float specdist = dot(R, Lsun);
    specdist *= pow( specdist, 32);
    //dot(R, Lsun) *16 -16 + specchannel;
    //(dot(R, Lsun) -1 ) * 64 * (specchannel +1) + specchannel ; //over complicated 
    //    max( allcolors , (specdist * SUNcolor) ) ;

    float3 allcolors = 0;
    allcolors = lerp(surfacediffuselight, SUNcolor , saturate(specdist * specchannel)) ;
    allcolors += AmbientLightColor * albedocolor;

  #ifdef IS_BUILDNG
    //float dist2dmg = saturate( dot(i.CoordOBJ, i.CoordOBJ) /32 );
    float4 dmgtex = tex2D(DamagedTextureSampler , i.MainTexUV.zw);
    allcolors *= (i.VertexColor.w < 0.375)? dmgtex.xyz : 1 ;
    alpha *= dmgtex.w ;
  #else
    alpha *= i.VertexColor.w ;
  #endif

    allcolors *= tex2D(ShroudTextureSampler, i.FogCloudUV.xy).xyz ;
    allcolors *= TintColor ;

    return float4(allcolors.rgb , (alpha * OpacityOverride));
};

*/