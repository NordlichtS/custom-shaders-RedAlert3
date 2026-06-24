

#include "head0-common.fxh"













// ==============================

float3x3 Quaternion2Matrix(float4 q)
{
    float xx = q.x * q.x,  yy = q.y * q.y,  zz = q.z * q.z;
    float xy = q.x * q.y,  xz = q.x * q.z,  yz = q.y * q.z;
    float wx = q.w * q.x,  wy = q.w * q.y,  wz = q.w * q.z;
    // Transposed layout to match row-vector convention, 
    return float3x3(
        1 - 2*(yy + zz),   2*(xy + wz),      2*(xz - wy),
            2*(xy - wz),   1 - 2*(xx + zz),  2*(yz + wx),
            2*(xz + wy),   2*(yz - wx),      1 - 2*(xx + yy)
    );
}

// High Quality Input (P, N, T, B)
struct VS_H_unified_input
{
    float4 position0    : POSITION0;
    float4 position1    : POSITION1;
    float4 normal0      : NORMAL0;
    float4 normal1      : NORMAL1;
    float4 tangent0     : TANGENT0;
    float4 tangent1     : TANGENT1;
    float4 binormal0    : BINORMAL0;
    float4 binormal1    : BINORMAL1;
    float4 blendindices : BLENDINDICES;
    float4 blendweight  : BLENDWEIGHT;
    float4 texcoord     : TEXCOORD0;
    float4 texcoordNEW  : TEXCOORD1;
    float4 color        : COLOR;
};

struct VS_H_output
{
    float4 Position : POSITION;   //VS一定要输出的clip space渲染坐标
    float4 VertexColor : COLOR0;  //顶点颜色
    float4 MainTexUV  : TEXCOORD0; //XY是主帖图UV, ZW是建筑损伤图 (并没有反)
    float4 ShadowCS : TEXCOORD1; // 阴影的 CLIP SPACE坐标，像素里还得除
    float4 FogCloudUV : TEXCOORD2; //迷雾和云的UV
    float3 WorldPE : TEXCOORD3;  //世界空间位置
    float3 WorldN : TEXCOORD4; //世界法线Z
    float3 WorldT : TEXCOORD5; //世界切线Y
    float3 WorldB : TEXCOORD6; //世界切线X
    float3 CoordOBJ  : TEXCOORD7;   //物体或骨骼空间坐标， w= index
    //float4 CoordCLIP : TEXCOORD8;
};

VS_H_output VS_H_Unified(VS_H_unified_input i, uniform int BonePerVertex)
{
    VS_H_output o;
    float4 WorldPosition = float4(0, 0, 0, 1);
    float3 WorldP = 0;
    
    o.VertexColor = i.color;
    o.MainTexUV = float4(i.texcoord.xy, i.texcoordNEW.xy);
    o.CoordOBJ.xyz = i.position0.xyz; // Default for 0 and 1 bone [cite: 14, 24]

    // ==========================================
    // 0 Bones (Rigid Mesh)
    if (BonePerVertex == 0)
    {
        WorldP = mul(float4(i.position0.xyz, 1), World);
        o.WorldN = mul(i.normal0.xyz, (float3x3)World);
        o.WorldT = mul(i.tangent0.xyz, (float3x3)World);
        o.WorldB = mul(i.binormal0.xyz, (float3x3)World);
    }
    // ==========================================
    // 1 Bone (Hard Skin)
    else if (BonePerVertex == 1)
    {
        int BoneIndex = floor(i.blendindices.x * 2);
        float3x3 boneMatrix = Quaternion2Matrix(WorldBones[BoneIndex]); // Matrix Optimization [cite: 88, 89]
        float4 bone_offset_alpha = WorldBones[BoneIndex + 1];

        WorldP = mul(i.position0.xyz, boneMatrix) + bone_offset_alpha.xyz;
        o.WorldN = mul(i.normal0.xyz, boneMatrix);
        o.WorldT = mul(i.tangent0.xyz, boneMatrix);
        o.WorldB = mul(i.binormal0.xyz, boneMatrix);
        o.VertexColor.w *= bone_offset_alpha.w;
    }
    // ==========================================
    // 2 Bones (Soft Skin)
    else if (BonePerVertex == 2)
    {
        int2 BoneIndex = floor(i.blendindices.xy * 2);
        
        float3x3 m0 = Quaternion2Matrix(WorldBones[BoneIndex.x]); // Matrix Optimization [cite: 89]
        float3x3 m1 = Quaternion2Matrix(WorldBones[BoneIndex.y]);
        float4 off0 = WorldBones[BoneIndex.x + 1];
        float4 off1 = WorldBones[BoneIndex.y + 1];

        float2 bonescale = 1;
        #ifdef BONE_ALPHA_SHRINK
        bonescale = float2(off0.w, off1.w); 
        #endif

        float3 wp0 = mul(i.position0.xyz * bonescale.x , m0) + off0.xyz;
        float3 wp1 = mul(i.position1.xyz * bonescale.y , m1) + off1.xyz;
        
        WorldP = lerp(wp1, wp0, i.blendweight.x);
        o.WorldN = lerp(mul(i.normal1.xyz, m1), mul(i.normal0.xyz, m0), i.blendweight.x);
        o.WorldT = lerp(mul(i.tangent1.xyz, m1), mul(i.tangent0.xyz, m0), i.blendweight.x);
        o.WorldB = lerp(mul(i.binormal1.xyz, m1), mul(i.binormal0.xyz, m0), i.blendweight.x);
        o.VertexColor.w *= lerp(off1.w, off0.w, i.blendweight.x);
        
        o.CoordOBJ.xyz = WorldP - WorldBones[1].xyz; // Specific to 22skin [cite: 47]
    }

    // ==========================================
    // Shared Calculations
    WorldPosition.xyz = WorldP;
    o.WorldPE = WorldP - getEYEpos() ;
    o.WorldN = normalize(o.WorldN);
    o.VertexColor.rgb = getAccentLight(o.WorldN) ; 
    
    o.ShadowCS = mul(WorldPosition, ShadowMapWorldToShadow);
    o.FogCloudUV.xy = getWarfogUV(WorldPosition);
    o.FogCloudUV.zw = getCloudUV(WorldPosition);

    #ifdef SUPPORT_TREAD_SCROLLING
    o.MainTexUV.x += o.VertexColor.a;
    o.VertexColor.a = 1;
    #endif

    o.Position = mul(WorldPosition, getVPmatrix());
    return o;
}


