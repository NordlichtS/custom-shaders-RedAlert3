
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
    float4 ShadowCS : TEXCOORD1; // 阴影的 CLIP SPACE坐标，像素里还得除
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
    o.ShadowCS = o.FogCloudUV = 0 ;
    o.VertexColor.rgb = PV_accentlight ;  //
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
    o.ShadowCS = mul(WorldPosition, ShadowMapWorldToShadow); ;
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

    //以上要换成双骨骼软绑定相关的代码，以下保留======

    WorldPosition.xyz = o.WorldP  ; //四维世界坐标
    o.WorldN = normalize(o.WorldN);
    o.VertexColor.rgb = hp_getAccentLight(o.WorldN)/2;
    //if(HasShadow) 
    o.ShadowCS = mul(WorldPosition, ShadowMapWorldToShadow); ;
    o.FogCloudUV.xy = getWarfogUV( WorldPosition) ;
    o.FogCloudUV.zw = getCloudUV ( WorldPosition) ;

    #ifdef SUPPORT_TREAD_SCROLLING
    o.MainTexUV.x += o.VertexColor.a ;
    o.VertexColor.a = 1 ;
    #endif

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
    o.ShadowCS = mul(WorldPosition, ShadowMapWorldToShadow); ;
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
    float4 ShadowCS : TEXCOORD1; //CLIP SPACE 影子，需要在PS里除
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
    o.ShadowCS = mul(WorldPosition, ShadowMapWorldToShadow); ;

    //#ifdef SUPPORT_TREAD_SCROLLING
    //o.MainTexUV.x += OpacityOverride ;
    //#endif
    
    o.Position = mul(WorldPosition, ViewProjection); //给rasterizer的clip space坐标

    return o;
};

VS_notgt_output  VS_L_11skin (VS_11skin_notgt_input  i)//, uniform bool UseShadowAndCloud)  
{
    VS_notgt_output o; //声明下输出数组的结构缩写

    float4 WorldPosition = float4(0,0,0,1);
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
    o.VertexColor.w = bone_offset_alpha.w ;
    o.FogCloudUV.xy = getWarfogUV( WorldPosition) ;
    o.FogCloudUV.zw = getCloudUV ( WorldPosition) ;
    o.ShadowCS = mul(WorldPosition, ShadowMapWorldToShadow); ;

    #ifdef SUPPORT_TREAD_SCROLLING
    o.MainTexUV.x += o.VertexColor.a ;
    o.VertexColor.a = 1 ;
    #endif
    
    o.Position = mul(WorldPosition, ViewProjection); //给rasterizer的clip space坐标

    return o;
};

VS_notgt_output  VS_L_22skin (VS_22skin_notgt_input  i)//, uniform bool UseShadowAndCloud)  
{
    VS_notgt_output o; //声明下输出数组的结构缩写

    float4 WorldPosition = float4(0,0,0,1);
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
    o.VertexColor.w = lerp(bone_offset_alpha_1.w , bone_offset_alpha_0.w , i.blendweight.x) ; 

    //以上是物体到世界空间相关的代码，以下保留======

    WorldPosition.xyz = o.WorldP  ; //四维世界坐标
    o.WorldN = normalize(o.WorldN);
    o.VertexColor.rgb = hp_getAccentLight(o.WorldN)/2;
    o.FogCloudUV.xy = getWarfogUV( WorldPosition) ;
    o.FogCloudUV.zw = getCloudUV ( WorldPosition) ;
    o.ShadowCS = mul(WorldPosition, ShadowMapWorldToShadow); ;

    o.CoordOBJ.xyz = WorldPosition.xyz - WorldBones[1].xyz ; //o.CoordOBJ.w = -1;
    
    o.Position = mul(WorldPosition, ViewProjection); //给rasterizer的clip space坐标
    return o;
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

VS_ShadowMaker_output VS_ShadowMaker_CLIPALL()
{   
    VS_ShadowMaker_output  o;
    o.Position = float4(2,2,2,1) ;
    o.ClipSpace = o.Position ;
    return o ;
}

//==阴影图VS结束，下面是阴影图PS  =============

float4 PS_ShadowMaker_NoAlphaTest(VS_ShadowMaker_output i) : COLOR 
{    return (i.ClipSpace.z / i.ClipSpace.w) ; }

#ifdef IS_OBJECT_BUILDING_SHADER

float4 PS_ShadowMaker_AlphaTest(VS_ShadowMaker_output i) : COLOR 
{  
    float extra_alpha = 1 ;

    #ifdef OPACITY_OVERRIDE_CLIP
    extra_alpha *= OpacityOverride ;
    #endif

    #ifdef ALLOW_CLIP_VERTEX_ALPHA
    extra_alpha *= i.Valpha;
    #endif

    #ifdef ALLOW_CLIP_TEXTURE_ALPHA
    extra_alpha *= tex2D(DiffuseEasySampler , i.MainTexUV.xy).w ;
    #endif

    #ifdef IS_BUILDNG
    float dmgalpha = tex2D(DamagedTextureSampler , i.MainTexUV.zw).w ;
    dmgalpha = (i.Valpha < 0.375)? dmgalpha : 1;
    extra_alpha *= dmgalpha ;
    #endif 

    #ifdef IS_NANO_BUILDUP
    extra_alpha *= hp_nano_build(i.Valpha, i.MainTexUV.xy).x;
    #endif

    clip(extra_alpha - 0.375);
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
