Shader"Myshader/GGP"
{
    Properties
    {   
        [Space(10)][Header(_________________Texture)]
        _LogoTexture("广告牌LOGO",2d)="black"{}
        _DistortionTexture("信号故障 RGBA",2d)="black"{}
        _BackgroundTexture("背景",2d)="black"{}
        _LedTexture("LED灯",2d)="black"{}
        _LedGlowTexture("LED数据贴图 RGBA",2d)="black"{}
        
        [Space(10)][Header(__________________Adjust)]
        _MainColor("基础颜色混合",Color)=(1.0,1.0,1.0,1.0)
        _LogoSpeed("LOGO播放速度控制",range(0,2))=0.5
        _BackgroundStrength("背景亮度控制",range(0,1))=1.0
        _DistortionStrength("故障强度控制",range(0,1))=1.0
        _DistortionSpeed("故障速度控制",range(0,1))=1.0
        _ledTexStrength("LED灯强度控制",range(0,1))=1.0
        _LedColorR("LED R动画颜色",Color)=(0.5, 1.0, 0.5, 1.0)
        _LedColorG("LED G动画颜色",Color)=(1.0, 0.2, 0.2, 1.0)
        
  
        
    }
    SubShader
    {
        Tags
        {
           "RenderType"="Opaque"
           "RenderPipeline"="UniversalPipeline"
        
        }
        LOD 100
        cull back
        
        //------------------------------------多pass公用数据------------
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
        
        
        //-----------------------------------PASS0/Kajita_Kay------------------
        Pass
        {
        
            Name "GGP"
            Tags
            {

               "LightMode" = "UniversalForward"
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            //------------------设置SRP Batch ,变量声明
            CBUFFER_START(UnityPerMaterial)
            
            uniform float _LogoSpeed,_BackgroundStrength,_DistortionStrength,_ledTexStrength,_DistortionSpeed;
            uniform float4 _MainColor,_LedColorR,_LedTexture_ST,_LedColorG;
            
           
       
            
            CBUFFER_END

            //------------------纹理声明
            TEXTURE2D(_LogoTexture);
            SAMPLER(sampler_LogoTexture);

            TEXTURE2D(_DistortionTexture);
            SAMPLER(sampler_DistortionTexture);

            TEXTURE2D(_BackgroundTexture);
            SAMPLER(sampler_BackgroundTexture);

            TEXTURE2D(_LedTexture);
            SAMPLER(sampler_LedTexture);

            TEXTURE2D(_LedGlowTexture);
            SAMPLER(sampler_LedGlowTexture);


            

            /*
            封装函数实例
            // funcion：按照法线方向 偏移 Tangent 方向
            float3 ShiftTangent(float3 T,float3 N,float3 shift)
            {
                return normalize(T + shift *N);
                
            }
            */

            //-------------------------------顶点的输出结构--------------
            struct v2f
            {
                float4 posCS : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float3 nDirWS : TEXCOORD2;
                float4 TtoW0 : TEXCOORD3;
                float4 TtoW1 : TEXCOORD4;
                float4 TtoW2 : TEXCOORD5;
                float4 color :COLOR;
            };

 
            
            //-------------------------------顶点着色器-----------
            v2f vert (Attributes v)
            {
                
                v2f o;
                o.posCS = TransformObjectToHClip(v.vertex.xyz);
                float3 posWS = TransformObjectToWorld(v.vertex.xyz);
                
                o.nDirWS = TransformObjectToWorldNormal(v.normal.xyz);
                float3 tDirWS = mul(unity_ObjectToWorld,float4(v.tangent.xyz,0.0).xyz);
                float3 bDirWS = normalize(cross(o.nDirWS,tDirWS) * v.tangent.w);

                o.TtoW0 = float4(tDirWS.x,bDirWS.x,o.nDirWS.x,posWS.x);
                o.TtoW1 = float4(tDirWS.y,bDirWS.y,o.nDirWS.y,posWS.y);
                o.TtoW2 = float4(tDirWS.z,bDirWS.z,o.nDirWS.z,posWS.z);
                
                o.uv0 = v.uv;
                o.uv1 = v.uv1;
                o.color = v.color;
                return o;
            }

            //------------------------------片段着色器--------------
            half4 frag (v2f i) : SV_Target
            {
                //////准备基本数据
                Light light = GetMainLight();
                
                float3 lDirWS = normalize(light.direction);
                float3 lightCol = light.color;
                float3 nDirWS = normalize(i.nDirWS);
                
                float3 posWS = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
                float3 tDirWS = normalize(float3(i.TtoW0.x,i.TtoW1.x,i.TtoW2.x));
                float3 bDirWS = normalize(float3(i.TtoW0.y,i.TtoW1.y,i.TtoW2.y));
                float3 vDirWS = SafeNormalize(GetCameraPositionWS()-posWS);//观察相机方向
                float3 hDirWS = SafeNormalize(vDirWS + lDirWS);//半角方向

                float nDotl = saturate(dot(nDirWS,lDirWS));
                float nDotv = saturate(dot(nDirWS,vDirWS));

                //////准备采样UV
                float2 logoTexUV = float2(i.uv0.x + _Time.y * _LogoSpeed, i.uv0.y);
                //UV动画,通过加一个方向然后乘以时间，移动uv位置
                float2 pannerR = _DistortionSpeed * _Time.y * float2(1,2) + i.uv0;
                float2 pannerG = _DistortionSpeed * _Time.y * float2(-1.8,0.3) + i.uv0;
                float2 pannerB = _DistortionSpeed * _Time.y * float2(0.8,-1.5) + i.uv0;
                float2 pannerA = _DistortionSpeed * _Time.y * float2(-0.8,-1.5) + i.uv0;
                float2 ledGlowUvR = _Time.y * float2(0,0.6) +i.uv0;
                float2 ledGlowUvG = _Time.y *0.1 * float2(2,3) +i.uv0;
                
                /////纹理采样
                float3 logoTexColor  = SAMPLE_TEXTURE2D(_LogoTexture,sampler_LogoTexture,logoTexUV);
                //分别用不同的uv动画采样四个通道的mask
                float distortionTexColorR  = SAMPLE_TEXTURE2D(_DistortionTexture,sampler_DistortionTexture,pannerR).r;
                float distortionTexColorG  = SAMPLE_TEXTURE2D(_DistortionTexture,sampler_DistortionTexture,pannerG).g;
                float distortionTexColorB  = SAMPLE_TEXTURE2D(_DistortionTexture,sampler_DistortionTexture,pannerB).b;
                float distortionTexColorA  = SAMPLE_TEXTURE2D(_DistortionTexture,sampler_DistortionTexture,pannerA).a;
                float distortion =  distortionTexColorR + distortionTexColorG + distortionTexColorB + distortionTexColorA;
                
                float3 backgroundTexColor  = SAMPLE_TEXTURE2D(_BackgroundTexture,sampler_BackgroundTexture,i.uv0 + distortion * _DistortionStrength);
                float4 ledTexColor  = SAMPLE_TEXTURE2D(_LedTexture,sampler_LedTexture,i.uv0 *_LedTexture_ST.xy +_LedTexture_ST.zw);
                
                float3 ledGlowTexColorR  = SAMPLE_TEXTURE2D(_LedGlowTexture,sampler_LedGlowTexture,ledGlowUvR).r * _LedColorR;
                float3 ledGlowTexColorG  = SAMPLE_TEXTURE2D(_LedGlowTexture,sampler_LedGlowTexture,ledGlowUvG).g * _LedColorG;
                
                float3 pixelColor = logoTexColor + backgroundTexColor * _BackgroundStrength + ledTexColor * _ledTexStrength + ledGlowTexColorR +ledGlowTexColorG;
                //float3 pixelColor =ledGlowTexColorG;

                return float4(pixelColor, 1);
            }
                
            ENDHLSL
        }
        
 
   
    }
}
