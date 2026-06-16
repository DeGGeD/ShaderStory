#ifndef WORKSHOP_WAVE_NORMALS_RECONSTRUCTION_INCLUDED
#define WORKSHOP_WAVE_NORMALS_RECONSTRUCTION_INCLUDED

// Shared normal reconstruction helpers for workshop wave shaders.
// The key teaching point is that geometry displacement and shading correction
// are related, but separable concerns.
//
// Usage pattern:
// 1. Provide a shader-specific function named:
//      float3 ApplyAllWaves(float3 baseWS);
//    It must return the displaced world-space position for the input point.
// 2. Call ReconstructWaveNormalWS(baseWS, _NormalEpsilon) when the material
//    toggle enables reconstructed normals.
// 3. Optionally layer a tangent-space detail normal on top of the reconstructed
//    geometric normal using ApplyDetailNormalTS_WS(...).

float3 ReconstructWaveNormalWS(float3 baseWS, float normalEpsilon)
{
    float eps = max(normalEpsilon, 0.0001);

    float3 p  = ApplyAllWaves(baseWS);
    float3 px = ApplyAllWaves(baseWS + float3(eps, 0.0, 0.0));
    float3 pz = ApplyAllWaves(baseWS + float3(0.0, 0.0, eps));

    float3 dx = px - p;
    float3 dz = pz - p;

    // Cross order is chosen for an upward-facing XZ plane convention.
    return normalize(cross(dz, dx));
}

// Decode a tangent-space normal map using Unity's helper so platform-specific
// packing/import settings are handled correctly.
float3 SampleDetailNormalTS(TEXTURE2D_PARAM(normalTex, normalSampler), float2 uv, half strength)
{
    half4 packed = SAMPLE_TEXTURE2D(normalTex, normalSampler, uv);
    return normalize(UnpackNormalScale(packed, strength));
}

// Apply a tangent-space detail normal on top of a reconstructed large-scale
// geometric normal. The incoming tangent comes from the mesh / UV basis, then
// gets re-orthonormalized against the reconstructed normal so the detail rides
// on the displaced surface shape instead of the original flat plane.
float3 ApplyDetailNormalTS_WS(
    float3 geometricNormalWS,
    float4 tangentWSAndSign,
    float3 detailNormalTS)
{
    float3 tangentWS = normalize(tangentWSAndSign.xyz);
    tangentWS = normalize(tangentWS - geometricNormalWS * dot(tangentWS, geometricNormalWS));

    float tangentSign = tangentWSAndSign.w;
    float3 bitangentWS = normalize(cross(geometricNormalWS, tangentWS)) * tangentSign;

    float3 detailWS =
        tangentWS         * detailNormalTS.x +
        bitangentWS       * detailNormalTS.y +
        geometricNormalWS * detailNormalTS.z;

    return normalize(detailWS);
}

#endif
