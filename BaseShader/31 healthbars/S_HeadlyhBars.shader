Shader"Myshader/HealthBars"
{
    Properties
    {  
        _HealthValue("Health",range(0,1))=1.0
        _RedHeathPoint("RedHeathPoint",range(0,1))=0.3
        _GreenHealthPoint("GreenHealthPoint",range(0,1))=0.8
        
    }
    SubShader
    {
        Tags
        {   
            
           "RenderType"="Transparent"
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
        
        
        //-----------------------------------PASS0/------------------
        Pass
        {
        
            Name "flowmap"
            Tags
            {
                //渲染路径
               "LightMode" = "UniversalForward"
            }
            //cull off
            //zwrite off
  
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            //------------------设置SRP Batch ,变量声明
            CBUFFER_START(UnityPerMaterial)

            uniform float _HealthValue,_RedHeathPoint,_GreenHealthPoint;
 
            CBUFFER_END

            //------------------纹理声明
            //TEXTURE2D(_DiffTexture);
            //SAMPLER(sampler_DiffTexture);

            

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

                float steosmooth = smoothstep(_RedHeathPoint,_GreenHealthPoint,_HealthValue);
                //01
                float3 healthColor = lerp(float3(1.0,0.0,0.0),float3(0.0,1.0,0.0),steosmooth);
                float3 background = float3(0.0,0.0,0.0);
                float  stepHealth = step(_HealthValue,i.uv0.x);
                float3 finalColor = lerp(healthColor,background,stepHealth);

                //02

                
                
                return float4(finalColor,1);
            }
                
            ENDHLSL
        }


    }
}
