# Shader Story

## Lighting Models : Halftone

> **Halftone lighting** is a stylized shading technique inspired by traditional printmaking, comics, and illustration.

Instead of smooth gradients, lighting is represented using repeating pattern textures that vary in density based on light intensity. Such shading is usually layered on top of a standard lighting model (such as Blinn-Phong).
The lighting result controls where the halftone pattern appears and how strong it is.

Top usage scenarios:
- **Comic-style visuals**
- **Stylized games**
- **NPR (Non-Photorealistic Rendering) pipelines**

---

### Visual demo

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Lighting/Models/Halftone/DA_Lighting_Models_Halftone_Demo_01.gif" alt="Shader Story: Lighting Models - Halftone" title="Shader Story: Lighting Models - Halftone">
</p>

---

```hlsl
// Pseudo-code (Complete per-vertex and per-pixel implementations, with detailed comments, are available in the related Patreon post)
// Link: https://www.patreon.com/posts/shader-story-148056797


// Compute standard lighting (Blinn–Phong or similar)
lighting = ComputeLighting(N, V, L)

// Choose UVs for halftone pattern
if (patternSpace == SCREEN_SPACE)
    uv_ht = ScreenSpaceUV(position)
else
    uv_ht = ObjectUV

// Apply tiling and rotation to pattern UVs
uv_ht = RotateAndTile(uv_ht)

// Sample halftone pattern
pattern = SamplePatternTexture(uv_ht)

// Compute lighting threshold from surface orientation
lightFactor = dot(N, L)
threshold = Remap(lightFactor)

// Smooth transition for softer edges
mask = smoothstep(threshold, threshold + softness, pattern)

// Convert lit color to grayscale halftone shade
luminance = dot(litColor, LUMA_WEIGHTS)
halftoneShade = luminance * shadeMultiplier

// Blend between normal lighting and halftone shading
finalColor = lerp(litColor, halftoneShade, mask)

```

Complete implementation, with detailed comments, is available on [Patreon](https://www.patreon.com/posts/shader-story-148056797).

---

### Basic idea

The core idea behind halftone lighting:

- **Compute lighting as usual.** A regular lighting model (diffuse + specular) determines how lit each fragment is.

- **Convert lighting into a threshold.** The angle between the surface normal and the light direction defines whether a surface is considered lit or shadowed.

- **Compare lighting against a pattern texture.** A repeating halftone texture (e.g. dots, lines, noise) is used as a mask.
Where the pattern value exceeds the lighting threshold, shading appears.

- **Replace smooth shading with stylized tones.** Instead of continuous gradients, light and shadow emerge as patterned regions, creating a graphic, printed look.


### Halftone Lighting Equation

> C_output = lerp(C_lit, L(C_lit) × S, H)

Where:

- **C_lit** - surface color after standard lighting
- **L(C_lit)** - luminance of the lit color
- **S** - halftone shade multiplier
- **H** - halftone mask derived from pattern texture and lighting threshold

The halftone mask H is defined as:

> H = smoothstep(T, T + ε, P(UV))

Where:

- **P(UV)** - sampled halftone pattern texture
- **T** - lighting-based threshold
- **ε** – softness factor controlling edge smoothness

---

## 🔗 Related Functions

[Smoothstep](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Smoothstep.md) • [Dot](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Dot.md) • [Lerp](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Lerp.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
