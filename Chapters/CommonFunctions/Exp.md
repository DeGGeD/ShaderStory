# Shader Story

## Common HLSL Functions: Exp

> exp(x) computes Euler’s number e raised to the power of x.
> exp2(x) computes 2 raised to the power of x.
> These are useful for creating exponential growth/decay curves, nonlinear fades, and falloff effects like fog or light attenuation.

```hlsl
float exp_result = exp(x);   // e^x
float exp2_result = exp2(x); // 2^x
```
---

### Visual demo 
This shader visualizes exp() and exp2() functions applied to a UV gradient.
The result is a sharply rising curve often used for decay, fadeout, or response curves.
Toggling between exp() and exp2() helps compare their rate of change.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Exp/DA_CommonFuncs_Exp_Demo_01.gif" alt="Shader Story: Function - Exp" title="Shader Story: Function - Exp">
</p>

---
### URP Shader Code

```hlsl
Shader "DecompiledArt/CommonFunctions/Exp/Exp"
{
    Properties
    {
        _Tint01("Tint01", Color) = (1,1,1,1)
        _Tint02("Tint02", Color) = (1,1,1,1)
        _ExpFactor("ExpFactor", Range(0.01, 3.0)) = 3.0
        [Toggle(USE_EXP2)] _UseExp2("useExp2", Int) = 0

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

            #pragma shader_feature_local USE_EXP2
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
            half _ExpFactor;
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
                half uvsX = -IN.uvs.x * _ExpFactor;
                #ifdef USE_EXP2
                    half exp_output = saturate(exp2(uvsX + 0.001));
                #else
                    half exp_output = saturate(exp(uvsX + 0.001));
                #endif

                half3 col_output = lerp(_Tint01, _Tint02, exp_output);

                #ifdef SHOW_GRAPH
                    half graph_line = saturate(1 - smoothstep(0.0, _GraphLineWidth, abs(IN.uvs.y - exp_output)));
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
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Exp/DA_CommonFuncs_Exp_Graph_01.png" alt="Shader Story: Function - Exp" title="Shader Story: Function - Exp">
</p>

---

## 🔗 Related Functions

[Pow](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Power.md) •
[Remap](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Remap.md) • 
[Smoothstep](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Smoothstep.md) • 
[Lerp](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Lerp.md) • 
[Abs](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Abs.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://img.shields.io/badge/Join%20on%20Patreon-%20Exclusive%20Updates%20%26%20Community-orange?style=for-the-badge&logo=patreon" alt="Join on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