//  3DSMAX SPECIAL VS


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
    
    o.WorldPE = WorldPosition.xyz - getEYEpos(); //世界坐标
    o.MainTexUV = float4(i.texcoord.xy , i.texcoordNEW.xy) ; //直接转存贴图UV
    o.Position = mul(i.position , MAXwvp); //给rasterizer的clip space坐标

    return o; 
};

#endif // 3dsmax end


// ===========================
// end high 
// =======================

// Low Quality Input (P, N)
struct VS_L_unified_input
{
    float4 position0    : POSITION0;
    float4 position1    : POSITION1;
    float4 normal0      : NORMAL0;
    float4 normal1      : NORMAL1;
    float4 blendindices : BLENDINDICES;
    float4 blendweight  : BLENDWEIGHT;
    float4 texcoord     : TEXCOORD0;
    float4 texcoordNEW  : TEXCOORD1;
    float4 color        : COLOR;
};

struct VS_notgt_output  //
{
    float4 Position : POSITION;   //VS一定要输出的clip space渲染坐标
    float4 VertexColor : COLOR0;  //顶点颜色 
    float3 CoordOBJ  : COLOR1;
    //float4 CoordCLIP : COLOR2;
    float4 MainTexUV  : TEXCOORD0; //XY是主帖图UV,ZW是建筑损伤图UV
    float4 ShadowCS : TEXCOORD1; //CLIP SPACE 影子，需要在PS里除
    float4 FogCloudUV : TEXCOORD2; //迷雾和云的UV
    float3 WorldPE : TEXCOORD3;  //世界空间位置    
    float3 WorldN : TEXCOORD4;//_centroid; //世界法线

};

VS_notgt_output VS_L_Unified(VS_L_unified_input i, uniform int BonePerVertex)
{
    VS_notgt_output o;
    float4 WorldPosition = float4(0, 0, 0, 1);
    float3 WorldP = 0 ;
    
    o.VertexColor = i.color;
    o.MainTexUV = float4(i.texcoord.xy, i.texcoordNEW.xy);
    o.CoordOBJ.xyz = i.position0.xyz;

    if (BonePerVertex == 0)
    {
        WorldP = mul(float4(i.position0.xyz, 1), World);
        o.WorldN = mul(i.normal0.xyz, (float3x3)World);
    }
    else if (BonePerVertex == 1)
    {
        int BoneIndex = floor(i.blendindices.x * 2);
        float4 bone_Quat = WorldBones[BoneIndex];
        float4 bone_off  = WorldBones[BoneIndex + 1];
        
        float bonescale = 1;
        #ifdef BONE_ALPHA_SHRINK
        bonescale = bone_off.w; 
        #endif

        WorldP = QuaternionRotate(bone_Quat, i.position0.xyz * bonescale) + bone_off.xyz;
        o.WorldN = QuaternionRotate(bone_Quat, i.normal0.xyz);
        o.VertexColor.w = bone_off.w;
    }
    else if (BonePerVertex == 2)
    {
        int2 BoneIndex = floor(i.blendindices.xy * 2);
        float4 q0 = WorldBones[BoneIndex.x];
        float4 q1 = WorldBones[BoneIndex.y];
        float4 off0 = WorldBones[BoneIndex.x + 1];
        float4 off1 = WorldBones[BoneIndex.y + 1];

        float2 bonescale = 1;
        #ifdef BONE_ALPHA_SHRINK
        bonescale = float2(off0.w, off1.w); 
        #endif

        float3 wp0 = QuaternionRotate(q0, i.position0.xyz * bonescale.x) + off0.xyz;
        float3 wp1 = QuaternionRotate(q1, i.position1.xyz * bonescale.y) + off1.xyz;
        
        WorldP = lerp(wp1, wp0, i.blendweight.x);
        o.WorldN = lerp(QuaternionRotate(q1, i.normal1.xyz), QuaternionRotate(q0, i.normal0.xyz), i.blendweight.x);
        o.VertexColor.w = lerp(off1.w, off0.w, i.blendweight.x);
        o.CoordOBJ.xyz = WorldP - WorldBones[1].xyz;
    }

    WorldPosition.xyz = WorldP;
    o.WorldPE = WorldP - getEYEpos() ;

    o.WorldN = normalize(o.WorldN);
    o.VertexColor.rgb = getAccentLight(o.WorldN) ;
    o.FogCloudUV.xy = getWarfogUV(WorldPosition);
    o.FogCloudUV.zw = getCloudUV(WorldPosition);
    o.ShadowCS = mul(WorldPosition, ShadowMapWorldToShadow);

    o.Position = mul(WorldPosition, getVPmatrix());
    return o;
}

