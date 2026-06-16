using UnityEngine;
using UnityEngine.InputSystem;

[RequireComponent(typeof(CharacterController))]
public class DemoCharacterController_Final : MonoBehaviour
{
    public float moveSpeed = 5f;
    public float rotationSpeed = 10f;

    [Header("Shader Target")]
    public Renderer targetRenderer;

    [Header("Response Timing (Artist Control)")]
    public float moveResponseTime = 0.08f;
    public float stopResponseTime = 0.25f;

    [Header("Angular Motion")]
    public float angularStrength = 0.8f;
    public float turnResponseTime = 0.06f;
    public float turnStopResponseTime = 0.22f;

    CharacterController controller;

    Vector3 lastPosition;
    Vector3 velocityWS;

    Vector3 lastForward;
    Vector3 angularVelocityWS;

    float smoothedSpeed;
    float smoothedYawRate;

    void Start()
    {
        controller = GetComponent<CharacterController>();
        lastPosition = transform.position;
        lastForward = transform.forward;
    }

    void Update()
    {
        float dt = Time.deltaTime;

        // ===== INPUT =====
        Vector2 input = Vector2.zero;

        if (Keyboard.current != null)
        {
            if (Keyboard.current.wKey.isPressed) input.y += 1;
            if (Keyboard.current.sKey.isPressed) input.y -= 1;
            if (Keyboard.current.aKey.isPressed) input.x -= 1;
            if (Keyboard.current.dKey.isPressed) input.x += 1;
        }

        Vector3 moveInput = new Vector3(input.x, 0, input.y);

        // ===== CAMERA RELATIVE =====
        if (Camera.main != null)
        {
            Vector3 forward = Camera.main.transform.forward;
            Vector3 right = Camera.main.transform.right;

            forward.y = 0;
            right.y = 0;

            forward.Normalize();
            right.Normalize();

            moveInput = forward * input.y + right * input.x;
        }

        // ===== MOVE =====
        if (moveInput.sqrMagnitude > 0.001f)
        {
            Vector3 moveDir = moveInput.normalized;

            Quaternion targetRot = Quaternion.LookRotation(moveDir);
            transform.rotation = Quaternion.Slerp(
                transform.rotation,
                targetRot,
                rotationSpeed * dt
            );

            controller.Move(moveDir * moveSpeed * dt);
        }

        // ===== VELOCITY =====
        Vector3 newVelocity = (transform.position - lastPosition) / dt;
        lastPosition = transform.position;

        float responseTime = (moveInput.sqrMagnitude > 0.001f) ? moveResponseTime : stopResponseTime;
        float lerpFactor = 1f - Mathf.Exp(-dt / Mathf.Max(0.0001f, responseTime));

        velocityWS = Vector3.Lerp(velocityWS, newVelocity, lerpFactor);
        smoothedSpeed = velocityWS.magnitude;

        // ===== ANGULAR VELOCITY =====
        Vector3 currentForward = transform.forward;
        float rawYawRate = Vector3.SignedAngle(lastForward, currentForward, Vector3.up) * Mathf.Deg2Rad / Mathf.Max(dt, 0.0001f);
        float turnResponse = Mathf.Abs(rawYawRate) > 0.01f ? turnResponseTime : turnStopResponseTime;
        float angularLerpFactor = 1f - Mathf.Exp(-dt / Mathf.Max(0.0001f, turnResponse));

        smoothedYawRate = Mathf.Lerp(smoothedYawRate, rawYawRate, angularLerpFactor);
        angularVelocityWS = Vector3.up * smoothedYawRate;
        lastForward = currentForward;

        // ===== SEND TO SHADER =====
        if (targetRenderer != null)
        {
            var mat = targetRenderer.material;

            mat.SetVector("_CharacterVelocityWS", velocityWS);
            mat.SetFloat("_SmoothedSpeed", smoothedSpeed);
            mat.SetVector("_CharacterForwardWS", transform.forward);
            mat.SetVector("_AngularVelocityWS", angularVelocityWS);
            mat.SetFloat("_AngularStrength", angularStrength);
        }
    }
}