Shader "DecompiledArt/Workshop/03/Transforms/Scaling"
{
    Properties
    {
        [Header(Scale XYZ)]
        _Scale ("Scale", Vector) = (1,1,1,0)
    }

    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque"
            "RenderPipeline"="UniversalPipeline"
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
                float3 _Scale;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o;

                // Educational version: Per-vertex matrix construction (NOT for production)
                float4x4 S = float4x4(
                    float4(_Scale.x, 0, 0, 0),
                    float4(0, _Scale.y, 0, 0),
                    float4(0, 0, _Scale.z, 0),
                    float4(0, 0, 0, 1)
                );

                float3 posOS = mul(S, v.positionOS).xyz;

                // Production version
                //float3 posOS = v.positionOS.xyz * _Scale;

                float3 posWS = TransformObjectToWorld(posOS);
                o.positionCS = TransformWorldToHClip(posWS);

                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                return 1.0;
            }

            ENDHLSL
        }
    }
}
