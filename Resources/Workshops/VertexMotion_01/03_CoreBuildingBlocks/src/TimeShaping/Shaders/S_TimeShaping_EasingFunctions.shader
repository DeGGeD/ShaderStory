Shader "DecompiledArt/Workshop/03/TimeShaping/EasingFunctions"
{
    Properties
    {
        [MainColor] _BaseColor ("Base Color", Color) = (1.0, 0.9, 0.7, 1.0)

        // Keep the live demo enum intentionally short and readable.
        // The actual easing math is centralized in the shared include.
        [Enum(Linear,0,InSine,1,InOutSine,2,InQuad,3,OutBounce,4,InOutBack,5,OutElastic,6)]
        _EaseMode ("Easing Function", Float) = 0

        [Min(0.001)] _Duration ("Duration (Seconds)", Float) = 1.5
        _Distance ("Distance", Float) = 0.75

        // Direction of the translation in object space.
        _MoveDirectionOS ("Move Direction (Object Space)", Vector) = (0,1,0,0)

        // 0 = one-way looping motion 0->1
        // 1 = ping-pong motion 0->1->0
        [Toggle] _PingPong ("Ping Pong", Float) = 0

        // Lets you compare shaped time vs raw linear time.
        [Toggle] _UseRawPhase ("Use Raw Phase (Bypass Ease)", Float) = 0

        // Optional: keep motion centered around the rest pose for presentation.
        // Off: object moves from rest pose toward target.
        // On: object moves from -Distance to +Distance around rest pose.
        [Toggle] _CenterAroundOrigin ("Center Around Rest Pose", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "TAEasingFunctions.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                half3 normalOS    : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                half3  normalWS    : TEXCOORD0;
                half   debugPhase  : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                half3 _MoveDirectionOS;
                half  _Distance;
                half  _Duration;
                half  _EaseMode;
                half  _PingPong;
                half  _UseRawPhase;
                half  _CenterAroundOrigin;
            CBUFFER_END

            inline half GetLoopPhase01()
            {
                half invDuration = rcp(max(_Duration, 0.0001h));
                return frac(_Time.y * invDuration);
            }

            inline half ToPingPong01(half t)
            {
                // 0..1 sawtooth -> 0..1..0 triangle wave
                return 1.0h - abs(2.0h * t - 1.0h);
            }

            inline half3 SafeNormalizeHalf3(half3 v)
            {
                half lenSq = dot(v, v);
                return (lenSq > 1e-6h) ? v * rsqrt(lenSq) : half3(0.0h, 1.0h, 0.0h);
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                float3 positionOS = IN.positionOS.xyz;

                // Whole-object-style translation:
                // every vertex receives the same time value.
                half baseT = GetLoopPhase01();
                half loopT = lerp(baseT, ToPingPong01(baseT), saturate(_PingPong));

                int easeMode = (int)round(_EaseMode);
                half easedT = ApplyEaseByEnum(loopT, easeMode);
                half finalT = lerp(easedT, loopT, saturate(_UseRawPhase));

                half3 moveDirOS = SafeNormalizeHalf3(_MoveDirectionOS);

                // Two presentation modes:
                // 1) One-way motion:   0 -> Distance
                // 2) Centered motion: -Distance -> +Distance
                half displacementT = lerp(finalT, finalT * 2.0h - 1.0h, saturate(_CenterAroundOrigin));
                positionOS += moveDirOS * (displacementT * _Distance);

                VertexPositionInputs positionInputs = GetVertexPositionInputs(positionOS);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS);

                OUT.positionHCS = positionInputs.positionCS;
                OUT.normalWS = normalInputs.normalWS;
                OUT.debugPhase = finalT;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half3 normalWS = normalize(IN.normalWS);
                half ndl = saturate(dot(normalWS, normalize(half3(-0.3h, 0.85h, 0.25h))));
                half lighting = 0.2h + 0.8h * ndl;

                // Light visual feedback showing current normalized motion state.
                half accent = lerp(0.92h, 1.08h, IN.debugPhase);

                return half4(_BaseColor.rgb * lighting * accent, _BaseColor.a);
            }
            ENDHLSL
        }
    }
}