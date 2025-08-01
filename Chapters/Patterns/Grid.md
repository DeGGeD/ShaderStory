# Shader Story

## Patterns & Shapes: Grid

> **frac()**, **abs()**, and **fwidth()** are used to create a clean, antialiased square grid pattern.
Ideal for **UI masking**, **procedural overlays**, **pattern transitions**.



```hlsl
half2 uvTiled = frac(uv * tiling + offset);
half2 uvBox = abs((uvTiled * 2.0) - 1.0) - edge;
half2 smooth = 1.0 - (uvBox / fwidth(uvBox));
half col_output = saturate(min(smooth.x, smooth.y));
```
---

### Visual demo
This pattern tiles a square grid across UV space by combining frac() and centered distance masking with screen-space derivatives.
It ensures clean anti-aliased lines across all resolutions and zoom levels.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/DA_Patterns_Grid_Demo_01.gif" alt="Shader Story: Patterns - Grid" title="Shader Story: Patterns - Grid">
</p>

---
### URP Shader Code

```hlsl

Shader "DecompiledArt/Patterns/Grid/Grid"
{
    Properties
    {
        _Tiling_XY_Offset_ZW("Tiling_XY_Offset_ZW", Vector) = (4.0, 4.0, 0.0, 0.0)
        _EdgeLength("EdgeLength", Range(0.0, 1.0)) = 0.5
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {            
            ...
            

            half4 frag(Varyings IN) : SV_Target
            {
                half2 uvs = frac(IN.uvs * _Tiling_XY_Offset_ZW.xy + _Tiling_XY_Offset_ZW.zw);

                uvs = abs((uvs * 2) - 1) - half2(_EdgeLength, _EdgeLength);
                uvs = 1 - uvs/fwidth(uvs);
                
                half col_output = saturate(min(uvs.x, uvs.y));

                return half4(col_output.xxx, 1.0);
            }

            ENDHLSL
        }
    }
}

```


### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/DA_Patterns_Grid_Graph_01.png" alt="Shader Story: Patterns - Grid" title="Shader Story: Patterns - Grid">
</p>

---

## 🔗 Related Functions

[Frac](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Frac.md) • [Abs](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Abs.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
