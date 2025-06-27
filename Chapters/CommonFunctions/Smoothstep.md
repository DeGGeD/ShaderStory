# Shader Story

## Common HLSL Functions: Smoothstep

> `smoothstep(edge_01, edge_02, x)` returns a smooth Hermite interpolation between `0.0` and `1.0`, based on the value of `x` within the `[edge_01, edge_02]` range. 
>  It’s perfect for **soft transitions**, **anti-aliased masks**, **gradients**, and **stylized blending**.

```hlsl
float smoothstep(float edge_01_, float edge_02_, float x);
```

### Visual demo 
This example uses smoothstep() across the horizontal UV axis, producing a smooth vertical blend between two colors.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Step/DA_CommonFuncs_Step_Demo_01.gif" alt="Shader Story: Function - Smoothstep" title="Shader Story: Function - Smoothstep">
</p>

### URP Shader Code

```hlsl

Shader "DecompiledArt/CommonFunctions/Smoothstep/Smoothstep"
{
    Properties
    {
        _Tint01("Tint01", Color) = (1,1,1,1)
        _Tint02("Tint02", Color) = (1,1,1,1)
        _StepEdgeStart("StepEdgeStart", Range(0.0 ,1.0)) = 1.0
        _StepEdgeEnd("StepEdgeEnd", Range(0.0 ,1.0)) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                half2 uvs: TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                half2 uvs: TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
            half4 _Tint01;
            half4 _Tint02;
            half _StepEdgeStart;
            half _StepEdgeEnd;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uvs = IN.uvs;
                return OUT;
            }

            half4 frag(Varyings i) : SV_Target
            {
                half edge_step = smoothstep(_StepEdgeStart, _StepEdgeEnd, i.uvs.x);

                half3 col_smoothstep = lerp(_Tint01.xyz, _Tint02.xyz, edge_step);
                half4 col_output = half4(col_smoothstep, 1.0);
                return col_output;
            }

            ENDHLSL
        }
    }
}
```

### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Step/DA_CommonFuncs_Step_Graph_01.png" alt="Shader Story: Function - Smoothstep" title="Shader Story: Function - Smoothstep">
</p>