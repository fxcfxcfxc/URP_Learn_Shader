                                                              Shader"Myshader/srp_mulit_pass"
{
    Properties
    {   
       _BaseColor("Base Color",Color)=(1,1,1,1)
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
        
            Name "U_basecolor"
            Tags
            {
              "LightMode" = "UniversalForward"
            
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            
            uniform half4  _BaseColor;

            struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 posCS : SV_POSITION;
                float2 uv0 : TEXCOORD0;
            };


            v2f vert (Attributes v)
            {
                v2f o;
                o.posCS = TransformObjectToHClip(v.vertex.xyz);
                o.uv0 = v.uv;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                return _BaseColor;
            }
            
            ENDHLSL
        }
        
        pass
        {
            //通过添加lightmode为SRPDEFAULTUNLIT 实现多pass
        
            Name "outline"
            Tags
            {
              "LightMode"  = "SRPDefaultUnlit"
            }
            cull front
            
            HLSLPROGRAM
            #pragma vertex vert_outline
            #pragma fragment frag_outline
            uniform float4 _outlineCol;
            uniform float  _outlineWidth;
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            
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
           
            };
            
            
            
            v2f vert_outline (Attributes v)
            {
                v2f o;
                o.posCS = TransformObjectToHClip(v.vertex.xyz);
                
                //为了使相机无论远近，都是拥有相对的描边宽度
                float3 nDirWS = TransformObjectToWorldNormal(v.normal);//模型法线->世界空间
                //float3 nDirVS = TransformWorldToViewDir(nDirWS);//世界空间法线->观察空间，URP函数可以直接从世界到齐次裁剪空间
                float3 nDirClip = TransformWorldToHClipDir(nDirWS,true);//世界空间-》观察空间-》齐次裁剪空间
                float3 nDirNDC =  nDirClip * o.posCS.w; //齐次裁剪空间 ->NDC
                
                //修复屏幕比例引起的描边问题
                float4 nearUpperRight = mul(unity_CameraInvProjection, float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));//将近裁剪面右上角位置的顶点变换到观察空间
                float aspect = abs(nearUpperRight.y / nearUpperRight.x);//求得屏幕宽高比
                nDirNDC.x *= aspect;
                
                //顶点扩张
                o.posCS.xy = o.posCS.xy + nDirNDC.xy * _outlineWidth*0.1;
                o.uv0 = v.uv;
                return o;
            }

            half4 frag_outline (v2f i) : SV_Target
            {
                return _outlineCol;
            }
        
            ENDHLSL
        }
    }
}
