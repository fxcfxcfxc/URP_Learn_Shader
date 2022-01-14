Shader"Myshader/U_stencil_rock"
{
    Properties
    {  
    
        _MainColor("颜色",Color)=(1.0,1.0,1.0,1.0)
        _MainTex("主要纹理颜色",2D)="white"{}
        _ID("Mask ID",int)=1
    }
    SubShader
    {   
        Tags
        {   "RenderType"="Opaque"
            "Queue" = "Geometry+2" //为了在mask之后渲染
            "RenderPipeline" = "UniversalPipeline"

        }
        //ColorMask 0
        Stencil
        {
                  Ref[_ID]
                  Comp equal //默认always
                  //Pass replace  //默认keep
                  //Fail Keep  
                  //ZFaill Kepp
        }
        LOD 200


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
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
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
                
                float3 mainTexCol = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv0);

                float  lambert = max(0.0,dot(nDir,lDir));
                float3 finalColor = lambert * _MainColor * mainTexCol;

                return half4(finalColor,1.0);
            }
            ENDHLSL
        }
    }
}
