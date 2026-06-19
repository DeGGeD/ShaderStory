Shader "DecompiledArt/Workshop/03/Transforms/TranslationScalingRotation"
{
    Properties
    {
        [Header(Translation)]
        _Translate ("Translation", Vector) = (0,0,0,0)

        [Header(Scale)]
        _Scale ("Scale", Vector) = (1,1,1,0)

        [Header(Rotation XYZ (Degrees))]
        _Rotation ("Rotation", Vector) = (0,0,0,0)

        [KeywordEnum(TRS, TSR, RTS, RST, STR, SRT)]
        _TransformOrder ("Transform Order", Float) = 0
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

            #pragma shader_feature_local _TRANSFORMORDER_TRS _TRANSFORMORDER_TSR _TRANSFORMORDER_RTS _TRANSFORMORDER_RST _TRANSFORMORDER_STR _TRANSFORMORDER_SRT

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
                float3 _Scale;
                float3 _Rotation;
            CBUFFER_END

            // -----------------------------------------------------------------
            // Matrix builders used for workshop explanation.
            //
            // In production usually avoid constructing full matrices per
            // vertex when simpler math will do, but they are excellent for
            // explaining how TRS is organized and why order matters.
            // -----------------------------------------------------------------

            // Translation lives in the last column.
            // It affects positions because positions use w = 1.
            float4x4 Translation(float3 t)
            {
                return float4x4(
                    1, 0, 0, t.x,
                    0, 1, 0, t.y,
                    0, 0, 1, t.z,
                    0, 0, 0, 1
                );
            }

            // Scale - diagonal
            float4x4 Scale(float3 s)
            {
                return float4x4(
                    s.x, 0,   0,   0,
                    0,   s.y, 0,   0,
                    0,   0,   s.z, 0,
                    0,   0,   0,   1
                );
            }

            float4x4 Rotation(float3 rDeg)
            {
                float3 r = radians(rDeg);

                float cx = cos(r.x); float sx = sin(r.x);
                float cy = cos(r.y); float sy = sin(r.y);
                float cz = cos(r.z); float sz = sin(r.z);

                float4x4 Rx = float4x4(
                    1, 0,  0,  0,
                    0, cx, -sx,0,
                    0, sx, cx, 0,
                    0, 0,  0,  1
                );

                float4x4 Ry = float4x4(
                    cy,  0, sy, 0,
                    0,   1, 0,  0,
                    -sy, 0, cy, 0,
                    0,   0, 0,  1
                );

                float4x4 Rz = float4x4(
                    cz, -sz, 0, 0,
                    sz, cz,  0, 0,
                    0,  0,   1, 0,
                    0,  0,   0, 1
                );

                return mul(Rz, mul(Ry, Rx));
            }

            Varyings vert (Attributes v)
            {
                Varyings o;

                float4x4 T = Translation(_Translate);
                float4x4 S = Scale(_Scale);
                float4x4 R = Rotation(_Rotation);

                // Use w = 1 because this is a position.
                // If we were transforming a direction, we would use w = 0 so
                // translation would not affect it.
                float4 pos = v.positionOS;

                // Order matters.
                //
                // When we write T * R * S and multiply by a column vector,
                // the actual execution order is right-to-left:
                // S first, then R, then T.
                #if defined(_TRANSFORMORDER_TRS)
                    pos = mul(T, mul(R, mul(S, pos)));
                #elif defined(_TRANSFORMORDER_TSR)
                    pos = mul(T, mul(S, mul(R, pos)));
                #elif defined(_TRANSFORMORDER_RTS)
                    pos = mul(R, mul(T, mul(S, pos)));
                #elif defined(_TRANSFORMORDER_RST)
                    pos = mul(R, mul(S, mul(T, pos)));
                #elif defined(_TRANSFORMORDER_STR)
                    pos = mul(S, mul(T, mul(R, pos)));
                #elif defined(_TRANSFORMORDER_SRT)
                    pos = mul(S, mul(R, mul(T, pos)));
                #endif

                // The custom TRS logic above stays in object space.
                // After that, Unity still applies the regular object-to-world
                // and world-to-clip transforms for rasterization.
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