# Shader Story

## Patterns & Shapes: Square

> **fwidth()** and **saturate()** are used here to create a crisp, antialiased square mask.
Good for **stylized shapes**, **UI masks**, **scanlines**, or **procedural transitions**.



```hlsl
half2 uvOffset = abs((uv * 2.0) - 1.0) - edgeLength;
half2 aaEdge = 1.0 - (uvOffset / fwidth(uvOffset));
half col_output = saturate(min(aaEdge.x, aaEdge.y));
```
---

### Visual demo
This pattern defines a square shape by measuring the offset of each fragment from the UV center.
Using fwidth() ensures the edges stay consistent across varying screen resolutions and scale.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/DA_Patterns_Square_Demo_01.gif" alt="Shader Story: Patterns - Square" title="Shader Story: Patterns - Square">
</p>

---
### URP Shader Code

```hlsl

Shader "DecompiledArt/Patterns/Square/Square"
{
    Properties
    {
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
                half2 uvs = abs((IN.uvs.xy * 2) - 1) - _EdgeLength;
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
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/DA_Patterns_Square_Graph_01.png" alt="Shader Story: Patterns - Square" title="Shader Story: Patterns - Square">
</p>

---

## 🔗 Related Functions

[Clamp/Saturate](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/ClampSaturate.md) • [Smoothstep](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Smoothstep.md) • [Abs](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Abs.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
