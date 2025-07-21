# Shader Story

## Derivatives Sample: Slope Detect

> This sample demonstrates how to use screen-space derivatives (ddx, ddy) to measure surface slope by analyzing how much the world-space Y position changes across pixels.
> This might be useful for **terrain-aware blending**, **snow accumulating** or **moss growing** on gentle slopes. You can mask or blend between two materials or tints based on slope intensity.

```hlsl
float dy_dx = ddx(worldPos.y);
float dy_dy = ddy(worldPos.y);
float slope = length(float2(dy_dx, dy_dy));
```
---

### Visual demo
This shader visualizes the slope of each surface fragment.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Derivatives/DA_Derivatives_SlopeDetect_Demo_01.gif" alt="Shader Story: Derivatives - Slope Detect" title="Shader Story: Derivatives - Slope Detect">
</p>

---
### URP Shader Code

```hlsl

Shader "DecompiledArt/Derivatives/SlopeDetect/SlopeDetect"
{
    Properties
    {
        _Tint_Flat("Tint Flat", Color) = (1,1,1,1)
        _Tint_Steep("Tint Steep", Color) = (0.2,0.8,1,1)
        _Slope_Threshold("Slope Threshold", Range(0.0, 0.005)) = 0.004
        _Slope_Blend("Slope Blend", Range(0.0, 0.005)) = 0.002
        
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
                half3 normalOS   : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS  : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
            half _Slope_Threshold;
            half _Slope_Blend;
            half4 _Tint_Flat;
            half4 _Tint_Steep;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half dy_dx = ddx(IN.positionWS.y);
                half dy_dy = ddy(IN.positionWS.y);

                half slopeMagnitude = length(half2(dy_dx, dy_dy));
                half slopeMask = smoothstep(_Slope_Threshold - _Slope_Blend, _Slope_Threshold + _Slope_Blend, slopeMagnitude);

                half3 col_output = lerp(_Tint_Flat.rgb, _Tint_Steep.rgb, slopeMask);
                return half4(col_output, 1.0);
            }

            ENDHLSL
        }
    }
}

```

### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Derivatives/DA_Derivatives_SlopeDetect_Graph_01.png" alt="Shader Story: Derivatives - Slope Detect" title="Shader Story: Derivatives - SLope Detect">
</p>

---

## 🔗 Related Functions

[Length](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Length.md) • [Lerp](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Lerp.md) • [Smoothstep](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Smoothstep.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://img.shields.io/badge/Join%20on%20Patreon-%20Exclusive%20Updates%20%26%20Community-orange?style=for-the-badge&logo=patreon" alt="Join on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
