Shader"Myshader/matcap"
{
    Properties
    {   
       _BaseColor("Base Color",Color)=(1,1,1,1)
       _matcapTex("matcap贴图",2D)="white"{}
       _smoothPow("菲尼尔强度",float)=1.0
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
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            
            uniform half4  _BaseColor;
            uniform float  _smoothPow;
            
            TEXTURE2D(_matcapTex);
            SAMPLER(sampler_matcapTex);
            
            
            struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal :NORMAL;
                
            };

            struct v2f
            {   
                float4 posCS : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float3 nDirWS : TEXCOORD1;
                float3 vDirVS : TEXCOORD2;
                float3 posWS : TEXCOORD3;
                
                
            };


            v2f vert (Attributes v)
            {
                v2f o;
                o.posCS = TransformObjectToHClip(v.vertex.xyz);
                o.posWS = TransformObjectToWorld(v.vertex.xyz);
                o.nDirWS = TransformObjectToWorldNormal(v.normal.xyz);
                o.vDirVS = TransformWorldToViewDir(o.nDirWS.xyz);   
                o.uv0 = v.uv;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                //用该片元的法线在观察空间下的向量值的xy，采样贴图
                //注意归一化的法线值为区间为[-1,1]转换到适用于纹理的区间[0,1]
                float3 matcapTex =  SAMPLE_TEXTURE2D(_matcapTex,sampler_matcapTex,i.vDirVS.xy *0.5 +0.5);
                
                //菲涅尔现象：除了金属意外的物体，视角向量与表面向量越垂直，反射就会比较弱，夹角越小，反射越明显
                float3 vDirWS = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);
                float ndotv = pow(1-dot(i.nDirWS,vDirWS),_smoothPow);
                float3 finalcolor = matcapTex + ndotv; 
                return half4(finalcolor,1.0);
            }
            ENDHLSL
        }
    }
}
                                                                                                