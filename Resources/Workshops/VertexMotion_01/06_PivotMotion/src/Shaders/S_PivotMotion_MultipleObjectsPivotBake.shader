Shader "DecompiledArt/Workshop/06/PivotMotion/03_MultiplePivots"
{
    Properties
    {
        [Header(Surface)]
        [MainTexture] _BaseMap      ("Base Map", 2D)              = "white" {}
        [MainColor]   _BaseColor    ("Base Color", Color)          = (1,1,1,1)
        _Cutoff                     ("Alpha Cutoff", Range(0,1))   = 0.5
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 0

        [Header(Pivot Data)]
        _PivotMin           ("Pivot Min (Object Space)", Vector)   = (-1,-1,-1,0)
        _PivotMax           ("Pivot Max (Object Space)", Vector)   = ( 1, 1, 1,0)
        _VertexColorGamma   ("Vertex Color Gamma", Float)          = 1.0

        [Header(Motion)]
        _MotionStrength         ("Motion Strength",        Range(0,2))  = 1
        _WobbleSpeed            ("Wobble Speed",           Float)        = 1
        _WobbleAmountDegrees    ("Wobble Amount Degrees",  Range(0,90)) = 25
        _WindAxisOS             ("Rotation Axis (Object Space)", Vector) = (1,0,0,0)
        _PhaseScale             ("Vertex Alpha Phase Scale", Float)      = 6.2831853

        [Header(Debug)]
        [Enum(Off,0,Raw_Vertex_Color,1,Decoded_Pivot_OS,2,Pivot_Distance,3,Motion_Delta,4,Alpha_Phase,5,Signed_Pivot_Delta_OS,6)]
        _DebugMode             ("Debug Mode",            Float) = 0
        _PivotDistanceDebugScale ("Pivot Distance Debug Scale", Float) = 8
        _MotionDeltaDebugScale ("Motion Delta Debug Scale", Float) = 10
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"     = "TransparentCutout"
            "Queue"          = "AlphaTest"
        }

        LOD 200
        Cull [_Cull]

        // ── Forward pass ─────────────────────────────────────────────────────
        Pass
        {
            Name "ForwardUnlit"
            Tags { "LightMode" = "UniversalForward" }

            ZWrite On
            ZTest  LEqual
            Cull  [_Cull]

            HLSLPROGRAM

            #pragma vertex   Vert
            #pragma fragment Frag
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)

                float4 _BaseMap_ST;
                half4  _BaseColor;
                half   _Cutoff;

                float4 _PivotMin;
                float4 _PivotMax;
                half   _VertexColorGamma;

                half   _MotionStrength;
                half   _WobbleSpeed;
                half   _WobbleAmountDegrees;
                float4 _WindAxisOS;
                half   _PhaseScale;

                float  _DebugMode;
                half   _PivotDistanceDebugScale;
                half   _MotionDeltaDebugScale;

            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
                float4 color      : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;

                // originalOS  – pre-animation object-space position
                // animatedOS  – post-animation object-space position
                // pivotOS     – decoded pivot for this vertex
                float3 originalOS : TEXCOORD1;
                float3 animatedOS : TEXCOORD2;
                float3 pivotOS    : TEXCOORD3;
                float4 color      : COLOR;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            // Rotation of v around a normalised axis by angle (radians).
            float3 RotateAroundAxis(float3 v, float3 axis, half angle)
            {
                half s, c;
                sincos(angle, s, c);
                return v * c + cross(axis, v) * s + axis * dot(axis, v) * (1.0h - c);
            }

            // Applies the artist-controlled gamma curve to raw vertex colour.
            // _VertexColorGamma = 1  → no change (linear workflow, colours already linear).
            // _VertexColorGamma = 2.2 → treat sRGB-stored colours as if in gamma space.
            half3 ApplyVertexColorGamma(half3 c)
            {
                return pow(max(c, 1e-4h), (half)_VertexColorGamma);
            }

            // Reconstruct the per-leaf pivot from vertex color RGB
            // Colour values are gamma-corrected then remapped from [0,1] → [PivotMin, PivotMax].
            float3 DecodePivotOS(float4 vertexColor)
            {
                half3 corrected = ApplyVertexColorGamma((half3)vertexColor.rgb);
                return lerp(_PivotMin.xyz, _PivotMax.xyz, (float3)corrected);
            }

            Varyings Vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                float3 posOS   = input.positionOS.xyz;
                float3 pivotOS = DecodePivotOS(input.color);
                float3 axisOS  = normalize(_WindAxisOS.xyz);

                // Per-leaf phase offset breaks up synchronised motion.
                half phase = (half)input.color.a * _PhaseScale;
                half angle = sin(_Time.y * _WobbleSpeed + phase)
                           * radians(_WobbleAmountDegrees)
                           * _MotionStrength;

                // Rotate the vertex relative to its decoded pivot, then translate back.
                float3 localOS    = posOS - pivotOS;
                float3 rotatedOS  = RotateAroundAxis(localOS, axisOS, angle);
                float3 animatedOS = pivotOS + rotatedOS;

                output.positionCS = TransformObjectToHClip(animatedOS);
                output.uv         = TRANSFORM_TEX(input.uv, _BaseMap);

                output.originalOS = posOS;
                output.animatedOS = animatedOS;
                output.pivotOS    = pivotOS;
                output.color      = input.color;

                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                half4 baseSample = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;

                // Alpha cutout applies in all modes so debug visualisation
                // still respects the leaf silhouette.
                clip(baseSample.a - _Cutoff);

                // ── Debug visualisations ──────────────────────────────────────

                // 1 · Raw vertex colour – exactly what the DCC tool stored,
                //     before any gamma correction.
                if (_DebugMode == 1)
                    return half4((half3)input.color.rgb, 1.0h);

                // 2 · Decoded pivot (object-space) remapped to [0,1] colour.
                //     Every vertex on the same leaf must show an identical,
                //     solid colour – any variation within a leaf indicates a
                //     baking or decoding error.
                if (_DebugMode == 2)
                {
                    half3 pivotNorm = (half3)saturate(
                        (input.pivotOS - _PivotMin.xyz) /
                        max(_PivotMax.xyz - _PivotMin.xyz, 1e-5)
                    );
                    return half4(pivotNorm, 1.0h);
                }

                // 3 · Pivot distance – useful for bake validation.
                //     The pivot centre is bright, and it fades toward the leaf tips.
                //     Increase _PivotDistanceDebugScale if the whole leaf looks flat.
                //     Off-centre gradients usually mean a packing, axis-conversion,
                //     or object-space mismatch.
                if (_DebugMode == 3)
                {
                    float3 pivotDelta = input.originalOS - input.pivotOS;
                    half pivotDistance = length(pivotDelta);
                    half pivotMask = 1.0h - saturate(pivotDistance * _PivotDistanceDebugScale);
                    pivotMask *= pivotMask;
                    return half4(pivotMask.xxx, 1.0h);
                }

                // 4 · Motion delta – RGB magnitude of displacement from animation,
                //     scaled by _MotionDeltaDebugScale.  Pivot-centre = black,
                //     leaf tips = bright.  Zero motion = black.
                if (_DebugMode == 4)
                {
                    half3 delta = (half3)(abs(input.animatedOS - input.originalOS)
                                  * _MotionDeltaDebugScale);
                    return half4(saturate(delta), 1.0h);
                }

                // 5 · Alpha / phase seed – vertex colour alpha driving per-leaf
                //     phase offset.  Each leaf should show a uniform value;
                //     varied alpha across a leaf means incorrect baking.
                if (_DebugMode == 5)
                    return half4((half3)input.color.aaa, 1.0h);

                // 6 · Signed pivot delta in object space.
                //     0.5 means the pivot itself, red/green/blue shifts show
                //     which side of the pivot the leaf geometry lives on.
                //     This is the fastest way to spot axis remap mistakes.
                if (_DebugMode == 6)
                {
                    float3 pivotDelta = input.originalOS - input.pivotOS;
                    half3 signedDelta = (half3)(pivotDelta * _PivotDistanceDebugScale * 0.5f + 0.5f);
                    return half4(saturate(signedDelta), 1.0h);
                }

                // ── Normal unlit surface output ───────────────────────────────
                return baseSample;
            }

            ENDHLSL
        }
    }

    FallBack Off
}
