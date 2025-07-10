# Shader Story

## Derivatives Sample: Edge Transition

>  **screen-space derivatives** via `fwidth()` combined with `smoothstep()` are used to create a clean, antialiased transition across a UV-defined edge.
> It’s a common technique for **stylized outlines**, **highlight edges**, and **procedural UV masks**.

```hlsl
float edgeWidth = fwidth(uv.y);
float mask = smoothstep(threshold - edgeWidth, threshold + edgeWidth, uv.y);
```
---

### Visual demo
This shader creates a smooth vertical transition along the UV Y-axis. The fwidth() function ensures consistent edge thickness across screen resolutions and object scaling.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Derivatives/DA_Derivatives_EdgeTransition_Demo_01.gif" alt="Shader Story: Derivatives - EdgeTransition" title="Shader Story: Derivatives - EdgeTransition">
</p>

---
### URP Shader Code

```hlsl

Shader "DecompiledArt/Derivatives/EdgeTransition/EdgeTransition"
{
    Properties
    {
        _EdgeFactor("EdgeFactor", Range(0.0, 1.0)) = 0.0
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
                half2 uvs : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS: TEXCOORD1;
                float3 normalWS : NORMAL;
                half2 uvs : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
            half _EdgeFactor;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);

                OUT.uvs = IN.uvs;
                
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half edgeWidth = fwidth(IN.uvs.y);
                half edge = smoothstep(_EdgeFactor - edgeWidth, _EdgeFactor + edgeWidth, IN.uvs.y);
                
                half4 col_output = half4(edge.xxx, 1.0);

                return col_output;
            }

            ENDHLSL
        }
    }
}

```

### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Derivatives/DA_Derivatives_EdgeTransition_Graph_01.png" alt="Shader Story: Derivatives - EdgeTransition" title="Shader Story: Derivatives - EdgeTransition">
</p>

---

## 🔗 Related Functions

[Smoothstep](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Smoothstep.md) • [Lerp](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Lerp.md) • [Step](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Step.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://img.shields.io/badge/Join%20on%20Patreon-%20Exclusive%20Updates%20%26%20Community-orange?style=for-the-badge&logo=patreon" alt="Join on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
