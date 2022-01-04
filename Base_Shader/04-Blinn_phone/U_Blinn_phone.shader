Shader"Myshader/samplerTexture"
{
    Properties
    {  
    
        _MainColor("颜色",Color)=(1.0,1.0,1.0,1.0)
        _smoothness("高光范围",float)=20.0
        _SpecColor("高光颜色",Color)=(1.0,1.0,1.0,1.0)
        _ambStrength("环境光",range(0,1))=1.0
        
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
                o.posWS  = TransformObjectToWorld(v.vertex.xyz);//URP下的函数从模型空间转换到裁切空间
                o.nDirWS = TransformObjectToWorldNormal(v.normal.xyz);//URP下的函把法线型空间转换到世界
                o.uv0 = v.uv;                      
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {      
                
                Light light = GetMainLight();//获取到灯光对象
                float3 lightCol = light.color;//获取光源对象颜色
                float3 lDir = normalize(light.direction);//获取光方向
                float3 nDir = normalize(i.nDirWS);//一定要归一化法线

                float3 vDir = SafeNormalize(GetCameraPositionWS()-i.posWS);//视角方向safe 方位分母为0
                float3 hDir = SafeNormalize(vDir +lDir);//半角方向
                float3 ndoth = saturate(dot(hDir,nDir));


                float3 specularCol = pow(ndoth,_smoothness)* lightCol * _SpecColor;//高光

                float  lambert = max(0.0,dot(nDir,lDir));//lambert
                float3  ambColor = UNITY_LIGHTMODEL_AMBIENT.rgb * _ambStrength;//abmient
                
                float3 finalColor = lambert * _MainColor + specularCol+ambColor;

                return float4(finalColor,1.0);
            }
            ENDHLSL
        }
    }
}
