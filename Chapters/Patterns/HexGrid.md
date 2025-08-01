# Shader Story

## Patterns & Shapes: Hex Grid

> This pattern creates a hexagonal grid by distorting and tiling the UVs in a skewed coordinate system, using **frac()**, **floor()**, and **step()** to define the grid lines.
Great for **map overlays**, **stylized UI**, or **futuristic screen effects**.



```hlsl
uv -= 0.5;
uv.x *= aspect_ratio;
uv *= grid_scale;

uv.x /= sin(60°); // PI / 3.0
uv.y += floor(uv.x) * 0.5;
uv = abs(frac(uv) - 0.5);

mask = step(line_width, abs(1 - max(uv.x * 1.5 + uv.y, uv.y * 2.0)));
```
---

### Visual demo
This shader manipulates UVs into a distorted space that maps them into hex tiles. Each hex cell is computed from the local fragment position inside the tile, and line width is controlled with step() for sharp borders.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/DA_Patterns_HexGrid_Demo_01.gif" alt="Shader Story: Patterns - HexGrid" title="Shader Story: Patterns - HexGrid">
</p>

---
### URP Shader Code

```hlsl

Shader "DecompiledArt/Patterns/HexGrid/HexGrid"
{
    Properties
    {
        _Tint_01("Tint_01", Color) = (1,1,1,1)
        _Tint_02("Tint_02", Color) = (0,0,0,1)
        _HexGrid_Resolution("HexGrid_Resolution", Vector) = (640, 480, 0, 0)
        _HexGrid_LineWidth("HexGrid_LineWidth", Range(0.01, 0.5)) = 0.05
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {            
            ...
            

            half4 frag(Varyings IN) : SV_Target
            {
                half2 uvs_centered = IN.uvs - half2(0.5, 0.5);
                uvs_centered.x *= _HexGrid_Resolution.x / _HexGrid_Resolution.y;
                uvs_centered *= 5.0;

                uvs_centered.x /= sin(PI / 3.0);
                uvs_centered.y += floor(uvs_centered.x) / 2.0;
                uvs_centered = abs(frac(uvs_centered) - 0.5);
                
                half mask_hex = step(_HexGrid_LineWidth, abs(1 - max(uvs_centered.x * 1.5 + uvs_centered.y, uvs_centered.y * 2.0)));
                
                half3 col_output = lerp(_Tint_01.xyz, _Tint_02.xyz, mask_hex);
                return half4(col_output, 1.0);
            }

            ENDHLSL
        }
    }
}

```


### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/DA_Patterns_HexGrid_Graph_01.png" alt="Shader Story: Patterns - HexGrid" title="Shader Story: Patterns - HexGrid">
</p>

---

## 🔗 Related Functions

[Frac](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Frac.md) • [Floor](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Floor.md) • [Step](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Step.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
