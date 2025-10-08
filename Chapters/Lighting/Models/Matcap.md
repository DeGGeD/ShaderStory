# Shader Story

## Lighting Models : Matcap

> The **Matcap (Material Capture) lighting model** is a screen-space shading technique that uses a pre-rendered texture (the matcap) to simulate complex lighting and reflections without requiring actual scene lights. The texture encodes how a material responds to light from every viewing angle, effectively “capturing” the look of a specific lighting setup.

Originally popularized in sculpting software like ZBrush and Blender. Model allows to visualize materials with minimal performance cost. The lighting effect is achieved by mapping the view-space normal direction of each pixel into the matcap texture, so that the color lookup directly represents the material’s response to light from that view angle.

---

### Visual demo

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Lighting/Models/Matcap/DA_Lighting_Models_Matcap_Demo_01.gif" alt="Shader Story: Lighting Models - Matcap" title="Shader Story: Lighting Models - Matcap">
</p>

---

```hlsl
// Pseudo-code (Complete per-vertex and per-pixel implementations, with detailed comments, are available in the related Patreon post)
// Link: https://www.patreon.com/posts/shader-story-140584174


// Inputs: normalWS - world-space normal
// Output: matcap color based on view direction

// Convert normal to view space
half3 normalVS = normalize(TransformWorldToViewDir(normalWS)) 

// Map to [0,1] UV space
half2 matcapUV = normalVS.xy * 0.5 + 0.5

// Lookup color
half3 col_matcap = SAMPLE_TEXTURE2D(BaseMap, samplerBaseMap, matcapUV).rgb

// Apply contrast
col_matcap = pow(matcapColor, _MatcapContrast.xxx)

// Adjust brightness
col_matcap *= _MatcapBrightness

// Tint and output
half3 col_output = col_matcap * _Tint.rgb
return half4(col_output, 1.0)

```

Complete per-vertex and per-pixel implementations, with detailed comments, are available on [Patreon](https://www.patreon.com/posts/shader-story-140584174).

---

### Basic idea

The normal direction of each pixel (in view/camera space) determines where to sample from the matcap texture.

The **texture** itself **encodes precomputed lighting** and **reflection information**. Basically, it's a “snapshot” of how a material looks under a specific lighting environment.

Because the lookup depends on the view-space normal, the **shading automatically reacts to camera movement**, mimicking real reflection behavior without actual scene lighting.

This **approach completely bypasses dynamic lights, shadows, or specular calculations** - it’s effectively image-based lighting, but baked into a 2D texture.


### Minnaert Equation

> d = T(N_v​.xy​ / 2 + 0.5) ^ γ x b x Tint

Where:

- **N_v**​ - surface normal. Transformed into view space
- **T(UV)** - matcap texture sample
- **γ** - contrast exponent
- **b** - brightness factor
- **Tint** - per-material color parameter

---
Matcap shading proves that simple ideas can deliver stunning results. With just one texture, you can fake complex lighting, reflections, and material depth. It’s fast, flexible, and perfect for stylized rendering.

This lighting model remains one of the most elegant tricks in a technical artist’s toolbox. Sometimes, less really is more.


---

## 🔗 Related Functions

[Normalize](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Normalize.md) • [Power](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Power.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
