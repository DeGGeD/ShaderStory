Shader "DecompiledArt/Workshop/03/Transforms/Translation"
{
    Properties
    {
        [Header(Translation XYZ)]
        _Translate ("Translation", Vector) = (0,0,0,0)
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
                float3 _Translate;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o;

                // Educational version: Per-vertex matrix construction (NOT for production)
                float4x4 T = float4x4(
                    1,0,0,_Translate.x,
                    0,1,0,_Translate.y,
                    0,0,1,_Translate.z,
                    0,0,0,1
                );

                float3 positionOS = mul(T, v.positionOS).xyz;

                // Production version
                // float3 positionOS = v.positionOS.xyz + _Translate;

                // Space transform
                float3 positionWS = TransformObjectToWorld(positionOS);
                o.positionCS = TransformWorldToHClip(positionWS);

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
