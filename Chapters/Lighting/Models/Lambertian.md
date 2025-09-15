# Shader Story

## Lighting Models : Lambertian

> Lambertian lighting, named after Johann Heinrich Lambert, is one of the most fundamental and widely used models for diffuse reflection in computer graphics.

It works on the principle that light striking a surface is scattered evenly in all directions - perfect for matte materials such as **chalk**, **clay**, **unpolished stone**, etc.

Its strength lies in its simplicity: brightness depends only on the cosine of the angle between the surface normal and the incoming light direction. This is known as Lambert’s Cosine Law.

```hlsl
// Pseudo-code (Complete per-vertex and per-pixel implementations, with detailed comments, are available in the related Patreon post)
// Link: https://www.patreon.com/posts/shader-story-137878509


float3 SurfaceColor;          // surface color
float3 LightColor;            // light color * intensity
float LightAttenuation;       // shadowing / distance falloff

float NdotL = max(0.0, dot(normalDirection, lightDirection));

float LambertDiffuse = NdotL * SurfaceColor; // Lambert's cosine law
float3 finalColor = LambertDiffuse * LightAttenuation * LightColor;

```

---

### Basic idea

Light is emitted from a source, reflected from the surface, and perceived by the viewer (camera).

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Lighting/Models/Lambertian/DA_Lighting_Models_Lambertian_BasicIdea.png" alt="Shader Story: Lighting Models - Lambertian. Basic Idea" title="Shader Story: Lighting Models - Lambertian. Basic Idea">
</p>

### Cosine Falloff

The amount of diffuse reflection decreases with the angle between the surface normal **N** and the light reflection direction **L**.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Lighting/Models/Lambertian/DA_Lighting_Models_Lambertian_CosineFalloff.png" alt="Shader Story: Lighting Models - Lambertian. Cosine Falloff" title="Shader Story: Lighting Models - Lambertian. Cosine Falloff">
</p>

### Spherical Falloff

Diffuse light contribution also decreases with distance, following the light’s attenuation curve (0 to 1).

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Lighting/Models/Lambertian/DA_Lighting_Models_Lambertian_SphericalFalloff.png" alt="Shader Story: Lighting Models - Lambertian. Spherical Falloff" title="Shader Story: Lighting Models - Lambertian. Spherical Falloff">
</p>

### Lambertian Equation

> d = Σ (from i=0 to n) [ intensity(light_i) × diffuse(material_property) × attenuation(light_i) × max(0, N · L) ]

- Summation over all incident light sources
- Surface diffuse property (material roughness, 0 → black / 1 → full reflection)
- Light attenuation (distance and shadow falloff)
- Cosine factor max(0, dot(N,L))

The final diffuse **d** is computed as the **sum over all lights of their intensity**, the surface’s **diffuse material property**, **light attenuation**, and the **Lambertian cosine factor max(0, N·L)**. It ensures that light contributes proportionally to how directly it strikes the surface.

---

### Visual demo

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Lighting/Models/Lambertian/DA_Lighting_Models_Lambertian_Demo_01.gif" alt="Shader Story: Lighting Models - Lambertian" title="Shader Story: Lighting Models - Lambertian">
</p>


Complete per-vertex and per-pixel implementations, with detailed comments, are available on [Patreon](https://www.patreon.com/posts/shader-story-137878509).

---

## 🔗 Related Functions

[Max](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/MinMax.md) • [Dot](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Dot.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
