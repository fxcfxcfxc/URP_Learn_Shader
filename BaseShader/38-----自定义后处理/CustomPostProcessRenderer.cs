using UnityEngine;
using UnityEngine.Rendering.Universal;

[System.Serializable]

public class CustomPostProcessRenderer : ScriptableRendererFeature
{
    CustomPostProcessPass pass;
    public Material material;
    public RenderPassEvent PassEvent = RenderPassEvent.BeforeRenderingPostProcessing;

    public override void Create()
    {
        pass = new CustomPostProcessPass(material){renderPassEvent = PassEvent};
        
    }
    
    //添加pass
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(pass);
    }
}