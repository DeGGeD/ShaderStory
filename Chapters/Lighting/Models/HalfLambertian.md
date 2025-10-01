# Shader Story

## Lighting Models : Half-Lambertian

Traditional Lambertian diffuse lighting is widely used in real-time rendering, but it has a common drawback: surfaces facing away from the light quickly fall into complete darkness. While this is mathematically correct, in games and stylized rendering it can make models appear too harsh or flat.

Half-Lambertian lighting is an alternative that softens this transition. It ensures back-facing surfaces receive at least some illumination, resulting in smoother shading, better readability of silhouettes, and an overall softer look. This approach was famously popularized in Valve’s Half-Life 2 shaders.

---

### Visual demo

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Lighting/Models/HalfLambertian/DA_Lighting_Models_HalfLambertian_Demo_01.gif" alt="Shader Story: Lighting Models - Half-Lambertian" title="Shader Story: Lighting Models - Half-Lambertian">
</p>

---

```hlsl
// Pseudo-code (Complete per-vertex and per-pixel implementations, with detailed comments, are available in the related Patreon post)
// Link: https://www.patreon.com/posts/shader-story-140108682


// Inputs: normalWS (world normal), lightDir (directional light), lightColor, attenuation, wrap factor, contrast
float NdotL = dot(normalWS, lightDir)

// Shift the dot product with "wrap" to allow some light on back faces
float wrapped = saturate((NdotL + wrap) / (1.0 + wrap))

// Apply contrast for sharper or softer transitions
float diff = pow(wrapped, contrast)

// Final diffuse contribution
colorDiffuse = diff x attenuation x lightColor

// Final output
colorOutput = baseColor x colorDiffuse

```

Complete per-vertex and per-pixel implementations, with detailed comments, are available on [Patreon](https://www.patreon.com/posts/shader-story-140108682).

---

### Basic idea

- **Standard Lambert:** Computes diffuse as max(0, dot(N, L)). Back faces get zero light.

- **Half-Lambert:** Shifts and normalizes the dot product with a wrap factor. This means that even when dot(N, L) is negative, the formula pushes values into the positive range. The result: a smooth falloff rather than a hard cutoff.

- **Contrast control:** An exponent parameter adjusts how quickly the shading transitions between lit and unlit. Higher contrast yields sharper highlights, while lower contrast gives a softer gradient.

This lighting model is especially useful in stylized rendering or cases where strict physical accuracy is less important than readability and softness.


### Half-Lambertian Equation

> NdotL = dot(N, L)
> 
> wrapped = saturate((NdotL + wrap) / (1 + wrap))
> 
> diffuseTerm = pow(wrapped, contrast)
> 
> L_halfLambert = diffuseTerm x attenuation x LightColor
> 

Where:
**N** - surface normal
**L** - light direction
**wrap** - defines how much to “push” lighting into the shadowed side (0 = standard Lambertian)
**contrast** - controls the curve of the lighting falloff
**attenuation** - handles distance/light falloff
**LightColor** - main light’s color and intensity

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
