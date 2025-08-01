# Shader Story

## Patterns & Shapes: Ripplewaves

> This pattern uses **radial distance** from the center combined with a **sine wave** and **smoothstep()** to create concentric ripple rings.
Great for water ripple effects, radial gradients, or stylized wave patterns.



```hlsl
half2 uvs_centered = uv - 0.5;
half dist = length(uvs_centered);

half wave = sin(dist * frequency);
half mask_wave = smoothstep(1.0 - thickness, 1.0, abs(wave));
```
---

### Visual demo
This shader calculates the distance from the UV center, applies a sine wave modulated by frequency, then uses smoothstep to create soft edges around the ripples.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/DA_Patterns_Ripplewaves_Demo_01.gif" alt="Shader Story: Patterns - Ripplewaves" title="Shader Story: Patterns - Ripplewaves">
</p>

---
### URP Shader Code

```hlsl

Shader "DecompiledArt/Patterns/RippleWaves/RippleWaves"
{
    Properties
    {
        _Tint_01("Tint_01", Color) = (1,1,1,1)
        _Tint_02("Tint_02", Color) = (0,0,0,1)
        _RippleWaves_Frequency("RippleWaves_Frequency", Float) = 20.0
        _RippleWaves_Thickness("RippleWaves_Thickness", Range(0.01, 1.0)) = 0.1
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {            
            ...
            

            half4 frag(Varyings IN) : SV_Target
            {
                half2 uvs_centered = IN.uvs - 0.5;
                half dist = length(uvs_centered);

                half wave = sin(dist * _RippleWaves_Frequency);
                half mask_wave = smoothstep(1.0 - _RippleWaves_Thickness, 1.0, abs(wave));

                half3 col_output = lerp(_Tint_01.xyz, _Tint_02.xyz, 1.0 - mask_wave);
                return half4(col_output, 1.0);
            }

            ENDHLSL
        }
    }
}

```


### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/DA_Patterns_Ripplewaves_Graph_01.png" alt="Shader Story: Patterns - Ripplewaves" title="Shader Story: Patterns - Ripplewaves">
</p>

---

## 🔗 Related Functions

[Sine/Cosine](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/SineCosine.md) • [Smoothstep](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Smoothstep.md) • [Length](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Length.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
