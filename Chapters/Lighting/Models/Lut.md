# Shader Story

## Lighting Models : Lookup Tables (LUT)

> **Lookup Table (LUT)** is a way to remap complex lighting outputs or color responses using precomputed textures.

Instead of recalculating light equations every frame, LUT store color or lighting relationships inside a texture, which the shader simply samples at runtime.

This technique is used for **stylized rendering** and **color grading**.

---

### Visual demo

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Lighting/Models/Lut/DA_Lighting_Models_Lut_Demo_01.gif" alt="Shader Story: Lighting Models - Lookup Table (LUT)" title="Shader Story: Lighting Models - Lookup Table (LUT)">
</p>

---

```hlsl
// Pseudo-code (Complete per-vertex and per-pixel implementations, with detailed comments, are available in the related Patreon post)
// Link: https://www.patreon.com/posts/shader-story-lut-142912145


// Input lighting color
inputColor = (r, g, b)

// Sample LUT per channel (1D lookup along X axis)
lutColor.r = sampleLUT(inputColor.r)
lutColor.g = sampleLUT(inputColor.g)
lutColor.b = sampleLUT(inputColor.b)

// Blend original lighting with LUT-mapped result
finalColor = lerp(
    inputColor,
    lutColor × inputColor,
    LutTransition
)

// Output color after LUT coloring
return finalColor

```

Complete per-vertex and per-pixel implementations, with detailed comments, are available on [Patreon](https://www.patreon.com/posts/shader-story-lut-142912145).

---

### Basic idea

A Lookup Table (LUT) acts as a color transformation map.
Each lighting value (or color channel) is used as a coordinate to fetch precomputed color information from a texture.

This allows to fine-tune the lighting output. Without the actual lighting setup change it's possible to set the tone remapping to stylize the project visuals.

Typical workflow:
- Compute lighting normally (e.g., Blinn-Phong, Lambertian, etc.)
- Use lighting color or intensity as input to a LUT texture
- Sample LUT and blend results with the original lighting
- Adjust blending strength to control stylization


### Image-Based Lighting Equation

> C_output = lerp(C_in, T(C_in) × C_in, α)

Where:

Where:

- **C_in** - input lighting color
- **T(C_in)** - texture lookup from LUT
- **α** - LUT blending factor (transition control)

---

## 🔗 Related Functions

[Lerp](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Lerp.md) • [Dot](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Dot.md) • [Saturate](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/ClampSaturate.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
