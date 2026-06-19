Shader "DecompiledArt/Workshop/03/Masks/Procedural"
{
    Properties
    {
        // ================================================================
        // Surface
        // ================================================================
        [MainColor] _BaseColor("Base Color", Color) = (0.75, 0.85, 1.0, 1.0)

        // ================================================================
        // Vertex Motion
        // ================================================================
        [Header(Vertex Motion)]
        _Amplitude("Amplitude", Range(0.0, 2.0)) = 0.15
        _WaveFrequency("Wave Frequency", Range(0.0, 20.0)) = 2.0
        _WaveSpeed("Wave Speed", Range(-10.0, 10.0)) = 1.5

        // Direction of displacement in object space
        // Example:
        // (0,1,0) = move along local up
        // (1,0,0) = move along local right
        _DisplaceDirectionOS("Displace Direction OS", Vector) = (0, 1, 0, 0)

        // Axis used to distribute phase across the mesh in object space.
        // Example:
        // (0,1,0) = vertical phase progression
        // (1,0,0) = horizontal phase progression
        _WaveAxisOS("Wave Axis OS", Vector) = (0, 1, 0, 0)

        // ================================================================
        // Mask Mode
        // ================================================================
        [Header(Mask Mode)]
        [KeywordEnum(None, Gradient, Noise, GradientNoise)] _MASKMODE("Mask Mode", Float) = 0

        // ================================================================
        // Gradient
        // ================================================================
        [Header(Gradient)]
        [KeywordEnum(UV_Y, Object_Y)] _GRADIENTSOURCE("Gradient Source", Float) = 0

        // Only used when Gradient Source = Object_Y
        _GradientScale("Gradient Scale (Object Y)", Float) = 1.0
        _GradientOffset("Gradient Offset (Object Y)", Float) = 0.0

        // Smoothstep remap controls.
        // Useful for tightening/softening the active region of the mask.
        _MaskMin("Mask Min", Range(-2.0, 2.0)) = 0.0
        _MaskMax("Mask Max", Range(-2.0, 2.0)) = 1.0

        // ================================================================
        // Noise
        // ================================================================
        [Header(Noise)]
        [KeywordEnum(Object, World)] _NOISESPACE("Noise Space", Float) = 0

        _NoiseSeed("Noise Seed", Float) = 42.0
        _NoiseScale("Noise Scale", Range(0.01, 32.0)) = 4.0
        _NoiseSpeed("Noise Scroll Speed", Range(-5.0, 5.0)) = 0.5
        _NoiseContrast("Noise Contrast", Range(0.25, 4.0)) = 1.0

        // ================================================================
        // Debug
        // ================================================================
        [Header(Debug)]
        [Toggle(_DEBUG_MASK)] _DebugMask("Debug Mask Output", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"     = "Opaque"
            "Queue"          = "Geometry"
        }

        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma target 3.0

            #pragma vertex vert
            #pragma fragment frag

            // ------------------------------------------------------------
            // Feature keywords
            // ------------------------------------------------------------
            #pragma shader_feature_local _MASKMODE_NONE _MASKMODE_GRADIENT _MASKMODE_NOISE _MASKMODE_GRADIENTNOISE
            #pragma shader_feature_local _GRADIENTSOURCE_UV_Y _GRADIENTSOURCE_OBJECT_Y
            #pragma shader_feature_local _NOISESPACE_OBJECT _NOISESPACE_WORLD
            #pragma shader_feature_local _DEBUG_MASK

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #ifndef TWO_PI
                #define TWO_PI 6.28318530718
            #endif

            struct Attributes
            {
                float4 positionOS : POSITION;
                half3  normalOS   : NORMAL;
                half2  uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS  : TEXCOORD0;
                half3  normalWS    : TEXCOORD1;
                half   mask        : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;

                half _Amplitude;
                half _WaveFrequency;
                half _WaveSpeed;
                half4 _DisplaceDirectionOS;
                half4 _WaveAxisOS;

                half _GradientScale;
                half _GradientOffset;
                half _MaskMin;
                half _MaskMax;

                half _NoiseSeed;
                half _NoiseScale;
                half _NoiseSpeed;
                half _NoiseContrast;
            CBUFFER_END

            // ============================================================
            // Helper Functions
            // ============================================================

            // Cheap cubic fade for gradient noise interpolation.
            inline half Fade(half t)
            {
                return t * t * (3.0h - 2.0h * t);
            }

            // Approximate pow for mask shaping / contrast
            inline half ApproxPowPositive(half x, half p)
            {
                return exp2(p * log2(max(x, 1e-4h)));
            }

            // Pseudo-random 2D hash for gradient generation
            inline half2 Hash2(half2 p)
            {
                p += _NoiseSeed;

                p = half2(
                    dot(p, half2(127.1h, 311.7h)),
                    dot(p, half2(269.5h, 183.3h))
                );

                return frac(sin(p) * 43758.5453h) * 2.0h - 1.0h;
            }

            // Simple 2D gradient noise.
            // Output is approximately in [-1, 1].
            inline half GradientNoise2D(half2 p)
            {
                half2 cell = floor(p);
                half2 f    = frac(p);

                half2 g00 = Hash2(cell + half2(0.0h, 0.0h));
                half2 g10 = Hash2(cell + half2(1.0h, 0.0h));
                half2 g01 = Hash2(cell + half2(0.0h, 1.0h));
                half2 g11 = Hash2(cell + half2(1.0h, 1.0h));

                half n00 = dot(g00, f - half2(0.0h, 0.0h));
                half n10 = dot(g10, f - half2(1.0h, 0.0h));
                half n01 = dot(g01, f - half2(0.0h, 1.0h));
                half n11 = dot(g11, f - half2(1.0h, 1.0h));

                half2 u = half2(Fade(f.x), Fade(f.y));

                half nx0 = lerp(n00, n10, u.x);
                half nx1 = lerp(n01, n11, u.x);

                return lerp(nx0, nx1, u.y);
            }

            // Wrapped angular time for sine phase.
            // This keeps the animated phase bounded to [0, 2PI),
            // preventing very large arguments from being fed into sin()
            // during long editor/runtime sessions.
            inline half GetWrappedWavePhase()
            {
                float cycles = _Time.y * (float)_WaveSpeed;
                return (half)(frac(cycles) * TWO_PI);
            }

            // Wrapped noise scroll offset.
            // Wrapping avoids ever-growing UV offsets over time.
            inline half GetWrappedNoiseOffset()
            {
                float noiseTime = frac(_Time.y * (float)_NoiseSpeed);
                return (half)noiseTime;
            }

            // ============================================================
            // Mask Evaluation
            // ============================================================

            inline half EvaluateGradientMask(float3 positionOS, half2 uv)
            {
                half rawGradient;

                #if defined(_GRADIENTSOURCE_UV_Y)
                    // Uses authored UV layout.
                    rawGradient = uv.y;
                #else
                    // Fully procedural local-object gradient.
                    rawGradient = (half)positionOS.y * _GradientScale + _GradientOffset;
                #endif

                // smoothstep remap makes the gradient more art-directable.
                return smoothstep(_MaskMin, _MaskMax, rawGradient);
            }

            inline half EvaluateNoiseMask(float3 positionOS, float3 positionWS)
            {
                half2 noiseUV;

                #if defined(_NOISESPACE_OBJECT)
                    // Noise moves with the object.
                    noiseUV = (half2)positionOS.xz;
                #else
                    // Noise remains fixed in world space.
                    noiseUV = (half2)positionWS.xz;
                #endif

                noiseUV *= _NoiseScale;

                // Wrapped animated scroll.
                noiseUV.x += GetWrappedNoiseOffset();

                half n = GradientNoise2D(noiseUV);

                // Normalize from roughly [-1,1] to [0,1].
                n = n * 0.5h + 0.5h;

                // Optional shaping for stronger or softer breakup.
                n = ApproxPowPositive(saturate(n), _NoiseContrast);

                return saturate(n);
            }

            inline half EvaluateMask(float3 positionOS, float3 positionWS, half2 uv)
            {
                #if defined(_MASKMODE_NONE)
                    return 1.0h;
                #elif defined(_MASKMODE_GRADIENT)
                    return EvaluateGradientMask(positionOS, uv);
                #elif defined(_MASKMODE_NOISE)
                    return EvaluateNoiseMask(positionOS, positionWS);
                #else
                    // Gradient gives large-scale structure.
                    // Noise adds local variation.
                    half gradientMask = EvaluateGradientMask(positionOS, uv);
                    half noiseMask    = EvaluateNoiseMask(positionOS, positionWS);
                    return gradientMask * noiseMask;
                #endif
            }

            // ============================================================
            // Vertex
            // ============================================================

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                // Start from original object-space position.
                float3 positionOS = IN.positionOS.xyz;

                // World position before displacement is used when noise is sampled in world space.
                float3 originalPositionWS = TransformObjectToWorld(positionOS);

                // Evaluate mask before deformation so the mask is stable relative
                // to the source coordinates chosen for the demo.
                half mask = EvaluateMask(positionOS, originalPositionWS, IN.uv);

                // Normalize author-driven vectors once per vertex.
                half3 waveAxisOS     = normalize(_WaveAxisOS.xyz);
                half3 displaceDirOS  = normalize(_DisplaceDirectionOS.xyz);

                // Phase distribution across the mesh.
                half phaseCoord = dot((half3)positionOS, waveAxisOS);

                // Wrapped animated phase for long-session stability.
                half wrappedTimePhase = GetWrappedWavePhase();

                // Final waveform.
                half wave = sin(phaseCoord * _WaveFrequency + wrappedTimePhase);

                // Apply mask to the displacement amount.
                half displacement = wave * _Amplitude * mask;

                // Displace in object space.
                positionOS += (float3)(displaceDirOS * displacement);

                // Final outputs.
                OUT.positionWS  = TransformObjectToWorld(positionOS);
                OUT.positionHCS = TransformWorldToHClip(OUT.positionWS);

                // Normals handling
                // For larger displacement, normal reconstruction can be added
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);

                OUT.mask = mask;
                return OUT;
            }

            // ============================================================
            // Fragment
            // ============================================================

            half4 frag(Varyings IN) : SV_Target
            {
                #if defined(_DEBUG_MASK)
                    // Useful when teaching masks directly instead of only their motion effect.
                    return half4(IN.mask.xxx, 1.0h);
                #else
                    half3 normalWS = normalize(IN.normalWS);

                    // Main light only for a simple and readable demo shader.
                    Light mainLight = GetMainLight();

                    half3 lambert = LightingLambert(mainLight.color, mainLight.direction, normalWS);
                    half3 ambient = SampleSH(normalWS);

                    half3 color = _BaseColor.rgb * (ambient + lambert);

                    return half4(color, _BaseColor.a);
                #endif
            }
            ENDHLSL
        }
    }

    FallBack Off
}