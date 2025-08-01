# Shader Story

## Patterns & Shapes: Line

> **fwidth()** and **saturate()** are used to define a crisp, antialiased line in UV space.  
> Good for for **stylized masks**, **transitions**, **scanlines**, or any UI elements requiring crisp anti-aliasing.



```hlsl
half2 uvs = abs(uv + float2(-offsetX, 0.0)) - float2(width, 1.0);
half2 mask_line = 1 - (uvs / fwidth(uvs));
half col_output = saturate(min(mask_line.x, mask_line.y));
```
---

### Visual demo
This pattern draws a centered vertical line based on a horizontal offset and customizable width. Shape is created by using fwidth() for screen-space derivatives and saturate() to clamp the result.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/DA_Patterns_Line_Demo_01.gif" alt="Shader Story: Patterns - Line" title="Shader Story: Patterns - Line">
</p>

---
### URP Shader Code

```hlsl

Shader "DecompiledArt/Patterns/Line/Line"
{
    Properties
    {
        _Offset_X("Offset_X", Float) = 0.5
        _Line_Width("Line_Width", Range(0.0, 0.5)) = 0.2
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {            
            ...
            

            half4 frag(Varyings IN) : SV_Target
            {
                half2 uvs = abs(IN.uvs + half2(mul(_Offset_X, -1.0), 0.0)) - half2(_Line_Width, 1.0);
                half2 mask_line = 1 - (uvs / fwidth(uvs));

                half col_output = saturate(min(mask_line.x, mask_line.y));

                return half4(col_output.xxx, 1.0);
            }

            ENDHLSL
        }
    }
}

```


### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/DA_Patterns_Line_Graph_01.png" alt="Shader Story: Patterns - Line" title="Shader Story: Patterns - Line">
</p>

---

## 🔗 Related Functions

[Clamp/Saturate](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/ClampSaturate.md) • [Smoothstep](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Smoothstep.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
