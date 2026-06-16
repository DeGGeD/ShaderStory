using UnityEngine;

public class VelocityToShader : MonoBehaviour
{
    public Renderer targetRenderer;

    Vector3 lastPos;
    Vector3 velocity;

    void Start()
    {
        lastPos = transform.position;
    }

    void Update()
    {
        velocity = (transform.position - lastPos) / Time.deltaTime;
        lastPos = transform.position;

        targetRenderer.material.SetVector("_CharacterVelocityWS", velocity);
    }
}