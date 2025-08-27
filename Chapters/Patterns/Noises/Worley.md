# Shader Story

## Patterns & Shapes: Worley Noise

> Worley noise was introduced by Steven Worley in 1996 in his paper A Cellular Texture Basis Function. It was designed as a procedural method to generate natural-looking cellular patterns, useful for simulating stone, water, and organic textures in computer graphics.


<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/Noises/DA_Patterns_Noises_Worley_Demo_01.png" alt="Shader Story: Patterns - Worley Noise" title="Shader Story: Patterns - Worley Noise">
</p>

---
### Practical usage scenarios:  

| Use Case | Noise Application |
|-----|------------------|
| **Terrains** | Rocks, Cliffs. Distances create jagged edges | 
| **Textures Generation** | Natural variation without seams. Mix with Perlin for smoother edges |
| **Clouds** | Fluffy shapes |
| **Water** | Bubble‑like distances; warp domains for waves |
| **Fire / Smoke** | Good for uneven flame fronts & turbulence |
| **Destruction masks** | Good for distance thresholds |

---

### Worley vs Perlin vs Simplex

| Feature | Worley | Perlin | Simplex |
|---------|--------|--------|---------|
| Noise type | Cell / distance | Gradient | Gradient |
| Seamlessness | Easy with hash tiling | Needs special gradients | Needs special gradients |
| GPU cost | Low (distance calcs) | Low‑medium | Medium |
| Visual feel | Cellular, jagged | Smooth, natural | Smooth, less directional |

---

### Performance Tips
- **GPU vs CPU** - compute on the GPU whenever possible; a few texture lookups and linear interpolation are cheap.  
- **CPU** - use to pre‑compute a small texture array of hash values.
- **Precision** - **float** is default; **half** can reduce detail at high frequencies.  
- **Hash**  - fast multiplicative hash is quick but lower quality.  
- **Caching** - store grid indices as integers; convert to float only when needed. Use a texture lookup for hash tables on GPU.  

---

### Visual demo

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/Noises/DA_Patterns_Noises_Worley_Demo_01.gif" alt="Shader Story: Patterns - Worley Noise" title="Shader Story: Patterns - Worley Noise">
</p>

---
### URP Shader Code

```hlsl

Shader "DecompiledArt/Patterns/Noise/Worley/Worley_2D"
{
    Properties
    {
        _Noise_Scale("Noise_Scale", Range(1, 50)) = 20
        _Noise_Strength("Noise_Strength", Range(0.0, 2.0)) = 1.0
        _Noise_Contrast("Noise_Contrast", Range(0.1, 5.0)) = 1.0
        _Noise_Jitter("Noise_Jitter", Range(0.0, 1.0)) = 0.8
        [Toggle(IS_ANIMATED)] _IsAnimated ("Is Animated", Float) = 0
        _Noise_AnimSpeed("Noise_AnimSpeed", Range(0.01, 50)) = 0.5
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
            half _Noise_AnimSpeed;
            half _Noise_Jitter;
            half _Noise_Strength;
            half _Noise_Contrast;
            CBUFFER_END

            half2 hash2(half2 p)
            {
                p = half2(dot(p, half2(127.1, 311.7)), dot(p, half2(269.5, 183.3)));
                return frac(sin(p) * 43758.5453123);
            }

            half2 getJitteredPosition(half2 cellPos, half time)
            {
                half2 baseHash = hash2(cellPos);
                half2 basePosition = half2(0.5, 0.5);
                half2 jitterOffset = (baseHash - 0.5) * _Noise_Jitter;
                
                #ifdef IS_ANIMATED
                    half2 animHash = hash2(cellPos + 100.0);
                    half2 animOffset = sin(time * 0.8 + animHash * 6.283185) * 0.2 * _Noise_Jitter;
                    jitterOffset += animOffset;
                #endif
                
                jitterOffset = clamp(jitterOffset, -0.45, 0.45);
                
                return basePosition + jitterOffset;
            }

            float worleyNoise(half2 uv, half time)
            {
                half2 gridPos = floor(uv);
                half2 localPos = frac(uv);
                
                half minDist = 10.0;
                
                for(int y = -1; y <= 1; y++)
                {
                    for(int x = -1; x <= 1; x++)
                    {
                        half2 neighbor = half2(half(x), half(y));
                        half2 cellPos = gridPos + neighbor;
                        
                        half2 featurePoint = getJitteredPosition(cellPos, time);
                        
                        half2 diff = neighbor + featurePoint - localPos;
                        half dist = length(diff);
                        
                        minDist = min(minDist, dist);
                    }
                }
                
                return minDist;
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
                half2 uvs = IN.uvs * _Noise_Scale;

                half time = 0.0;
                #ifdef IS_ANIMATED
                    time = _Time.y * _Noise_AnimSpeed * 0.1; 
                #endif

                half mask_noise = worleyNoise(uvs, time);
                
                half col_output = 1.0 - saturate(mask_noise);
                col_output = saturate(col_output * _Noise_Strength);
                col_output = pow(col_output, _Noise_Contrast);

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
