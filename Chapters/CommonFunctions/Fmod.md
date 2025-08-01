# Shader Story

## Common HLSL Functions: Fmod

> fmod(x, y) returns the remainder of x divided by y, preserving the sign of the numerator.
> It's especially useful for **tiling patterns**, **time wrapping**, and **procedural animation**.

```hlsl
float fmod(float x, float y);
```
---

### Visual demo
This shader uses fmod to generate animated, scrolling vertical stripes.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Fmod/DA_CommonFuncs_Fmod_Demo_01.gif" alt="Shader Story: Function - Fmod" title="Shader Story: Function - Fmod">
</p>

---
### URP Shader Code

```hlsl

Shader "DecompiledArt/CommonFunctions/Fmod/Fmod"
{
    Properties
    {
        _Tint_01("Tint_01", Color) = (1,1,1,1)
        _Tint_02("Tint_02", Color) = (0,0,0,1)
        _Line_Width("Line_Width", Range(0.01, 2.0)) = 0.2
        _Speed("Speed", Float) = 1.0
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
            half _Line_Width;
            half _Speed;
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
                half uv_x = IN.uvs.x + (_Time.y * _Speed); 
                half mask_line = step(_Line_Width, fmod(uv_x, 1.0));

                half3 col_output = lerp(_Tint_01, _Tint_02, mask_line).xyz;

                return half4(col_output, 1.0);
            }

            ENDHLSL
        }
    }
}

```

### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Fmod/DA_CommonFuncs_Fmod_Graph_01.png" alt="Shader Story: Function - Fmod" title="Shader Story: Function - Fmod">
</p>

---

## 🔗 Related Functions

[Smoothstep]([../Smoothstep.md](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Smoothstep.md)) • [Step](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Step.md) • [Frac](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Frac.md) • [Lerp](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Lerp.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
