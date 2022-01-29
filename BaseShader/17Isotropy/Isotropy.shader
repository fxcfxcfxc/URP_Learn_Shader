Shader"Myshader/isotropy"
{
    Properties
    {   
     
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
            
            struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv1 :TEXCOORD1;
                float3 normal : NORMAL;
                float4 color  : COLOR;
                
            };

            struct v2f
            {
                float4 posCS : SV_POSITION;
                float3 posWS : POSITION_WS;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float3 nDirWS : TEXCOORD2;
                float4 color :COLOR;
            };


            v2f vert (Attributes v)
            {
                v2f o;
                o.posCS = TransformObjectToHClip(v.vertex.xyz);
                o.posWS = TransformObjectToWorld(v.vertex.xyz);
                o.nDirWS = TransformObjectToWorldNormal(v.normal.xyz);
                o.uv0 = v.uv;
                o.uv1 = v.uv1;
                o.color = v.color;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {

                return float4(1,1,1,0);
            }
            
            ENDHLSL
        }
        
       
   
    }
}
