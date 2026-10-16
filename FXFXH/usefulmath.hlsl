

// this can be called anywhere and requires no global variable


float3 QuaternionRotation(float4 q, float3 block) 
{
	float4 a
	= q.wwwx * block.xyzx + q.yzxy * block.zxyy;
	a.w = -a.w;
	a -= q.zxyz * block.yzxz;
    float3 finalvector 
    = q.www * a.xyz - q.xyz * a.www + q.yzx * a.zxy - q.zxy * a.yzx;
	return finalvector;
}; 

float3x3 QuaternionToMatrix(float4 q)
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
/*
mul(v, M)  // dot v with each COLUMN of M , produces row vector (RA3)
mul(M, v)  // dot v with each ROW of M , produces column vector (modern)
*/


// ComputeNTB - Pixel shader tangent frame from screen-space derivatives
// Compatible with Shader Model 3.0
// Approximately correct, optimized for GPU real-time rendering.
// P  = interpolated world-space pos
// uv = interpolated texture coordinates
float3x3 ComputeTangentSpaceFacet(float3 P, float2 uv)
{
    float3 dPdx = ddx(P);
    float3 dPdy = ddy(P);
    float2 dUdx = ddx(uv);
    float2 dUdy = ddy(uv);

    float3 N = normalize(cross(dPdx, dPdy));

    float  det  = dUdx.x * dUdy.y - dUdx.y * dUdy.x;
    float  flip = sign(det);

    float3 T = normalize(dPdx * dUdy.y - dPdy * dUdx.y) * flip;
    float3 B = normalize(dPdy * dUdx.x - dPdx * dUdy.x) * flip;

    return float3x3(T, B, N);
}
/*
Facet normal — cross order for DirectX left-handed convention.
Backfaces: N will point inward, but without SV_IsFrontFace in SM3
there's nothing cheap we can do. Single-sided meshes are unaffected.
        
Tangent and binormal — same Jacobian inversion as the full version,
but we skip dividing by det and normalize instead.
This loses UV scale info (like the reference) but avoids a division
and is stable without a det==0 guard (normalize handles near-zero).
flip = sign(det) preserves UV mirror handedness at near-zero cost.
*/


// 8 pixel alpha dither
void dither4x2clip(float2 vpos, float alpha)
{
    float2 block = frac(vpos * float2(0.25, 0.5)) * float2(4, 2);
    int rowindex = floor(block.x) ;
    const float4 row0 = {1, 5, 3, 7};
    const float4 row1 = {6, 2, 8, 4};
    // the number in array is retained pixel count in the block 
    float rank = (block.y < 0.5) ? row0[rowindex] : row1[rowindex];
    float scaledalpha = alpha * 8 + 0.5 ; // 0 - 1 to  0.5 - 8.5
    clip( scaledalpha - rank);
}

void dither8clip(float2 vpos, float alpha)
{
    float2 block = frac(vpos / float2(4, 2)) * float2(4, 8);
    // start all (0,0) end: from (3, 1) to ( 0.75, 0.5) to (3, 4)
    int rowindex = round(block.x + block.y) ; // 0 - 7
    const float row[8] = {6, 2, 8, 4,   1, 5, 3, 7};
    float scaledalpha = alpha * 8 + 0.5 ; // 0 - 1 to  0.5 - 8.5
    clip( scaledalpha - row[rowindex]);
}


/*

for non-metal, reflectivity is zero at max roughness. 
but metal still has it.
or does it?
metal F0 is the same as albedo, so usually non zero, but if black, zero
dielectric F0 always set to zero
we use a fresnel term clamper to limit F0 to 0 at extreme roughness (spm 0)
this applies to both metal and not

F0 is no longer a constant. completely controlled by metalness
actually similar to G-term , at spm.r=0 or low, this is used to darken rim by CLAMP fresnel term 
actual clamper value: lerp( 1, K_fresnel, realRoughness)
clamper is , applied after dotNH or dotVL and exponent, before lerp with F0
for both metal and dielectric, both sunlight and skybox.
because in all dielectric and pure-black metal, F0 = 0

*/


void sketchPBR(float3 difTex, float3 spmTex, float3 realHC, float minRoughness, float dotVL )
{
    float3 baseColor = difTex * lerp(1, realHC , spmTex.bbb) ; //mix recolorcolor
    baseColor *= baseColor ; //gamma 2.0
    // float desaturated = dot(baseColor, (float3(5,6,5) / 16.0) ); // no need

    float roughness = lerp( 1 , minRoughness  ,  spmTex.r ); // texture has smoothness
    float metalness = spmTex.g ; // (3 - 2 * spmTex.g) * spmTex.g * spmTex.g; //cubic hermit

    float3 diffuseColor = lerp( baseColor, 0 , metalness ) ;
    
    float fresnelterm = pow( (1 - dotVL) , 2); //more realistic approximate 
    fresnelterm = min(fresnelterm, spmTex.r) ; //simulate G term
    // fresnelterm *= fresnelterm ; //maybe more smooth looking ?
    float3 f0 = lerp(0 , baseColor, metalness) ; //assume dielectric F0 = 0 
    float3 fresnelMask = lerp(f0, 1, fresnelterm); // MULTIPLIED TO SPECULAR COLOR
}

