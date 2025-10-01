# Shader Story

## Lighting Models : Ambient Lighting & Hemi Lights

In real-time rendering, light defines form, depth, and mood. While direct lighting (such as Lambertian or Blinn-Phong) handles illumination from explicit sources, the world also needs **Ambient** and **Hemi (hemispheric)** lighting to simulate the contribution of the environment.

**Ambient light** ensures surfaces in shadow are never completely black, while **Hemi** lights provide a smooth gradient between the **ground** and the **sky**, enriching the sense of directionality even without strong light sources.

---

### Visual demo

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Lighting/Models/AmbientHemi/DA_Lighting_Models_AmbientHemi_Demo_01.gif" alt="Shader Story: Lighting Models - Ambient & Hemi Lighting" title="Shader Story: Lighting Models - Ambient & Hemi Lighting">
</p>

---

```hlsl
// Pseudo-code (Complete per-vertex and per-pixel implementations, with detailed comments, are available in the related Patreon post)
// Link: https://www.patreon.com/posts/shader-story-140104400


// Inputs: surface normal in world space
float3 normalWS = normalize(surfaceNormalWS)

// Base color
float3 colorBase = texture(BaseMap, uv) * Tint

// Initialize lighting contribution
float3 colorLighting = 0

// Sample Spherical Harmonics (SH) baked into the scene
float3 ambient = SampleSH(normalWS)
colorLighting += ambient

// Use the Y component of the normal to blend between ground and sky
half mask = remap(normalWS.y, -1, 1, 0, 1)
mask = pow(abs(mask), HemiContrast)
float3 hemi = lerp(TintGround, TintSky, mask) * HemiPower
colorLighting += hemi

// Final color
float4 colorOutput = float4(colorBase * saturate(colorLighting), 1.0)

```

Complete per-vertex and per-pixel implementations, with detailed comments, are available on [Patreon](https://www.patreon.com/posts/shader-story-140104400).

---

### Basic idea

- **Ambient Lighting:**
Represents global light coming from the environment, regardless of direction. It ensures all objects are lit to some degree, preventing harsh black shadows. In modern rendering, ambient light is often provided via Spherical Harmonics (SH), which captures low-frequency environment lighting.

- **Hemi Lighting:**
A simplified model for directional environmental light. It blends between two colors - sky and ground. They are based on the surface’s upward or downward orientation. Surfaces facing up receive more of the sky tint, while downward-facing surfaces receive more of the ground tint. This provides a natural gradient and emphasizes orientation relative to the environment.


### Equation

Ambient Lighting:
> L_ambient = SH(n)

where **n** is the surface normal and **SH(n)** is the evaluation of spherical harmonics.

Hemi Lighting:
> L_hemi = ((1 - m) x C_ground + m x C_sky) * P

where:
- **m** = remap(n.y, -1, 1, 0, 1) ^ contrast
- **n.y** - Y-component of the surface normal
- **C_ground**, **C_sky** - sky/ground tint colors
- **P** - global intensity

Final Color:
> C_out = C_base * saturate(L_ambient + L_hemi)

Keep in mind that Ambient and Hemi lighting are not complete lighting models. They only approximate how the environment influences surfaces.

---

## 🔗 Related Functions

[Max](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/MinMax.md) • [Dot](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Dot.md) • [Saturate](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/ClampSaturate.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
