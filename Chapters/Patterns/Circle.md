# Shader Story

## Patterns & Shapes: Circle

> **smoothstep()** if used for edge softening and antialiased visuals. Useful for **stylized masks**, **transitions**, **shape blending**.



```hlsl
half shape = 1 - distance(uv, float2(0.5, 0.5));
half col_output = smoothstep(inner, outer, shape);
```
---

### Visual demo
This pattern uses the distance from the UV center to define a circular shape. A smoothstep() is then applied to blend the shape’s edge based on configurable thresholds, producing a clean soft circle mask.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/DA_Patterns_Circle_Demo_01.gif" alt="Shader Story: Patterns - Circle" title="Shader Story: Patterns - Circle">
</p>

---
### URP Shader Code

```hlsl

Shader "DecompiledArt/Patterns/Circle/Circle"
{
    Properties
    {
        _Edge_In_Out("Edge_In_Out", Vector) = (0,0,0,0)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {            
            ...
            

            half4 frag(Varyings IN) : SV_Target
            {
                half shape = 1 - distance(IN.uvs, half2(0.5, 0.5));
                half col_output = smoothstep(_Edge_In_Out.x, _Edge_In_Out.y, shape);

                return half4(col_output.xxx,1);
            }

            ENDHLSL
        }
    }
}

```


### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/DA_Patterns_Circle_Graph_01.png" alt="Shader Story: Patterns - Circle" title="Shader Story: Patterns - Circle">
</p>

---

## 🔗 Related Functions

[Smoothstep](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Smoothstep.md) • [Distance](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Distance.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
