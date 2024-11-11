
//#include "PBR1-constants.FXH"
#include "PBR2-functions.FXH"


//standard structures =================






//高画质下VS输出 都用这个数组结构 （但PS输入最好不要直接用）
struct VS_H_output
{
    float4 Position : POSITION;   //VS一定要输出的clip space渲染坐标
    float4 VertexColor : COLOR0;  //顶点颜色
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
#ifdef _3DSMAX_ 

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
VS_H_output VSforMAX(VS_3dsmax_input i)  
{ 
    VS_H_output  o;

    float4 WorldPosition = float4(0,0,0,1);
    o.ShadowPROJ = o.FogCloudUV = 0 ;
    o.VertexColor = i.color ;  //顶点颜色，opacity 放ps里去吧

    float3 MAXtangent = i.tangent.xyz ;
    float3 MAXbinormal = i.binormal.xyz ;

    if(0){  //exchange max tangent and binormal
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
    o.VertexColor = i.color ;  //顶点颜色，opacity 放ps里去吧

    // 从object space 到 world space===========

    o.WorldP = mul(float4(i.position.xyz, 1), World);
    o.WorldN = mul(i.normal.xyz, (float3x3)World);
    o.WorldT = mul(i.tangent.xyz, (float3x3)World);
    o.WorldB = mul(i.binormal.xyz, (float3x3)World);
    //以上要换成骨骼相关的代码，以下保留======

    WorldPosition.xyz = o.WorldP ; //世界坐标
    o.MainTexUV = float4(i.texcoord.xy , i.texcoordNEW.xy) ; //直接转存贴图UV
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
    o.MainTexUV = float4(i.texcoord.xy , i.texcoordNEW.xy) ; //直接转存贴图UV
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

    int2 BoneIndex = floor(i.blendindices.xy * 2 );
    //先算第一骨骼
    float4 This_Quaternion   = WorldBones[BoneIndex.x];
    float4 This_offset_alpha = WorldBones[BoneIndex.x + 1];
    //     this                        this             .x         0.       this
    float3 this_WorldP = Quaternion_R( This_Quaternion , i.position0.xyz) + This_offset_alpha.xyz ;
    float3 this_WorldN = Quaternion_R( This_Quaternion , i.normal0.xyz);
    float3 this_WorldT = Quaternion_R( This_Quaternion , i.tangent0.xyz);
    float3 this_WorldB = Quaternion_R( This_Quaternion , i.binormal0.xyz);

    //第二骨骼
    float4 That_Quaternion   = WorldBones[BoneIndex.y ];
    float4 That_offset_alpha = WorldBones[BoneIndex.y + 1];
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
    o.MainTexUV = float4(i.texcoord.xy , i.texcoordNEW.xy) ; //直接转存贴图UV
    //if(HasShadow) 
    o.ShadowPROJ = getShadowMapUV( WorldPosition) ;
    o.FogCloudUV.xy = getWarfogUV( WorldPosition) ;
    o.FogCloudUV.zw = getCloudUV ( WorldPosition) ;

    o.Position = mul(WorldPosition, ViewProjection); //给rasterizer的clip space坐标
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
    float4 MainTexUV  : TEXCOORD0; //XY是主帖图UV,ZW是建筑损伤图UV
    float3 ShadowPROJ : TEXCOORD1; //XYZ阴影空间投影, （W 是顶点阴影的阳光？还是用Z存）
    float4 FogCloudUV : TEXCOORD2; //迷雾和云的UV
    float3 WorldP : TEXCOORD3;  //世界空间位置    
    float3 WorldN : TEXCOORD4_centroid; //世界法线
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

    // 从object space 到 world space===========
    o.WorldP = mul(float4(i.position.xyz, 1), World);
    o.WorldN = mul(i.normal.xyz, (float3x3)World);
    //以上要换成骨骼相关的代码，以下保留======

    WorldPosition.xyz = o.WorldP ; //世界坐标
    o.MainTexUV = float4(i.texcoord.xy , i.texcoordNEW.xy) ; //直接转存贴图UV
    o.FogCloudUV.xy = getWarfogUV( WorldPosition) ;
    //if(UseShadowAndCloud){     //高画质永远有云！
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

    // 从object space 到 world space===========
    float4 This_Quaternion   = WorldBones[i.blendindices.x * 2 ];
    float4 This_offset_alpha = WorldBones[i.blendindices.x * 2 + 1];

    o.WorldP = Quaternion_R( This_Quaternion , i.position.xyz) + This_offset_alpha.xyz ;
    o.WorldN = Quaternion_R( This_Quaternion , i.normal.xyz);
    o.VertexColor.w *= This_offset_alpha.w ; //顶点颜色乘以骨骼透明度
    //以上要换成双骨骼软绑定相关的代码，以下保留======

    WorldPosition.xyz = o.WorldP  ; //四维世界坐标
    o.MainTexUV = float4(i.texcoord.xy , i.texcoordNEW.xy) ; //直接转存贴图UV
    o.FogCloudUV.xy = getWarfogUV( WorldPosition) ;
    //if(UseShadowAndCloud){     //高画质永远有云！
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

    int2 BoneIndex = floor(i.blendindices.xy) * 2 ;
    //先算第一骨骼
    float4 This_Quaternion   = WorldBones[BoneIndex.x];
    float4 This_offset_alpha = WorldBones[BoneIndex.x + 1];
    float3 this_WorldP = Quaternion_R( This_Quaternion , i.position0.xyz) + This_offset_alpha.xyz ;
    float3 this_WorldN = Quaternion_R( This_Quaternion , i.normal0.xyz);
    //第二骨骼
    float4 That_Quaternion   = WorldBones[BoneIndex.y];
    float4 That_offset_alpha = WorldBones[BoneIndex.y + 1];
    float3 that_WorldP = Quaternion_R( That_Quaternion , i.position1.xyz) + That_offset_alpha.xyz ;
    float3 that_WorldN = Quaternion_R( That_Quaternion , i.normal1.xyz);
    //混合结果，lerpw越大越靠近第一骨骼，所以左 that 右 this
    o.WorldP = lerp( that_WorldP , this_WorldP , i.blendweight.x) ;
    o.WorldN = lerp( that_WorldN , this_WorldN , i.blendweight.x) ;
    o.VertexColor.w *= lerp(That_offset_alpha.w , This_offset_alpha.w , i.blendweight.x) ; 
    //o.WorldN = normalize(o.WorldN); //插值后向量会变短要拉回来

    //以上是物体到世界空间相关的代码，以下保留======

    WorldPosition.xyz = o.WorldP  ; //四维世界坐标
    o.MainTexUV = float4(i.texcoord.xy , i.texcoordNEW.xy) ; //直接转存贴图UV
    o.FogCloudUV.xy = getWarfogUV( WorldPosition) ;
    //if(UseShadowAndCloud){     //高画质永远有云！
    o.FogCloudUV.zw = getCloudUV ( WorldPosition) ;
    o.ShadowPROJ = getShadowMapUV( WorldPosition) ;
    
    o.Position = mul(WorldPosition, ViewProjection); //给rasterizer的clip space坐标
    return o;
};

//中低画质的PS ====================
struct PS_notgt_input
{
    //float4 Position : POSITION;   //VS一定要输出的clip space渲染坐标
    float4 VertexColor : COLOR0;  //顶点颜色
    float4 MainTexUV  : TEXCOORD0; //XY是主帖图UV,ZW是建筑损伤图UV
    float3 ShadowPROJ : TEXCOORD1; //XYZ阴影空间投影, W弃用
    float4 FogCloudUV : TEXCOORD2; //迷雾和云的UV
    float3 WorldP : TEXCOORD3;  //世界空间位置
    float3 WorldN : TEXCOORD4_centroid; //世界法线Z
};

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

//===========================================
//制造阴影图的  VS + PS
//===========================================

struct VS_ShadowMaker_output  //
{
    float4 Position : POSITION;   //VS一定要输出的clip space渲染坐标
    float  Sdepth : COLOR0;  //阴影空间里的深度
    float  Valpha : COLOR1;  //顶点alpha
    float4 MainTexUV  : TEXCOORD0; //XY是主帖图UV,ZW是建筑损伤图UV
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
    o.Valpha = i.color.w * OpacityOverride ;
    //以下是阴影空间投影
    o.Position = mul(WorldPosition, ViewProjection);
    o.Sdepth = o.Position.z / o.Position.w;

    return o ;
}

VS_ShadowMaker_output VS_ShadowMaker_11skin(VS_ShadowMaker_11skin_input i)
{
    VS_ShadowMaker_output  o;
    float4 WorldPosition = float4(0,0,0,1);
    o.MainTexUV = float4(i.texcoord.xy , i.texcoordNEW.xy) ;

    float4 This_Quaternion   = WorldBones[i.blendindices.x * 2 ];
    float4 This_offset_alpha = WorldBones[i.blendindices.x * 2 + 1];
    WorldPosition.xyz = Quaternion_R( This_Quaternion , i.position.xyz) + This_offset_alpha.xyz ;
    o.Valpha = This_offset_alpha.w ;
    //以下是阴影空间投影
    o.Position = mul(WorldPosition, ViewProjection);
    o.Sdepth = o.Position.z / o.Position.w;

    return o ;
}

VS_ShadowMaker_output VS_ShadowMaker_22skin(VS_ShadowMaker_22skin_input i)
{
    VS_ShadowMaker_output  o;
    float4 WorldPosition = float4(0,0,0,1);
    o.MainTexUV = float4(i.texcoord.xy , i.texcoordNEW.xy) ;

    int2 BoneIndex = floor(i.blendindices.xy * 2 );
    float4 This_Quaternion   = WorldBones[BoneIndex.x];
    float4 This_offset_alpha = WorldBones[BoneIndex.x + 1];
    float3 this_WorldP = Quaternion_R( This_Quaternion , i.position0.xyz) + This_offset_alpha.xyz ;
    float4 That_Quaternion   = WorldBones[BoneIndex.y];
    float4 That_offset_alpha = WorldBones[BoneIndex.y + 1];
    float3 that_WorldP = Quaternion_R( That_Quaternion , i.position1.xyz) + That_offset_alpha.xyz ;
    WorldPosition.xyz = lerp( that_WorldP , this_WorldP , i.blendweight.x) ;
    o.Valpha = lerp(That_offset_alpha.w , This_offset_alpha.w , i.blendweight.x) ; 
    //以下是阴影空间投影
    o.Position = mul(WorldPosition, ViewProjection);
    o.Sdepth = o.Position.z / o.Position.w;

    return o ;
}

//==阴影图VS结束，下面是阴影图PS  =============


// shadowmap ==============================

struct PS_ShadowMaker_input  //
{
    float  Sdepth : COLOR0;  //阴影空间里的深度
    float  Valpha : COLOR1;  //顶点alpha
    float4 MainTexUV  : TEXCOORD0; //XY是主帖图UV,ZW是建筑损伤图UV
};

float4 PS_ShadowMaker_Simple(PS_ShadowMaker_input i) : COLOR 
{  
  clip(i.Valpha - 0.5);
  return i.Sdepth ; 
}

float4 PS_ShadowMaker_AlphaTest(PS_ShadowMaker_input i) : COLOR 
{  
  float alpha = tex2D(DiffuseEasySampler , i.MainTexUV.xy).w ;
  alpha *= i.Valpha ;
  clip(alpha - 0.5);
  return i.Sdepth ; 
}

float4 PS_ShadowMaker_DamageTest(PS_ShadowMaker_input i) : COLOR 
{  
  float alpha0 = tex2D(DiffuseEasySampler, i.MainTexUV.xy).w ;
  float alpha1 = tex2D(DamagedEasySampler, i.MainTexUV.zw).w ;
  alpha0 *= lerp(1 , alpha1 , i.Valpha);
  clip(alpha0 - 0.5);
  return i.Sdepth ; 
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

    float3 this_WorldP = Quaternion_R( This_Quaternion , i.position0.xyz) + This_offset_alpha.xyz ;
    float3 this_WorldN = Quaternion_R( This_Quaternion , i.normal0.xyz);
    o.WorldP = this_WorldP ;  
    o.WorldN = this_WorldN ;
    o.VertexColor.w = This_offset_alpha.w ;
    if(tangent_xy_mult != 0) { //启用切线框架
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
    if(tangent_xy_mult != 0) { //启用切线框架
        that_WorldT = Quaternion_R( That_Quaternion , i.tangent1.xyz);
        that_WorldB = Quaternion_R( That_Quaternion , i.binormal1.xyz);
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


*/