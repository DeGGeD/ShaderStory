Shader "DecompiledArt/Workshop/07/ShippingDebugging/InstancingConcerns"
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

        // ---- Instance Variation --------------------------------------------
        // Stable desynchronization using object-space identity or explicit
        // per-renderer overrides. This keeps shader logic shared while making
        // large foliage populations feel less synchronized.
        _InstancePhaseJitter     ("Instance Phase Jitter", Range(0,1)) = 1.0
        _InstanceAmplitudeJitter ("Instance Amplitude Jitter", Range(0,1)) = 0.25
        [PerRendererData] _InstancePhaseOffset ("Instance Phase Offset", Range(0,1)) = 0
        [PerRendererData] _InstanceAmplitudeScale ("Instance Amplitude Scale", Range(0.5,2)) = 1

        // ---- Debug ---------------------------------------------------------
        [Toggle(MAINBENDNOISE_DEBUG_ON)] MainBendNoise_Debug ("MainBendNoise_Debug", Float) = 0
        [Toggle(_VISUALIZE_MOTION_LOD)] _VisualizeMotionLod("Visualize Motion LOD", Float) = 0
        [Toggle(_VISUALIZE_VERTEX_MOTION)] _VisualizeVertexMotion("Visualize Vertex Motion", Float) = 0
        [Toggle(_VISUALIZE_MOTION_VECTOR_ERROR)] _VisualizeMotionVectorError("Visualize Motion Vector Error", Float) = 0
        [Toggle(_VISUALIZE_INSTANCE_VARIATION)] _VisualizeInstanceVariation("Visualize Instance Variation", Float) = 0
        [Toggle(_SIMULATE_TAA_GHOSTING)] _SimulateTaaGhosting("Simulate TAA Ghosting", Float) = 0
        [Toggle(_VISUALIZE_BOUNDS_RISK)] _VisualizeBoundsRisk("Visualize Bounds Risk", Float) = 0
        [Toggle(_SIMULATE_BOUNDS_POP)] _SimulateBoundsPop("Simulate Bounds Pop", Float) = 0
        _DebugBoundsExtents("Debug Bounds Extents", Vector) = (0.5, 0.5, 0.5, 0)
        _DebugBoundsPadding("Debug Bounds Padding", Float) = 0.0
        _MotionVectorDebugScale("Motion Vector Debug Scale", Float) = 40.0
        _GhostingDebugStrength("Ghosting Debug Strength", Range(0,2)) = 1.0

        // ---- Motion LOD Simplification ------------------------------------
        // Distances define when we step from LOD0->1, LOD1->2 and LOD2->3.
        //
        // Production-oriented demo setup:
        // LOD0 = full motion
        // LOD1 = reduced motion on all layers
        // LOD2 = no leaf motion and no normal reconstruction
        // LOD3 = motion disabled
        _MotionLodDistances("Motion LOD Distances", Vector) = (10, 20, 35, 0)
        _MotionLodMainScale("Motion LOD Main Scale", Vector) = (1, 0.7, 0.45, 0)
        _MotionLodNoiseScale("Motion LOD Noise Scale", Vector) = (1, 0.5, 0.2, 0)
        _MotionLodDetailScale("Motion LOD Detail Scale", Vector) = (1, 0.5, 0, 0)
        _MotionLodLeafScale("Motion LOD Leaf Scale", Vector) = (1, 0.35, 0, 0)

        // ============================================================
        // Workshop Fixes
        // ============================================================
        [Toggle(_FORWARD_ALPHA_CLIP)] _ForwardAlphaClip("Forward Alpha Clip", Float) = 0
        [Toggle(_FIX_SHADOWPASS)] _FixShadowPass("Fix Shadow Pass", Float) = 0
        [Toggle(_SHADOW_ALPHA_CLIP)]  _ShadowAlphaClip("Shadow Alpha Clip", Float) = 0
        [Toggle(_FIX_DEPTHPASS)] _FixDepthPass("Fix Depth Pass", Float) = 0
        [Toggle(_DEPTH_ALPHA_CLIP)]   _DepthAlphaClip("Depth Alpha Clip", Float) = 0
        [Toggle(_FIX_MOTION_VECTORS)] _FixMotionVectors("Fix Motion Vectors", Float) = 0
        [Toggle(_MOTION_VECTOR_ALPHA_CLIP)] _MotionVectorAlphaClip("Motion Vector Alpha Clip", Float) = 1
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

            float  _InstancePhaseJitter;
            float  _InstanceAmplitudeJitter;

            float3 _MotionLodDistances;
            float  _DebugBoundsPadding;

            float  _MotionVectorDebugScale;
            float  _GhostingDebugStrength;

            float4 _MotionLodMainScale;
            float4 _MotionLodNoiseScale;
            float4 _MotionLodDetailScale;
            float4 _MotionLodLeafScale;

            float3 _DebugBoundsExtents;

        CBUFFER_END

        UNITY_INSTANCING_BUFFER_START(WorkshopPerInstance)
            UNITY_DEFINE_INSTANCED_PROP(float, _InstancePhaseOffset)
            UNITY_DEFINE_INSTANCED_PROP(float, _InstanceAmplitudeScale)
        UNITY_INSTANCING_BUFFER_END(WorkshopPerInstance)

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
            UNITY_VERTEX_INPUT_INSTANCE_ID
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
            half motionLodLevel : TEXCOORD7;
            half motionMagnitude : TEXCOORD8;
            half motionVectorError : TEXCOORD9;
            half instanceSeed  : TEXCOORD10;
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

        float WrappedTimeOffset(float offset)
        {
            const float kWrapPeriod = 1024.0;
            float wrappedTime =
                _Time.y + offset;

            return frac(
                wrappedTime / kWrapPeriod +
                1.0) * kWrapPeriod;
        }

        float MotionDeltaTime()
        {
            return max(
                unity_DeltaTime.x,
                1.0 / 60.0);
        }

        float Hash13(float3 value)
        {
            value = frac(value * 0.1031);
            value += dot(value, value.yzx + 33.33);
            return frac((value.x + value.y) * value.z);
        }

        float GetInstanceSeed01()
        {
            float3 objectPivotWS =
                TransformObjectToWorld(float3(0, 0, 0));

            return Hash13(objectPivotWS);
        }

        float GetInstancePhaseOffsetRadians()
        {
            float seededPhase01 =
                GetInstanceSeed01() *
                _InstancePhaseJitter;

            float explicitPhase01 =
                UNITY_ACCESS_INSTANCED_PROP(
                    WorkshopPerInstance,
                    _InstancePhaseOffset);

            return (seededPhase01 + explicitPhase01) * 6.2831853;
        }

        float GetInstanceAmplitudeScale()
        {
            float seededAmplitude =
                lerp(
                    1.0 - _InstanceAmplitudeJitter,
                    1.0,
                    GetInstanceSeed01());

            float explicitAmplitude =
                UNITY_ACCESS_INSTANCED_PROP(
                    WorkshopPerInstance,
                    _InstanceAmplitudeScale);

            return seededAmplitude * explicitAmplitude;
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
        // Motion LOD helpers
        //
        // This shader variant demonstrates a common optimization strategy:
        // distant vegetation keeps only the broadest motion while the more
        // expensive or visually subtle layers are progressively removed.
        //
        // LOD0 = full motion
        // LOD1 = reduced motion on all wind layers
        // LOD2 = broad sway only, leaf motion removed, normal rebuild disabled
        // LOD3 = motion disabled
        // ---------------------------------------------------------------------

        half ComputeMotionLodLevel()
        {
            float3 objectPivotWS =
                TransformObjectToWorld(float3(0, 0, 0));

            float3 cameraToPivot =
                GetCameraPositionWS() -
                objectPivotWS;

            float distanceSq =
                dot(
                    cameraToPivot,
                    cameraToPivot);

            float3 lodDistanceSq =
                _MotionLodDistances *
                _MotionLodDistances;

            half motionLodLevel =
                step(lodDistanceSq.x, distanceSq);

            motionLodLevel +=
                step(lodDistanceSq.y, distanceSq);

            motionLodLevel +=
                step(lodDistanceSq.z, distanceSq);

            return motionLodLevel;
        }

        float2 ComputeClipMotionDelta(
            float3 currentPositionOS,
            float3 previousPositionOS)
        {
            float4 currentPositionCS =
                TransformWorldToHClip(
                    TransformObjectToWorld(currentPositionOS));

            float4 previousPositionCS =
                TransformWorldToHClip(
                    TransformObjectToWorld(previousPositionOS));

            float2 currentPositionNDC =
                currentPositionCS.xy /
                max(currentPositionCS.w, 1e-5);

            float2 previousPositionNDC =
                previousPositionCS.xy /
                max(previousPositionCS.w, 1e-5);

            return currentPositionNDC - previousPositionNDC;
        }

        float4 GetMotionLodScales(half motionLodLevel)
        {
            if (motionLodLevel < 0.5h)
            {
                return float4(
                    _MotionLodMainScale.x,
                    _MotionLodNoiseScale.x,
                    _MotionLodDetailScale.x,
                    _MotionLodLeafScale.x);
            }

            if (motionLodLevel < 1.5h)
            {
                return float4(
                    _MotionLodMainScale.y,
                    _MotionLodNoiseScale.y,
                    _MotionLodDetailScale.y,
                    _MotionLodLeafScale.y);
            }

            if (motionLodLevel < 2.5h)
            {
                return float4(
                    _MotionLodMainScale.z,
                    _MotionLodNoiseScale.z,
                    _MotionLodDetailScale.z,
                    _MotionLodLeafScale.z);
            }

            return float4(
                _MotionLodMainScale.w,
                _MotionLodNoiseScale.w,
                _MotionLodDetailScale.w,
                _MotionLodLeafScale.w);
        }

        // ---------------------------------------------------------------------
        // Main Bend
        // ---------------------------------------------------------------------

        float3 MainBend(
            float3 positionOS,
            float3 worldPos,
            float time,
            float mainScale,
            float noiseScale,
            float phaseOffset,
            float instanceAmplitudeScale,
            out float noiseDebug)
        {
            float heightMask =
                saturate(
                    positionOS.y +
                    MainBend_HeightMask);

            float phase =
                time *
                MainBend_Freq +
                phaseOffset;

            float sway =
                sin(phase) *
                MainBend_Ampl *
                mainScale *
                instanceAmplitudeScale;

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
                MainBend_NoiseInflPow *
                noiseScale;

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
            float time,
            float detailScale,
            float phaseOffset,
            float instanceAmplitudeScale)
        {
            float phase =
                time *
                DetailBend_Freq *
                mask +
                phaseOffset;

            float offset =
                sin(phase) *
                DetailBend_Ampl *
                detailScale *
                instanceAmplitudeScale;

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
            float time,
            float leafScale,
            float phaseOffset,
            float instanceAmplitudeScale)
        {
            float sway =
                sin(time * LeafBend_Freq + phaseOffset) *
                LeafBend_Ampl *
                leafScale *
                instanceAmplitudeScale *
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
            half motionLodLevel,
            out float noiseDebug)
        {
            float4 lodScales =
                GetMotionLodScales(motionLodLevel);

            float instancePhaseOffset =
                GetInstancePhaseOffsetRadians();

            float instanceAmplitudeScale =
                GetInstanceAmplitudeScale();

            float3 offset =
                MainBend(
                    positionOS,
                    worldPos,
                    time,
                    lodScales.x,
                    lodScales.y,
                    instancePhaseOffset,
                    instanceAmplitudeScale,
                    noiseDebug);

            offset +=
                DetailBend(
                    color.g,
                    time,
                    lodScales.z,
                    instancePhaseOffset,
                    instanceAmplitudeScale);

            offset +=
                LeafBend(
                    color.r,
                    time,
                    lodScales.w,
                    instancePhaseOffset,
                    instanceAmplitudeScale);

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

            half motionLodLevel =
                ComputeMotionLodLevel();

            return ApplyWindOffsetAtTime(
                positionOS,
                worldPos,
                color,
                time,
                motionLodLevel,
                noiseDebug);
        }

        float3 EvaluateAnimatedPositionOS(
            float3 positionOS,
            float4 color,
            float time,
            half motionLodLevel,
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
                    motionLodLevel,
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
            float4 color,
            half motionLodLevel)
        {
            const float eps = 0.01;
            float time = WrappedTime();

            float unusedNoise;

            float3 p0 =
                EvaluateAnimatedPositionOS(
                    positionOS,
                    color,
                    time,
                    motionLodLevel,
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
                    motionLodLevel,
                    unusedNoise);

            float3 pz =
                EvaluateAnimatedPositionOS(
                    pzOS,
                    color,
                    time,
                    motionLodLevel,
                    unusedNoise);

            return normalize(
                cross(
                    pz - p0,
                    px - p0));
        }

        float3 RecalculateAnimatedTangentOS(
            float3 positionOS,
            float3 tangentOS,
            float4 color,
            half motionLodLevel)
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
                    motionLodLevel,
                    unusedNoise);

            float3 ptOS =
                positionOS +
                tangentDirOS * eps;

            float3 pt =
                EvaluateAnimatedPositionOS(
                    ptOS,
                    color,
                    time,
                    motionLodLevel,
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
            #pragma multi_compile_instancing
            #pragma shader_feature_local MAINBENDNOISE_DEBUG_ON
            #pragma shader_feature_local _VISUALIZE_MOTION_LOD
            #pragma shader_feature_local _VISUALIZE_VERTEX_MOTION
            #pragma shader_feature_local _VISUALIZE_MOTION_VECTOR_ERROR
            #pragma shader_feature_local _VISUALIZE_INSTANCE_VARIATION
            #pragma shader_feature_local _SIMULATE_TAA_GHOSTING
            #pragma shader_feature_local _FORWARD_ALPHA_CLIP
            #pragma shader_feature_local _FIX_MOTION_VECTORS
            #pragma shader_feature_local _RECALCULATE_NORMALS
            #pragma shader_feature_local _VISUALIZE_BOUNDS_RISK
            #pragma shader_feature_local _SIMULATE_BOUNDS_POP


            Varyings Vert(Attributes IN)
            {
                Varyings OUT;

                UNITY_SETUP_INSTANCE_ID(IN);

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

                half motionLodLevel =
                    ComputeMotionLodLevel();

                float noiseDebug;

                float3 displacedOS =
                    EvaluateAnimatedPositionOS(
                        IN.positionOS,
                        IN.color,
                        windTime,
                        motionLodLevel,
                        noiseDebug);

                float previousTime =
                    WrappedTimeOffset(
                        -MotionDeltaTime());

                float previousNoiseDebug;

                float3 previousDisplacedOS =
                    EvaluateAnimatedPositionOS(
                        IN.positionOS,
                        IN.color,
                        previousTime,
                        motionLodLevel,
                        previousNoiseDebug);

                float2 correctMotionVector =
                    ComputeClipMotionDelta(
                        displacedOS,
                        previousDisplacedOS);

                // Missing vertex motion vectors often collapse to zero for
                // static objects whose deformation happens only in the shader.
                // Enabling _FIX_MOTION_VECTORS switches the reported vector to
                // the correct deformed current-vs-previous result.
                float2 reportedMotionVector =
                    float2(0.0, 0.0);

                #if defined(_FIX_MOTION_VECTORS)

                    reportedMotionVector =
                        correctMotionVector;

                #endif

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

                    // Normal reconstruction is one of the most expensive parts
                    // of this workshop shader, so a production-friendly setup
                    // keeps it only on the two nearest motion LODs.

                    if (motionLodLevel < 2.0h)
                    {

                    float3 originalNormalWS =
                        TransformObjectToWorldNormal(
                            IN.normalOS);

                    float3 animatedNormalOS =
                        RecalculateAnimatedNormalOS(
                            IN.positionOS,
                            IN.color,
                            motionLodLevel);

                    float3 animatedNormalWS =
                        TransformObjectToWorldNormal(
                            animatedNormalOS);

                    OUT.normalWS =
                        normalize(
                            lerp(
                                originalNormalWS,
                                animatedNormalWS,
                                _NormalBlend));

                    }

                    else
                    {

                        OUT.normalWS =
                            TransformObjectToWorldNormal(
                                IN.normalOS);

                    }

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

                    if (motionLodLevel < 2.0h)
                    {

                    tangentOS =
                        RecalculateAnimatedTangentOS(
                            IN.positionOS,
                            IN.tangentOS.xyz,
                            IN.color,
                            motionLodLevel);

                    }

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

                OUT.motionLodLevel =
                    motionLodLevel;

                OUT.motionMagnitude =
                    length(correctMotionVector);

                OUT.motionVectorError =
                    length(correctMotionVector - reportedMotionVector);

                OUT.instanceSeed =
                    GetInstanceSeed01();

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
                //
                // Keeping the packing intentionally simple for workshop use.
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

                float3 N =
                    normalize(
                        IN.normalWS);

                float3 T =
                    normalize(
                        IN.tangentWS.xyz);

                T =
                    normalize(
                        T - N * dot(T, N));

                // Build a stable orthonormal basis in world space.
                // We re-orthogonalize T against N first, then derive B.
                float3 B =
                    normalize(
                        cross(N, T)) *
                    IN.tangentWS.w;

                float3x3 tbn =
                    float3x3(
                        T,
                        B,
                        N);

                // Convert tangent-space normal into world space for lighting.
                N =
                    normalize(
                        mul(
                            tbn,
                            tangentNormal));

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
                // TAA / motion-vectors debug
                //
                // A material shader cannot access TAA history directly, so the
                // ghosting mode below is an approximation. It highlights the
                // places where animated vertices move but a broken motion-
                // vectors path would still report zero motion.
                // ------------------------------------------------------------

                half motionAmount =
                    saturate(
                        IN.motionMagnitude *
                        _MotionVectorDebugScale);

                half motionErrorAmount =
                    saturate(
                        IN.motionVectorError *
                        _MotionVectorDebugScale);

                #if defined(_SIMULATE_TAA_GHOSTING)

                    half ghostAmount =
                        saturate(
                            motionErrorAmount *
                            _GhostingDebugStrength);

                    half3 ghostTint =
                        half3(0.72h, 0.82h, 1.0h);

                    finalColor =
                        lerp(
                            finalColor,
                            finalColor * 0.35h + ghostTint * 0.65h,
                            ghostAmount);

                #endif

                // ------------------------------------------------------------
                // Debug visualization
                // ------------------------------------------------------------

                #if defined(MAINBENDNOISE_DEBUG_ON)

                    return half4(
                        IN.noiseDebug.xxx,
                        1.0h);

                #endif

                #if defined(_VISUALIZE_VERTEX_MOTION)

                    half3 lowMotionColor = half3(0.1h, 0.8h, 0.2h);
                    half3 highMotionColor = half3(1.0h, 0.3h, 0.1h);

                    return half4(
                        lerp(
                            lowMotionColor,
                            highMotionColor,
                            motionAmount),
                        1.0h);

                #endif

                #if defined(_VISUALIZE_MOTION_VECTOR_ERROR)

                    half3 lowErrorColor = half3(0.15h, 0.35h, 1.0h);
                    half3 highErrorColor = half3(1.0h, 0.0h, 0.1h);

                    return half4(
                        lerp(
                            lowErrorColor,
                            highErrorColor,
                            motionErrorAmount),
                        1.0h);

                #endif

                #if defined(_VISUALIZE_INSTANCE_VARIATION)

                    half phase =
                        IN.instanceSeed * 6.2831853h;

                    half3 variationColor =
                        0.5h + 0.5h * cos(
                            phase +
                            half3(0.0h, 2.0944h, 4.1888h));

                    return half4(
                        variationColor,
                        1.0h);

                #endif

                #if defined(_VISUALIZE_MOTION_LOD)

                    // Green -> Yellow -> Orange -> Red
                    // makes the four simplification bands easy to read live.
                    half3 lodColor = half3(0.2h, 0.9h, 0.2h);

                    if (IN.motionLodLevel > 0.5h)
                    {
                        lodColor = half3(0.95h, 0.8h, 0.15h);
                    }

                    if (IN.motionLodLevel > 1.5h)
                    {
                        lodColor = half3(1.0h, 0.45h, 0.1h);
                    }

                    if (IN.motionLodLevel > 2.5h)
                    {
                        lodColor = half3(0.85h, 0.15h, 0.15h);
                    }

                    return half4(lodColor, 1.0h);

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
            #pragma multi_compile_instancing

            #pragma shader_feature_local _FIX_SHADOWPASS
            #pragma shader_feature_local _SHADOW_ALPHA_CLIP

            Varyings ShadowVert(Attributes IN)
            {
                Varyings OUT;

                UNITY_SETUP_INSTANCE_ID(IN);

                float3 positionOS = IN.positionOS;

                #if defined(_FIX_SHADOWPASS)

                    float windTime =
                        WrappedTime();

                    half motionLodLevel =
                        ComputeMotionLodLevel();

                    float unusedNoise;

                    positionOS =
                        EvaluateAnimatedPositionOS(
                            IN.positionOS,
                            IN.color,
                            windTime,
                            motionLodLevel,
                            unusedNoise);

                #endif

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

        // -----------------------------------------------------------------
        // Motion Vectors
        //
        // This is the production-side fix for the workshop issue:
        // the motion-vectors pass must evaluate the same deformation as the
        // color pass, both for the current frame and the previous frame.
        //
        // Broken mode outputs zero motion, which is a common failure when
        // vertex animation exists only in the forward pass.
        // Fixed mode reuses the shared wind function and previous-frame time.
        // -----------------------------------------------------------------
        Pass
        {
            Name "MotionVectors"
            Tags { "LightMode" = "MotionVectors" }

            ZWrite Off
            ZTest LEqual
            Cull Off

            HLSLPROGRAM

            #pragma target 4.5

            #pragma vertex MotionVectorVert
            #pragma fragment MotionVectorFrag
            #pragma multi_compile_instancing

            #pragma shader_feature_local _FIX_MOTION_VECTORS
            #pragma shader_feature_local _MOTION_VECTOR_ALPHA_CLIP

            struct MotionVectorAttributes
            {
                float3 positionOS : POSITION;
                float4 color      : COLOR;
                float2 uv0        : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct MotionVectorVaryings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                float2 motionVector : TEXCOORD1;
            };

            MotionVectorVaryings MotionVectorVert(MotionVectorAttributes IN)
            {
                MotionVectorVaryings OUT;

                UNITY_SETUP_INSTANCE_ID(IN);

                float windTime =
                    WrappedTime();

                float previousTime =
                    WrappedTimeOffset(
                        -MotionDeltaTime());

                half motionLodLevel =
                    ComputeMotionLodLevel();

                float currentNoise;
                float previousNoise;

                float3 currentPositionOS =
                    IN.positionOS;

                float3 previousPositionOS =
                    IN.positionOS;

                #if defined(_FIX_MOTION_VECTORS)

                    currentPositionOS =
                        EvaluateAnimatedPositionOS(
                            IN.positionOS,
                            IN.color,
                            windTime,
                            motionLodLevel,
                            currentNoise);

                    previousPositionOS =
                        EvaluateAnimatedPositionOS(
                            IN.positionOS,
                            IN.color,
                            previousTime,
                            motionLodLevel,
                            previousNoise);

                    OUT.motionVector =
                        ComputeClipMotionDelta(
                            currentPositionOS,
                            previousPositionOS);

                #else

                    OUT.motionVector =
                        float2(0.0, 0.0);

                #endif

                OUT.positionCS =
                    TransformWorldToHClip(
                        TransformObjectToWorld(currentPositionOS));

                OUT.uv = IN.uv0;

                return OUT;
            }

            float4 MotionVectorFrag(MotionVectorVaryings IN) : SV_Target
            {
                #if defined(_MOTION_VECTOR_ALPHA_CLIP)

                    half alpha =
                        SAMPLE_TEXTURE2D(
                            Tex_Main,
                            sampler_Tex_Main,
                            IN.uv).a;

                    clip(alpha - AlphaClipThreshold);

                #endif

                return float4(
                    IN.motionVector,
                    0.0,
                    0.0);
            }

            ENDHLSL
        }

        // This pass only writes depth.
        // For workshop clarity we name and tag it honestly instead of pretending
        // to output normals. Add a dedicated DepthNormals pass later if the
        // project needs SSAO or another effect that samples scene normals.
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Off

            HLSLPROGRAM

            #pragma target 3.0

            #pragma vertex DepthVert
            #pragma fragment DepthFrag
            #pragma multi_compile_instancing

            #pragma shader_feature_local _FIX_DEPTHPASS
            #pragma shader_feature_local _DEPTH_ALPHA_CLIP

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct DepthAttributes
            {
                float3 positionOS : POSITION;
                float4 color      : COLOR;
                float2 uv0        : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct DepthVaryings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
            };

            DepthVaryings DepthVert(DepthAttributes IN)
            {
                DepthVaryings OUT;

                UNITY_SETUP_INSTANCE_ID(IN);

                float3 positionOS = IN.positionOS;

                #if defined(_FIX_DEPTHPASS)

                    float dummy;

                    float windTime =
                        WrappedTime();

                    half motionLodLevel =
                        ComputeMotionLodLevel();

                    positionOS =
                        EvaluateAnimatedPositionOS(
                            IN.positionOS,
                            IN.color,
                            windTime,
                            motionLodLevel,
                            dummy);

                #endif

                OUT.positionCS =
                    TransformObjectToHClip(positionOS);

                OUT.uv = IN.uv0;

                return OUT;
            }

            half4 DepthFrag(DepthVaryings IN) : SV_TARGET
            {
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
