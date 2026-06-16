Shader "DecompiledArt/Workshop/03/Masks/Runtime/GlobalWave"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (0.6,0.6,1,1)

        _Amplitude ("Wave Amplitude", Float) = 0.5
        _Frequency ("Wave Frequency", Float) = 2.0
        _Speed ("Wave Speed", Float) = 1.0

        // New: shaping controls
        _WaveMin ("Wave Min Threshold", Range(-1,1)) = -0.2
        _WaveMax ("Wave Max Threshold", Range(-1,1)) = 0.8
        _WaveSharpness ("Wave Sharpness", Range(0.5,8)) = 2.0

        // Debug toggle
        _DebugWave ("Debug Wave", Range(0,1)) = 0
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" }

        Pass
        {
            Name "Forward"
            Tags { "LightMode"="UniversalForward" }

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
                float4 positionHCS : SV_POSITION;
                float  waveMask    : TEXCOORD0; // for debug
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;

                float _Amplitude;
                float _Frequency;
                float _Speed;

                float _WaveMin;
                float _WaveMax;
                float _WaveSharpness;

                float _DebugWave;
            CBUFFER_END

            // Convert a raw sine wave into a more art-directable mask.
            // Thresholds choose which part of the wave survives.
            // Sharpness controls how soft or narrow the active crest becomes.
            float ComputeWaveMask(float rawWave)
            {
                // Remap sine (-1..1) into controllable band
                float mask = smoothstep(_WaveMin, _WaveMax, rawWave);

                // Shape crest sharpness (art direction control)
                mask = pow(mask, _WaveSharpness);

                return mask;
            }

            Varyings vert (Attributes v)
            {
                Varyings o;

                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);

                // Build one shared field in world space.
                // Every object samples the same wave using its world position,
                // so the pattern reads like a level-wide runtime effect.
                // Radial distance in XZ plane
                float distXZ = length(positionWS.xz);

                // Stable wrapped time keeps the animated phase bounded.
                float time = frac(_Time.y * _Speed);

                // Base wave
                float rawWave = sin(distXZ * _Frequency - time * TWO_PI);

                // Shaped mask
                float waveMask = ComputeWaveMask(rawWave);

                // The runtime field becomes a mask that controls how much
                // vertical response each vertex receives.
                positionWS.y += waveMask * _Amplitude;

                o.waveMask = waveMask;
                o.positionHCS = TransformWorldToHClip(positionWS);

                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                // Debug visualization:
                // 0 -> final color
                // 1 -> show the evaluated runtime wave mask directly
                half3 debugColor = lerp(
                    _BaseColor.rgb,
                    half3(i.waveMask, i.waveMask, i.waveMask),
                    _DebugWave
                );

                return half4(debugColor, 1.0);
            }

            ENDHLSL
        }
    }
}