# Shader Story

## Patterns & Shapes: Simplex Noise

> Ken Perlin created Simplex noise in 2001 to replace his earlier 1985 “Perlin noise.”  
It fixes the grid‑like visual artifacts of older Perlin noise and runs faster on early GPUs.


<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/Noises/DA_Patterns_Noises_Simplex_Demo_01.png" alt="Shader Story: Patterns - Simplex Noise" title="Shader Story: Patterns - Simplex Noise">
</p>

---
### Practical usage scenarios:  

| Use Case | Noise Application |
|-----|------------------|
| **Terrains** | Smooth transitions, no visible grid | 
| **Textures Generation** | Repeated patterns that look natural |
| **Clouds** | Fluffy shapes |
| **Water** | Ripples & waves |
| **Fire / Smoke** | Turbulence & domain warping |
| **Destruction masks** | Noise‑driven masks for sharp edges |

---

### Simplex vs Perlin vs Value  (Pros / Cons)

| Noise Type | Pros | Cons |
|------------|------|------|
| **Simplex** | • No grid‑like artifacts<br>• Faster on GPU (fewer samples)<br>• Built‑in tiling options | • Slightly more math per sample |
| **Perlin** | • Familiar, easy to understand<br>• Works well for low‑poly art | • Visible square artefacts in high‑detail<br>• Slower on modern GPUs |
| **Value** | • Cheap (hash + lerp)<br>• Good for low‑detail, stylised effects | • Rougher, less smooth transitions |

---

### Performance Tips
- **GPU vs CPU** - GPUs are massively parallel; evaluate noise in a fragment shader for full‑screen effects. On CPU, pre‑compute a small 2‑D texture (e.g., 256 × 256) and sample it with bilinear interpolation.  
- **Precision** - **float** is default; **half** is for low‑detail layers.  
- **Hash** - A simple integer hash (XOR & bit shifts) is fast. Avoid heavy math like sine or pow inside the loop.  
- **Caching** - Re‑use the same gradient lookup table per frame if the noise is static.

---

### Visual demo

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/Noises/DA_Patterns_Noises_Simplex_Demo_01.gif" alt="Shader Story: Patterns - Simplex Noise" title="Shader Story: Patterns - Simplex Noise">
</p>

---
### URP Shader Code

```hlsl

Shader "DecompiledArt/Patterns/Noise/Simplex/Simplex_2D"
{
    Properties
    {
        _Noise_Scale("Noise_Scale", Range(1, 50)) = 20
        _Noise_Strength("Noise_Strength", Range(0.0, 20.0)) = 1.0
        _Noise_Contrast("Noise_Contrast", Range(0.1, 20.0)) = 1.0
        [Toggle(IS_ANIMATED)] _IsAnimated ("Is Animated", Float) = 0
        _Noise_AnimSpeed("Noise_AnimSpeed", Range(0.01, 20)) = 0.5
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
            half _Noise_Strength;
            half _Noise_Contrast;
            CBUFFER_END

            // Helpers
            half2 mod289(half2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
            half3 mod289(half3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
            half3 permute(half3 x) { return mod289(((x*34.0)+1.0)*x); }

            float noise(half2 v)
            {
                const half4 C = half4(0.211324865405187,  
                                        0.366025403784439,  
                                       -0.577350269189626,  
                                        0.024390243902439);
                // First corner
                half2 i  = floor(v + dot(v, C.yy));
                half2 x0 = v -   i + dot(i, C.xx);

                // Other corners
                half2 i1;
                i1 = (x0.x > x0.y) ? half2(1.0, 0.0) : half2(0.0, 1.0);
                half2 x1 = x0.xy - i1 + C.xx;
                half2 x2 = x0.xy - 1.0 + 2.0 * C.xx;

                // Permutations
                i = mod289(i);
                half3 p = permute(permute(
                          i.y + half3(0.0, i1.y, 1.0))
                        + i.x + half3(0.0, i1.x, 1.0));

                half3 x_ = frac(p * C.w) * 2.0 - 1.0;
                half3 h = abs(x_) - 0.5;
                half3 ox = floor(x_ + 0.5);
                half3 a0 = x_ - ox;

                // Gradients
                half2 g0 = half2(a0.x, h.x);
                half2 g1 = half2(a0.y, h.y);
                half2 g2 = half2(a0.z, h.z);

                // Normalize gradients
                half3 t = max(0.5 - half3(dot(x0,x0), dot(x1,x1), dot(x2,x2)), 0.0);
                half3 t2 = t * t;
                half3 t4 = t2 * t2;
                float3 n = t4 * half3(dot(g0,x0), dot(g1,x1), dot(g2,x2));

                return 70.0 * dot(n, 1.0);
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
                    time = fmod(_Time.y * _Noise_AnimSpeed, 1000.0);
                #endif

                float mask_noise = noise(uvs + time);
                // normalize output
                mask_noise = 0.5 * (mask_noise + 1.0);

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
