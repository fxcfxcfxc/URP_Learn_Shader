Shader"Myshader/S_Grabpass"
{
    Properties
    {  
        _NoiseTexture("NoiseTexture",2d)="white"{}
        _disTime("Distime",Range(0,5)) = 0.5
        _DisStrength("_DisStrength",Range(0,1))=0.2
  
    }
    SubShader
    {
        Tags
        {   
            //半透明设置
           "RenderType"="Transparent"
            "Queue" =   "Transparent"
            "IgnoreProjector" = "True"
           "RenderPipeline"="UniversalPipeline"
            "PreviewType"= "Plane"
        
        }
       
        cull off
        lighting off
        zwrite off

        //------------------------------------多pass公用数据------------
        HLSLINCLUDE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            

        //--------------输入结构---------------
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
        //-----
        
        //-----------------------------------PASS0/Kajita_Kay------------------
        Pass
        {
        
            Name "qxty front"
            Tags
            {
                //渲染路径
               "LightMode" = "UniversalForward"
            }
            cull off
            //zwrite off
  
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            //------------------设置SRP Batch ,变量声明
            CBUFFER_START(UnityPerMaterial)

            uniform float4 _NoiseTexture_ST;
            uniform float _disTime,_DisStrength;
            
            CBUFFER_END

            //------------------纹理声明

            
            TEXTURE2D(_NoiseTexture);
            SAMPLER(sampler_NoiseTexture);


            //-------------------------------顶点的输出结构--------------
            struct v2f
            {
                float4 posCS : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float3 nDirWS : TEXCOORD1;
                float4 grabPos : TEXCOORD2;
 
            };
            
            //-------------------------------顶点着色器-----------
            v2f vert (Attributes v)
            {
                
                v2f o;
                
                o.posCS = TransformObjectToHClip(v.vertex.xyz);
                o.nDirWS = TransformObjectToWorldNormal(v.normal.xyz);
                o.uv0 =TRANSFORM_TEX(v.uv,_NoiseTexture);
                o.grabPos =ComputeScreenPos(o.posCS);//该函数返回的是齐次坐标下的屏幕空间值
                return o;
            }

            //------------------------------片段着色器--------------
            half4 frag (v2f i) : SV_Target
            {
                //偏移UV值
                float4 noiseTexColor = SAMPLE_TEXTURE2D(_NoiseTexture,sampler_NoiseTexture,i.uv0);
                //扰动uv
                i.grabPos.xy += noiseTexColor.xy  * _DisStrength;
                //采样屏幕
                float3 bgColor = SampleSceneColor(i.grabPos.xy/i.grabPos.w);
                return float4(bgColor,1.0);
            }
                
            ENDHLSL
        }


    }
}
