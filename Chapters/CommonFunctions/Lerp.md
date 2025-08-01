# Shader Story

## Common HLSL Functions: Lerp

> lerp(a, b, t) returns the linear interpolation between values a and b, using t (0–1) as the blend factor.
> It's foundational in shaders for blending, animation, transitions, gradients, and cross-fading effects.

```hlsl
float3 result = lerp(colorA, colorB, blendFactor); // Linear interpolation

```
---

### Visual demo 
This shader demonstrates a color blend using lerp() across the horizontal UV (x) axis.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Lerp/DA_CommonFuncs_Lerp_Demo_01.gif" alt="Shader Story: Function - Lerp" title="Shader Story: Function - Lerp">
</p>

---
### URP Shader Code

```hlsl
Shader "DecompiledArt/CommonFunctions/Lerp/Lerp"
{
    Properties
    {
        _Tint_01("Tint_01", Color) = (1.0, 0.0, 0.0, 1.0)
        _Tint_02("Tint_02", Color) = (0.0, 0.0, 1.0, 1.0)
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
            half4 _Tint_01;
            half4 _Tint_02;
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
                return half4(lerp(_Tint_01.xyz, _Tint_02.xyz, IN.uvs.x), 1.0);
            }

            ENDHLSL
        }
    }
}


```

### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Lerp/DA_CommonFuncs_Lerp_Graph_01.png" alt="Shader Story: Function - Lerp" title="Shader Story: Function - Lerp">
</p>

---

## 🔗 Related Functions

[Step](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Step.md) •
[Remap](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Remap.md) • 
[Smoothstep](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Smoothstep.md) • 
[Exp](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Exp.md) • 
[Abs](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Abs.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
