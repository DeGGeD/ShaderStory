Shader "DecompiledArt/Workshop/06/PivotMotion/02_SingleObjectPivotData"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (0.45, 0.8, 0.35, 1.0)

        [Header(Pivot Motion)]
        _PivotOS("Pivot OS", Vector) = (0, 0, 0, 0)
        _AxisOS("Axis OS", Vector) = (0, 0, 1, 0)
        _Speed("Speed", Float) = 1.0
        _AngleAmplitude("Angle Amplitude Radians", Float) = 0.5
        _MaskStrength("Mask Strength", Range(0, 1)) = 1.0

        [Header(Debug Pivot)]
        [Toggle] _ShowPivotDebug("Show Pivot Debug", Float) = 0
        _PivotDebugRadius("Pivot Debug Radius", Float) = 0.25
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

                float4 _PivotOS;
                float4 _AxisOS;

                half _Speed;
                half _AngleAmplitude;
                half _MaskStrength;

                half _ShowPivotDebug;
                half _PivotDebugRadius;
                half4 _PivotDebugColor;
                half _PivotDebugIntensity;

            CBUFFER_END

            struct Attributes
            {
                float3 positionOS : POSITION;
                half4  color      : COLOR;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 originalOS : TEXCOORD0;
                half4  color      : COLOR;
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
                float3 pivotOS    = _PivotOS.xyz;
                float3 axisOS     = normalize(_AxisOS.xyz);

                OUT.originalOS = positionOS;

                // Vertex alpha becomes a simple stiffness mask.
                // 0 means pinned to the original pose, 1 means fully rotated.
                half mask = saturate(IN.color.a * _MaskStrength);

                // Keep the phase bounded so this stays workshop-friendly and stable.
                half phase = frac(_Time.y * _Speed * INV_TWO_PI) * TWO_PI;
                half angle = sin(phase) * _AngleAmplitude;

                // Pivot rotation pattern:
                // 1. move into pivot-relative space
                // 2. rotate around the chosen axis
                // 3. move back into object space
                float3 local = positionOS - pivotOS;
                local = RotateAroundAxis(local, axisOS, angle);
                float3 rotatedPositionOS = pivotOS + local;

                // Blend back toward the bind pose so the pivot data can drive partial motion.
                positionOS = lerp(positionOS, rotatedPositionOS, mask);

                OUT.positionCS = TransformObjectToHClip(positionOS);
                OUT.color = IN.color;

                return OUT;
            }

            half4 Frag(Varyings IN) : SV_Target
            {
                half3 color = _BaseColor.rgb;

                if (_ShowPivotDebug == 1.0)
                {
                    half3 pivotOS = _PivotOS.xyz;
                    half  dist    = length(IN.originalOS - pivotOS);

                    half radius = max(_PivotDebugRadius, 1e-4h);
                    half mask   = 1.0h - saturate(dist / radius);
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