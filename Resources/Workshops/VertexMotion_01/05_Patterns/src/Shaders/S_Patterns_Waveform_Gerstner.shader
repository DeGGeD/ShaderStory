Shader "DecompiledArt/Workshop/05/Patterns/Waveform_Gerstner"
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

        [NoScaleOffset] _NormalMap ("Detail Normal Map", 2D) = "bump" {}
        _NormalMapStrength ("Detail Normal Strength", Range(0.0, 2.0)) = 1.0

        [IntRange] _WaveCount ("Wave Count", Range(1, 4)) = 2

        _DirA ("Wave A Direction XZ", Vector) = (1.0, 0.0, 0.0, 0.0)
        _AmpA ("Wave A Amplitude", Range(0.0, 1.0)) = 0.18
        _FreqA ("Wave A Frequency", Range(0.0, 10.0)) = 2.0
        _SpeedA ("Wave A Speed", Range(-10.0, 10.0)) = 1.0
        _PhaseA ("Wave A Phase Offset", Range(-6.283185, 6.283185)) = 0.0
        _SteepA ("Wave A Steepness", Range(0.0, 1.0)) = 0.55

        _DirB ("Wave B Direction XZ", Vector) = (0.7, 0.7, 0.0, 0.0)
        _AmpB ("Wave B Amplitude", Range(0.0, 1.0)) = 0.12
        _FreqB ("Wave B Frequency", Range(0.0, 10.0)) = 3.6
        _SpeedB ("Wave B Speed", Range(-10.0, 10.0)) = 1.4
        _PhaseB ("Wave B Phase Offset", Range(-6.283185, 6.283185)) = 1.3
        _SteepB ("Wave B Steepness", Range(0.0, 1.0)) = 0.45

        _DirC ("Wave C Direction XZ", Vector) = (-0.3, 1.0, 0.0, 0.0)
        _AmpC ("Wave C Amplitude", Range(0.0, 1.0)) = 0.08
        _FreqC ("Wave C Frequency", Range(0.0, 10.0)) = 5.2
        _SpeedC ("Wave C Speed", Range(-10.0, 10.0)) = 1.8
        _PhaseC ("Wave C Phase Offset", Range(-6.283185, 6.283185)) = 2.4
        _SteepC ("Wave C Steepness", Range(0.0, 1.0)) = 0.35

        _DirD ("Wave D Direction XZ", Vector) = (-1.0, 0.2, 0.0, 0.0)
        _AmpD ("Wave D Amplitude", Range(0.0, 1.0)) = 0.05
        _FreqD ("Wave D Frequency", Range(0.0, 10.0)) = 7.0
        _SpeedD ("Wave D Speed", Range(-10.0, 10.0)) = 2.2
        _PhaseD ("Wave D Phase Offset", Range(-6.283185, 6.283185)) = 0.7
        _SteepD ("Wave D Steepness", Range(0.0, 1.0)) = 0.25
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

                int   _WaveCount;
                float _NormalEpsilon;
                half  _NormalMapStrength;

                float4 _DirA; float _AmpA; float _FreqA; float _SpeedA; float _PhaseA; float _SteepA;
                float4 _DirB; float _AmpB; float _FreqB; float _SpeedB; float _PhaseB; float _SteepB;
                float4 _DirC; float _AmpC; float _FreqC; float _SpeedC; float _PhaseC; float _SteepC;
                float4 _DirD; float _AmpD; float _FreqD; float _SpeedD; float _PhaseD; float _SteepD;
            CBUFFER_END

            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);

            struct Attributes
            {
                float4 positionOS : POSITION;
                half3  normalOS   : NORMAL;
                half4  tangentOS  : TANGENT;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS        : SV_POSITION;
                float3 positionWS        : TEXCOORD0;
                half3  geometricNormalWS : TEXCOORD1;
                float4 shadowCoord       : TEXCOORD2;
                half3  bakedGI           : TEXCOORD3;
                float2 uv                : TEXCOORD4;
                half4  tangentWS         : TEXCOORD5;
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

            float3 GerstnerOffset(float3 baseWS, float2 dirXZ, float amplitude, float frequency, float speed, float phaseOffset, float steepness)
            {
                float2 dir = SafeNormalizeXZ(dirXZ);
                float phase = dot(baseWS.xz, dir) * frequency + GetWrappedPhase(speed) + phaseOffset;

                float s = sin(phase);
                float c = cos(phase);
                float Q = saturate(steepness);

                float3 offset;
                offset.xz = dir * (Q * amplitude * c);
                offset.y  = amplitude * s;
                return offset;
            }

            float3 ApplyAllWaves(float3 baseWS)
            {
                float3 displaced = baseWS;
                // Sample all waves from the same original position so each layer
                // behaves like an independent field instead of feeding the next.
                displaced += GerstnerOffset(baseWS, _DirA.xy, _AmpA, _FreqA, _SpeedA, _PhaseA, _SteepA);
                if (_WaveCount > 1) displaced += GerstnerOffset(baseWS, _DirB.xy, _AmpB, _FreqB, _SpeedB, _PhaseB, _SteepB);
                if (_WaveCount > 2) displaced += GerstnerOffset(baseWS, _DirC.xy, _AmpC, _FreqC, _SpeedC, _PhaseC, _SteepC);
                if (_WaveCount > 3) displaced += GerstnerOffset(baseWS, _DirD.xy, _AmpD, _FreqD, _SpeedD, _PhaseD, _SteepD);
                return displaced;
            }

            Varyings Vert(Attributes IN)
            {
                Varyings OUT;

                float3 baseWS = TransformObjectToWorld(IN.positionOS.xyz);
                float3 posWS = ApplyAllWaves(baseWS);

                #if defined(_RECONSTRUCT_NORMALS)
                    half3 geometricNormalWS = (half3)ReconstructWaveNormalWS(baseWS, _NormalEpsilon);
                #else
                    // Keep the original mesh normal when reconstruction is off.
                    // This intentionally preserves the shading error for teaching.
                    half3 geometricNormalWS = TransformObjectToWorldNormal(IN.normalOS);
                #endif

                VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);

                OUT.positionWS = posWS;
                OUT.positionCS = TransformWorldToHClip(posWS);
                OUT.geometricNormalWS = normalize(geometricNormalWS);
                OUT.shadowCoord = TransformWorldToShadowCoord(posWS);
                OUT.bakedGI = SampleSH(OUT.geometricNormalWS);
                OUT.uv = IN.uv;
                OUT.tangentWS = half4(normalInputs.tangentWS.xyz, IN.tangentOS.w);
                return OUT;
            }

            half4 Frag(Varyings IN) : SV_Target
            {
                half3 geometricNormalWS = normalize(IN.geometricNormalWS);
                half3 normalWS = geometricNormalWS;

                #if defined(_RECONSTRUCT_NORMALS)
                    // Only layer tangent-space micro detail when the large-scale
                    // geometric normal has already been corrected.
                    float3 detailTS = SampleDetailNormalTS(TEXTURE2D_ARGS(_NormalMap, sampler_NormalMap), IN.uv, _NormalMapStrength);
                    normalWS = (half3)ApplyDetailNormalTS_WS(geometricNormalWS, IN.tangentWS, detailTS);
                #endif

                Light mainLight = GetMainLight(IN.shadowCoord);
                half3 viewDirWS = SafeNormalize(GetWorldSpaceViewDir(IN.positionWS));
                half3 halfDirWS = SafeNormalize(mainLight.direction + viewDirWS);

                half NdotL = saturate(dot(normalWS, mainLight.direction));
                half NdotH = saturate(dot(normalWS, halfDirWS));

                half3 diffuse = _BaseColor.rgb * mainLight.color * (NdotL * mainLight.shadowAttenuation);
                half3 ambient = _BaseColor.rgb * IN.bakedGI * _AmbientStrength;

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
