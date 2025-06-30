# Shader Story

## Common HLSL Functions: Abs

> `abs(x)` returns the **absolute value** of a number, effectively flipping negative values to positive.  
> Useful for **mirrored gradients**, **distance calculations**, **symmetry effects**, and **contrast shaping**.

```hlsl
float abs(float x);
float2 abs(float2 x);
float3 abs(float3 x);

// etc.
```

---
### Visual demo
This shader demonstrates the use of abs() by mirroring the UV space around the center, producing a diamond-like symmetry.
A toggle allows you to compare the behavior with and without the absolute value.

---
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Abs/DA_CommonFuncs_Abs_Demo_01.gif" alt="Shader Story: Functions - Abs" title="Shader Story: Functions - Abs">
</p>

### URP Shader Code

```hlsl

Shader "DecompiledArt/CommonFunctions/Abs/Abs"
{
    Properties
    {
        _UVTile("UVTile", Range(0.5, 10.0)) = 1.0
        [Toggle(USE_ABS)] _UseAbs("useAbs", Int) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature USE_ABS

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                half2 uvs: TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                half2 uvs: TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
            half _UVTile;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uvs = IN.uvs;
                return OUT;
            }

            half4 frag(Varyings i) : SV_Target
            {
                #ifdef USE_ABS
                    half2 abs_output = abs(frac(i.uvs * _UVTile) - 0.5);
                #else
                    half2 abs_output = frac(i.uvs * _UVTile) - 0.5;
                #endif

                half col_output = max(abs_output.x, abs_output.y);
                return half4(col_output, col_output, col_output, 1.0);
            }

            ENDHLSL
        }
    }
}


```

### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Abs/DA_CommonFuncs_Abs_Graph_01.png" alt="Shader Story: Functions - Abs" title="Shader Story: Functions - Abs">
</p>

---
## 🔗 Related Functions

[Step]([../Step.md](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Step.md)) • [Smoothstep]([../Smoothstep.md](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Smoothstep.md)) • [Remap](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Remap.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://img.shields.io/badge/Join%20on%20Patreon-%20Exclusive%20Updates%20%26%20Community-orange?style=for-the-badge&logo=patreon" alt="Join on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
