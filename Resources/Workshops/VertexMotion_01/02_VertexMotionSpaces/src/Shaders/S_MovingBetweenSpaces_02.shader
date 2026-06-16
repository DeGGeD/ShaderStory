Shader "DecompiledArt/Workshop/02/Spaces/02"
{
    Properties
    {
        [MainColor] _BaseColor ("Base Color", Color) = (0.4, 0.8, 1.0, 1.0)

        // 0 = Object, 1 = World, 2 = View
        [Enum(Object,0,World,1,View,2)] _MotionSpace ("Motion Space", Float) = 0

        _Amplitude ("Amplitude", Range(0.0, 0.5)) = 0.08
        _Frequency ("Frequency", Range(0.0, 20.0)) = 6.0
        _Speed ("Speed", Range(-4.0, 4.0)) = 1.0
        _Ambient ("Ambient", Range(0.0, 1.0)) = 0.2

        // Teaching controls: exaggerate how each non-object space behaves.
        _WorldRamp ("World Space Ramp", Range(0.01, 2.0)) = 0.15
        _ViewNear  ("View Space Near", Range(0.0, 10.0)) = 1.0
        _ViewFar   ("View Space Far",  Range(0.01, 25.0)) = 9.0
    }

    SubShader
    {
        Tags
        {
            "RenderType"     = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue"          = "Geometry"
        }

        Pass
        {
            Name "ForwardOnly"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #define WORKSHOP_TWO_PI 6.2831853h

            struct Attributes
            {
                float4 positionOS : POSITION;
                half3  normalOS   : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                half3  normalWS   : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                half  _MotionSpace;
                half  _Amplitude;
                half  _Frequency;
                half  _Speed;
                half  _Ambient;
                half  _WorldRamp;
                half  _ViewNear;
                half  _ViewFar;
            CBUFFER_END

            half GetAnimatedPhase()
            {
                // Keep animated phase bounded to avoid very large time inputs.
                return frac(_Time.y * _Speed) * WORKSHOP_TWO_PI;
            }

            half GetObjectSpaceWave(float3 positionOS, half timePhase)
            {
                return sin(positionOS.y * _Frequency + timePhase) * _Amplitude;
            }

            half GetWorldSpaceWave(float3 positionWS, half timePhase)
            {
                // Teaching mask: no motion at world origin, more motion with distance.
                half distanceMask = saturate(length(positionWS) * _WorldRamp);
                half baseWave = sin(positionWS.y * _Frequency + timePhase) * _Amplitude;
                return baseWave * distanceMask;
            }

            half GetViewSpaceWave(float3 positionVS, half timePhase)
            {
                // In view space, depth communicates camera-relative motion most clearly.
                float viewDistance = abs(positionVS.z);
                half distanceMask = saturate((viewDistance - _ViewNear) / max(_ViewFar - _ViewNear, 0.001h));
                half baseWave = sin(positionVS.x * _Frequency + timePhase) * _Amplitude;
                return baseWave * distanceMask;
            }

            Varyings Vert(Attributes IN)
            {
                Varyings OUT;

                float3 positionOS = IN.positionOS.xyz;
                half3  normalOS   = normalize(IN.normalOS);

                float3 positionWS = TransformObjectToWorld(positionOS);
                half3  normalWS   = normalize(TransformObjectToWorldNormal(normalOS));

                float4 positionCS;
                half timePhase = GetAnimatedPhase();

                // Object space: motion belongs to the mesh.
                if (_MotionSpace < 0.5h)
                {
                    half wave = GetObjectSpaceWave(positionOS, timePhase);

                    positionOS += normalOS * wave;

                    VertexPositionInputs posInputs = GetVertexPositionInputs(positionOS);
                    positionCS = posInputs.positionCS;

                    // Lighting remains intentionally simple for workshop clarity.
                    OUT.normalWS = normalize(TransformObjectToWorldNormal(normalOS));
                }
                // World space: motion belongs to the environment.
                else if (_MotionSpace < 1.5h)
                {
                    half wave = GetWorldSpaceWave(positionWS, timePhase);

                    positionWS += normalWS * wave;

                    positionCS = TransformWorldToHClip(positionWS);
                    OUT.normalWS = normalWS;
                }
                // View space: motion belongs to the camera.
                else
                {
                    float3 positionVS = TransformWorldToView(positionWS);
                    half3 normalVS = normalize(mul((float3x3)UNITY_MATRIX_V, normalWS));

                    half wave = GetViewSpaceWave(positionVS, timePhase);

                    positionVS += normalVS * wave;

                    positionCS = mul(UNITY_MATRIX_P, float4(positionVS, 1.0));
                    OUT.normalWS = normalWS;
                }

                OUT.positionCS = positionCS;
                return OUT;
            }

            half4 Frag(Varyings IN) : SV_Target
            {
                half3 normalWS = normalize(IN.normalWS);

                Light mainLight = GetMainLight();
                half NdotL = saturate(dot(normalWS, mainLight.direction));

                half3 litColor = _BaseColor.rgb * (_Ambient + NdotL * mainLight.color);
                return half4(litColor, _BaseColor.a);
            }
            ENDHLSL
        }
    }
}
