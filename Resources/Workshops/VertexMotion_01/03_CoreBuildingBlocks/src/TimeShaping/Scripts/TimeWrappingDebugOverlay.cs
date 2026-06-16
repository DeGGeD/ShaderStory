using System.Text;
using UnityEngine;

/// <summary>
/// Workshop helper for the shader:
/// "Workshop/URP/Time Wrapping Vertex Motion"
///
/// Mirrors the shader's time math on the CPU so students can compare:
/// - raw shader time (_Time.y equivalent)
/// - direct unbounded angle
/// - wrapped 0..1 phase
/// - wrapped angle in radians
/// - currently selected mode from the material
///
/// This is a CPU-side equivalent of the shader formulas, not a readback of the exact GPU value.
/// </summary>
[ExecuteAlways]
[DisallowMultipleComponent]
public sealed class TimeWrappingDebugOverlay : MonoBehaviour
{
    public enum TimeMode
    {
        DirectTime = 0,
        WrappedPhase = 1,
    }

    [Header("Target")]
    [SerializeField] private Renderer targetRenderer;
    [SerializeField] private bool preferSharedMaterialInEditMode = true;

    [Header("Display")]
    [SerializeField] private bool showOverlay = true;
    [SerializeField] private bool showInGameView = true;
    [SerializeField] private bool showInSceneView = true;
    [SerializeField] private Vector2 overlayPosition = new Vector2(12f, 12f);
    [SerializeField] private Vector2 overlaySize = new Vector2(480f, 280f);

    [Header("Optional Console Logging")]
    [SerializeField] private bool logToConsole = false;
    [SerializeField] private float logInterval = 1.0f;
    [SerializeField] private bool logWhenModeChanges = true;

    [Header("Representative Sample Point")]
    [Tooltip("Optional object-space position used to demonstrate the full vertex angle = angular time + spatial phase.")]
    [SerializeField] private Vector3 samplePositionOS = Vector3.zero;

    private static readonly int TimeModeId = Shader.PropertyToID("_TimeMode");
    private static readonly int SpeedId = Shader.PropertyToID("_Speed");
    private static readonly int FrequencyId = Shader.PropertyToID("_Frequency");
    private static readonly int PhaseOffsetId = Shader.PropertyToID("_PhaseOffset");
    private static readonly int AmplitudeId = Shader.PropertyToID("_Amplitude");
    private static readonly int MaskByHeightId = Shader.PropertyToID("_MaskByHeight");
    private static readonly int HeightMinId = Shader.PropertyToID("_HeightMin");
    private static readonly int HeightMaxId = Shader.PropertyToID("_HeightMax");

    private float _nextLogTime;
    private int _lastLoggedMode = int.MinValue;
    private GUIStyle _labelStyle;
    private GUIStyle _boxStyle;
    private readonly StringBuilder _sb = new StringBuilder(1024);

    private void Reset()
    {
        targetRenderer = GetComponent<Renderer>();
    }

    private void OnEnable()
    {
        if (targetRenderer == null)
        {
            targetRenderer = GetComponent<Renderer>();
        }

        _nextLogTime = GetNow() + Mathf.Max(0.01f, logInterval);
    }

    private void Update()
    {
        if (targetRenderer == null)
        {
            return;
        }

        if (!TryBuildSnapshot(out var snapshot))
        {
            return;
        }

        if (!logToConsole)
        {
            return;
        }

        bool shouldLog = false;

        if (logWhenModeChanges && snapshot.TimeModeInt != _lastLoggedMode)
        {
            shouldLog = true;
        }

        float now = GetNow();
        if (now >= _nextLogTime)
        {
            shouldLog = true;
            _nextLogTime = now + Mathf.Max(0.01f, logInterval);
        }

        if (shouldLog)
        {
            _lastLoggedMode = snapshot.TimeModeInt;
            Debug.Log(snapshot.ToMultilineString(), this);
        }
    }

    private void OnGUI()
    {
        if (!showOverlay || targetRenderer == null)
        {
            return;
        }

        if (Application.isPlaying)
        {
            if (!showInGameView)
            {
                return;
            }
        }
        else
        {
            if (!showInSceneView)
            {
                return;
            }
        }

        if (!TryBuildSnapshot(out var snapshot))
        {
            return;
        }

        EnsureGuiStyles();

        Rect rect = new Rect(overlayPosition.x, overlayPosition.y, overlaySize.x, overlaySize.y);
        GUI.Box(rect, GUIContent.none, _boxStyle);

        Rect labelRect = new Rect(rect.x + 12f, rect.y + 10f, rect.width - 24f, rect.height - 20f);
        GUI.Label(labelRect, snapshot.ToOverlayString(), _labelStyle);
    }

