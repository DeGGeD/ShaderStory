# Shader Story

## Derivatives Sample: Silhouette

> In this sample, screen-space derivatives (ddx, ddy) are used to estimate changes in surface normals and depth across neighboring pixels.
> These values help detect edges or silhouettes by highlighting areas where geometry orientation or depth changes rapidly.
> This technique is useful for **stylized outlines**, **non-photorealistic rendering (NPR)**, and **post-process edge detection effects**.

```hlsl
half normalDiff = length(ddx(normalWS) + ddy(normalWS));
half depthDiff = length(float2(ddx(depth), ddy(depth)));
```
---

### Visual demo
This shader highlights geometry edges and silhouettes by measuring changes in surface normals and depth across the screen.
The stronger the difference, the brighter the output—making silhouettes pop naturally from the background.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Derivatives/DA_Derivatives_Silhouette_Demo_01.gif" alt="Shader Story: Derivatives - Silhouette" title="Shader Story: Derivatives - Silhouette">
</p>

---
### URP Shader Code

```hlsl

Shader "DecompiledArt/Derivatives/Silhouette/Silhouette"
{
    Properties
    {
        _EdgeFactor("EdgeFactor", Range(0.0, 0.1)) = 0.025
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
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normalWS : NORMAL;
                float4 screenPos :TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
            half _EdgeFactor;
            CBUFFER_END

            TEXTURE2D(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.screenPos = ComputeScreenPos(OUT.positionHCS);
                
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float2 screenUV = IN.screenPos.xy / IN.screenPos.w;
                
                float rawDepth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV).r;
                float linearDepth = Linear01Depth(rawDepth, _ZBufferParams);

                half depthDiff = length(float2(ddx(linearDepth), ddy(linearDepth)));
                half normalDiff = length(ddx(IN.normalWS) + ddy(IN.normalWS));

                half edge = smoothstep(_EdgeFactor - 0.01, _EdgeFactor + 0.01, normalDiff + depthDiff);

                return half4(edge.xxx, 1.0);
            }

            ENDHLSL
        }
    }
}

```

### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Derivatives/DA_Derivatives_Silhouette_Graph_01.png" alt="Shader Story: Derivatives - Silhouette" title="Shader Story: Derivatives - Silhouette">
</p>

---

## 🔗 Related Functions

[Length](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Length.md) • [Normalize](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Normalize.md) • [Smoothstep](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Smoothstep.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://img.shields.io/badge/Join%20on%20Patreon-%20Exclusive%20Updates%20%26%20Community-orange?style=for-the-badge&logo=patreon" alt="Join on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
