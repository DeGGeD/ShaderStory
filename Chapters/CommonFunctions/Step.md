# Shader Story

## Common HLSL Functions: Step

> `step(edge, x)` compares a value to a threshold and returns `0.0` or `1.0`.  
> Great for **hard masks**, **binary cutoffs**, and **stylized effects**.

```hlsl
float step(float edge, float x);
```
---

### Visual demo
This shader applies step() to the horizontal UV axis, creating a crisp vertical cutoff.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Step/DA_CommonFuncs_Step_Demo_01.gif" alt="Shader Story: Function - Step" title="Shader Story: Function - Step">
</p>

---
### URP Shader Code

```hlsl

Shader "DecompiledArt/CommonFunctions/Step/Step"
{
    Properties
    {
        _Step("Step", Range(0.0 ,1.0)) = 1.0
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
                half2 uvs: TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                half2 uvs: TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
            half _Step;
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
                half col_step = step(_Step, i.uvs.x);
                half4 col_output = half4(col_step, col_step, col_step, 1.0);
                return col_output;
            }

            ENDHLSL
        }
    }
}
```

### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Step/DA_CommonFuncs_Step_Graph_01.png" alt="Shader Story: Function - Step" title="Shader Story: Function - Step">
</p>

---

## 🔗 Related Functions

[Smoothstep]([../Smoothstep.md](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Smoothstep.md)) • [Remap](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Remap.md) • [MinMax](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/MinMax.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://img.shields.io/badge/Join%20on%20Patreon-%20Exclusive%20Updates%20%26%20Community-orange?style=for-the-badge&logo=patreon" alt="Join on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