    private void EnsureGuiStyles()
    {
        if (_labelStyle == null)
        {
            _labelStyle = new GUIStyle(GUI.skin.label)
            {
                richText = false,
                fontSize = 13,
                wordWrap = true,
                alignment = TextAnchor.UpperLeft
            };
        }

        if (_boxStyle == null)
        {
            _boxStyle = new GUIStyle(GUI.skin.box)
            {
                alignment = TextAnchor.UpperLeft,
                padding = new RectOffset(8, 8, 8, 8)
            };
        }
    }

    private bool TryBuildSnapshot(out Snapshot snapshot)
    {
        snapshot = default;

        Material material = GetMaterial();
        if (material == null)
        {
            return false;
        }

        float shaderTimeY = GetNow();
        float speed = material.HasProperty(SpeedId) ? material.GetFloat(SpeedId) : 1.0f;
        float frequency = material.HasProperty(FrequencyId) ? material.GetFloat(FrequencyId) : 1.0f;
        float phaseOffset = material.HasProperty(PhaseOffsetId) ? material.GetFloat(PhaseOffsetId) : 0.0f;
        float amplitude = material.HasProperty(AmplitudeId) ? material.GetFloat(AmplitudeId) : 0.25f;
        float maskByHeight = material.HasProperty(MaskByHeightId) ? material.GetFloat(MaskByHeightId) : 0.0f;
        float heightMin = material.HasProperty(HeightMinId) ? material.GetFloat(HeightMinId) : -0.5f;
        float heightMax = material.HasProperty(HeightMaxId) ? material.GetFloat(HeightMaxId) : 0.5f;
        int timeModeInt = material.HasProperty(TimeModeId) ? Mathf.RoundToInt(material.GetFloat(TimeModeId)) : 0;

        float cycles = shaderTimeY * speed;
        float directAngle = cycles * (Mathf.PI * 2.0f);
        float wrappedPhase = cycles - Mathf.Floor(cycles);
        float wrappedAngle = wrappedPhase * (Mathf.PI * 2.0f);
        float selectedAngularTime = timeModeInt >= 1 ? wrappedAngle : directAngle;

        float spatialPhase = samplePositionOS.x * frequency + phaseOffset;
        float finalAngleDirect = directAngle + spatialPhase;
        float finalAngleWrapped = wrappedAngle + spatialPhase;
        float finalAngleSelected = selectedAngularTime + spatialPhase;

        float waveDirect = Mathf.Sin(finalAngleDirect);
        float waveWrapped = Mathf.Sin(finalAngleWrapped);
        float waveDelta = Mathf.Abs(waveDirect - waveWrapped);

        float heightMask = EvaluateHeightMask(samplePositionOS.y, maskByHeight, heightMin, heightMax);
        float offsetAmountSelected = Mathf.Sin(finalAngleSelected) * amplitude * heightMask;

        snapshot = new Snapshot
        {
            ObjectName = name,
            MaterialName = material.name,
            TimeModeInt = timeModeInt,
            TimeModeName = timeModeInt >= 1 ? TimeMode.WrappedPhase.ToString() : TimeMode.DirectTime.ToString(),
            ShaderTimeY = shaderTimeY,
            Speed = speed,
            DirectAngle = directAngle,
            WrappedPhase = wrappedPhase,
            WrappedAngle = wrappedAngle,
            SelectedAngularTime = selectedAngularTime,
            SamplePositionOS = samplePositionOS,
            SpatialPhase = spatialPhase,
            FinalAngleDirect = finalAngleDirect,
            FinalAngleWrapped = finalAngleWrapped,
            FinalAngleSelected = finalAngleSelected,
            WaveDirect = waveDirect,
            WaveWrapped = waveWrapped,
            WaveDelta = waveDelta,
            HeightMask = heightMask,
            OffsetAmountSelected = offsetAmountSelected,
            Amplitude = amplitude,
        };

        return true;
    }

    private Material GetMaterial()
    {
        if (targetRenderer == null)
        {
            return null;
        }

        if (!Application.isPlaying && preferSharedMaterialInEditMode)
        {
            return targetRenderer.sharedMaterial;
        }

        return targetRenderer.material;
    }

