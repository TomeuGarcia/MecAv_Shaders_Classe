using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;
using UnityEditor;

[ExecuteInEditMode]
public class MyCommandBuffer : MonoBehaviour
{
    [SerializeField] private CameraEvent cameraEvent = CameraEvent.AfterForwardOpaque;

    private int bufferPrePass_PropertyID = Shader.PropertyToID("_PrePass");
    private int bufferAfterPass_PropertyID = Shader.PropertyToID("_AfterPass");

    private CommandBuffer commandBuffer;
    private Camera targetCamera;
    [SerializeField] Material material;


    void OnValidate()
    {
        Create_CommandBuffer_Camera_Material();
        Debug.Log("TEST PRINT");
    }


    private void Create_CommandBuffer_Camera_Material()
    {
        if (commandBuffer == null)
        {
            commandBuffer = new CommandBuffer();
            commandBuffer.name = "MyCommandBuffer";
        }
        else
        {
            commandBuffer.Clear();
        }

        if (targetCamera == null)
        {
            targetCamera = Camera.main;
            targetCamera.AddCommandBuffer(cameraEvent, commandBuffer);
        }

        if (material == null)
        {
            material = new Material(Shader.Find("01_FXStack/Shader_01_FXStack_PostProcessing"));
        }

        RenderTextureDescriptor renderTextureDescriptor = new RenderTextureDescriptor
        {
            height = 1080,
            width = 1920,
            msaaSamples = 0,
            graphicsFormat = GraphicsFormat.R16G16B16_SFloat,
            dimension = TextureDimension.Tex2D,
            useMipMap = false
        };

        commandBuffer.GetTemporaryRT(bufferPrePass_PropertyID, renderTextureDescriptor, FilterMode.Bilinear);
        commandBuffer.Blit(bufferPrePass_PropertyID, BuiltinRenderTextureType.CameraTarget, material);

    }
    
    


    void Update()
    {
        
    }
}
