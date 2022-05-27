Shader"Myshader/Parallex"
{
    Properties
    {  
        _AlbedoTex("Albedo",2d)="white"{}
        _ParallexTex("ParallexTex",2d)="white"{}
        _ParallexStrength("ParallexStrength",range(-0.5,0.5))=0
        
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
        
        
        //-----------------------------------PASS0------------------
        Pass
        {
        
            Name "parallex"
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
            uniform float _ParallexStrength;
            
 
            CBUFFER_END

            //------------------纹理声明
            TEXTURE2D(_AlbedoTex);
            SAMPLER(sampler_AlbedoTex);

            TEXTURE2D(_ParallexTex);
            SAMPLER(sampler_ParallexTex);
            

            /*
            封装函数格式参考
            // funcion：按照法线方向 偏移 Tangent 方向
            float3 ShiftTangent(float3 T,float3 N,float3 shift)
            {
                return normalize(T + shift *N);
                
            }
            */

            
// 计算视差凹凸贴图的UV偏移
        inline float2 ParallaxOffset( float h, float height, float3 viewDir )
        {
            //h为视差贴图采样的结果*高度后-高度/2
            //这是Unity官方提供的一种性能高的视差贴图算法，对于视差偏移度小的效果还不错
            //由于是在平面上移动UV点，对于视差偏移度过大的效果并不好
            h = h * height - height/2.0;
            float3 v = normalize(viewDir);
            v.z += 0.42;
            return h * (v.xy / v.z);
        }



            //-------------------------------顶点——》片段--------------
            struct v2f
            {
                float4 posCS : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float3 vDirTS : TEXCOORD2;
       
            };
            
            //-------------------------------顶点着色器-----------
            v2f vert (Attributes v)
            {
                
                v2f o;
                
                o.posCS = TransformObjectToHClip(v.vertex.xyz);
                float3 posWS = TransformObjectToWorld(v.vertex);
                o.uv0 = v.uv;
                float3 nDirWS = normalize(TransformObjectToWorldNormal(v.normal));
                float3 tDirWS = mul(unity_ObjectToWorld,float4(v.tangent.xyz,0.0).xyz);
                float3 bDirWS = normalize(cross(nDirWS,tDirWS) * v.tangent.w);
                float3 toW1 = float3(tDirWS.x,bDirWS.x,nDirWS.x);
                float3 toW2 = float3(tDirWS.y,bDirWS.y,nDirWS.y);
                float3 toW3 = float3(tDirWS.z,bDirWS.z,nDirWS.z);
                
                float3x3 TBN = float3x3(toW1,toW2,toW3);//切线空间-》世界空间
                float3 vDirWS = SafeNormalize(GetCameraPositionWS() - posWS);
                o.vDirTS = mul(vDirWS,TBN);//TBN放后面 相当于 逆矩阵得到 ，切线空间下的 视角方向
                //TANGENT_SPACE_ROTATION;

                return o;
            }

            //------------------------------片段着色器--------------
            half4 frag (v2f i) : SV_Target
            {
                //////准备基本数据
                Light light = GetMainLight();
                
                float3 lDirWS = normalize(light.direction);
                float3 lightCol = light.color;
                float h  = SAMPLE_TEXTURE2D(_ParallexTex,sampler_ParallexTex,i.uv0).r;
                h = h * 2 -1;

                float2 offsetUV = ParallaxOffset(h,_ParallexStrength,i.vDirTS);
                float3 albedoColor = SAMPLE_TEXTURE2D(_AlbedoTex,sampler_AlbedoTex,i.uv0+offsetUV);
     
                
                
 
                
                return float4(albedoColor,1);
            }
                
            ENDHLSL
        }


    }
}
