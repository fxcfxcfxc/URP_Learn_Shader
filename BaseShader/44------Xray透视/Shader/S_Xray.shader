Shader"Myshader/Xray"
{
    Properties
    {  
    
        [HDR]_MainColor("颜色",Color)=(1.0,1.0,1.0,1.0)
        _smoothness("高光范围",float)=20.0
        _SpecColor("高光颜色",Color)=(1.0,1.0,1.0,1.0)
        _ambStrength("环境光",range(0,1))=1.0
        _MainTex("主要纹理颜色",2D)="white"{}
        
    }
    SubShader
    {   
        Tags
        {   
            "RenderPipeline" = "UniversalPipeline"
        }


        Pass
        {
            name "Xray"
           Tags{"LightMode"="UniversalForward"}
      
                Blend SrcAlpha OneMinusSrcAlpha
                ZTest Greater
                ZWrite off
            
                Stencil
                {
                   Ref 1 
                   Comp GEqual
                   Pass Replace
                    
                }
            
                HLSLPROGRAM
                #pragma  vertex vert
                #pragma  fragment frag

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

                float4 _MainColor;
                struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv     : TEXCOORD0;
                float3 normal :NORMAL;
            };

            struct v2f
            {
                
                float4 posCS  : SV_POSITION;
                float3 posWS  : POSITION_WS;
                float2 uv0    : TEXCOORD0;
                float3 nDirWS : TEXCOORD1;
            };


            v2f vert (Attributes v)
            {
                v2f o;
                o.posCS  = TransformObjectToHClip(v.vertex.xyz);
                o.posWS  = TransformObjectToWorld(v.vertex.xyz);//URP下的函数从模型空间转换到世界空间
                o.nDirWS = TransformObjectToWorldNormal(v.normal.xyz);//URP下的函把法线型空间转换到世界
       
                o.uv0 = v.uv;                      
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 vDirWS = normalize(  _WorldSpaceCameraPos  - i.posWS );
                float ndotv =  pow(   1-  max(0,  dot(i.nDirWS , vDirWS) ), 5)  ;
                float3 pixelcolor = ndotv * _MainColor;
                return float4(pixelcolor,  0.5);
            }

                
                ENDHLSL
                
                
        
            
        }

    }
}