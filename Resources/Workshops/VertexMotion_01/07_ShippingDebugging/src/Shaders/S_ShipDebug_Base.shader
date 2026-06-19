Shader "DecompiledArt/Workshop/07/ShippingDebugging/Base"
{
    Properties
    {
        // ---- Surface maps --------------------------------------------------
        Color_Main("Main Color", Color) = (1,1,1,1)

        SpecularPower("Specular Intensity", Range(0,40)) = 1
        GlossPower("Gloss Strength", Range(0.25,4)) = 1

        _NormalBlend("Normal Reconstruction Blend", Range(0,1)) = 0

        AlphaClipThreshold("Alpha Clip Threshold", Range(0,1)) = 0.5
        
        [MainTexture] Tex_Main   ("Tex_Main",   2D) = "white" {}
        Tex_Normal               ("Tex_Normal", 2D) = "bump" {}
        Tex_Spec                 ("Tex_Spec",   2D) = "white" {}

        // ---- Main Bend -----------------------------------------------------
        MainBend_Dir             ("MainBend_Dir",              Vector) = (0, 0, 0, 0)
        MainBend_HeightMask      ("MainBend_HeightMask",       Float)  = 0
        MainBend_Ampl            ("MainBend_Ampl",             Float)  = 2.0
        MainBend_Freq            ("MainBend_Freq",             Float)  = 5.0
        MainBend_Tex_Noise       ("MainBend_Tex_Noise",        2D)     = "white" {}

        // Noise_MaskContrast: remaps noise [0,1] to [1-C, C].
        // At C=0.5 the range is [0.5, 0.5] — constant, no variation.
        // At C=1.0 the range is [0, 1]     — full contrast.
        MainBend_Noise_MaskContrast ("MainBend_Noise_MaskContrast", Float) = 0.0

        // NoiseSpeed: XY scroll velocity mapped to world XZ (units/sec)
        MainBend_NoiseSpeed      ("MainBend_NoiseSpeed",       Vector) = (0.05, 0, 0, 0)

        // NoiseInflPow: scalar multiplier applied to the remapped noise vector
        // before it is subtracted from the main sway
        MainBend_NoiseInflPow    ("MainBend_NoiseInflPow",     Float)  = 0.5

        // NoiseTile: world-space tiling of the noise texture
        MainBend_NoiseTile       ("MainBend_NoiseTile",        Float)  = 1.0

        // ---- Detail Bend (Green vertex channel — branch Y oscillation) -----
        DetailBend_Freq          ("DetailBend_Freq", Float) = 1.0
        DetailBend_Ampl          ("DetailBend_Ampl", Float) = 0.0

        // ---- Leaf Bend (Red vertex channel — leaf XZ oscillation) ----------
        LeafBend_Freq            ("LeafBend_Freq",  Float) = 1.0
        LeafBend_Ampl            ("LeafBend_Ampl",  Float) = 0.05

        // ---- Debug ---------------------------------------------------------
        [Toggle(MAINBENDNOISE_DEBUG_ON)] MainBendNoise_Debug ("MainBendNoise_Debug", Float) = 0
        [Toggle(_VISUALIZE_BOUNDS_RISK)] _VisualizeBoundsRisk("Visualize Bounds Risk", Float) = 0
        [Toggle(_SIMULATE_BOUNDS_POP)] _SimulateBoundsPop("Simulate Bounds Pop", Float) = 0
        _DebugBoundsExtents("Debug Bounds Extents", Vector) = (0.5, 0.5, 0.5, 0)
        _DebugBoundsPadding("Debug Bounds Padding", Float) = 0.0

        // ============================================================
        // Workshop Fixes
        // ============================================================
        [Toggle(_FORWARD_ALPHA_CLIP)] _ForwardAlphaClip("Forward Alpha Clip", Float) = 0
        [Toggle(_FIX_SHADOWPASS)] _FixShadowPass("Fix Shadow Pass", Float) = 0
        [Toggle(_SHADOW_ALPHA_CLIP)]  _ShadowAlphaClip("Shadow Alpha Clip", Float) = 0
        [Toggle(_FIX_DEPTHPASS)] _FixDepthPass("Fix Depth Pass", Float) = 0
        [Toggle(_DEPTH_ALPHA_CLIP)]   _DepthAlphaClip("Depth Alpha Clip", Float) = 0
        [Toggle(_RECALCULATE_NORMALS)] _RecalculateNormals("Recalculate Normals", Float) = 0
    }

    SubShader
    {
        HLSLINCLUDE

        // ---------------------------------------------------------------------
        // URP includes
        // ---------------------------------------------------------------------

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

        // ---------------------------------------------------------------------
        // Textures
        // ---------------------------------------------------------------------

        TEXTURE2D(Tex_Main);
        SAMPLER(sampler_Tex_Main);

        TEXTURE2D(Tex_Normal);
        SAMPLER(sampler_Tex_Normal);

        TEXTURE2D(Tex_Spec);
        SAMPLER(sampler_Tex_Spec);

        TEXTURE2D(MainBend_Tex_Noise);
        SAMPLER(sampler_MainBend_Tex_Noise);

        // ---------------------------------------------------------------------
        // Material Properties
        //
        // SRP Batcher compatible.
        // Everything exposed in Properties that is accessed by shader code
        // must live here.
        // ---------------------------------------------------------------------

        CBUFFER_START(UnityPerMaterial)

            // Surface

            float4 Color_Main;

            float SpecularPower;
            half GlossPower;
            float AlphaClipThreshold;

            half _NormalBlend;

            // Main Bend

            float3 MainBend_Dir;
            float  MainBend_HeightMask;

            float  MainBend_Ampl;
            float  MainBend_Freq;
            float  MainBend_Noise_MaskContrast;

            float2 MainBend_NoiseSpeed;

            float  MainBend_NoiseInflPow;
            float  MainBend_NoiseTile;

            // Detail Bend

            float  DetailBend_Freq;
            float  DetailBend_Ampl;

            // Leaf Bend
            float  LeafBend_Freq;
            float  LeafBend_Ampl;

            float3 _DebugBoundsExtents;
            float  _DebugBoundsPadding;

        CBUFFER_END

        // ---------------------------------------------------------------------
        // Shared structs
        // ---------------------------------------------------------------------

        struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS   : NORMAL;
            float4 tangentOS  : TANGENT;
            float4 color      : COLOR;
            float4 uv0        : TEXCOORD0;
        };

        struct Varyings
        {
            float4 positionCS : SV_POSITION;

            float3 normalWS    : TEXCOORD0;
            float4 tangentWS   : TEXCOORD1;
            float2 uv          : TEXCOORD2;
            half noiseDebug    : TEXCOORD3;
            float4 shadowCoord : TEXCOORD4;
            float3 viewDirWS   : TEXCOORD5;
            half boundsRisk    : TEXCOORD6;
        };

        // ---------------------------------------------------------------------
        // Time wrapping
        //
        // Prevents precision loss during very long sessions.
        //
        // Using frac() is cheaper than fmod().
        // ---------------------------------------------------------------------

        float WrappedTime()
        {
            const float kWrapPeriod = 1024.0;
            return frac(_Time.y / kWrapPeriod) * kWrapPeriod;
        }

        // ---------------------------------------------------------------------
        // Noise Sampling
        // ---------------------------------------------------------------------

        float2 SampleWindNoise(
            float3 worldPos,
            float time)
        {
            float2 uv =
                worldPos.xz *
                MainBend_NoiseTile;

            uv +=
                MainBend_NoiseSpeed *
                time;

            float2 noise =
                SAMPLE_TEXTURE2D_LOD(
                    MainBend_Tex_Noise,
                    sampler_MainBend_Tex_Noise,
                    uv,
                    0).rg;

            return noise;
        }

        // ---------------------------------------------------------------------
        // Main Bend
        // ---------------------------------------------------------------------

        float3 MainBend(
            float3 positionOS,
            float3 worldPos,
            float time,
            out float noiseDebug)
        {
            float heightMask =
                saturate(
                    positionOS.y +
                    MainBend_HeightMask);

            float phase =
                time *
                MainBend_Freq;

            float sway =
                sin(phase) *
                MainBend_Ampl;

            float2 noise =
                SampleWindNoise(
                    worldPos,
                    time);

            noiseDebug = noise.r;

            float2 remappedNoise =
                lerp(
                    1.0 - MainBend_Noise_MaskContrast,
                    MainBend_Noise_MaskContrast,
                    noise);

            float2 noiseOffset =
                (remappedNoise - 0.5) *
                MainBend_NoiseInflPow;

            float3 bendDir =
                normalize(
                    MainBend_Dir);

            float3 offset =
                bendDir *
                sway *
                heightMask;

            offset.xz -=
                noiseOffset *
                heightMask;

            return offset;
        }

        // ---------------------------------------------------------------------
        // Detail Bend
        // ---------------------------------------------------------------------

        float3 DetailBend(
            float mask,
            float time)
        {
            float phase =
                time *
                DetailBend_Freq *
                mask;

            float offset =
                sin(phase) *
                DetailBend_Ampl;

            return float3(
                0,
                offset,
                0);
        }

        // ---------------------------------------------------------------------
        // Leaf Bend
        // ---------------------------------------------------------------------

        float3 LeafBend(
            float mask,
            float time)
        {
            float sway =
                sin(time * LeafBend_Freq) *
                LeafBend_Ampl *
                mask;

            return float3(
                sway,
                0,
                sway);
        }

        // ---------------------------------------------------------------------
        // Shared deformation
        // ---------------------------------------------------------------------

        // Core wind function with explicit time input.
        // Reconstruction helpers use this overload so they only wrap time once.
        float3 ApplyWindOffsetAtTime(
            float3 positionOS,
            float3 worldPos,
            float4 color,
            float time,
            out float noiseDebug)
        {
            float3 offset =
                MainBend(
                    positionOS,
                    worldPos,
                    time,
                    noiseDebug);

            offset +=
                DetailBend(
                    color.g,
                    time);

            offset +=
                LeafBend(
                    color.r,
                    time);

            return offset;
        }

        // Convenience wrapper for code paths that only need one deformation
        // sample and do not need to manage wrapped time themselves.
        float3 ApplyWindOffset(
            float3 positionOS,
            float3 worldPos,
            float4 color,
            out float noiseDebug)
        {
            float time =
                WrappedTime();

            return ApplyWindOffsetAtTime(
                positionOS,
                worldPos,
                color,
                time,
                noiseDebug);
        }

        float3 EvaluateAnimatedPositionOS(
            float3 positionOS,
            float4 color,
            float time,
            out float noiseDebug)
        {
            float3 worldPos =
                TransformObjectToWorld(positionOS);

            return positionOS +
                ApplyWindOffsetAtTime(
                    positionOS,
                    worldPos,
                    color,
                    time,
                    noiseDebug);
        }

        // Returns 1 when the animated vertex leaves the original local-space
        // bounds box defined for the workshop demo. This approximates the kind
        // of GPU-vs-CPU mismatch that causes culling pops in production.
        half ComputeBoundsRisk(float3 positionOS)
        {
            float3 paddedExtents =
                _DebugBoundsExtents + _DebugBoundsPadding;

            float3 overflow =
                abs(positionOS) - paddedExtents;

            float maxOverflow =
                max(
                    overflow.x,
                    max(overflow.y, overflow.z));

            return
                step(0.0, maxOverflow);
        }

        // ---------------------------------------------------------------------
        // Animated normal reconstruction
        //
        // We rebuild the geometric normal from three nearby animated points.
        // This is a simple and robust workshop-friendly approach for vegetation:
        // when vertices move in the wind, the original mesh normal no longer
        // matches the deformed surface.
        // ---------------------------------------------------------------------

        float3 RecalculateAnimatedNormalOS(
            float3 positionOS,
            float4 color)
        {
            const float eps = 0.01;
            float time = WrappedTime();

            float unusedNoise;

            float3 p0 =
                EvaluateAnimatedPositionOS(
                    positionOS,
                    color,
                    time,
                    unusedNoise);

            float3 pxOS =
                positionOS +
                float3(eps,0,0);

            float3 pzOS =
                positionOS +
                float3(0,0,eps);

            float3 px =
                EvaluateAnimatedPositionOS(
                    pxOS,
                    color,
                    time,
                    unusedNoise);

            float3 pz =
                EvaluateAnimatedPositionOS(
                    pzOS,
                    color,
                    time,
                    unusedNoise);

            return normalize(
                cross(
                    pz - p0,
                    px - p0));
        }

        float3 RecalculateAnimatedTangentOS(
            float3 positionOS,
            float3 tangentOS,
            float4 color)
        {
            const float eps = 0.01;
            float time = WrappedTime();

            float unusedNoise;

            float3 tangentDirOS =
                normalize(tangentOS);

            float3 p0 =
                EvaluateAnimatedPositionOS(
                    positionOS,
                    color,
                    time,
                    unusedNoise);

            float3 ptOS =
                positionOS +
                tangentDirOS * eps;

            float3 pt =
                EvaluateAnimatedPositionOS(
                    ptOS,
                    color,
                    time,
                    unusedNoise);

            return normalize(pt - p0);
        }

        ENDHLSL


        Tags
        {
            "RenderPipeline"     = "UniversalPipeline"
            "RenderType"         = "Opaque"
            "Queue"              = "AlphaTest"   // matches graph: AlphaToMask On
        }

        // =====================================================================
        // FORWARD PASS
        // =====================================================================
        Pass
        {
            Name "UniversalForward"
            Tags { "LightMode" = "UniversalForward" }

            Cull        Off         // two-sided (leaves)
            Blend       One Zero
            ZTest       LEqual
            ZWrite      On
            AlphaToMask On          // MSAA-friendly alpha clip for leaf cutouts

            HLSLPROGRAM

            #pragma target 4.5
            #pragma vertex   Vert
            #pragma fragment Frag
            #pragma shader_feature_local MAINBENDNOISE_DEBUG_ON
            #pragma shader_feature_local _FORWARD_ALPHA_CLIP
            #pragma shader_feature_local _RECALCULATE_NORMALS
            #pragma shader_feature_local _VISUALIZE_BOUNDS_RISK
            #pragma shader_feature_local _SIMULATE_BOUNDS_POP


            Varyings Vert(Attributes IN)
            {
                Varyings OUT;

                // ------------------------------------------------------------
                // Evaluate vegetation animation
                //
                // IMPORTANT:
                // The same deformation function must be reused by:
                //
                // - Forward pass
                // - ShadowCaster pass
                // - DepthOnly pass
                //
                // Otherwise the rendered mesh, shadows and depth buffer
                // will become visually mismatched.
                // ------------------------------------------------------------

                float windTime =
                    WrappedTime();

                float noiseDebug;

                float3 displacedOS =
                    EvaluateAnimatedPositionOS(
                        IN.positionOS,
                        IN.color,
                        windTime,
                        noiseDebug);

                // Transform deformed vertex to world space
                float3 displacedWS =
                    TransformObjectToWorld(displacedOS);

                // ------------------------------------------------------------
                // Position outputs
                // ------------------------------------------------------------

                OUT.positionCS =
                    TransformWorldToHClip(displacedWS);

                // ------------------------------------------------------------
                // Normal output
                //
                // The default mesh normal is correct only for the bind pose.
                // Once wind offsets the vertex positions, lighting should use
                // a normal reconstructed from the animated surface.
                // ------------------------------------------------------------

                #if defined(_RECALCULATE_NORMALS)

                    float3 originalNormalWS =
                        TransformObjectToWorldNormal(
                            IN.normalOS);

                    float3 animatedNormalOS =
                        RecalculateAnimatedNormalOS(
                            IN.positionOS,
                            IN.color);

                    float3 animatedNormalWS =
                        TransformObjectToWorldNormal(
                            animatedNormalOS);

                    OUT.normalWS =
                        normalize(
                            lerp(
                                originalNormalWS,
                                animatedNormalWS,
                                _NormalBlend));

                #else

                    OUT.normalWS =
                        TransformObjectToWorldNormal(
                            IN.normalOS);

                #endif

                // ------------------------------------------------------------
                // Tangent output
                //
                // Used to build the TBN matrix for normal mapping.
                // ------------------------------------------------------------

                // URP stores tangent handedness in .w.
                // GetOddNegativeScale keeps the bitangent consistent when the
                // object is mirrored by its transform.
                //
                // When normals are rebuilt from the animated surface, we also
                // rebuild the tangent direction so tangent-space normal maps
                // continue to light correctly after the wind deformation.
                float3 tangentOS =
                    IN.tangentOS.xyz;

                #if defined(_RECALCULATE_NORMALS)

                    tangentOS =
                        RecalculateAnimatedTangentOS(
                            IN.positionOS,
                            IN.tangentOS.xyz,
                            IN.color);

                #endif

                float3 tangentWS =
                    normalize(
                        TransformObjectToWorldDir(
                            tangentOS));

                float tangentSign =
                    IN.tangentOS.w *
                    GetOddNegativeScale();

                OUT.tangentWS =
                    float4(
                        tangentWS,
                        tangentSign);

                // ------------------------------------------------------------
                // UVs
                // ------------------------------------------------------------

                OUT.uv =
                    IN.uv0.xy;

                // ------------------------------------------------------------
                // Debug visualization
                // ------------------------------------------------------------

                OUT.noiseDebug =
                    (half)noiseDebug;

                OUT.boundsRisk =
                    ComputeBoundsRisk(displacedOS);

                // ------------------------------------------------------------
                // Lighting support
                // ------------------------------------------------------------

                // Main directional light shadow lookup.
                OUT.shadowCoord =
                    TransformWorldToShadowCoord(
                        displacedWS);

                // Store NON-normalized vector.
                // Fragment shader normalizes after interpolation,
                // producing more accurate specular highlights.
                OUT.viewDirWS =
                    GetCameraPositionWS() -
                    displacedWS;

                return OUT;
            }

            half4 Frag(Varyings IN) : SV_Target
            {
                // ------------------------------------------------------------
                // Surface textures
                // ------------------------------------------------------------

                half4 albedoSample =
                    SAMPLE_TEXTURE2D(
                        Tex_Main,
                        sampler_Tex_Main,
                        IN.uv);

                half4 specSample =
                    SAMPLE_TEXTURE2D(
                        Tex_Spec,
                        sampler_Tex_Spec,
                        IN.uv);

                half3 albedo =
                    albedoSample.rgb *
                    Color_Main.rgb;

                // ------------------------------------------------------------
                // Optional alpha clipping
                //
                // Used to demonstrate matching Forward and ShadowCaster
                // silhouette behaviour.
                // ------------------------------------------------------------

                #if defined(_FORWARD_ALPHA_CLIP)

                    clip(
                        albedoSample.a -
                        AlphaClipThreshold);

                #endif

                // ------------------------------------------------------------
                // Bounds debug
                //
                // Real bounds failures happen on the CPU before the shader
                // runs, so this is only an approximation for teaching.
                //
                // - Visualize mode paints risky vertices red.
                // - Simulate mode discards risky fragments to mimic popping.
                // ------------------------------------------------------------

                #if defined(_SIMULATE_BOUNDS_POP)

                    clip(0.5h - IN.boundsRisk);

                #endif

                // ------------------------------------------------------------
                // SpecGloss texture layout
                //
                // R = Specular intensity
                // G = Gloss / smoothness
                // ------------------------------------------------------------

                half specMask = specSample.r;
                half gloss = pow(specSample.g, GlossPower);


                // ------------------------------------------------------------
                // Normal mapping
                // ------------------------------------------------------------

                // Unpack tangent-space normal from the normal map.
                // URP's UnpackNormal handles standard packed normal textures.
                half3 tangentNormal =
                    UnpackNormal(
                        SAMPLE_TEXTURE2D(
                            Tex_Normal,
                            sampler_Tex_Normal,
                            IN.uv));

                float3 N = normalize(IN.normalWS);
                float3 T = normalize(IN.tangentWS.xyz);

                T = normalize(T - N * dot(T, N));

                // Build a stable orthonormal basis in world space.
                // We re-orthogonalize T against N first, then derive B.
                float3 B = normalize(cross(N, T)) * IN.tangentWS.w;

                float3x3 tbn = float3x3(T, B,N);

                // Convert tangent-space normal into world space for lighting.
                N = normalize(mul(tbn, tangentNormal));

                // ------------------------------------------------------------
                // Main directional light
                // ------------------------------------------------------------

                Light mainLight =
                    GetMainLight(
                        IN.shadowCoord);

                half NdotL =
                    saturate(
                        dot(
                            N,
                            mainLight.direction));

                half shadowAtten =
                    mainLight.shadowAttenuation;

                half3 diffuse =
                    albedo *
                    mainLight.color *
                    NdotL *
                    shadowAtten;

                // ------------------------------------------------------------
                // Blinn-Phong specular
                //
                // Gloss controls highlight size.
                // SpecMask controls highlight intensity.
                //
                // SpecularPower acts as a global material multiplier.
                //
                // Exponent range intentionally kept modest so artists
                // retain useful control over the gloss map.
                // ------------------------------------------------------------

                half3 V = normalize(IN.viewDirWS);
                half3 H = SafeNormalize(mainLight.direction + V);

                half shininess =
                    lerp(
                        8.0h,
                        128.0h,
                        gloss);

                half specularTerm =
                    pow(
                        saturate(dot(N, H)),
                        shininess);

                specularTerm *= NdotL;

                half3 specular =
                    specularTerm *
                    specMask *
                    SpecularPower *
                    mainLight.color *
                    shadowAtten;

                // ------------------------------------------------------------
                // Ambient
                // ------------------------------------------------------------

                half3 ambient =
                    SampleSH(N);

                // ------------------------------------------------------------
                // Final Lighting
                // ------------------------------------------------------------

                half3 finalColor =
                    ambient * albedo
                    + diffuse
                    + specular;

                // ------------------------------------------------------------
                // Debug visualization
                // ------------------------------------------------------------

                #if defined(MAINBENDNOISE_DEBUG_ON)

                    return half4(
                        IN.noiseDebug.xxx,
                        1.0h);

                #endif

                #if defined(_VISUALIZE_BOUNDS_RISK)

                    half3 safeColor = finalColor;
                    half3 riskColor = half3(1.0h, 0.1h, 0.1h);

                    return half4(
                        lerp(
                            safeColor,
                            riskColor,
                            IN.boundsRisk),
                        albedoSample.a);

                #endif

                return half4(
                    finalColor,
                    albedoSample.a);
            }

            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"

            Tags
            {
                "LightMode"="ShadowCaster"
            }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Off

            HLSLPROGRAM

            #pragma target 4.5

            #pragma vertex ShadowVert
            #pragma fragment ShadowFrag

            #pragma shader_feature_local _FIX_SHADOWPASS
            #pragma shader_feature_local _SHADOW_ALPHA_CLIP
            #pragma shader_feature_local _SIMULATE_BOUNDS_POP

            Varyings ShadowVert(Attributes IN)
            {
                Varyings OUT;

                float3 positionOS = IN.positionOS;
                float noiseDebug;

                #if defined(_FIX_SHADOWPASS)

                    positionOS =
                        EvaluateAnimatedPositionOS(
                            IN.positionOS,
                            IN.color,
                            WrappedTime(),
                            noiseDebug);

                #else

                    noiseDebug = 0.0;

                #endif

                OUT.boundsRisk =
                    ComputeBoundsRisk(positionOS);

                float3 positionWS =
                    TransformObjectToWorld(positionOS);

                float3 normalWS =
                    TransformObjectToWorldNormal(IN.normalOS);

                OUT.positionCS =
                    TransformWorldToHClip(
                        ApplyShadowBias(
                            positionWS,
                            normalWS,
                            _MainLightPosition.xyz));

                OUT.uv = IN.uv0.xy;

                return OUT;
            }

            half4 ShadowFrag(Varyings IN) : SV_TARGET
            {
                #if defined(_SIMULATE_BOUNDS_POP)

                    clip(0.5h - IN.boundsRisk);

                #endif

                #if defined(_SHADOW_ALPHA_CLIP)

                    half alpha =
                        SAMPLE_TEXTURE2D(
                            Tex_Main,
                            sampler_Tex_Main,
                            IN.uv).a;

                    clip(alpha - AlphaClipThreshold);

                #endif

                return 0;
            }

            ENDHLSL
        }

        // DepthNormalsOnly
        Pass
        {
            Name "DepthNormalsOnly"
            Tags { "LightMode" = "DepthNormalsOnly" }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Off

            HLSLPROGRAM

            #pragma target 3.0

            #pragma vertex DepthVert
            #pragma fragment DepthFrag

            #pragma shader_feature_local _FIX_DEPTHPASS
            #pragma shader_feature_local _DEPTH_ALPHA_CLIP
            #pragma shader_feature_local _SIMULATE_BOUNDS_POP

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct DepthAttributes
            {
                float3 positionOS : POSITION;
                float4 color      : COLOR;
                float2 uv0        : TEXCOORD0;
            };

            struct DepthVaryings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                half boundsRisk   : TEXCOORD1;
            };

            DepthVaryings DepthVert(DepthAttributes IN)
            {
                DepthVaryings OUT;

                float3 positionOS = IN.positionOS;
                float noiseDebug;

                #if defined(_FIX_DEPTHPASS)

                    positionOS =
                        EvaluateAnimatedPositionOS(
                            IN.positionOS,
                            IN.color,
                            WrappedTime(),
                            noiseDebug);

                #else

                    noiseDebug = 0.0;

                #endif

                OUT.boundsRisk =
                    ComputeBoundsRisk(positionOS);

                OUT.positionCS =
                    TransformObjectToHClip(positionOS);

                OUT.uv = IN.uv0;

                return OUT;
            }

            half4 DepthFrag(DepthVaryings IN) : SV_TARGET
            {
                #if defined(_SIMULATE_BOUNDS_POP)

                    clip(0.5h - IN.boundsRisk);

                #endif

                #if defined(_DEPTH_ALPHA_CLIP)

                    half alpha =
                        SAMPLE_TEXTURE2D(
                            Tex_Main,
                            sampler_Tex_Main,
                            IN.uv).a;

                    clip(alpha - AlphaClipThreshold);

                #endif

                return 0;
            }

            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Lit"
}
