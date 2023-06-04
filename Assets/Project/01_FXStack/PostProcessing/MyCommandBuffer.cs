using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Serialization;

#if UNITY_EDITOR
using UnityEditor;
#endif

[ExecuteInEditMode]
public class MyCommandBuffer : MonoBehaviour
{
    [SerializeField, ColorUsageAttribute(true, true)] private Color rimLightColor = Color.white;
    [SerializeField, FormerlySerializedAs("BlurSize"), Tooltip("Default size = 48"), Range(0f, 1000f)] private float blurSize = 4f;
    [SerializeField, Range(1f, 10f)] private float blurSharpness = 4f;
    [SerializeField, Range(1, 6)] private int minLevel = 1;

    [SerializeField] private Shader shader;

    [SerializeField] private Renderer[] renderers;
    private const string SHADER_NAME = "01_FXStack/Shader_01_FXStack_PostProcessing";

    // shader pass indices
    private const int SHADER_PASS_MASK = 0;
    private const int SHADER_PASS_BLUR = 1;
    private const int SHADER_PASS_ADDITIVE = 2;

    // render pass texture IDs
    private int maskBuffer = Shader.PropertyToID("_Mask");
    private int glowBuffer = Shader.PropertyToID("_Glow");
    private int mainBuffer = Shader.PropertyToID("_Main");
    


    private int bufferPrePass_PropertyID = Shader.PropertyToID("_PrePass");
    private int bufferAfterPass_PropertyID = Shader.PropertyToID("_AfterPass");

    private CommandBuffer commandBuffer;
    private Camera targetCamera;
    [SerializeField] private CameraEvent cameraEvent = CameraEvent.AfterForwardOpaque;
    [SerializeField] private Material material;
    


# if UNITY_EDITOR
    void OnValidate()
    {
        if (shader == null)
        {
            shader = Shader.Find(SHADER_NAME);
        }
    }
#endif

    private void OnEnable()
    {
        Debug.Log("ON");
        Camera.onPreRender += ApplyCommandBuffer;
        Camera.onPostRender += RemoveCommandBuffer;
    }
    private void OnDisable()
    {
        Debug.Log("OFF");
        Camera.onPreRender -= ApplyCommandBuffer;
        Camera.onPostRender -= RemoveCommandBuffer;
    }


    private Mesh MeshFromRenderer(Renderer renderer)
    {
        if (renderer is MeshRenderer)
        {
            return renderer.GetComponent<MeshFilter>().sharedMesh;
        }

        return null;
    }

    private void CreateCommandBuffer(Camera cam)
    {
        if (renderers == null || renderers.Length == 0)
            return;

        if (commandBuffer == null)
        {
            commandBuffer = new UnityEngine.Rendering.CommandBuffer();
            commandBuffer.name = "MyCommandBuffer: " + gameObject.name;
        }
        else
        {
            commandBuffer.Clear();
        }

        if (material == null)
        {
            material = new Material(shader != null ? shader : Shader.Find(SHADER_NAME));
        }

        // do nothing if no rimlight will be visible
        if (rimLightColor.a <= (1f / 255f) || blurSize <= 0f)
        {
            commandBuffer.Clear();
            return;
        }

        // support meshes with sub meshes
        // can be from having multiple materials, complex skinning rigs, or a lot of vertices
        int renderersCount = renderers.Length;
        int[] subMeshCount = new int[renderersCount];

        for (int i = 0; i < renderersCount; i++)
        {
            var mesh = MeshFromRenderer(renderers[i]);

            if (mesh != null)
            {
                // assume staticly batched meshes only have one sub mesh
                if (renderers[i].isPartOfStaticBatch)
                    subMeshCount[i] = 1; // hack hack hack
                else
                    subMeshCount[i] = mesh.subMeshCount;
            }
        }

        // match current quality settings' MSAA settings
        // doesn't check if current camera has MSAA enabled
        // also could just always do MSAA if you so pleased
        int msaa = 1;

        int width = cam.scaledPixelWidth;
        int height = cam.scaledPixelHeight;


        // setup descriptor for descriptor of inverted alpha render texture
        RenderTextureDescriptor maskRTD = new RenderTextureDescriptor()
        {
            dimension = TextureDimension.Tex2D,
            graphicsFormat = GraphicsFormat.A10R10G10B10_XRUNormPack32,

            width = width,
            height = height,

            msaaSamples = msaa,
            depthBufferBits = 0,

            sRGB = false,

            useMipMap = true,
            autoGenerateMips = true
        };


        material.SetFloat("_Distance", blurSize);
        material.SetFloat("_Sharpness", blurSharpness);
        material.SetFloat("_MinLevel", minLevel);
        material.SetColor("_RimLightColor", rimLightColor);

        commandBuffer.GetTemporaryRT(maskBuffer, maskRTD, FilterMode.Trilinear);

        // render meshes to main buffer for the interior stencil mask
        commandBuffer.SetRenderTarget(maskBuffer);
        commandBuffer.ClearRenderTarget(true, true, Color.clear);
        for (int rendererI = 0; rendererI < renderersCount; ++rendererI)
        {
            for (int subMeshI = 0; subMeshI < subMeshCount[rendererI]; ++subMeshI)
            {
                commandBuffer.DrawRenderer(renderers[rendererI], material, subMeshI, SHADER_PASS_MASK);
            }
        }

        //commandBuffer.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);


        // setup descriptor of inverted alpha render texture
        RenderTextureDescriptor glowRTD = new RenderTextureDescriptor()
        {
            dimension = TextureDimension.Tex2D,
            graphicsFormat = GraphicsFormat.A10R10G10B10_XRUNormPack32,

            width = width,
            height = height,

            msaaSamples = msaa,
            depthBufferBits = 0,

            sRGB = false,

            useMipMap = true,
            autoGenerateMips = true
        };




        // crate silhouette buffer and assign it as the current render target
        commandBuffer.GetTemporaryRT(glowBuffer, glowRTD, FilterMode.Trilinear);
        commandBuffer.Blit(maskBuffer, glowBuffer, material, SHADER_PASS_BLUR);

        commandBuffer.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);

        commandBuffer.Blit(glowBuffer, BuiltinRenderTextureType.CameraTarget, material, SHADER_PASS_ADDITIVE);


        commandBuffer.ReleaseTemporaryRT(maskBuffer);
        commandBuffer.ReleaseTemporaryRT(glowBuffer);
        commandBuffer.ReleaseTemporaryRT(mainBuffer);
    }

    private void ApplyCommandBuffer(Camera cam)
    {
        CreateCommandBuffer(cam);
        if (commandBuffer == null) return;

        targetCamera = cam;
        targetCamera.AddCommandBuffer(cameraEvent, commandBuffer);
    }
    private void RemoveCommandBuffer(Camera cam)
    {
        if (targetCamera != null && commandBuffer != null)
        {
            targetCamera.RemoveCommandBuffer(cameraEvent, commandBuffer);
            targetCamera = null;
        }
    }



}
