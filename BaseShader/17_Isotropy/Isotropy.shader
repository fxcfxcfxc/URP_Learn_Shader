Shader"Myshader/isotropy"
{
    Properties
    {   
        _baseCol("BaseCol",Color)=(1.0,0.0,0.0,1.0)
        _specluarRange("specluarRange",range(0,1))=0.9
        _hairNoise("hairNoise",2D)="white"{}
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
            uniform float _specluarRange;
            uniform float4 _baseCol;
            CBUFFER_END

            TEXTURE2D(_hairNoise);
            SAMPLER(sampler_hairNoise);
            
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

                Light light = GetMainLight();
                float3 lDir = normalize(light.direction);
                float3 lightCol = light.color;
                float3 nDir = normalize(i.nDirWS);

                float3 vDir = SafeNormalize(GetCameraPositionWS()-i.posWS);
                float3 hDir = SafeNormalize(vDir + lDir);//半角方向
                
            
                float blinnPhong = saturate(dot(hDir,nDir));
                float w = fwidth(blinnPhong) * 2.0;
                
                float3 specularCol = lerp(0,1,smoothstep(-w,w,blinnPhong - (1 - _specluarRange)))  * step(0.0001,_specluarRange)* lightCol;//a，x，Returns (x >= a) ? 1 : 0
                // 用来当值为0时高光不消失的解决办法 step(0.0001,_specluarRange)
                // (1 - _specluarRange) 便于习惯取反，值越大高光越大，用来控制高光范围
                // lerp函数 用来最后的修正  lerp（a，b，x）
                
                float3 pixelCol = specularCol + _baseCol;
                return float4(pixelCol,0);
            }
            
            ENDHLSL
        }
        
       
   
    }
}
