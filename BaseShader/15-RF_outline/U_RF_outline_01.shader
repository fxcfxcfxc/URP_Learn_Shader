Shader"Myshader/RenderFuture_outline"
{
    Properties
    {   
      _outlineCol("描边颜色",color)=(1.0,0.0,0.0,1.0)
      _outlineWidth("描边宽度",float)=1.0
    }
    SubShader
    {
        Tags
        {   "RenderType"="Opaque"  
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100

        Pass
        {
            Name "outline"
            Tags{"LightMode"="UniversalForward"}
            cull front
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            
            //设置SRP Batch
            CBUFFER_START(UnityPerMaterial)
            uniform float4 _outlineCol;
            uniform float  _outlineWidth;
            CBUFFER_END
            
            struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal :NORMAL;
                
            };

            struct v2f
            {   
                float4 posCS : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float3 nDirWS : TEXCOORD1;
                float3 vDirVS : TEXCOORD2;
           
            };


            v2f vert (Attributes v)
            {
                v2f o;
                v.vertex.xyz = v.vertex.xyz + v.normal *  _outlineWidth * 0.1; 
                o.posCS = TransformObjectToHClip(v.vertex.xyz);
                //为了使相机无论远近，都是拥有相对的描边宽度
                o.uv0 = v.uv;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
      
                return _outlineCol;
            }
            ENDHLSL
        }
    }
}
                                                                                                