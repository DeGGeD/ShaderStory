# Shader Story

## Common HLSL Functions: Frac

> `frac(x)` returns the **fractional (non-integer) part** of a value.  
> It’s often used for **tiling UVs**, **procedural animation**, **pattern looping**, and **modular effects**.

```hlsl
float frac(float x);
float2 frac(float2 x);
float3 frac(float3 x);
...
```

---

### Visual demo 
This shader uses frac() to wrap the UV coordinates repeatedly based on a tiling multiplier, creating a looping pattern.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Frac/DA_CommonFuncs_Frac_Demo_01.gif" alt="Shader Story: Function - Frac" title="Shader Story: Function - Frac">
</p>

---
### URP Shader Code

```hlsl

Shader "DecompiledArt/CommonFunctions/Frac/Frac"
{
    Properties
    {
        _UVTile("UVTile", Range(0.5, 10.0)) = 1.0
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
            half _UVTile;
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
                return half4(frac(i.uvs * _UVTile), 0.0, 1.0);
            }

            ENDHLSL
        }
    }
}

```

### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Frac/DA_CommonFuncs_Frac_Graph_01.png" alt="Shader Story: Function - Frac" title="Shader Story: Function - Frac">
</p>

---

## 🔗 Related Functions

[Step]([../Step.md](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Step.md)) • [Remap](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Remap.md) • [Smoothstep](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Smoothstep.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
