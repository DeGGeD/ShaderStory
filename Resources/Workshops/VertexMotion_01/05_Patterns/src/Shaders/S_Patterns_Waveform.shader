Shader "DecompiledArt/Workshop/05/Patterns/Waveform"
{
    Properties
    {
        [MainColor] _BaseColor ("Base Color", Color) = (0.18, 0.42, 0.65, 1.0)
        _AmbientStrength ("Ambient Strength", Range(0.0, 1.0)) = 0.2

        _SpecColor ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _SpecIntensity ("Specular Intensity", Range(0.0, 4.0)) = 1.5
        _SpecPower ("Specular Power", Range(2.0, 64.0)) = 20.0

        [Toggle(_RECONSTRUCT_NORMALS)] _ReconstructNormals ("Reconstruct Normals", Float) = 0
        _NormalEpsilon ("Normal Reconstruction Epsilon", Range(0.001, 0.25)) = 0.05

        _Amplitude ("Amplitude", Range(0.0, 1.0)) = 0.2
        _Frequency ("Frequency", Range(0.0, 10.0)) = 2.0
        _Speed ("Speed", Range(-10.0, 10.0)) = 1.0
        _PhaseOffset ("Phase Offset", Range(-6.283185, 6.283185)) = 0.0
        _WaveDirectionXZ ("Wave Direction XZ", Vector) = (1.0, 0.0, 0.0, 0.0)
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
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment Frag

            #pragma shader_feature_local _ _RECONSTRUCT_NORMALS

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // Forward declaration so the shared include can call the shader-specific
            // displacement function before its full definition appears below.
            float3 ApplyAllWaves(float3 baseWS);

            #include "Workshop_WaveNormalsReconstruction.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                half  _AmbientStrength;
                half4 _SpecColor;
                half  _SpecIntensity;
                half  _SpecPower;

                float _NormalEpsilon;

                float _Amplitude;
                float _Frequency;
                float _Speed;
                float _PhaseOffset;
                float4 _WaveDirectionXZ;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                half3  normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                half3  normalWS   : TEXCOORD1;
                float4 shadowCoord: TEXCOORD2;
                half3  bakedGI    : TEXCOORD3;
            };

            float2 SafeNormalizeXZ(float2 value)
            {
                float lenSq = dot(value, value);
                return (lenSq > 1e-6) ? value * rsqrt(lenSq) : float2(1.0, 0.0);
            }

            float GetWrappedPhase(float speed)
            {
                return frac((_Time.y * speed) / TWO_PI) * TWO_PI;
            }

            float3 ApplyAllWaves(float3 baseWS)
            {
                float2 dir = SafeNormalizeXZ(_WaveDirectionXZ.xy);
                float phase = dot(baseWS.xz, dir) * _Frequency + GetWrappedPhase(_Speed) + _PhaseOffset;

                float3 displaced = baseWS;
                displaced.y += sin(phase) * _Amplitude;
                return displaced;
            }

            Varyings Vert(Attributes IN)
            {
                Varyings OUT;

                float3 baseWS = TransformObjectToWorld(IN.positionOS.xyz);
                float3 posWS = ApplyAllWaves(baseWS);

                #if defined(_RECONSTRUCT_NORMALS)
                    half3 normalWS = (half3)ReconstructWaveNormalWS(baseWS, _NormalEpsilon);
                #else
                    // Intentionally keep the original mesh normal when reconstruction is off.
                    // This makes the lighting mismatch easy to demonstrate during the workshop.
                    half3 normalWS = TransformObjectToWorldNormal(IN.normalOS);
                #endif

                OUT.positionWS = posWS;
                OUT.positionCS = TransformWorldToHClip(posWS);
                OUT.normalWS = normalize(normalWS);
                OUT.shadowCoord = TransformWorldToShadowCoord(posWS);
                OUT.bakedGI = SampleSH(OUT.normalWS);
                return OUT;
            }

            half4 Frag(Varyings IN) : SV_Target
            {
                half3 normalWS = normalize(IN.normalWS);
                Light mainLight = GetMainLight(IN.shadowCoord);

                half3 viewDirWS = SafeNormalize(GetWorldSpaceViewDir(IN.positionWS));
                half3 halfDirWS = SafeNormalize(mainLight.direction + viewDirWS);

                half NdotL = saturate(dot(normalWS, mainLight.direction));
                half NdotH = saturate(dot(normalWS, halfDirWS));

                half3 diffuse = _BaseColor.rgb * mainLight.color * (NdotL * mainLight.shadowAttenuation);
                half3 ambient = _BaseColor.rgb * IN.bakedGI * _AmbientStrength;

                // Explicit Blinn-Phong style specular for workshop readability.
                half spec = ((_SpecPower + 2.0h) * 0.125h)
                          * pow(max(NdotH, 0.0001h), _SpecPower)
                          * _SpecIntensity
                          * NdotL
                          * mainLight.shadowAttenuation;

                half3 specular = _SpecColor.rgb * mainLight.color * spec;
                return half4(diffuse + ambient + specular, _BaseColor.a);
            }
            ENDHLSL
        }
    }
}
