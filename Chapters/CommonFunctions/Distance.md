# Shader Story

## Common HLSL Functions: Distance

> `distance(a, b)` returns the Euclidean distance between two points `a` and `b`.
> It’s useful for **radial falloffs**, **circular masks**, **ripples**, and **proximity-based effects**.

```hlsl
float d = distance(float3(0.0, 0.0, 0.0), float3(1.0, 1.0, 1.0));

```
---

### Visual demo 
This shader visualizes how distance() calculates the separation between world-space positions and a given center point. The result is a smooth radial gradient, often used in glow masks, area effects, and procedural transitions.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Distance/DA_CommonFuncs_Distance_Demo_01.gif" alt="Shader Story: Function - Distance" title="Shader Story: Function - Distance">
</p>

---
### URP Shader Code

```hlsl
Shader "DecompiledArt/CommonFunctions/Distance/Distance"
{
    Properties
    {
        _Pos_X("Pos_X", Range(-10.0, 10.0)) = 0.0
        _Pos_Y("Pos_Y", Range(-10.0, 10.0)) = 0.0
        _Pos_Z("Pos_Z", Range(-10.0, 10.0)) = 0.0
        _Contrast("Contrast", Range(0.01, 8.0)) = 1.0
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
                float3 positionWS : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
            half _Pos_X;
            half _Pos_Y;
            half _Pos_Z;
            half _Contrast;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half3 pos = half3(_Pos_X, _Pos_Y, _Pos_Z);
                half col_output = pow((1 - saturate(distance(pos, IN.positionWS.xyz))), _Contrast);
                

                return half4(col_output.xxx, 1.0);

            }

            ENDHLSL
        }
    }
}


```

### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Distance/DA_CommonFuncs_Distance_Graph_01.png" alt="Shader Story: Function - Distance" title="Shader Story: Function - Distance">
</p>

---

## 🔗 Related Functions

[Length](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Length.md) • [Normalize](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Normalize.md) • [Smoothstep](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Smoothstep.md) • [Dot](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Dot.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://img.shields.io/badge/Join%20on%20Patreon-%20Exclusive%20Updates%20%26%20Community-orange?style=for-the-badge&logo=patreon" alt="Join on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
