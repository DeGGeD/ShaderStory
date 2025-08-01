# Shader Story

## Patterns & Shapes: Checkerboard

> **floor()** and **fmod()** are used here to generate a tileable checkerboard pattern by alternating colors based on the parity of tiled UV coordinates.
Perfect for **stylized grid overlays**, **procedural scanlines** and/or **patterned transitions**.



```hlsl
half2 uvs = floor(uv * tiling);
half mask_board = fmod(uvs.x + uvs.y, 2.0);
```
---

### Visual demo
This pattern divides UV space into a grid by flooring scaled UVs, then uses the sum of the cell coordinates modulo 2 to alternate between two colors, creating a classic checkerboard effect.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/DA_Patterns_Checkerboard_Demo_01.gif" alt="Shader Story: Patterns - Checkerboard" title="Shader Story: Patterns - Checkerboard">
</p>

---
### URP Shader Code

```hlsl

Shader "DecompiledArt/Patterns/Checkerboard/Checkerboard"
{
    Properties
    {
        _Tint_01("Tint_01", Color) = (1,1,1,1)
        _Tint_02("Tint_02", Color) = (1,1,1,1)
        _BoardScale("BoardScale", float) = 2.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {            
            ...
            

            half4 frag(Varyings IN) : SV_Target
            {
                half2 uvs = floor(IN.uvs);
                half mask_board = fmod(uvs.x + uvs.y, 2.0);

                half3 col_output = lerp(_Tint_01, _Tint_02, mask_board).xyz;

                return half4(col_output, 1.0);
            }

            ENDHLSL
        }
    }
}

```


### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/DA_Patterns_Checkerboard_Graph_01.png" alt="Shader Story: Patterns - Checkerboard" title="Shader Story: Patterns - Checkerboard">
</p>

---

## 🔗 Related Functions

[Floor](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Floor.md) • [Fmod](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Fmod.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
