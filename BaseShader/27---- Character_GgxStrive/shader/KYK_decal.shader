Shader"Myshader/KYK_Decal"
{
    Properties
    {   
       _BaseTex("固有色",2D)="white"{}
    }
    SubShader
    {
        Tags
        {   "RenderType"="Transparent"  
            "RenderPipeline" = "UniversalPipeline"
            "Queue"="Transparent"
        }
        LOD 100
                                                 
        Pass
        {
        
            Name "U_basecolor"
            Tags
            {
              "LightMode" = "UniversalForward"
            
            }
            cull off
            zwrite off
            Blend DstColor SrcColor
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            
            
            //设置SRP Batch
            CBUFFER_START(UnityPerMaterial)
            CBUFFER_END
            TEXTURE2D(_BaseTex);
            SAMPLER(sampler_BaseTex);

            struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                
            };

            struct v2f
            {
                float4 posCS : SV_POSITION;
                float3 posWS : POSITION_WS;
                float2 uv0 : TEXCOORD0;
                float3 nDirWS : TEXCOORD1;
            };


            v2f vert (Attributes v)
            {
                v2f o;
                o.posCS = TransformObjectToHClip(v.vertex.xyz);
                o.posWS = TransformObjectToWorld(v.vertex.xyz);
                o.nDirWS = TransformObjectToWorldNormal(v.normal.xyz);
                o.uv0 = v.uv;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float3 decalTexCol = SAMPLE_TEXTURE2D(_BaseTex,sampler_BaseTex,i.uv0);
 
                return float4(decalTexCol,1.0);
            }
            
            ENDHLSL
        }
        

    }
}
