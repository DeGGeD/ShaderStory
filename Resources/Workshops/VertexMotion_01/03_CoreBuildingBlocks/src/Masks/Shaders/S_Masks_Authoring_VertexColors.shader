Shader "DecompiledArt/Workshop/03/Masks/Authoring/VertexColors"
{
    Properties
    {
        [Header(Vertex Color Debug Channels)]
        [Toggle] _DebugR ("Show Red Channel", Float) = 0
        [Toggle] _DebugG ("Show Green Channel", Float) = 0
        [Toggle] _DebugB ("Show Blue Channel", Float) = 0
        [Toggle] _DebugA ("Show Alpha Channel", Float) = 0

        [Toggle] _FallbackFullColor ("Show Full Vertex Color When No Toggles", Float) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }

        Pass
        {
            Name "VertexColorDebug"
            Tags { "LightMode" = "UniversalForward" }

            Cull Back
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half _DebugR;
                half _DebugG;
                half _DebugB;
                half _DebugA;
                half _FallbackFullColor;
            CBUFFER_END

            struct Attributes
            {
                float3 positionOS : POSITION;
                half4 color       : COLOR;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                half4 color       : COLOR;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS);
                OUT.color = saturate(IN.color);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 vc = IN.color;

                half anyDebug =
                    saturate(_DebugR + _DebugG + _DebugB + _DebugA);

                half3 debugColor = 0;

                // Respect channel identity:
                // R = red, G = green, B = blue, A = grayscale alpha preview.
                debugColor += half3(vc.r, 0.0h, 0.0h) * _DebugR;
                debugColor += half3(0.0h, vc.g, 0.0h) * _DebugG;
                debugColor += half3(0.0h, 0.0h, vc.b) * _DebugB;
                debugColor += half3(vc.a, vc.a, vc.a) * _DebugA;

                half3 fullColor = vc.rgb;

                half3 finalColor = lerp(
                    fullColor * _FallbackFullColor,
                    saturate(debugColor),
                    anyDebug
                );

                return half4(finalColor, 1.0h);
            }
            ENDHLSL
        }
    }

    FallBack Off
}