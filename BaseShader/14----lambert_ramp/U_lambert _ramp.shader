Shader"Myshader/U_lambert_ramp"
{
    Properties
    {  
    
        _MainColor("��ɫ",Color)=(1.0,1.0,1.0,1.0)
        _rampTex("ramp��ͼ",2D)="white"{}
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
            TEXTURE2D(_rampTex);
            SAMPLER(sampler_rampTex);

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
                o.posCS = TransformObjectToHClip(v.vertex.xyz);//URP�µĺ�����ģ�Ϳռ�ת�������пռ�
                o.nDirWS = TransformObjectToWorldNormal(v.normal.xyz);//URP�µĺ��ѷ����Ϳռ�ת��������
                o.uv0 = v.uv;                      
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {   
                Light light = GetMainLight();//��ȡ��Դ��������
                float3 lDir = light.direction;//��ȡ����
                float3 nDir = i.nDirWS;

                float  lambert = max(0.0,dot(nDir,lDir));
                
                float3 rampcolor = SAMPLE_TEXTURE2D(_rampTex,sampler_rampTex,float2(lambert,2));
                return half4(rampcolor,1.0);
            }
            ENDHLSL
        }
    }
}
