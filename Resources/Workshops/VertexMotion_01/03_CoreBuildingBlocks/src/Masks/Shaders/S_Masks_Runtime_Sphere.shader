Shader "DecompiledArt/Workshop/03/Masks/Runtime/SphereMask"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (0.7,0.7,0.7,1)
        _MaskColor ("Debug Mask Color", Color) = (1,0,0,1)

        // Final displacement amplitude applied after the runtime mask is evaluated.
        _DisplaceStrength ("Displace Strength", Float) = 0.5

        // Normal mode is the clearest default for sphere-mask deformation.
        // Custom World mode is useful in the workshop for showing upward or sideways push.
        [Enum(NormalWS,0,CustomWorldDirection,1)] _DisplaceMode ("Displace Mode", Float) = 0
        _DisplaceDirectionWS ("Displace Direction WS", Vector) = (0,1,0,0)

        // Optional: toggle debug visibility
        _DebugMask ("Debug Mask Visibility", Range(0,1)) = 1
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
                float3 normalOS   : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS  : TEXCOORD0;
                float  mask        : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                half4 _MaskColor;

                float _DisplaceStrength;
                float _DisplaceMode;
                float4 _DisplaceDirectionWS;
                float _DebugMask;

                // From global system
                float3 _MaskCenterWS;
                float _MaskRadius;
                float _MaskSoftness;
            CBUFFER_END

            // Reusable mask function (matches your slide math concept)
            float ComputeSphereMask(float3 positionWS)
            {
                float dist = distance(positionWS, _MaskCenterWS);

                // Smooth falloff
                return 1.0 - smoothstep(
                    _MaskRadius,
                    _MaskRadius + _MaskSoftness,
                    dist
                );
            }

            float3 SafeNormalizeWS(float3 v, float3 fallbackValue)
            {
                float lenSq = dot(v, v);
                return (lenSq > 1e-6) ? v * rsqrt(lenSq) : fallbackValue;
            }

            float3 EvaluateDisplaceDirectionWS(float3 normalWS)
            {
                float useCustomDirection = step(0.5, _DisplaceMode);
                float3 customDirectionWS = SafeNormalizeWS(_DisplaceDirectionWS.xyz, float3(0.0, 1.0, 0.0));
                return normalize(lerp(normalWS, customDirectionWS, useCustomDirection));
            }

            Varyings vert (Attributes v)
            {
                Varyings o;

                // Convert to world space
                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                float3 normalWS   = SafeNormalizeWS(TransformObjectToWorldNormal(v.normalOS), float3(0.0, 1.0, 0.0));

                // Evaluate runtime mask
                float mask = ComputeSphereMask(positionWS);

                // The mask is driven by runtime world-space data.
                // The response direction can still be swapped for presentation.
                float3 displaceDirectionWS = EvaluateDisplaceDirectionWS(normalWS);

                // Apply masked displacement after evaluating the field.
                positionWS += displaceDirectionWS * mask * _DisplaceStrength;

                // Output
                o.positionWS = positionWS;
                o.mask = mask;
                o.positionHCS = TransformWorldToHClip(positionWS);

                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                // Debug visualization (optional blend)
                half3 color = lerp(
                    _BaseColor.rgb,
                    _MaskColor.rgb,
                    i.mask * _DebugMask
                );

                return half4(color, 1.0);
            }

            ENDHLSL
        }
    }
}