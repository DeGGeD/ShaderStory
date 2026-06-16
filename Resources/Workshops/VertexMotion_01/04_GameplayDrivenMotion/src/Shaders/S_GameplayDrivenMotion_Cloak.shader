Shader "DecompiledArt/Workshop/04/GameplayDrivenMotion/Cloak"
{
    Properties
    {
        [Enum(None,0, TimeOnly,1, WorldAxis,2, VertexMask,3, Velocity,4)]
        _DemoState ("Demo State", Float) = 0

        [Enum(VertexColor,0, UVGradient,1)]
        _MaskSource ("Mask Source", Float) = 1

        [Enum(U,0, V,1)]
        _MaskUVChannel ("Mask UV Channel", Float) = 0
        _MaskUVScale ("Mask UV Scale", Float) = 1
        _MaskUVOffset ("Mask UV Offset", Float) = 0
        _MaskUVStart ("Mask UV Start", Float) = 0
        _MaskUVEnd ("Mask UV End", Float) = 1

        _MaskPower ("Mask Power", Float) = 1
        _MaskInvert ("Mask Invert", Float) = 0

        _Amplitude ("Amplitude", Float) = 0.08
        _Frequency ("Frequency", Float) = 3
        _Speed ("Speed", Float) = 1.5
        _IdleAmplitude ("Idle Amplitude", Float) = 0.02
        _IdleFrequencyScale ("Idle Frequency Scale", Float) = 0.45

        _CharacterVelocityWS ("Velocity", Vector) = (0,0,0,0)
        _CharacterForwardWS ("Forward", Vector) = (0,0,1,0)
        _AngularVelocityWS ("Angular Velocity", Vector) = (0,0,0,0)

        _SmoothedSpeed ("Smoothed Speed", Float) = 0

        _VelocityStrength ("Velocity Strength", Float) = 1.2
        _VelocityClamp ("Velocity Clamp", Float) = 2
        _AngularStrength ("Angular Strength", Float) = 0.8

        _IdleGravityStrength ("Idle Gravity Strength", Float) = 0.42
        _MoveGravityStrength ("Move Gravity Strength", Float) = 0.12
        _TurnTrailStrength ("Turn Trail Strength", Float) = 0.08
        _TurnCurlStrength ("Turn Curl Strength", Float) = 0.05

        [Toggle] _DebugMask ("Debug Selected Mask", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Tags { "LightMode"="UniversalForward" }
            Cull Off

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)

                half _DemoState;
                half _MaskSource;
                half _MaskUVChannel;
                half _MaskUVScale;
                half _MaskUVOffset;
                half _MaskUVStart;
                half _MaskUVEnd;
                half _MaskPower;
                half _MaskInvert;

                half _Amplitude;
                half _Frequency;
                half _Speed;
                half _IdleAmplitude;
                half _IdleFrequencyScale;

                float3 _CharacterVelocityWS;
                float3 _CharacterForwardWS;
                float3 _AngularVelocityWS;

                half _SmoothedSpeed;

                half _VelocityStrength;
                half _VelocityClamp;
                half _AngularStrength;

                half _IdleGravityStrength;
                half _MoveGravityStrength;
                half _TurnTrailStrength;
                half _TurnCurlStrength;

                half _DebugMask;

            CBUFFER_END

            //#define TWO_PI 6.28318530718

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 color      : COLOR;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                half4 color        : COLOR;
                float2 uv          : TEXCOORD0;
                half mask          : TEXCOORD1;
            };

            float GetWrappedTemporalPhase()
            {
                float phase = _Time.y * _Speed * _Frequency;

                return frac(phase / TWO_PI) * TWO_PI;
            }

            float3 SafeNormalizeForward(float3 v)
            {
                float lenSq = dot(v, v);

                if (lenSq > 1e-6)
                    return normalize(v);

                return float3(0, 0, 1);
            }

            float3 SafeNormalizeAxis(float3 v, float3 fallback)
            {
                float lenSq = dot(v, v);

                if (lenSq > 1e-6)
                    return normalize(v);

                return fallback;
            }

            half GetMask(Attributes IN)
            {
                half mask = 1.0h;

                if (_DemoState >= 3)
                {
                    if (_MaskSource < 0.5)
                    {
                        mask = IN.color.r;
                    }
                    else
                    {
                        // Author the UV gradient directly in the material so
                        // the same mesh can be re-used with different pinning.
                        half uvCoord = (_MaskUVChannel < 0.5h) ? IN.uv.x : IN.uv.y;
                        uvCoord = uvCoord * _MaskUVScale + _MaskUVOffset;

                        half uvMin = min(_MaskUVStart, _MaskUVEnd);
                        half uvMax = max(_MaskUVStart, _MaskUVEnd);
                        half uvRange = max(uvMax - uvMin, 1e-4h);

                        mask = saturate((uvCoord - uvMin) / uvRange);

                        if (_MaskInvert > 0.5)
                            mask = 1.0h - mask;

                        mask = pow(mask, _MaskPower);
                    }
                }

                return mask;
            }

            Varyings vert (Attributes IN)
            {
                Varyings OUT;

                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                float3 normalWS   = TransformObjectToWorldNormal(IN.normalOS);

                half mask = GetMask(IN);

                float3 finalMove = 0;

                // =====================================================
                // DEMO STATES 1-3
                // =====================================================

                if (_DemoState < 4)
                {
                    if (_DemoState > 0)
                    {
                        float phase = GetWrappedTemporalPhase();

                        if (_DemoState >= 2)
                        {
                            float3 axis = SafeNormalizeForward(_CharacterForwardWS);

                            float spatialPhase =
                                dot(positionWS, axis) * _Frequency;

                            phase += spatialPhase;
                        }

                        float wave = sin(phase);

                        finalMove =
                            normalWS *
                            (wave * _Amplitude * mask);
                    }
                }

                // =====================================================
                // GAMEPLAY DRIVEN MOTION
                // =====================================================

                else
                {
                    float3 vel = _CharacterVelocityWS;
                    float3 angular = _AngularVelocityWS;

                    float speed = min((float)_SmoothedSpeed, (float)_VelocityClamp);
                    float speed01 = saturate(speed / max((float)_VelocityClamp, 1e-4));
                    float activation = smoothstep(0.04, 0.45, speed01);

                    float3 forwardAxis = SafeNormalizeForward(_CharacterForwardWS);
                    float3 velocityAxis = SafeNormalizeAxis(vel, forwardAxis);
                    float3 sideAxis = SafeNormalizeAxis(cross(float3(0, 1, 0), forwardAxis), float3(1, 0, 0));

                    // The controller sends signed yaw speed around world up.
                    // Positive and negative turns push the free edge sideways
                    // in opposite directions, which reads better than using a
                    // raw forward-delta vector directly as displacement.
                    float turnRate = dot(angular, float3(0, 1, 0));
                    float turnAmount = saturate(abs(turnRate) * _AngularStrength);

                    // Keep a small masked flutter alive while idle so the cloak
                    // never snaps from totally static to fully procedural.
                    float idlePhase =
                        _Time.y * _Speed * _IdleFrequencyScale +
                        dot(positionWS, forwardAxis) * (_Frequency * _IdleFrequencyScale);

                    float idleWave =
                        sin(idlePhase) *
                        cos(idlePhase * 0.73 + positionWS.y * 0.45);

                    float3 gravityDir = float3(0, -1, 0);

                    float tipBias = mask * mask * mask;
                    float bodyBias = mask * mask;

                    // Keep the cloak closer to the body at idle, then relax
                    // that pull while movement takes over.
                    float gravityStrength =
                        lerp(_IdleGravityStrength,
                             _MoveGravityStrength,
                             activation);

                    float3 gravityMove = gravityDir * gravityStrength * tipBias;

                    // Idle sway reads better when it moves across the cloak,
                    // perpendicular to the character's travel direction,
                    // instead of only inflating along the surface normal.
                    float3 idleMove =
                        sideAxis *
                        (idleWave * _IdleAmplitude * tipBias);

                    float3 animatedMove = 0;

                    float3 travelAxis = SafeNormalizeAxis(lerp(forwardAxis, velocityAxis, activation), forwardAxis);
                    float temporalPhase = GetWrappedTemporalPhase();
                    float spatialPhase = dot(positionWS, travelAxis) * _Frequency;
                    float wave = sin(temporalPhase + spatialPhase);

                    float motionBoost = lerp(0.25, 1.0, speed01) * _VelocityStrength;
                    float offset = wave * _Amplitude * mask * motionBoost;
                    animatedMove = normalWS * offset;

                    float turnSign = sign(turnRate);
                    float3 backwardAxis = -forwardAxis;

                    // Turning should make the cloak trail and arc, not only
                    // slide sideways. The side component gives readable lag,
                    // while the backward component helps the silhouette curve.
                    float3 turnTrailDir = SafeNormalizeAxis(
                        (-turnSign * sideAxis) + backwardAxis * 0.85,
                        -turnSign * sideAxis
                    );

                    float3 turnTrailMove =
                        turnTrailDir *
                        (_TurnTrailStrength * turnAmount * tipBias * (0.35 + bodyBias));

                    // Add a small normal-space curl on top so the free edge
                    // bends into a curved shape during turns instead of staying
                    // too planar.
                    float turnCurlPhase =
                        dot(positionWS, sideAxis) * (_Frequency * 0.35) +
                        positionWS.y * 0.5;

                    float turnCurlWave = sin(turnCurlPhase);

                    float3 turnCurlMove =
                        normalWS *
                        (turnCurlWave * _TurnCurlStrength * turnAmount * bodyBias * turnSign);

                    finalMove =
                        gravityMove +
                        lerp(idleMove, animatedMove, activation) +
                        turnTrailMove +
                        turnCurlMove;
                }

                positionWS += finalMove;

                OUT.positionHCS =
                    TransformWorldToHClip(positionWS);

                OUT.color = IN.color;
                OUT.uv = IN.uv;
                OUT.mask = mask;

                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                if (_DebugMask > 0.5)
                {
                    // Show the mask source currently driving deformation.
                    // VertexColor mode uses the authored red-channel weight.
                    // UVGradient mode shows the remapped UV mask after scale,
                    // offset, start/end, invert, and power shaping.
                    return half4(IN.mask.xxx, 1);
                }

                return half4(1.0, 0.85, 0.2, 1.0);
            }

            ENDHLSL
        }
    }
}