# Shader Story

## Lighting Models : Toon

> **Toon lighting** (also called cel shading) is a non-photorealistic lighting model designed to produce clear, stylized shading with sharp transitions between light and shadow.

Instead of smoothly interpolating light intensity, toon shading quantizes lighting into bands.

Top usage scenarios: the **illustrated look** commonly seen in anime, and other **stylized** games.

---

### Visual demo

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Lighting/Models/Toon/DA_Lighting_Models_Toon_Demo_01.gif" alt="Shader Story: Lighting Models - Toon Lighting" title="Shader Story: Lighting Models - Toon Lighting">
</p>

---

```hlsl
// Pseudo-code (Complete implementation, with detailed comments, is available on Patreon)
// Link: https://www.patreon.com/posts/shader-story-148942040


// Inputs
N = normalize(surfaceNormal)
V = normalize(viewDirection)
L = normalize(lightDirection)

// ===========================
// Toon Diffuse
// ===========================
NdotL = saturate(dot(N, L))

// Convert smooth lighting into a sharp band
toonDiffuse = smoothstep(ToonRampMin, ToonRampMax, NdotL)
toonDiffuse *= DiffuseIntensity

// ===========================
// Hemisphere Ambient
// ===========================
hemiMask = N.y * 0.5 + 0.5
hemiColor = lerp(GroundColor, SkyColor, hemiMask)
hemiColor *= HemiIntensity

// Reduce ambient in fully lit areas
ambient = hemiColor * (1 - toonDiffuse * HemiLitReduction)

// ===========================
// Toon Specular
// ===========================
H = normalize(V + L)
NdotH = saturate(dot(N, H))

specularTerm = pow(NdotH, SpecularGloss)

// Hard threshold for toon highlight
specularMask = step(SpecularThreshold, specularTerm)

// Only allow specular on lit surfaces
specularMask *= step(0.5, toonDiffuse)

specular = specularMask * SpecularColor * SpecularIntensity * LightColor

// ===========================
// Fresnel Rim
// ===========================
fresnelFactor = pow(1 - saturate(dot(N, V)), FresnelPower)
fresnelMask = smoothstep(FresnelMin, FresnelMax, fresnelFactor)
fresnel = fresnelMask * FresnelIntensity * SkyColor

// ===========================
// Final Lighting
// ===========================
lighting =
    toonDiffuse * LightColor +
    ambient +
    specular +
    fresnel

finalColor = baseColor * lighting
```

Complete implementation, with detailed comments, is available on [Patreon](https://www.patreon.com/posts/shader-story-148942040).

---

### Basic idea

Instead of treating light as a smooth physical phenomenon, toon lighting reinterprets lighting as a set of discrete visual components:

- The diffuse term (N·L) is represented by a narrow range and pushed through a threshold, turning gradual shading into distinct lit and shadowed areas.

- The ambient component is handled separately with hemisphere lighting and an ambient color, so the object never falls completely into black, with extra control over lit areas.

- Specular highlights appear as somewhat binary shapes or regions. Their presence is driven by a sharp condition: a threshold that is either met or not.

- Fresnel is used as a rim accent. It is not a physically accurate reflection, but it helps the silhouette pop against the background.


### Toon Lighting Equation

> D = smoothstep(R_min, R_max, max(0, N · L)) · k_d
>
> A = lerp(Ground, Sky, (N_y · 0.5 + 0.5)) · k_h · (1 − D · r)
>
> S = step(T_s, (N · H)^g) · step(0.5, D) · C_s · k_s
>
> F = smoothstep(F_min, F_max, (1 − N · V)^p) · k_f
> 
> L_final = BaseColor · (D + A + S + F)

Where:

- N, L, V, H: normal vector, light, view, and half vectors
- R_min, R_max: toon ramp thresholds
- k_d, k_s, k_h, k_f: intensity factors
- C_s: specular color
- Ground, Sky: hemisphere lighting tintings
- g: specular gloss exponent
- p: Fresnel contribution

---

## 🔗 Related Functions

[Smoothstep](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Smoothstep.md) • [Dot](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Dot.md) • [Saturate](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/ClampSaturate.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon: you'll get access to the related source files and reference cheat-sheets.

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
  <a href="https://www.buymeacoffee.com/shaderstory" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_BuyMeACoffee.png" alt="DecompiledArt on Buy Me a Coffee">
  </a>
</p>

Your support helps keep this library open and free for everyone.
