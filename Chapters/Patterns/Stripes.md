# Shader Story

## Patterns & Shapes: Stripes

> **frac()**, **step()**, and multiplicative masking are used here to generate a clean, tileable stripes pattern.
Perfect for **procedural scanlines**, **stylized grid overlays**, or **patterned transitions**.



```hlsl
half2 uvTiled = frac(uv * tiling + offset);
half2 maskA = step(edge, uvTiled);
half2 maskB = step(edge, 1.0 - uvTiled);
half col_output = maskA.x * maskA.y * maskB.x * maskB.y;
```
---

### Visual demo
This pattern uses fractional tiling of UVs to repeat a shape, then masks out the center of each tile using step() against both sides.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/DA_Patterns_Stripes_Demo_01.gif" alt="Shader Story: Patterns - Stripes" title="Shader Story: Patterns - Stripes">
</p>

---
### URP Shader Code

```hlsl

Shader "DecompiledArt/Patterns/Stripes/Stripes"
{
    Properties
    {
        _Tiling_XY_Offset_ZW("Tiling_XY_Offset_ZW", Vector) = (5.0, 5.0, 0.0, 0.0)
        _EdgeOffset("EdgeOffset", Range(0.0, 0.5)) = 0.15
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

                half2 a = step(_EdgeOffset, uvs);
                half2 b = step(_EdgeOffset, (1 - uvs));
                half col_output = a.x * a.y * b.x * b.y;

                return half4(col_output.xxx, 1.0);

            }

            ENDHLSL
        }
    }
}

```


### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/DA_Patterns_Stripes_Graph_01.png" alt="Shader Story: Patterns - Stripes" title="Shader Story: Patterns - Stripes">
</p>

---

## 🔗 Related Functions

[Frac](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Frac.md) • [Step](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Step.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
