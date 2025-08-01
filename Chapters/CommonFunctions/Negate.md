# Shader Story

## Common HLSL Functions: Negate

> Negating a value flips its sign.  
> Use `-x` or multiply by `-1.0` to invert a value or direction.  
> This is useful for **mirrored UVs**, **reversed gradients**, **animation flipping**, and **directional math**.

```hlsl
float negated = -x;
// or
float negated = x * -1.0;

```

---

### Visual demo 
This shader demonstrates how negation can flip UV-space symmetries.
When toggled, the output inverts horizontally and vertically around the center.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Negate/DA_CommonFuncs_Negate_Demo_01.gif" alt="Shader Story: Function - Negate" title="Shader Story: Function - Negate">
</p>

---
### URP Shader Code

```hlsl
Shader "DecompiledArt/CommonFunctions/Negate/Negate"
{
    Properties
    {
        _UVTile("UVTile", Range(0.5, 10.0)) = 1.0
        [Toggle(USE_NEGATE)] _UseNegate("useNegate", Int) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature USE_NEGATE

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
                #ifdef USE_NEGATE
                    half2 result = mul((frac(i.uvs * _UVTile) - 0.5), -1.0);
                #else
                    half2 result = frac(i.uvs * _UVTile) - 0.5;
                #endif

                half col_output = max(result.x, result.y);
                return half4(col_output, col_output, col_output, 1.0);
            }

            ENDHLSL
        }
    }
}
```

### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Negate/DA_CommonFuncs_Negate_Graph_01.png" alt="Shader Story: Function - Negate" title="Shader Story: Function - Negate">
</p>

---

## 🔗 Related Functions

[Step](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Step.md) • [Remap](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Remap.md) • [Smoothstep](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Smoothstep.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
