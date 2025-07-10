# Shader Story

## Derivatives Sample: Harden Normals

> In this sample **screen-space derivatives** (`ddx`, `ddy`) and a **cross product** are used to calculate a new surface normal.
> By blending between the geometry normal and the derived normal, we can “harden” the appearance of shading. Might be useful for **toon lighting**, **stylized rendering**, or **normal flattening**.

```hlsl
float3 normal_hardened = normalize(cross(ddy(positionWS), ddx(positionWS)));
```
---

### Visual demo
This shader demonstrates how modifying normals with screen-space derivatives sharpens lighting transitions across surfaces. Especially noticeable on curved or smooth geometry.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Derivatives/DA_Derivatives_HardenNormals_Demo_01.gif" alt="Shader Story: Derivatives - HardenNormals" title="Shader Story: Derivatives - HardenNormals">
</p>

---
### URP Shader Code

```hlsl

Shader "DecompiledArt/Derivatives/HardenNormals/HardenNormals"
{
    Properties
    {
        _NormalsFactor("NormalsFactor", Range(0.0, 1.0)) = 0.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS: TEXCOORD0;
                float3 normalWS : NORMAL;
            };

            CBUFFER_START(UnityPerMaterial)
            half _NormalsFactor;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half3 out_cross = normalize(cross(ddy(IN.positionWS), ddx(IN.positionWS)));
                half surface_factor = lerp(IN.normalWS, out_cross, _NormalsFactor).x;

                half4 col_output = half4(surface_factor.xxx, 1.0);
                return col_output;
            }

            ENDHLSL
        }
    }
}

```

### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Derivatives/DA_Derivatives_HardenNormals_Graph_01.png" alt="Shader Story: Derivatives - HardenNormals" title="Shader Story: Derivatives - HardenNormals">
</p>

---

## 🔗 Related Functions

[Cross](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Cross.md) • [Normalize](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Normalize.md) • [Lerp](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Lerp.md) • [Step](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Step.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://img.shields.io/badge/Join%20on%20Patreon-%20Exclusive%20Updates%20%26%20Community-orange?style=for-the-badge&logo=patreon" alt="Join on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
