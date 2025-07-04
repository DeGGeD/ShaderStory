# Shader Story

## Common HLSL Functions: Cross

> cross(a, b) computes a vector perpendicular to both input vectors a and b, following the right-hand rule.
> It’s essential for calculating **surface tangents**, **bitangents**, **normal maps**, and various geometric operations in shaders.

```hlsl
float3 c = cross(vecA, vecB); // perpendicular to vecA and vecB

```
---

### Visual demo 
This shader demonstrates the cross() function by computing the perpendicular vector between the surface normal (in view space) and a tangent vector (assumed in tangent space as (1, 0, 0)). The resulting vector is visualized as color output, showing how cross products produce orthogonal directions.

<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Cross/DA_CommonFuncs_Cross_Demo_01.gif" alt="Shader Story: Function - Cross" title="Shader Story: Function - Cross">
</p>

---
### URP Shader Code

```hlsl
Shader "DecompiledArt/CommonFunctions/Cross/Cross"
{
    Properties
    {
        [Toggle(CROSS_BXA)]_Cross_BxA("Cross_BxA", int) = 0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature_local CROSS_BXA

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                half3 normalOS   : NORMAL;
                half4 tangentOS  : TANGENT;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                half3 normalVS    : TEXCOORD0;
                half3 tangentTS   : TEXCOORD1;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                half3 normalWS = TransformObjectToWorldNormal(IN.normalOS);

                OUT.normalVS = mul((float3x3)UNITY_MATRIX_V, normalWS);
                OUT.tangentTS = half3(1, 0, 0); // In tangent space, the tangent vector is always (1,0,0)

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                #ifdef CROSS_BXA
                    half3 col_output = cross(IN.tangentTS, IN.normalVS);
                #else
                    half3 col_output = cross(IN.normalVS, IN.tangentTS);
                #endif

                return half4(col_output, 1.0);
            }

            ENDHLSL
        }
    }
}

```

### URP Shader graph
<p align="center">
<img src="https://github.com/DeGGeD/ShaderStory/blob/main/Resources/Images/Chapters/CommonFunctions/Cross/DA_CommonFuncs_Cross_Graph_01.png" alt="Shader Story: Function - Cross" title="Shader Story: Function - Cross">
</p>

---

## 🔗 Related Functions

[Dot](https://github.com/DeGGeD/ShaderStory/blob/main/Chapters/CommonFunctions/Dot.md)

---

## ❤️ Support Shader Story

If this article helped you, consider supporting the project:

<p align="center">
  <a href="https://www.patreon.com/decompiled_art" target="_blank">
    <img src="https://img.shields.io/badge/Join%20on%20Patreon-%20Exclusive%20Updates%20%26%20Community-orange?style=for-the-badge&logo=patreon" alt="Join on Patreon">
  </a>
</p>

Your support helps keep this library open, growing, and free for everyone.
