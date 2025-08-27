# Shader Story

## Patterns & Shapes: Voronoi Noise

> Voronoi noise is named after mathematician **Georgy Voronoi**. 
The core idea is simple: Space is divided into cells. 
Each cell is owned by a random point called a **seed**. All points closer to that seed belong to the same cell.  


<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/Noises/DA_Patterns_Noises_Voronoi_Demo_01.png" alt="Shader Story: Patterns - Voronoi Noise" title="Shader Story: Patterns - Voronoi Noise">
</p>

---
### Practical usage scenarios:  

| Use Case | Noise Application |
|-----|------------------|
| **Terrains** | Coastlines, continental shapes, cave systems | 
| **Textures Generation** | Stone, brick, tile patterns with sharp borders |
| **Water** | Ripple patterns and shoreline detail |
| **Fire / Smoke** | Good for irregular, blob‑like motion |
| **Destruction masks** | Good for destructible pbjects' pre‑cut shapes |

---

### Performance Tips
- **GPU** - use single‑instruction, multiple‑data loops.  
- **CPU** - cache grid points per tile to avoid recomputing randomness.
- **Precision** - **float** is default, but can drift at huge coordinates; **half** can reduce detail at high frequencies.  
- **Hash**  - fast integer‑based hash (e.g., xorshift) is enough; avoid expensive float‑to‑int conversions.
- **Sampling** - use linear filtering for cell centers, nearest for hard‑edge variants.  

---

### Visual demo

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/Patterns/Noises/DA_Patterns_Noises_Voronoi_Demo_01.gif" alt="Shader Story: Patterns - Voronoi Noise" title="Shader Story: Patterns - Voronoi Noise">
</p>

---
### URP Shader Code

```hlsl

Shader "DecompiledArt/Patterns/Noise/Voronoi/Voronoi_2D"
{
    Properties
    {
        _CellSize ("Cell Size", Range(0.01, 2)) = 1
        _CellWidth ("Cell Width", Range(0.1, 3)) = 1
        _BorderColor ("Border Color", Color) = (0, 0, 0, 1)
        _CellColor ("Cell Color", Color) = (1, 1, 1, 1)
        _AnimationSpeed("Animation Speed", Range(0, 5)) = 1
        _CellSizeVariation("Cell Size Variation", Range(0, 1)) = 0.3
        [Toggle(IS_ANIMATED)] _IsAnimated("Is Animated", Float) = 0
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType"="Opaque" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local IS_ANIMATED

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                half2 uvs : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                half2 uvs : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
            half _CellSize;
            half _CellWidth;
            half4 _BorderColor;
            half4 _CellColor;
            half _AnimationSpeed;
            half _CellSizeVariation;
            CBUFFER_END

            half random_2d_1d(half2 uv)
            {
                return frac(sin(dot(uv, float2(127.1, 311.7))) * 43758.5453);
            }

            half2 random_2d_2d(half2 uv)
            {
                half noiseX = frac(sin(dot(uv, float2(127.1, 311.7))) * 43758.5453);
                half noiseY = frac(sin(dot(uv, float2(269.5, 183.3))) * 43758.5453);
                return half2(noiseX, noiseY);
            }

            // Get animated cell position with size variation
            float2 getAnimatedCellPos(float2 cell)
            {
                float2 baseOffset = random_2d_2d(cell);
                
                #ifdef IS_ANIMATED
                    half time = fmod(_Time.y * _AnimationSpeed, 120.0);
                    half cellRandom = random_2d_1d(cell);
                
                // Create animated offset
                float2 animatedOffset = float2(
                    sin(time + cellRandom * 6.28318530718) * 0.3,
                    cos(time * 0.7 + cellRandom * 6.28318530718) * 0.3
                );
                
                // Dynamic size variation based on time and cell
                float sizeVariation = 1.0 + sin(time * 0.5 + cellRandom * 6.28318530718) * _CellSizeVariation;
                
                return cell + (baseOffset + animatedOffset) * sizeVariation;
                #else
                return cell + baseOffset;
                #endif
            }

            half3 voronoiNoise(half2 value)
            {
                float2 baseCell = floor(value);
                float minDistToCell = 10.0;
                float2 toClosestCell;
                float2 closestCell;

                [unroll]
                for (int x1 = -1; x1 <= 1; x1++)
                {
                    [unroll]
                    for (int y1 = -1; y1 <= 1; y1++)
                    {
                        float2 cell = baseCell + float2(x1, y1);
                        float2 cellPos = getAnimatedCellPos(cell);
                        float2 toCell = cellPos - value;
                        float dist = length(toCell) * _CellWidth;
                        if (dist < minDistToCell)
                        {
                            minDistToCell = dist;
                            toClosestCell = toCell;
                            closestCell = cell;
                        }
                    }
                }

                float minEdgeDist = 10.0;
                [unroll]
                for (int x2 = -1; x2 <= 1; x2++)
                {
                    [unroll]
                    for (int y2 = -1; y2 <= 1; y2++)
                    {
                        float2 cell = baseCell + float2(x2, y2);
                        float2 cellPos = getAnimatedCellPos(cell);
                        float2 toCell = cellPos - value;

                        if (any(abs(cell - closestCell) > 0.001))
                        {
                            float2 toCenter = 0.5 * (toClosestCell + toCell);
                            float2 diff = normalize(toCell - toClosestCell);
                            float edgeDist = dot(toCenter, diff) * _CellWidth;
                            minEdgeDist = min(minEdgeDist, edgeDist);
                        }
                    }
                }

                float randomVal = random_2d_1d(closestCell);
                return float3(minDistToCell, randomVal, minEdgeDist);
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uvs = IN.uvs;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half2 pos = IN.uvs / max(_CellSize, 0.01);

                half3 noise = voronoiNoise(pos);
                
                half3 cellColor = _CellColor.rgb;
                
                half valueChange = length(fwidth(pos)) * 0.5;
                half isBorder = 1.0 - smoothstep(0.05 - valueChange, 0.05 + valueChange, noise.z);

                half3 col_output = lerp(cellColor, _BorderColor.rgb, isBorder);
                return half4(col_output, 1.0);
            }
            ENDHLSL
        }
    }
}
```

---

## 🔗 Related Functions

[Floor](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Floor.md) • [Fmod](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Fmod.md) • [Exp](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Exp.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project on Patreon - you'll get access to the related source files, reference cheat-sheets, and other exclusive resources:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Github/ShaderStory_Github_Patreon.jpg" alt="DecompiledArt on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
