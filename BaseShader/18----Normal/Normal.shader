Shader"Myshader/Normal"
{
    Properties
    {   
        _normalMap("normalMap",2D)="bump"{}
    }
    SubShader
    {
        Tags
        {
           "RenderType"="Opaque"
           "RenderPipeline"="UniversalPipeline"
        
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

            CBUFFER_START(UnityPerMaterial)

            CBUFFER_END

            TEXTURE2D(_normalMap);
            SAMPLER(sampler_normalMap);
            
            struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 posCS : SV_POSITION;
                float3 posWS : POSITION_WS;
                float2 uv0 : TEXCOORD0;
                float3 nDirWS : TEXCOORD1;
                float3 tDirWS : TEXCOORD2;//切线向量
                float3 bDirWS : TEXCOORD3;//副切线向量
                
            };


            v2f vert (Attributes v)
            {
                v2f o;
                o.posCS = TransformObjectToHClip(v.vertex.xyz);
                o.posWS = TransformObjectToWorld(v.vertex.xyz);
                o.nDirWS = normalize(TransformObjectToWorldNormal(v.normal.xyz));
                o.tDirWS = mul(unity_ObjectToWorld,float4(v.tangent.xyz,0.0).xyz);
                o.bDirWS = normalize(cross(o.nDirWS,o.tDirWS) * v.tangent.w); 
                o.uv0 = v.uv;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {

                Light light = GetMainLight();
                float3 lDir = normalize(light.direction);
                
                float3 nDirTS = UnpackNormal(SAMPLE_TEXTURE2D(_normalMap,sampler_normalMap,i.uv0));//解码采样法线贴图
                float3x3 TBN =float3x3(i.tDirWS,i.bDirWS,i.nDirWS);//构建TBN矩阵
                float3 nDirF = normalize(mul(nDirTS,TBN));//将法线转换到世界空间

                float lambert = max(0.0,dot(nDirF,lDir));
                float3 pixelCol = lambert;
                return float4(pixelCol,0);
            }
            
            ENDHLSL
        }
        
       
   
    }
}
