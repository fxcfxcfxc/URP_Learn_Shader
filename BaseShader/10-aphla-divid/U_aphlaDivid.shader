Shader"Myshader/U_aphlaDivid"
{
    Properties
    {  
    
        _MainColor("颜色",Color)=(1.0,1.0,1.0,1.0)
        _smoothness("高光范围",float)=20.0
        _SpecColor("高光颜色",Color)=(1.0,1.0,1.0,1.0)
        _ambStrength("环境光",range(0,1))=0.1
        _MainTex("主要纹理颜色",2D)="white"{}
        _AphlaPower("透明度",Range(0.0,1.0))=0.5
        
    }
        SubShader
    {
        Tags
        {   
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"//一定要设置这个
            "Queue"="Transparent"//一定要设置这个
        }
        LOD 100


        Pass
        {
            Name "U_aphlaTest"
            Tags
            {
            "LightMode" = "UniversalForward"
            }
            cull off
            zwrite off //透明物体关闭深度写入
            Blend One One

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ///投影的相关申明
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT //软阴影
            ///
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"


            uniform float4 _MainColor;
            uniform float  _smoothness;
            uniform float4 _SpecColor;
            uniform float _ambStrength;
            uniform float _AphlaPower;
            TEXTURE2D(_MainTex);//纹理对象
            SAMPLER(sampler_MainTex);//采样器

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
    
                float3  ambColor = _GlossyEnvironmentColor * _ambStrength;//abmient                  

                float4 MainTexCol = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv0);//采样主帖图
    
                float4 SHADOW_COORDS = TransformWorldToShadowCoord(i.posWS);//把模型的世界空间顶点坐标输入，得到阴影坐标（shadow.hlsl文件）
                Light shadowLight = GetMainLight(SHADOW_COORDS);//getmain函数的重载函数，会调用 half MainLightRealtimeShadow(float4 shadowCoord) ，
                half shadow = shadowLight.shadowAttenuation;//获取影子值

    
                
                float3 finalColor = MainTexCol.rgb * lambert * _MainColor + specularCol+ambColor;//混合最终光照
    
                float aphla = MainTexCol.a * _AphlaPower;//片元透明度

                return float4(finalColor * aphla,aphla);
            }
            ENDHLSL

        }
        //UsePass "Universal Render Pipeline/Lit/ShadowCaster" //投射阴影使用的pass，最好自定义一个阴影pass
    }
}
