# Shader Story

## Patterns & Shapes: Turbulence Noise

> Turbulence noise comes from Ken Perlin’s 1983 “Turbulence” variant of value noise.


<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/Noises/DA_Patterns_Noises_Turbulence_Demo_01.png" alt="Shader Story: Patterns - Turbulence Noise" title="Shader Story: Patterns - Turbulence Noise">
</p>

---
### Practical usage scenarios:  

| Use Case | Noise Application |
|-----|------------------|
| **Terrains** | Height maps, erosion masks, and small rock detail | 
| **Textures Generation** | Procedural wood grain, marble veins, stone |
| **Clouds** | Volumetric density for realistic cloud formations |
| **Water** | Ripples on a surface and foam patches |
| **Fire / Smoke** | Turbulent smoke layers and ember motion |
| **Destruction VFX masks** | Good as a decision on where objects break or dissolve during gameplay |

---

### Performance Tips
- **GPU vs CPU** - compute on the GPU whenever possible; a few texture lookups and linear interpolation are cheap.  
- **CPU** - use to pre‑compute a small texture array of hash values.
- **Precision** - **float** is default; **half** on low-end devices.  
- **Hash**  - Simple bit‑mixing (Xorshift) is fast; avoid expensive float conversions.  
- **Caching** - Re‑use computed noise across shaders when possible.  
- **Sampling** - Reduce texture resolution for distant objects; use mipmaps.  

---

### Visual demo

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/Noises/DA_Patterns_Noises_Turbulence_Demo_01.gif" alt="Shader Story: Patterns - Turbulence Noise" title="Shader Story: Patterns - Turbulence Noise">
</p>

---
### URP Shader Code

```hlsl

Shader "DecompiledArt/Patterns/Noise/Turbulence/Turbulence_2D"
{
    Properties
    {
        _Noise_Scale("Noise_Scale", Range(1, 50)) = 20
        _Noise_Strength("Noise_Strength", Range(0.0, 20.0)) = 1.0
        _Noise_Contrast("Noise_Contrast", Range(0.1, 20.0)) = 1.0
        _Noise_Octaves("Noise_Octaves", Range(1, 5)) = 2
        [Toggle(IS_ANIMATED)] _IsAnimated ("Is Animated", Float) = 0
        _Noise_AnimSpeed("Noise_AnimSpeed", Range(0.01, 1)) = 0.5
        _Shape_AnimSpeed("Shape_AnimSpeed", Range(0.01, 1)) = 0.2
        _Octave_TimeOffset("Octave_TimeOffset", Range(0.1, 5.0)) = 1.0
        _Scale_Variation("Scale_Variation", Range(0.0, 2.0)) = 0.3
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
            int _Noise_Octaves;
            half _Shape_AnimSpeed;
            half _Octave_TimeOffset;
            half _Scale_Variation;
            CBUFFER_END

            // Helpers
            half2 mod289(half2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
            half3 mod289(half3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
            half3 permute(half3 x) { return mod289(((x*34.0)+1.0)*x); }

            half simplexNoise(half2 v)
            {
                const half4 C = half4(0.211324865405187,  
                                        0.366025403784439,  
                                       -0.577350269189626,  
                                        0.024390243902439);

                half2 i  = floor(v + dot(v, C.yy));
                half2 x0 = v - i + dot(i, C.xx);

                half2 i1 = (x0.x > x0.y) ? half2(1.0, 0.0) : half2(0.0, 1.0);
                half2 x1 = x0 - i1 + C.xx;
                half2 x2 = x0 - 1.0 + 2.0 * C.xx;

                i = mod289(i);
                half3 p = permute(permute(i.y + half3(0.0, i1.y, 1.0))
                                + i.x + half3(0.0, i1.x, 1.0));

                half3 x_ = frac(p * C.w) * 2.0 - 1.0;
                half3 h = abs(x_) - 0.5;
                half3 ox = floor(x_ + 0.5);
                half3 a0 = x_ - ox;

                half2 g0 = half2(a0.x, h.x);
                half2 g1 = half2(a0.y, h.y);
                half2 g2 = half2(a0.z, h.z);

                half3 t = max(0.5 - half3(dot(x0,x0), dot(x1,x1), dot(x2,x2)), 0.0);
                half3 t2 = t * t;
                half3 t4 = t2 * t2;
                half3 n = t4 * half3(dot(g0,x0), dot(g1,x1), dot(g2,x2));

                return 70.0 * dot(n, 1.0);
            }

            half noise(half2 uv, int octaves, half baseTime)
            {
                half sum = 0.0;
                half freq = 1.0;
                half amp = 1.0;
                
                for (int i = 0; i < octaves; i++)
                {
                    // Different time offsets for each octave to create shape variation
                    half octaveTime = baseTime + (float(i) * _Octave_TimeOffset);
                    
                    // Animate the sampling position differently for each octave
                    half2 timeOffset = half2(
                        sin(octaveTime * _Shape_AnimSpeed) * 0.5,
                        cos(octaveTime * _Shape_AnimSpeed * 0.7) * 0.5
                    );
                    
                    // Vary the scale over time for each octave
                    half scaleVariation = 1.0 + sin(octaveTime * _Shape_AnimSpeed * 0.3) * _Scale_Variation;
                    
                    // Sample noise with animated parameters
                    half noise = abs(simplexNoise((uv + timeOffset) * freq * scaleVariation));
                    
                    sum += noise * amp;
                    freq *= 2.0;
                    amp *= 0.5;
                }
                return sum;
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

                half mask_noise = saturate(noise(uvs + time, _Noise_Octaves, time));
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
