# Shader Story

## Patterns & Shapes: Value Noise

> First described by Ken Perlin in 1983 as a simple random field.  
In its core, its a function that assigns a single random value to each point on a lattice grid.  


<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/Noises/DA_Patterns_Noises_Value_Demo_01.png" alt="Shader Story: Patterns - Value Noise" title="Shader Story: Patterns - Value Noise">
</p>

---
### Practical usage scenarios:  

| Use Case | Noise Application |
|-----|------------------|
| **Terrains** | Simple, repeatable details | 
| **Textures Generation** | Repeated patterns that look natural |
| **Clouds** | Fluffy shapes |
| **Water** | Low‑frequency noise for calm waves; high‑frequency for foam |
| **Fire / Smoke** | Domain warping |
| **Destruction masks** | Threshold the noise to create breakup or damage masks for VFX elements |

---

### Simplex vs Perlin vs Value

| Noise Type | Pros | Cons |
|------------|------|------|
| **Simplex** | • No grid‑like artifacts<br>• Faster on GPU (fewer samples)<br>• Built‑in tiling options | • Slightly more math per sample |
| **Perlin** | • Familiar, easy to understand<br>• Works well for low‑poly art | • Visible square artefacts in high‑detail<br>• Slower on modern GPUs |
| **Value** | • Cheap (hash + lerp)<br>• Good for low‑detail, stylised effects | • Rougher, less smooth transitions |

---

### Performance Tips
- **GPU vs CPU** - compute on the GPU whenever possible; a few texture lookups and linear interpolation are cheap.  
- **Precision** - **float** is default; **half** can reduce detail at high frequencies.  
- **Hash** - a simple integer hash (XOR + bitshift) runs faster than complex permutations and avoids branching.   
- **Caching** - Re‑use the same lookups per frame if the noise is static.

---

### Visual demo

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/Noises/DA_Patterns_Noises_Value_Demo_01.gif" alt="Shader Story: Patterns - Value Noise" title="Shader Story: Patterns - Value Noise">
</p>

---
### URP Shader Code

```hlsl

Shader "DecompiledArt/Patterns/Noise/Value/Value_2D"
{
    Properties
    {
        _Noise_Scale ("Noise_Scale", Range(0.1, 50)) = 10
        _Noise_Strength ("Noise_Strength", Range(0, 1)) = 1
        _Noise_Contrast ("Noise_Contrast", Range(0.1, 5)) = 1
        [Toggle(IS_ANIMATED)] _IsAnimated ("Is Animated", Float) = 0
        _Noise_AnimSpeed ("Noise_AnimSpeed", Range(0.1, 1.0)) = 0.1
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType"="Opaque" }
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local IS_ANIMATED
            
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
            half _Noise_Scale;
            half _Noise_Strength;
            half _Noise_Contrast;
            half _Noise_AnimSpeed;
            CBUFFER_END

            // 2D random hash
            half random2(half2 st)
            {
                return frac(sin(dot(st, float2(127.1, 311.7))) * 43758.5453);
            }

            half noise(half2 st, half time)
            {
                half2 i = floor(st);
                half2 f = frac(st);
                
                // Smoothstep interpolation
                half2 u = f * f * (3.0 - 2.0 * f);
                
                float n00 = random2(i + float2(0.0, 0.0) + float2(time, time));
                float n10 = random2(i + float2(1.0, 0.0) + float2(time, time));
                float n01 = random2(i + float2(0.0, 1.0) + float2(time, time));
                float n11 = random2(i + float2(1.0, 1.0) + float2(time, time));

                return lerp(
                    lerp(n00, n10, u.x),
                    lerp(n01, n11, u.x),
                    u.y
                );
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
                half2 st = IN.uvs * _Noise_Scale;
                half time = 0.0;
                
                #ifdef IS_ANIMATED
                    time = fmod(_Time.y *  _Noise_AnimSpeed * 0.1, 1000.0);
                #endif

                half mask_noise = noise(st, time);
                half col_output = saturate(pow(mask_noise, _Noise_Contrast)) * _Noise_Strength;
                
                return half4(col_output.xxx, 1.0);
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
