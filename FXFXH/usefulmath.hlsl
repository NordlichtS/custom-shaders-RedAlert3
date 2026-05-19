

// this can be called anywhere and requires no global variable


float3 QuaternionRotation(float4 q, float3 p) 
{
	float4 a
	= q.wwwx * p.xyzx + q.yzxy * p.zxyy;
	a.w = -a.w;
	a -= q.zxyz * p.yzxz;
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