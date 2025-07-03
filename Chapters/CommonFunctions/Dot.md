# Shader Story

## Common HLSL Functions: Dot

> dot(a, b) returns the cosine of the angle between two normalized vectors, scaled by their lengths.
> It's useful for: **lighting calculations**, **Fresnel effects**, **Edge detection**

```hlsl
float d = dot(normalize(vecA), normalize(vecB)); // returns -1 to 1

```
---

### Visual demo 
This shader demonstrates the dot() function by computing the angle between the surface normal and a user-defined light direction. It shades the surface from dark (opposite) to bright (aligned), producing a soft lighting effect based on vector alignment.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Dot/DA_CommonFuncs_Dot_Demo_01.gif" alt="Shader Story: Function - Dot" title="Shader Story: Function - Dot">
</p>

---
### URP Shader Code

```hlsl
Shader "DecompiledArt/CommonFunctions/Dot/Dot"
{
    Properties
    {
        _LightDir("Light Direction", Vector) = (0, 1, 0, 0)
        _Tint_01("Tint_01", Color) = (0, 0, 0.2, 1)
        _Tint_02("Tint_02", Color) = (1, 1, 1, 1)
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
                half3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                half3 normalWS : NORMAL;
            };

            CBUFFER_START(UnityPerMaterial)
            half3 _LightDir;
            half4 _Tint_01;
            half4 _Tint_02;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half3 n = normalize(IN.normalWS);
                half3 l = normalize(_LightDir);

                half d = saturate(dot(n, l));

                half3 col_output = lerp(_Tint_01.rgb, _Tint_02.rgb, d);
                return half4(col_output, 1.0);
            }

            ENDHLSL
        }
    }
}

```

### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Dot/DA_CommonFuncs_Dot_Graph_01.png" alt="Shader Story: Function - Dot" title="Shader Story: Function - Dot">
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

If this article helped you, consider supporting the project:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://img.shields.io/badge/Join%20on%20Patreon-%20Exclusive%20Updates%20%26%20Community-orange?style=for-the-badge&logo=patreon" alt="Join on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
