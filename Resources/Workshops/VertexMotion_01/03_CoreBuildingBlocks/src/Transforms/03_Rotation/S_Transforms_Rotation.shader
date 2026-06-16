Shader "DecompiledArt/Workshop/03/Transforms/Rotation"
{
    Properties
    {
        [Header(Rotation XYZ (Degrees))]
        _Rotation ("Rotation", Vector) = (0,0,0,0)
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
                float3 _Rotation;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o;

                // Convert degrees to radians
                // trigonometric funcions expect radians
                float3 rotRad = radians(_Rotation);

                // X Rotation
                float cosX = cos(rotRad.x);
                float sinX = sin(rotRad.x);

                float4x4 Rx = float4x4(
                    float4(1, 0,    0,     0),
                    float4(0, cosX, -sinX, 0),
                    float4(0, sinX, cosX,  0),
                    float4(0, 0,    0,     1)
                );

                // Y Rotation
                float cosY = cos(rotRad.y);
                float sinY = sin(rotRad.y);

                float4x4 Ry = float4x4(
                    float4(cosY,  0, sinY, 0),
                    float4(0,     1, 0,    0),
                    float4(-sinY, 0, cosY, 0),
                    float4(0,     0, 0,    1)
                );

                // Z Rotation
                float cosZ = cos(rotRad.z);
                float sinZ = sin(rotRad.z);

                float4x4 Rz = float4x4(
                    float4(cosZ, -sinZ, 0, 0),
                    float4(sinZ, cosZ,  0, 0),
                    float4(0,    0,     1, 0),
                    float4(0,    0,     0, 1)
                );

                // Educational version: Sequential rotation (order matters)
                // float4 pos = v.positionOS;

                // pos = mul(Rx, pos);
                // pos = mul(Ry, pos);
                // pos = mul(Rz, pos);

                // Production version
                float4 pos = mul(Rz, mul(Ry, mul(Rx, v.positionOS)));

                float3 posWS = TransformObjectToWorld(pos.xyz);
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