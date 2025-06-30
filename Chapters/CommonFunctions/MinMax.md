# Shader Story

## Common HLSL Functions: Min/Max

> `min(a, b)` and `max(a, b)` return the smaller or larger of two values, respectively.  
> Great for **clamping**, **thresholding**, **UV bounding**, and **shader logic control**.

```hlsl
float min(float a, float b);
float max(float a, float b);
```

---
### Visual demo
This shader applies either `min()` or `max()` to the horizontal UV axis depending on the toggle.  
It demonstrates how values are limited based on shader input.

---
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/MinMax/DA_CommonFuncs_MinMax_Demo_01.gif" alt="Shader Story: Functions - Min/Max" title="Shader Story: Functions - Min/Max">
</p>

### URP Shader Code

```hlsl

Shader "DecompiledArt/CommonFunctions/MinMax/MinMax"
{
    Properties
    {
        _Min("Min", Range(0.0, 1.0)) = 0.0
        _Max("Max", Range(0.0, 1.0)) = 0.0
        [Toggle(SHOW_MAX)] _ShowMax("showMax", Int) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature SHOW_MAX

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
            half _Min;
            half _Max;
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
                #ifdef SHOW_MAX
                    half result = max(i.uvs.x, _Max);
                #else
                    half result = min(i.uvs.x, _Min);
                #endif

                return half4(result, result, result, 1.0);
            }

            ENDHLSL
        }
    }
}
```

### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/MinMax/DA_CommonFuncs_MinMax_Graph_01.png" alt="Shader Story: Functions - Min/Max" title="Shader Story: Functions - Min/Max">
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
