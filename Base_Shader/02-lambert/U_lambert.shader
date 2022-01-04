Shader"Myshader/U_lambert"
{
    Properties
    {  
    
        _MainColor("颜色",Color)=(1.0,1.0,1.0,1.0)
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
            Name "URPSimpleLit" 
            Tags{"LightMode"="UniversalForward"}

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag     
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


            uniform float4 _MainColor;
            struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                
                float4 posCS : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float3 nDirWS :TEXCOORD1;
            };


            v2f vert (Attributes v)
            {
                v2f o;
                o.posCS = TransformObjectToHClip(v.vertex.xyz);//URP下的函数从模型空间转换到裁切空间
                o.nDirWS = TransformObjectToWorldNormal(v.normal.xyz);//URP下的函把法线型空间转换到世界
                o.uv0 = v.uv;                      
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {   
                Light light = GetMainLight();//获取光源对象引用
                float3 lDir = light.direction;//获取方向
                float3 nDir = i.nDirWS;

                float  lambert = max(0.0,dot(nDir,lDir));
                float3 finalColor = lambert * _MainColor;

                return half4(finalColor,1.0);
            }
            ENDHLSL
        }
    }
}
