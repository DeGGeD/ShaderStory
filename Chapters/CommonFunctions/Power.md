# Shader Story

## Common HLSL Functions: Power

> `pow(x, y)` raises `x` to the power of `y`.  
> This is useful for **remapping gradients**, shaping data like **falloff masks**, **lighting ramps**, or **animation curves**.

```hlsl
float result = pow(x, y);
float2 result = pow(float2(x1, x2), y);
float3 result = pow(float3(x, y, z), 2.0);
```

---

### Visual demo 
This shader visualizes the pow() function by remapping a horizontal UV gradient.
The power exponent reshapes the curve:

- values < 1 bend it upward (fast rise)
- values > 1 bend it downward (slow rise)
  
useful for biasing interpolation or nonlinear fading.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Power/DA_CommonFuncs_Power_Demo_01.gif" alt="Shader Story: Function - Power" title="Shader Story: Function - Power">
</p>

---
### URP Shader Code

```hlsl

Shader "DecompiledArt/CommonFunctions/Power/Power"
{
    Properties
    {
        _Tint01("Tint01", Color) = (1,1,1,1)
        _Tint02("Tint02", Color) = (1,1,1,1)
        _Power("Power", Range(0.01, 10)) = 1.0

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
            half _Power;
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
                half value_for_viz = pow(abs(IN.uvs.x), _Power);
                half3 col_output = lerp(_Tint01, _Tint02, value_for_viz);

                #ifdef SHOW_GRAPH
                    half graph_line = saturate(1 - smoothstep(0.0, _GraphLineWidth, abs(IN.uvs.y - value_for_viz)));
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
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Power/DA_CommonFuncs_Power_Graph_01.png" alt="Shader Story: Function - Power" title="Shader Story: Function - Power">
</p>

---

## 🔗 Related Functions

[Abs](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Abs.md) • [Step](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Step.md) • [Remap](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Remap.md) • [Smoothstep](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Smoothstep.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
