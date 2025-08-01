# Shader Story

## Common HLSL Functions: Length

> length(v) returns the magnitude (Euclidean distance) of the input vector v.
> It's useful for **radial gradients**, **falloff masks**, **distance-based effects**.

```hlsl
float len = length(float3(0.5, 0.5, 0.5));

```
---

### Visual demo 
This shader visualizes how length() measures the magnitude of an object-space position offset. The result creates a circular gradient pattern, commonly used in procedural shaders like glow masks, ripples, or distance falloffs.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Length/DA_CommonFuncs_Length_Demo_01.gif" alt="Shader Story: Function - Length" title="Shader Story: Function - Length">
</p>

---
### URP Shader Code

```hlsl
Shader "DecompiledArt/CommonFunctions/Length/Length"
{
    Properties
    {
        _Dir_X("Dir_X", Range(-1.0, 1.0)) = 0.0
        _Dir_Y("Dir_Y", Range(-1.0, 1.0)) = 0.0
        _Dir_Z("Dir_Z", Range(-1.0, 1.0)) = 0.0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionOS : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
            half _Dir_X;
            half _Dir_Y;
            half _Dir_Z;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionOS = IN.positionOS.xyz;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half3 dir = half3(_Dir_X, _Dir_Y, _Dir_Z);
                half3 col_output = saturate(length(IN.positionOS.xyz + dir) - 1);

                return half4(col_output, 1.0);

            }

            ENDHLSL
        }
    }
}


```

### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Length/DA_CommonFuncs_Length_Graph_01.png" alt="Shader Story: Function - Length" title="Shader Story: Function - Length">
</p>

---

## 🔗 Related Functions

[Dot](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Dot.md) • [Normalize](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Normalize.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
