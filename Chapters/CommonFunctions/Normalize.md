# Shader Story

## Common HLSL Functions: Normalize

> normalize(v) returns the input vector scaled to a unit length (1), preserving its direction.
> This is essential for operations where only direction matters, such as **lighting**, **shading**, **direction vectors**, **interpolation**, and safe use of dot or cross products.

```hlsl
float3 dir = normalize(vec); // vector with length = 1

```
---

### Visual demo 
This shader visualizes how normalize() affects a lerped color value.
You’ll see the difference between raw interpolated colors vs. normalized vectors, which often leads to more balanced or directional outputs.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Normalize/DA_CommonFuncs_Normalize_Demo_01.gif" alt="Shader Story: Function - Normalize" title="Shader Story: Function - Normalize">
</p>

---
### URP Shader Code

```hlsl
Shader "DecompiledArt/CommonFunctions/Normalize/Normalize"
{
    Properties
    {
        _Tint_01("Tint_01", Color) = (1,1,1,1)
        _Tint_02("Tint_02", Color) = (1,1,1,1)
        [Toggle(NORMALIZE)]_Normalize("Normalize", int) = 0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature_local NORMALIZE

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
            half3 _Tint_01;
            half3 _Tint_02;
            CBUFFER_END

            half2 remap(half2 In, half2 InMinMax, half2 OutMinMax)
            {
                return OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uvs = IN.uvs;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half lerp_shape = saturate(1 - distance(remap(IN.uvs, half2(0, 1), half2(-1, 1)), half2(0, 0)));
                half3 lerp_color = lerp(_Tint_01.xyz, _Tint_02.xyz, lerp_shape);

                #ifdef NORMALIZE
                    half3 col_output = normalize(lerp_color);
                #else
                    half3 col_output = lerp_color;
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
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Normalize/DA_CommonFuncs_Normalize_Graph_01.png" alt="Shader Story: Function - Normalize" title="Shader Story: Function - Normalize">
</p>

---

## 🔗 Related Functions

[Dot](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Dot.md) • [Cross](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Cross.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
