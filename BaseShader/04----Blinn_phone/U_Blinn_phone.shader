Shader"Myshader/samplerTexture"
{
    Properties
    {  
    
        _MainColor("��ɫ",Color)=(1.0,1.0,1.0,1.0)
        _smoothness("�߹ⷶΧ",float)=20.0
        _SpecColor("�߹���ɫ",Color)=(1.0,1.0,1.0,1.0)
        _ambStrength("������",range(0,1))=1.0
        
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"


            uniform float4 _MainColor;
            uniform float  _smoothness;
            uniform float4 _SpecColor;
            uniform float _ambStrength;
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
                o.posWS  = TransformObjectToWorld(v.vertex.xyz);//URP�µĺ�����ģ�Ϳռ�ת�������пռ�
                o.nDirWS = TransformObjectToWorldNormal(v.normal.xyz);//URP�µĺ��ѷ����Ϳռ�ת��������
                o.uv0 = v.uv;                      
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {      
                
                Light light = GetMainLight();//��ȡ���ƹ����
                float3 lightCol = light.color;//��ȡ��Դ������ɫ
                float3 lDir = normalize(light.direction);//��ȡ�ⷽ��
                float3 nDir = normalize(i.nDirWS);//һ��Ҫ��һ������

                float3 vDir = SafeNormalize(GetCameraPositionWS()-i.posWS);//�ӽǷ���safe ��λ��ĸΪ0
                float3 hDir = SafeNormalize(vDir +lDir);//��Ƿ���
                float3 ndoth = saturate(dot(hDir,nDir));


                float3 specularCol = pow(ndoth,_smoothness)* lightCol * _SpecColor;//�߹�

                float  lambert = max(0.0,dot(nDir,lDir));//lambert
                float3  ambColor = UNITY_LIGHTMODEL_AMBIENT.rgb * _ambStrength;//abmient
                
                float3 finalColor = lambert * _MainColor + specularCol+ambColor;

                return float4(finalColor,1);
            }
            ENDHLSL
        }
    }
}
