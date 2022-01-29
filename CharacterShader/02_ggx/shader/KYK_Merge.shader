Shader"Myshader/KYK_Merge"
{
    Properties
    {   
       _BaseTex("固有色",2D)="white"{}
       _SssTex("阴影面颜色",2D)="white"{}
       _ILMTex("R:高光区域强度——G:固有阴影区域——B:高光形状——A:内描边（贴图要取消SRGB勾选导入）",2D)="white"{}
       _detailTex("细节纹理",2D)="white"{}
       _decalTex("贴花",2D)="white"{}
       _OutlineCol("描边颜色",color)=(1.0,0.0,0.0,1.0)
       _RimMin("边缘光Min",float) = 0.7
       _RimMax("边缘光max",float) = 0.72
       _SpecuPower("高光颜色强度",float) = 10 
       _OutlineWidth("描边宽度",float)=0.04
       _shadowthreshold("阴影阈值",float)=1
       [Space(30)]
       [Toggle(DebugMode)] _DebugMode("DebugMode?", Float) = 0
       [KeywordEnum(None,specShape)]_TestMode("Debug",Int) = 0
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
        
            Name "U_basecolor"
            Tags
            {
              "LightMode" = "UniversalForward"
            
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature DebugMode
            #pragma multi_compile_fog
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            
            
            //设置SRP Batch
            CBUFFER_START(UnityPerMaterial)
            uniform float  _shadowthreshold;
            uniform float  _RimMin;
            uniform float  _RimMax;
            uniform float _SpecuPower;
            uniform int   _TestMode;
            CBUFFER_END
            TEXTURE2D(_BaseTex);
            SAMPLER(sampler_BaseTex);
            
            TEXTURE2D(_ILMTex);
            SAMPLER(sampler_ILMTex);
            
            TEXTURE2D(_SssTex);
            SAMPLER(sampler_SssTex);
            
            TEXTURE2D(_detailTex);
            SAMPLER(sampler_detailTex);
            
            TEXTURE2D(_decalTex);
            SAMPLER(sampler_decalTex);
            
            

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
                //------------------------------------边缘光-------------------------
                Light light = GetMainLight();//获取相机对象
                float3 lDir = normalize(light.direction);
                float3 nDirWS = normalize(i.nDirWS); 
                float3 vDirWS = SafeNormalize(GetCameraPositionWS()-i.posWS);
                float baseRim = 1.0-dot(nDirWS,vDirWS);
                float modifyRim = smoothstep(_RimMin,_RimMax,baseRim);
                float4 baseTexCol = SAMPLE_TEXTURE2D(_BaseTex,sampler_BaseTex,i.uv0);  
                float3 finalRimColor = lerp(0,baseTexCol.rgb,max(0,modifyRim)) * baseTexCol.a;

                
                //-------------------------------------高光--------------------------
                float3 hDirWS = SafeNormalize(lDir + vDirWS);
                float  specular =max(0,dot(nDirWS,hDirWS));
                float4  iLMTexCol = SAMPLE_TEXTURE2D(_ILMTex,sampler_ILMTex,i.uv0);
                float  specMask = iLMTexCol.r;
                float  specShape = iLMTexCol.b;
                float modifySpec = specular - (1-specular)* (1-specShape)/specShape;//颜色加深a= a-(a反向 * B反向)/B
                float3 finalSpec =lerp(0,baseTexCol.rgb * _SpecuPower,max(0, modifySpec * specMask));
                
                //-------------------------------------光照阴影---------------------------
                float  lambert = dot(nDirWS,lDir);
                float  shadowIlm = iLMTexCol.g;
                float  shadowVertex = i.color.r;
                float3 sssTexCol = SAMPLE_TEXTURE2D(_SssTex,sampler_SssTex,i.uv0);
                float mainShadow = step(lambert * shadowVertex ,iLMTexCol.g * _shadowthreshold);
                

                //-------------------------------------内描边----------------------------------
                float inLine = iLMTexCol.a;
                //------------------------------------detail-------------------------------
                float detailTexCol = SAMPLE_TEXTURE2D(_detailTex,sampler_detailTex,i.uv1);
                
                //-----------------------------------贴花---------------------------------
                float3 decalTexCol = SAMPLE_TEXTURE2D(_decalTex,sampler_decalTex,i.uv0);
                
                //------------------------------- 颜色合并------------------------------
                float3 mainColor = lerp(baseTexCol.rgb + finalSpec,sssTexCol * 0.65,mainShadow) + finalRimColor;
                float3 mainColorLine = mainColor * inLine * detailTexCol;
                //-------------------------------------颜色输出-----------------------
                #ifdef DebugMode
                    if(_TestMode == 0)
                     {
                        return  float4(specMask,specMask,specMask,1.0);
                     }
                
                #endif
                 
                 
                float3  baseColor = mainColorLine;
                return float4(baseColor,1.0);
            }
            
            ENDHLSL
        }
        
        pass
        {
            //通过添加lightmode为SRPDEFAULTUNLIT 实现多pass
        
            Name "outline"
            Tags
            {
              "LightMode"  = "SRPDefaultUnlit"
            }
            cull front
            
            HLSLPROGRAM
            #pragma vertex vert_outline
            #pragma fragment frag_outline
            uniform float4 _OutlineCol;
            uniform float  _OutlineWidth;
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            
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
           
            };
            
            
            
            v2f vert_outline (Attributes v)
            {
                v2f o;
                o.posCS = TransformObjectToHClip(v.vertex.xyz);
                
                
                //---------------------------------------------描边--------------------------------------
                //为了使相机无论远近，都是拥有相对的描边宽度
                float3 nDirWS = TransformObjectToWorldNormal(v.normal);//模型法线->世界空间
                //float3 nDirVS = TransformWorldToViewDir(nDirWS);//世界空间法线->观察空间，URP函数可以直接从世界到齐次裁剪空间
                float3 nDirClip = TransformWorldToHClipDir(nDirWS,true);//世界空间-》观察空间-》齐次裁剪空间
                float3 nDirNDC =  nDirClip * o.posCS.w; //齐次裁剪空间 ->NDC
                
                //修复屏幕比例引起的描边问题
                float4 nearUpperRight = mul(unity_CameraInvProjection, float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));//将近裁剪面右上角位置的顶点变换到观察空间
                float aspect = abs(nearUpperRight.y / nearUpperRight.x);//求得屏幕宽高比
                nDirNDC.x *= aspect;
                
                //顶点扩张
                o.posCS.xy = o.posCS.xy + nDirNDC.xy * _OutlineWidth*0.1;
                o.uv0 = v.uv;
                return o;
            }

            half4 frag_outline (v2f i) : SV_Target
            {
                return _OutlineCol;
            }
        
            ENDHLSL
        }
    }
}
