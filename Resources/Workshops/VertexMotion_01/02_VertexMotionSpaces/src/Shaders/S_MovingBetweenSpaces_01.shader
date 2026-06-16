Shader "DecompiledArt/Workshop/02/Spaces/01"
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
            CBUFFER_END

            #define WORKSHOP_TWO_PI 6.2831853h
            
            // Keep animated phase bounded to avoid very large time inputs.
            half GetAnimatedPhase()
            {
                return frac(_Time.y * _Speed) * WORKSHOP_TWO_PI;
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

                // Object space:
                // motion belongs to the mesh
                if (_MotionSpace < half(0.5))
                {
                    half wave = sin(positionOS.y * _Frequency + timePhase) * _Amplitude;

                    positionOS += normalOS * wave;

                    VertexPositionInputs posInputs = GetVertexPositionInputs(positionOS);
                    positionCS = posInputs.positionCS;

                    OUT.normalWS = normalize(TransformObjectToWorldNormal(normalOS));
                }
                // World space:
                // motion belongs to the environment
                else if (_MotionSpace < half(1.5))
                {
                    half wave = sin(positionWS.y * _Frequency + timePhase) * _Amplitude;

                    positionWS += normalWS * wave;

                    positionCS = TransformWorldToHClip(positionWS);
                    OUT.normalWS = normalWS;
                }
                // View space:
                // motion belongs to the camera
                else
                {
                    float3 positionVS = TransformWorldToView(positionWS);

                    // World normal -> view normal so the displacement follows
                    // the camera-aligned frame instead of the mesh or world.
                    half3 normalVS = normalize(mul((float3x3)UNITY_MATRIX_V, normalWS));

                    half wave = sin(positionVS.x * _Frequency + timePhase) * _Amplitude;

                    positionVS += normalVS * wave;

                    positionCS = mul(UNITY_MATRIX_P, float4(positionVS, 1.0));

                    // Keep lighting in world space so the slide stays focused on
                    // motion ownership rather than full space-correct shading.
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