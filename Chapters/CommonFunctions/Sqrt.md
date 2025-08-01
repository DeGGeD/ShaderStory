# Shader Story

## Common HLSL Functions: Sqrt

> sqrt(x) returns the square root of a value.
> rsqrt(x) returns the reciprocal of the square root.
> These are useful for gradient shaping, distance-based falloffs, attenuation models, and normalizing vectors efficiently.

```hlsl
float result = sqrt(x);   // Standard square root
float result = rsqrt(x);  // Fast inverse square root (1.0 / sqrt(x))

```
---

### Visual demo
This shader visualizes sqrt(x) or rsqrt(x) using a horizontal UV gradient.
You can toggle between the two functions to observe their curve shapes:

- sqrt(x) grows slowly then rises
- rsqrt(x) spikes early then levels off (useful for attenuation/falloff)

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Sqrt/DA_CommonFuncs_Sqrt_Demo_01.gif" alt="Shader Story: Function - Sqrt" title="Shader Story: Function - Sqrt">
</p>

---
### URP Shader Code

```hlsl

Shader "DecompiledArt/CommonFunctions/Sqrt/Sqrt"
{
    Properties
    {
        _Tint01("Tint01", Color) = (1,1,1,1)
        _Tint02("Tint02", Color) = (1,1,1,1)
        [Toggle(INVERSE_SQRT)] _SqrtInverse("inverseSqrt", Int) = 0

        [Toggle(SHOW_GRAPH)] _ShowGraph("showGraph", Int) = 0
        _GraphLineWidth("Graph_LineWidth", Range(0.005, 0.025)) = 0.02
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

            #pragma shader_feature_local INVERSE_SQRT
            #pragma shader_feature_local SHOW_GRAPH

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
            half3 _Tint01;
            half3 _Tint02;
            half _GraphLineWidth;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uvs = IN.uvs;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                #ifdef INVERSE_SQRT
                    half sqrt_output = saturate(rsqrt(IN.uvs.x + 0.001));
                #else
                    half sqrt_output = sqrt(IN.uvs.x + 0.001);
                #endif

                half3 col_output = lerp(_Tint01, _Tint02, sqrt_output);

                #ifdef SHOW_GRAPH
                    half graph_line = saturate(1 - smoothstep(0.0, _GraphLineWidth, abs(IN.uvs.y - sqrt_output)));
                    col_output += graph_line;
                #endif

                return half4(col_output, 1.0);
            }

            ENDHLSL
        }
    }
}

```

### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Sqrt/DA_CommonFuncs_Sqrt_Graph_01.png" alt="Shader Story: Function - Sqrt" title="Shader Story: Function - Sqrt">
</p>

---

## 🔗 Related Functions

[Remap](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Remap.md) • [MinMax](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/MinMax.md) • [Exp](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Exp.md) • [Abs](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Abs.md) • [Power](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Power.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
