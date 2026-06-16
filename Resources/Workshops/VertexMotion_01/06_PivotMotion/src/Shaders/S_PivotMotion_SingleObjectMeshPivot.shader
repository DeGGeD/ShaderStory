Shader "DecompiledArt/Workshop/06/PivotMotion/01_SingleObjectMeshPivot"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (0.45, 0.8, 0.35, 1.0)

        [Header(Demo)]
        [Enum(Offset,0, RotateAroundPivot,1)]
        _Mode("Motion Mode", Float) = 0

        [Header(Animation)]
        _Speed("Speed", Float) = 1.5

        [Header(Offset Motion)]
        _OffsetDirectionOS("Offset Direction OS", Vector) = (1, 0, 0, 0)
        _OffsetAmplitude("Offset Amplitude", Float) = 0.25

        [Header(Pivot Rotation)]
        _AxisOS("Rotation Axis OS", Vector) = (0, 0, 1, 0)
        _AngleAmplitude("Angle Amplitude Radians", Float) = 0.5

        [Header(Debug Pivot)]
        [Toggle] _ShowPivotDebug("Show Pivot Debug", Float) = 0
        _PivotDebugRadius("Pivot Debug Radius", Float) = 0.15
        _PivotDebugColor("Pivot Debug Color", Color) = (1.0, 0.75, 0.05, 1.0)
        _PivotDebugIntensity("Pivot Debug Intensity", Float) = 1.5
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }

        Pass
        {
            Name "ForwardUnlit"
            Tags { "LightMode" = "UniversalForward" }

            Cull Back
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #define TWO_PI 6.2831853h
            #define INV_TWO_PI 0.15915494h

            CBUFFER_START(UnityPerMaterial)

                half4 _BaseColor;

                half _Mode;
                half _Speed;

                float4 _OffsetDirectionOS;
                half _OffsetAmplitude;

                float4 _AxisOS;
                half _AngleAmplitude;

                half _ShowPivotDebug;
                half _PivotDebugRadius;
                half4 _PivotDebugColor;
                half _PivotDebugIntensity;

            CBUFFER_END

            struct Attributes
            {
                float3 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 originalOS : TEXCOORD0;
            };

            float3 RotateAroundAxis(float3 v, float3 axis, half angle)
            {
                axis = normalize(axis);

                half s, c;
                sincos(angle, s, c);

                return v * c
                     + cross(axis, v) * s
                     + axis * dot(axis, v) * (1.0 - c);
            }

            Varyings Vert(Attributes IN)
            {
                Varyings OUT;

                float3 positionOS = IN.positionOS;
                OUT.originalOS = positionOS;

                // Keep the sine phase bounded so the demo stays numerically stable.
                half phase = frac(_Time.y * _Speed * INV_TWO_PI) * TWO_PI;
                half wave  = sin(phase);

                // Simple offset motion: the whole mesh slides along one direction.
                float3 offsetDir = normalize(_OffsetDirectionOS.xyz);
                float3 offsetPos = positionOS + offsetDir * wave * _OffsetAmplitude;

                // Mesh-pivot rotation: object-space origin is the pivot.
                // Because this mesh is authored around its pivot, we can rotate the
                // position directly without a subtract / add step.
                float3 rotatedPos = RotateAroundAxis(
                    positionOS,
                    _AxisOS.xyz,
                    wave * _AngleAmplitude
                );

                positionOS = lerp(offsetPos, rotatedPos, _Mode);

                OUT.positionCS = TransformObjectToHClip(positionOS);
                return OUT;
            }

            half4 Frag(Varyings IN) : SV_Target
            {
                half3 color = _BaseColor.rgb;

                if (_ShowPivotDebug > 0.5h)
                {
                    half dist = length(IN.originalOS);
                    half radius = max(_PivotDebugRadius, 1e-4h);

                    half mask = 1.0h - saturate(dist / radius);
                    mask *= mask;

                    color += _PivotDebugColor.rgb * mask * _PivotDebugIntensity;
                }

                return half4(color, 1.0);
            }

            ENDHLSL
        }
    }

    FallBack Off
}