# Shader Story

## Lighting Models : Fresnel

> The **Fresnel Lighting** describes how the amount of reflected light on a surface depends on the viewing angle.
When looking directly at a surface (normal incidence), reflection is minimal. But when viewing at a grazing angle, reflection increases dramatically.

This technique is widely used for:
- **Rim lighting** in stylized or toon shading
- Reflective materials like **glass**, **water**, or **polished metal**
- **Highlighting silhouettes** and enhancing form readability

---

### Visual demo

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Lighting/Models/Fresnel/DA_Lighting_Models_Fresnel_Demo_01.gif" alt="Shader Story: Lighting Models - Fresnel" title="Shader Story: Lighting Models - Fresnel">
</p>

---

```hlsl
// Pseudo-code (Complete per-vertex and per-pixel implementations, with detailed comments, are available in the related Patreon post)
// Link: https://www.patreon.com/posts/shader-story-141138764

// Determine how much the surface faces the camera
NdotV = dot(normal, viewDir)

// Fresnel factor increases at grazing angles
fresnelFactor = pow((1 - saturate(NdotV)), contrast)
fresnelFactor *= intensity

// Scale the chosen color by the Fresnel intensity
return color * fresnelFactor


```

Complete per-vertex and per-pixel implementations, with detailed comments, are available on [Patreon](https://www.patreon.com/posts/shader-story-141138764).

---

### Basic idea

The Fresnel effect enhances how light interacts with surfaces viewed at glancing angles.
Instead of relying only on direct lighting, it emphasizes the edges of objects, making them appear to “glow” or reflect more light as they turn away from the viewer.

Technically, this is achieved by comparing the surface normal with the view direction **(dot(N, V))**.

When the surface faces directly toward the camera, the Fresnel factor is small.
As the viewing angle becomes shallower (the surface turns away), the factor increases, brightening the rim of the object.


### Equation

> d = (1 - N·V) ^ p × i × Tint

Where:

- **N·V** - dot product between the surface normal and view direction
- **p** - Fresnel power, controls how sharp the rim appears
- **i** - intensity, scales the overall brightness of the effect
- **Tint** - per-material color parameter, tints the Fresnel glow

---

## 🔗 Related Functions

[Dot](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Dot.md) • [Power](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Power.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
