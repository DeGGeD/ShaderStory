# Shader Story

## Common HLSL Functions: Sine & Cosine

> sin(x) and cos(x) produce smooth, oscillating values between -1 and 1.
> These functions are essential for animations, wave patterns, UV warping, procedural motion, and cyclical behaviors.

```hlsl
float result = sin(x);  // Returns sine of input (radians)
float result = cos(x);  // Returns cosine of input (radians)

```
---

### Visual demo
This shader visualizes either a sine or cosine wave modulated over time.
The result is shaped spatially using UV distance, allowing the wave to pulse or animate across the surface.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/SineCosine/DA_CommonFuncs_SineCosine_Demo_01.gif" alt="Shader Story: Function - Sine/Cosine" title="Shader Story: Function - Sine/Cosine">
</p>

---
### URP Shader Code

```hlsl

Shader "DecompiledArt/CommonFunctions/SineCosine/SineCosine"
{
    Properties
    {
        _Frequency("Frequency", Range(0.01, 10.0)) = 1.0
        [Toggle(USE_COSINE)] _UseCosine("useCosine", Int) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature_local USE_COSINE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


            struct Attributes
            {
                float4 positionOS : POSITION;
                half2 uvs : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                half2 uvs : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
            half _Frequency;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uvs = IN.uvs;
                return OUT;
            }

            half2 remap(half2 In, half2 InMinMax, half2 OutMinMax)
            {
                return OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half time = _TimeParameters.x * _Frequency;
                
                #ifdef USE_COSINE
                    half oscillation = cos(time);
                #else
                    half oscillation = sin(time);
                #endif

                half2 shape = remap(IN.uvs, half2(0, 1), half2(-1, 1));
                shape = saturate(1 - distance(half2(0,0), shape));

                oscillation = (oscillation - 1) + shape;

                half4 col_output = half4(oscillation.xxx, 1.0);
                return col_output;
            }

            ENDHLSL
        }
    }
}


```

### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/SineCosine/DA_CommonFuncs_SineCosine_Graph_01.png" alt="Shader Story: Function - Sqrt" title="Shader Story: Function - Sqrt">
</p>

---

## 🔗 Related Functions

[Remap](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Remap.md) • [Step](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Step.md) • [Abs](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Abs.md) • [Power](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Power.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://img.shields.io/badge/Join%20on%20Patreon-%20Exclusive%20Updates%20%26%20Community-orange?style=for-the-badge&logo=patreon" alt="Join on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