//========================================
// end low color vs 
// ================================

// Shadow Maker Input (P only)
struct VS_Shadow_unified_input
{
    float4 position0    : POSITION0;
    float4 position1    : POSITION1;
    float4 blendindices : BLENDINDICES;
    float4 blendweight  : BLENDWEIGHT;
    float4 texcoord     : TEXCOORD0;
    float4 texcoordNEW  : TEXCOORD1;
};

struct VS_ShadowMaker_output  
{
    float4 Position : POSITION;   //VS一定要输出的clip space渲染坐标
    float  Valpha : COLOR1;  //顶点alpha
    float4 MainTexUV : TEXCOORD0; //XY是主帖图UV,ZW是建筑损伤图UV
    float4 ClipSpace : TEXCOORD1;  // PERSPECTIVE DIVISION IN PS
};

VS_ShadowMaker_output VS_ShadowMaker_Unified(VS_Shadow_unified_input i, uniform int BonePerVertex)
{
    VS_ShadowMaker_output o;
    float4 WorldPosition = float4(0, 0, 0, 1);
    
    o.MainTexUV = float4(i.texcoord.xy, i.texcoordNEW.xy);

    if (BonePerVertex == 0)
    {
        WorldPosition.xyz = mul(float4(i.position0.xyz, 1), World);
        o.Valpha = 1; 
    }
    else if (BonePerVertex == 1)
    {
        int BoneIndex = floor(i.blendindices.x * 2);
        float4 bone_Quat = WorldBones[BoneIndex];
        float4 bone_off  = WorldBones[BoneIndex + 1];

        float bonescale = 1;
        #ifdef BONE_ALPHA_SHRINK
        bonescale = bone_off.w; 
        #endif

        WorldPosition.xyz = QuaternionRotate(bone_Quat, i.position0.xyz * bonescale) + bone_off.xyz;
        o.Valpha = bone_off.w;
    }
    else if (BonePerVertex == 2)
    {
        int2 BoneIndex = floor(i.blendindices.xy * 2);
        float4 q0 = WorldBones[BoneIndex.x];
        float4 q1 = WorldBones[BoneIndex.y];
        float4 off0 = WorldBones[BoneIndex.x + 1];
        float4 off1 = WorldBones[BoneIndex.y + 1];

        float2 bonescale = 1;
        #ifdef BONE_ALPHA_SHRINK
        bonescale = float2( off0.w, off1.w); 
        #endif

        float3 wp0 = QuaternionRotate(q0, i.position0.xyz * bonescale.x) + off0.xyz;
        float3 wp1 = QuaternionRotate(q1, i.position1.xyz * bonescale.y) + off1.xyz;
        
        WorldPosition.xyz = lerp(wp1, wp0, i.blendweight.x);
        o.Valpha = lerp(off1.w, off0.w, i.blendweight.x); 
    }

    o.Position = mul(WorldPosition, getVPmatrix());
    o.ClipSpace = o.Position;
    return o;
}

float4 PS_ShadowMaker_NoAlphaTest(VS_ShadowMaker_output i) : COLOR 
{    return (i.ClipSpace.z / i.ClipSpace.w) ; }



// Shader arrays (compile-time blobs) for selection by index
VertexShader VS_H_Array[3] = {
    compile vs_3_0 VS_H_Unified(0),
    compile vs_3_0 VS_H_Unified(1),
    compile vs_3_0 VS_H_Unified(2),
};

VertexShader VS_L_Array[3] = {
    compile vs_3_0 VS_L_Unified(0),
    compile vs_3_0 VS_L_Unified(1),
    compile vs_3_0 VS_L_Unified(2),
};

VertexShader VS_Shadow_Array[3] = {
    compile vs_2_0 VS_ShadowMaker_Unified(0),
    compile vs_2_0 VS_ShadowMaker_Unified(1),
    compile vs_2_0 VS_ShadowMaker_Unified(2),
};