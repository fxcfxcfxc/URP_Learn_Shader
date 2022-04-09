Shader"Myshader/Flowmap"
{
    Properties
    {  
        _DiffTexture("DiffTexture",2D)="white"{}
        _FlowMapTexture("FlowMapTexture",2D)="white"{}
        _FlowSpeed("FlowSpeed",range(0,1))=1
        _TimeSpeed("TimeSpeed",range(0,1))=1
        [Toggle]_reverse_flow("flip flow direction ",Int)=0
        
    }
    SubShader
    {
        Tags
        {   
            
           "RenderType"="Opaque"
            "IgnoreProjector" = "True"
           "RenderPipeline"="UniversalPipeline"
        
        }
        LOD 100
        
        
        //------------------------------------多pass公用输入数据------------
        HLSLINCLUDE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
        //--------------------------------输入结构---------------
        struct Attributes
        {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv1 :TEXCOORD1;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 color  : COLOR;
             
        };
        
        ENDHLSL
        
        
        //-----------------------------------PASS0/Kajita_Kay------------------
        Pass
        {
        
            Name "flowmap"
            Tags
            {
                //渲染路径
               "LightMode" = "UniversalForward"
            }
            cull off
            zwrite on
            
  
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #pragma shader_feature _REVERSE_FLOW_ON

            //------------------设置SRP Batch ,变量声明
            CBUFFER_START(UnityPerMaterial)

            uniform float _FlowSpeed,_TimeSpeed;
    
            CBUFFER_END

            //------------------纹理声明
            TEXTURE2D(_DiffTexture);
            SAMPLER(sampler_DiffTexture);
            TEXTURE2D(_FlowMapTexture);
            SAMPLER(sampler_FlowMapTexture);

            

            /*
            封装函数格式参考
            // funcion：按照法线方向 偏移 Tangent 方向
            float3 ShiftTangent(float3 T,float3 N,float3 shift)
            {
                return normalize(T + shift *N);
                
            }
            */

            //-------------------------------顶点——》片段--------------
            struct v2f
            {
                float4 posCS : SV_POSITION;
                float2 uv0 : TEXCOORD0;
       
            };
            
            //-------------------------------顶点着色器-----------
            v2f vert (Attributes v)
            {
                
                v2f o;
                
                o.posCS = TransformObjectToHClip(v.vertex.xyz);
                o.uv0 = v.uv;

                return o;
            }

            //------------------------------片段着色器--------------
            half4 frag (v2f i) : SV_Target
            {
                //////准备基本数据
                Light light = GetMainLight();
                
                float3 lDirWS = normalize(light.direction);
                float3 lightCol = light.color;

                //纹理采样的范围是0-1，向量是-1 -1  ，所以我们要做一个映射区间
                float3 flowDir = SAMPLE_TEXTURE2D(_FlowMapTexture,sampler_FlowMapTexture,i.uv0) *2.0 -1.0;

                //控制强度
                flowDir *= - _FlowSpeed;

                //勾选则反转流向
                #ifdef _REVERSE_FLOW_ON
                    flowDir *= -1;
                #endif
                
                //构造周期相同，相位相差半个周期的波形函数
                float phase0 =frac(_Time.y * 0.1 * _TimeSpeed);
                float phase1 =frac(_Time.y * 0.1 * _TimeSpeed + 0.5);

                
                //分别采样
                float3 diffTexColor0 = SAMPLE_TEXTURE2D(_DiffTexture,sampler_DiffTexture,i.uv0 - flowDir * phase0);
                float3 diffTexColor1 = SAMPLE_TEXTURE2D(_DiffTexture,sampler_DiffTexture,i.uv0 - flowDir * phase1);


                //线性插值交替两层
                float flowLerp = abs((0.5 - phase0)/0.5);
                half3 finalColor = lerp(diffTexColor0,diffTexColor1,flowLerp);

                
                return float4(finalColor,1.0);
            }
                
            ENDHLSL
        }


    }
}
