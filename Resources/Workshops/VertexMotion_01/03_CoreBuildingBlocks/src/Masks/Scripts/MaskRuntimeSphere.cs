using UnityEngine;

[ExecuteAlways]
public class SphereMaskDriver : MonoBehaviour
{
    [Header("Mask Settings")]
    public float radius = 1.5f;
    [Range(0.001f, 1f)]
    public float softness = 0.25f;

    [Header("Debug")]
    public Color gizmoColor = new Color(1, 0, 0, 0.25f);

    void Update()
    {
        // Push global data every frame (or only when changed if optimizing)
        Shader.SetGlobalVector("_MaskCenterWS", transform.position);
        Shader.SetGlobalFloat("_MaskRadius", radius);
        Shader.SetGlobalFloat("_MaskSoftness", softness);
    }

    void OnDrawGizmos()
    {
        Gizmos.color = gizmoColor;

        // Solid sphere (transparent)
        Gizmos.DrawSphere(transform.position, radius);

        // Wireframe for clarity
        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(transform.position, radius);
    }
}