    private static float EvaluateHeightMask(float y, float maskByHeight, float heightMin, float heightMax)
    {
        float range = Mathf.Max(0.0001f, heightMax - heightMin);
        float t = Mathf.Clamp01((y - heightMin) / range);
        float shaped = t * t * (3.0f - 2.0f * t);
        return Mathf.Lerp(1.0f, shaped, Mathf.Clamp01(maskByHeight));
    }

    private static float GetNow()
    {
#if UNITY_EDITOR
        if (!Application.isPlaying)
        {
            return (float)UnityEditor.EditorApplication.timeSinceStartup;
        }
#endif
        return Time.time;
    }

    private struct Snapshot
    {
        public string ObjectName;
        public string MaterialName;
        public int TimeModeInt;
        public string TimeModeName;
        public float ShaderTimeY;
        public float Speed;
        public float DirectAngle;
        public float WrappedPhase;
        public float WrappedAngle;
        public float SelectedAngularTime;
        public Vector3 SamplePositionOS;
        public float SpatialPhase;
        public float FinalAngleDirect;
        public float FinalAngleWrapped;
        public float FinalAngleSelected;
        public float WaveDirect;
        public float WaveWrapped;
        public float WaveDelta;
        public float HeightMask;
        public float OffsetAmountSelected;
        public float Amplitude;

        public string ToOverlayString()
        {
            var sb = new StringBuilder(1024);
            sb.AppendLine("Time Wrapping Debug (CPU mirror of shader math)");
            sb.Append("Object: ").AppendLine(ObjectName);
            sb.Append("Material: ").AppendLine(MaterialName);
            sb.Append("Mode (_TimeMode): ").Append(TimeModeName).Append(" (").Append(TimeModeInt).AppendLine(")");
            sb.Append("_Time.y equivalent: ").AppendLine(ShaderTimeY.ToString("F6"));
            sb.Append("_Speed: ").AppendLine(Speed.ToString("F4"));
            sb.AppendLine();
            sb.Append("directAngle = _Time.y * _Speed * 2pi = ").AppendLine(DirectAngle.ToString("F6"));
            sb.Append("wrappedPhase = frac(_Time.y * _Speed) = ").AppendLine(WrappedPhase.ToString("F6"));
            sb.Append("wrappedAngle = wrappedPhase * 2pi = ").AppendLine(WrappedAngle.ToString("F6"));
            sb.Append("selectedAngularTime = ").AppendLine(SelectedAngularTime.ToString("F6"));
            sb.AppendLine();
            sb.Append("samplePositionOS = ").AppendLine(SamplePositionOS.ToString("F3"));
            sb.Append("spatialPhase = sample.x * _Frequency + _PhaseOffset = ").AppendLine(SpatialPhase.ToString("F6"));
            sb.Append("finalAngle(direct) = ").AppendLine(FinalAngleDirect.ToString("F6"));
            sb.Append("finalAngle(wrapped) = ").AppendLine(FinalAngleWrapped.ToString("F6"));
            sb.Append("sin(direct) = ").AppendLine(WaveDirect.ToString("F6"));
            sb.Append("sin(wrapped) = ").AppendLine(WaveWrapped.ToString("F6"));
            sb.Append("abs delta = ").AppendLine(WaveDelta.ToString("E3"));
            sb.AppendLine();
            sb.Append("heightMask(sample) = ").AppendLine(HeightMask.ToString("F6"));
            sb.Append("selected offset = sin(selected) * _Amplitude * mask = ").AppendLine(OffsetAmountSelected.ToString("F6"));
            return sb.ToString();
        }

        public string ToMultilineString()
        {
            var sb = new StringBuilder(1024);
            sb.AppendLine("[TimeWrappingDebugOverlay]");
            sb.Append("Object: ").AppendLine(ObjectName);
            sb.Append("Mode: ").Append(TimeModeName).Append(" (").Append(TimeModeInt).AppendLine(")");
            sb.Append("_Time.y equivalent: ").AppendLine(ShaderTimeY.ToString("F6"));
            sb.Append("directAngle: ").AppendLine(DirectAngle.ToString("F6"));
            sb.Append("wrappedPhase: ").AppendLine(WrappedPhase.ToString("F6"));
            sb.Append("wrappedAngle: ").AppendLine(WrappedAngle.ToString("F6"));
            sb.Append("selectedAngularTime: ").AppendLine(SelectedAngularTime.ToString("F6"));
            sb.Append("sin(direct): ").AppendLine(WaveDirect.ToString("F6"));
            sb.Append("sin(wrapped): ").AppendLine(WaveWrapped.ToString("F6"));
            sb.Append("abs delta: ").AppendLine(WaveDelta.ToString("E3"));
            return sb.ToString();
        }
    }
}