# Shader Story

## Patterns & Shapes: Perlin Noise

> Perlin noise is a smooth, pseudo‑random field created by interpolating gradients on a lattice. 
It was first described in 1983 and was widely used in early 3D games such as *Quake* and *Half‑Life*.


<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/Noises/DA_Patterns_Noises_Perlin_Demo_01.png" alt="Shader Story: Patterns - Perlin Noise" title="Shader Story: Patterns - Perlin Noise">
</p>

---
### Practical usage scenarios:  

| Use Case | Noise Application |
|-----|------------------|
| **Terrains** | Hills, valleys, cliffs | 
| **Textures Generation** | Patterns grain |
| **Clouds** | Density field |
| **Water** | Ripples |
| **Fire / Smoke** | Chaotic flicker |
| **Destruction masks** | Random spread |

---

### Perlin vs Simplex vs Value  

| Feature | Perlin | Simplex | Value |
|---------|--------|---------|-------|
| **Speed** | Moderate (many dot products) | Faster (fewer grid points) | Fastest (direct values) |
| **Artifacts** | Faceted, directional bias | Reduced | None (might but too sharp) |
| **Tiling** | Simple (wrap gradients) | More complex | Straightforward |
| **Implementation Complexity** | Medium | Medium‑high | Low |

---

### Visual demo

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/Noises/DA_Patterns_Noises_Perlin_Demo_01.gif" alt="Shader Story: Patterns - Perlin Noise" title="Shader Story: Patterns - Perlin Noise">
</p>

---
### URP Shader Code

```hlsl

Shader "DecompiledArt/Patterns/Noise/Perlin/Perlin_2D"
{
    Properties
    {
        _Noise_Seed("Noise_Seed", Integer) = 42
        _Noise_Scale ("Noise_Scale", Float) = 5.0
        _Noise_Strength ("Noise_Strength", Range(0, 5)) = 1.0
        _Noise_Contrast ("Noise_Contrast", Range(0.1, 5)) = 1.0
        [Toggle(_IS_ANIMATED)] _IsAnimated ("Is Animated", Float) = 1
        _Noise_Offset_Speed ("Noise_Offset_Speed", Vector) = (0.0, 0.0, 0.0, 0.0)
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local _IS_ANIMATED

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                half2 uvs : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                half2 uvs : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
            half _Noise_Seed;
            half _Noise_Scale;
            half _Noise_Strength;
            half _Noise_Contrast;
            half2 _Noise_Offset_Speed;
            CBUFFER_END

            // Hash generates pseudo-random gradients
            half2 hash(half2 p)
            {
                p += _Noise_Seed;
                p = half2(dot(p, half2(127.1, 311.7)), dot(p, half2(269.5, 183.3)));
                return frac(sin(p) * 43758.5453) * 2.0 - 1.0;
            }

            // Smoothstep-like fade function
            half fade(half t)
            {
                return t * t * (3.0 - 2.0 * t);
            }

            // Approximate pow for mobile (cheaper than real pow)
            half approx_pow(half x, half p)
            {
                return exp2(p * log2(x + 1e-4));
            }

            half perlin2D(half2 p)
            {
                half2 i = floor(p);
                half2 f = frac(p);

                // Gradient vectors at corners
                half2 a = hash(i + half2(0, 0));
                half2 b = hash(i + half2(1, 0));
                half2 c = hash(i + half2(0, 1));
                half2 d = hash(i + half2(1, 1));

                // Dot products between gradients and distance vectors
                half da = dot(a, f - half2(0, 0));
                half db = dot(b, f - half2(1, 0));
                half dc = dot(c, f - half2(0, 1));
                half dd = dot(d, f - half2(1, 1));

                half2 u = half2(fade(f.x), fade(f.y));

                // Bilinear interpolation
                half x1 = lerp(da, db, u.x);
                half x2 = lerp(dc, dd, u.x);
                half result = lerp(x1, x2, u.y);

                return result;
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uvs = IN.uvs * _Noise_Scale;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half2 uvs = IN.uvs;

                #ifdef _IS_ANIMATED
                    half2 t = fmod(_Time.y * _Noise_Offset_Speed, 1000.0);
                    uvs += t;
                #endif

                half mask_noise = perlin2D(uvs);
                
                // Normalization
                mask_noise = mask_noise * 0.5 + 0.5;

                mask_noise = approx_pow(mask_noise, _Noise_Contrast);
                mask_noise *= _Noise_Strength;

                half3 col_output = mask_noise.xxx;

                return half4(col_output, 1.0);
            }
            ENDHLSL
        }
    }
}
```

---

## 🔗 Related Functions

[Floor](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Floor.md) • [Fmod](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Fmod.md) • [Exp](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Exp.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
