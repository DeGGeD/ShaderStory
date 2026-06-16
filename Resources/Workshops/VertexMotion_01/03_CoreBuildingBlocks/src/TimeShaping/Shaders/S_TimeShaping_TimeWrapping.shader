Shader "DecompiledArt/Workshop/03/TimeShaping/TimeWrapping"
{
    Properties
    {
        [MainColor] _BaseColor ("Base Color", Color) = (0.8, 0.9, 1.0, 1.0)

        // 0 = direct unbounded time, 1 = wrapped phase.
        // This is useful in the workshop because you can live-toggle the difference.
        [Enum(DirectTime,0,WrappedPhase,1)] _TimeMode ("Time Mode", Float) = 1

        [Min(0.001)] _Speed ("Cycles Per Second", Float) = 1.0
        _Amplitude ("Amplitude", Float) = 0.25
        _Frequency ("Spatial Frequency", Float) = 1.0
        _PhaseOffset ("Phase Offset", Float) = 0.0

        // Direction in object space. Normalize in shader so artist input stays convenient.
        _MotionAxisOS ("Motion Axis (Object Space)", Vector) = (0,1,0,0)

        // Optional positional weighting so the mesh does not move as one rigid block.
        _MaskByHeight ("Mask By Local Y", Float) = 0.0
        _HeightMin ("Height Min", Float) = -0.5
        _HeightMax ("Height Max", Float) = 0.5
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

            struct Attributes
            {
                float4 positionOS : POSITION;
                half3 normalOS    : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                half3  normalWS    : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                half3 _MotionAxisOS;
                half  _MaskByHeight;
                half  _Amplitude;
                half  _Frequency;
                half  _PhaseOffset;
                half  _Speed;
                half  _TimeMode;
                half  _HeightMin;
                half  _HeightMax;
            CBUFFER_END

            inline half GetHeightMask(float3 positionOS)
            {
                // Workshop note:
                // This lets you show motion concentrated toward one side of the mesh.
                // Using smoothstep avoids a hard mechanical cutoff.
                half t = saturate((positionOS.y - _HeightMin) / max(0.0001h, _HeightMax - _HeightMin));
                half shaped = t * t * (3.0h - 2.0h * t);
                return lerp(1.0h, shaped, saturate(_MaskByHeight));
            }

            inline half GetAngularTime()
            {
                // DirectTime:
                //   angle keeps growing forever.
                // WrappedPhase:
                //   convert to repeating 0..1 phase first, then back to radians.
                //   This prevents huge arguments from entering sin(), which is safer
                //   for precision and long-running sessions.
                half timeMode = step(0.5h, _TimeMode);
                half directAngle = _Time.y * _Speed * TWO_PI;
                half wrappedAngle = frac(_Time.y * _Speed) * TWO_PI;
                return lerp(directAngle, wrappedAngle, timeMode);
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                float3 positionOS = IN.positionOS.xyz;

                half3 axisOS = normalize(_MotionAxisOS);
                half heightMask = GetHeightMask(positionOS);

                // Add per-vertex spatial phase so the mesh forms a traveling wave.
                half spatialPhase = positionOS.x * _Frequency + _PhaseOffset;
                half angle = GetAngularTime() + spatialPhase;

                half wave = sin(angle);
                half offsetAmount = wave * _Amplitude * heightMask;
                positionOS += axisOS * offsetAmount;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(positionOS);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS);

                OUT.positionHCS = positionInputs.positionCS;
                OUT.normalWS = normalInputs.normalWS;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // Minimal cheap shading so the workshop focus stays on motion.
                half3 normalWS = normalize(IN.normalWS);
                half ndl = saturate(dot(normalWS, normalize(half3(0.35h, 0.8h, 0.2h))));
                half lit = 0.25h + 0.75h * ndl;
                return half4(_BaseColor.rgb * lit, _BaseColor.a);
            }
            ENDHLSL
        }
    }
}
