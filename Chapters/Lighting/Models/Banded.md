# Shader Story

## Lighting Models : Banded

> **Banded lighting** (also known as **cel lighting**) quantizes smooth lighting into discrete brightness bands.
Instead of a continuous gradient from light to dark, you are able to get the distinct “steps”. Its a common technique in e.g. comic rendering.

It’s one of the simplest yet most effective ways to give 3D objects a hand-painted, non-photorealistic feel.

---

### Visual demo

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Lighting/Models/Banded/DA_Lighting_Models_Banded_Demo_01.gif" alt="Shader Story: Lighting Models - Banded" title="Shader Story: Lighting Models - Banded">
</p>

---

```hlsl
// Pseudo-code (Complete per-vertex and per-pixel implementations, with detailed comments, are available in the related Patreon post)
// Link: https://www.patreon.com/posts/shader-story-141647294

// Regular Lambertian diffuse term
float NdotL = max(0.0, dot(normal, lightDir));

// Optional offset for better visual balance
float additive = numSteps * (useHalfStep ? 1.0 : 0.5);

// Quantize smooth lighting into discrete bands
float banded = floor((NdotL stepSize + additive) / numSteps) (numSteps / stepSize);
banded = saturate(banded);

// Combine with diffuse term and light color
return banded * diffuseIntensity * lightColor;


```

Complete implementation, with detailed comments is available on [Patreon](https://www.patreon.com/posts/shader-story-141647294).

---

### Basic idea

Banded lighting takes smooth shading (like Lambert) and breaks it into a few flat tones. Commonly applied technique, just like in cartoon or cel-shaded art.

It starts with regular lighting:
- Calculate how much the surface faces the light using the dot product (N · L). This gives a smooth gradient from bright to dark.

Then, gradient should be turned into bands:
- Instead of keeping it smooth, the brightness is "quantized" - rounding it down into a few fixed levels.

Control the smoothness:
- TDedicated properties define how many bands appear and how wide each one is.
More steps = smoother look.
Fewer steps = bold, stylized shading.

(Optionally) Bands offset applied:
- The half-step factor shifts the light bands slightly, helping to center them and avoid harsh transitions.


### Equation

> L_banded = floor((max(0, N · L) × s + a) / n) × (n / s)

Where:

- **N · L** - Lambertian diffuse
- **s** - lighting step size (smoothness)
- **a** - additive offset (half-step factor toggle)
- **n** - number of light bands

This quantized diffuse factor replaces the smooth falloff used in traditional Lambert or Blinn-Phong lighting.

---

## 🔗 Related Functions

[Max](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/MinMax.md) • [Floor](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Floor.md) • [Saturate](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/ClampSaturate.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
