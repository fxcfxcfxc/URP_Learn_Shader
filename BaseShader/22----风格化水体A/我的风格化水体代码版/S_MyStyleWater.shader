Shader"Myshader/MyWater"
{
    Properties
    {  
//      _DiffTexture("DiffTexture",2D)="black"{}
//      _testrange("testrange",Range(0,10))=1
//      _normalMap("normalMap",2D)="bump"{}
        [Header(_________________________Texture)]
        _NoiseTexture("NoiseTexture",2D) ="Black"{} 
        _waterUpTexture("waterUpTexture",2D)="Black"{}
        _caustTexture("caust",2D)= "Black"{}
        
        [Header(_________________________MainColor)]
        _Edgecolor("Edgecolor",Color)=(0,0,0,1)
        _Maincolor("Maincolor",Color)=(1,1,1,1)
        _depth("depth",float) = 5.0
        _RippleColor("RippleColor",color)=(1, 1, 1, 1)
        
        [Header(_________________________Refraction)]
        _RefractionSpeed("RefractionSpeed",float) = 0.1  
        _RefractionScale("RefractionScale",float) = 0.3
        _reflactionUVDepthAmount("reflactionUVDepthAmount",float) = 5.0
        _NoiseX("NoiseX",float)=0.3
        _NoiseY("NoiseY",float)=0.3
        
        [Header(__________________________Foam)]
        _FoamSpeed("FoamSpeed",Range(0,0.5))=0.3
        _FoamScale("FoamScale",float)=4
        _FoamAmount("FoamAmount",float)=0.3
        _FoamColor("FoamColor",Color)=(1,1,1,1)
        
        [Header(_________________________WaterUp)]
        _WaterUpUvSize("WaterUpUvSize",Range(0,10))=1.0
        _waterSpeed("waterSpeed",Range(0,5))=0.18
        _waterUpStrength("waterUpStrength",Range(0,2))=0.1
        
        [Header(_________________________Caustic)]
        [HDR]_causticColor("_causticColor",Color)=(1, 1, 1, 1 )
        _causticScale("causticScale",float)=1.0
        _causticSpeed("causticSpeed",float)=0.1
        
    }
    SubShader
    {   
        
        //==================== Sub tag设置======================================
        Tags
        {   
            
           "RenderType"="Transparent"
           "RenderPipeline"="UniversalPipeline"
           "Queue" = "Transparent"
            "IgnoreProjector" = "True"
           
        
        }
        LOD 100
        
        
        //=========================================多pass公用输入数据===================
        HLSLINCLUDE
        //-----------------------库
    
        //----Verteices数据out ————》顶点着色器in
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
        
        
        //=============================================PASS 0===========================
        Pass
        {
            //-----------------pass name
            Name "flowmap"
            
            //------------------pass tags
            Tags
            {
                //渲染路径
               "LightMode" = "UniversalForward"
            }
            
            //---------------------
       
            
            cull off
            zwrite off
            Blend One OneMinusSrcAlpha
           
            //-----------
            HLSLPROGRAM
            
            #pragma target 3.5
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            

            //---------------------设置SRP Batch ,变量声明
            CBUFFER_START(UnityPerMaterial)
            uniform float _depth ,_RefractionSpeed,_RefractionScale,_NoiseX ,_NoiseY ,_FoamSpeed, _FoamScale,_FoamAmount, _reflactionUVDepthAmount;
            float _WaterUpUvSize, _waterSpeed ,_waterUpStrength, _causticScale, _causticSpeed;
            float4 _Edgecolor, _Maincolor, _FoamColor ,_causticColor , _RippleColor;
            float3 _Position ;
            float _OrthographicCamSize;
            CBUFFER_END

            //---------------------纹理声明
            // TEXTURE2D(_DiffTexture);
            // SAMPLER(sampler_DiffTexture);
            //
            TEXTURE2D(_NoiseTexture);
            SAMPLER(sampler_NoiseTexture);

            TEXTURE2D(_waterUpTexture);
            SAMPLER(sampler_waterUpTexture);

            TEXTURE2D(_caustTexture);
            SAMPLER(sampler_caustTexture);

            TEXTURE2D(_GlobalEffectRT);
            SAMPLER(sampler_GlobalEffectRT);

            //TEXTURE2D(_CameraDepthTexture);
            //SAMPLER(sampler_CameraDepthTexture);
            
            //------------------------自定义封装函数
            /*
            封装函数格式参考
            // funcion：按照法线方向 偏移 Tangent 方向
            float3 ShiftTangent(float3 T,float3 N,float3 shift)
            {
                return normalize(T + shift *N);
                
            }
            */

            //-------------------------提取水面边缘

            
            //-------------------------UV偏移
            half2 UVMove(float2 uv, float Speed , float Scale)
            {
                half2 newUV =uv * Scale + (_Time.y * Speed).rr;
                return newUV;
            }

            //-------------------------获取屏幕图像
            float3 GetSceneColor(float3 WorldPos,float2 offsetUV)
            {
                float4 ScreenPostion = ComputeScreenPos(TransformWorldToHClip(WorldPos));
                return SampleSceneColor( (ScreenPostion.xy + offsetUV) / ScreenPostion.w);
            }
            

            //-------------------------------顶点着色器out ——》片段着色器in
            struct v2f
            {
                float4 posCS : SV_POSITION;
                float3 posWS: POSITION_WS;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float3 nDirWS:TEXCOORD2;
                float3 tDirWS:TEXCOORD3;
                float  clipZ : TEXCOORD4;
                float4 color: COLOR;
       
            };
            
            //-----------------------------------------顶点着色器
            v2f vert (Attributes v)
            {
                
                v2f o;
                

                //-----------------------------------水面浮动
                //计算 采样水面浮动噪波的 UV 
                half2 waterUPUV = v.uv * _WaterUpUvSize + (_waterSpeed * _Time.y).rr;
                float NoiseUV  = SAMPLE_TEXTURE2D_LOD(_waterUpTexture, sampler_waterUpTexture, waterUPUV ,1.0).r ;
                v.vertex.y +=  NoiseUV * _waterUpStrength;
                //End-------------------------------------------
                
                //MVP  object world-》  world space-》 camera space-》clip space  posCS 的范围【-w,w】
                o.posCS = TransformObjectToHClip(v.vertex.xyz);
                o.clipZ = o.posCS.w;
                o.posWS = TransformObjectToWorld(v.vertex.xyz);
  
                o.nDirWS = TransformObjectToWorldNormal(v.normal.xyz);
                o.tDirWS= normalize( mul( unity_ObjectToWorld, float4(v.tangent.xyz,0.0) ) );
                     
                o.color = v.color;
                o.uv0 = v.uv;
                o.uv1 = v.uv1;

                return o;
            }

            //------------------------------------------片段着色器
            half4 frag (v2f i) : SV_Target
            {
                //-------------------------------------------------准备基本数据
                Light light = GetMainLight();
                //主方向灯光 世界方向
                float3 lDirWS = normalize(light.direction);
                //主方向灯光 颜色
                float3 lightCol = light.color;
                //ambient color
                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;
                //片元位置 世界空间
                float3 posWS = i.posWS;
                //片元 屏幕空间UV（unity帮我们处理了 裁剪空间下的坐标，经过透视除法，NDC，屏幕坐标映射，所以这里直接是屏幕位置）,Z值为【0，1】
                float2 posScreen = i.posCS.xy / _ScreenParams.xy;
                //片元z深度  clip空间
                float clipZ = i.clipZ;
                //片元 顶点色
                float4 vertexColor = i.color;
                //片元 世界法线方向
                float3 nDirWS =normalize( i.nDirWS );
                //片元切线方向 世界
                float3 tDirWS = i.tDirWS;
                //片元副切线方向 世界
                float3 biDirWS =normalize( cross(i.nDirWS,i.tDirWS) ) ;
                //UVO
                float2 uv0 = i.uv0;
                //uv1
                float2 uv1 = i.uv1;
                //视角相机方向 世界 
                float3 vDirWS =SafeNormalize( GetCameraPositionWS() - i.posWS);
                //灯光反射向量 世界
                float3 rDirWS = normalize( reflect(-lDirWS,nDirWS) );
                

                //---------------------------------------------------纹理数据采样
                
                //hlsl常规纹理采样格式   参数为：纹理，  采样器， 坐标
                // float3 textureColor = SAMPLE_TEXTURE2D(_DiffTexture,sampler_DiffTexture,uv0);

                //法线贴图(得到贴图中存储的切线空间下的法线信息)
                // float3 nDirTS = UnpackNormal( SAMPLE_TEXTURE2D(_normalMap,sampler_normalMap,i.uv0) );

                //深度图
                float depthvalue  = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, posScreen).r;
                
                
                //----------------------------------------------------计算

                //投影的交互浪花区域
                
                float2 a =float2(posWS.x,posWS.z)- float2(_Position.x,_Position.z);
                a= a/ (_OrthographicCamSize *2) + float2(0.5,0.5);
                float textureColor = SAMPLE_TEXTURE2D(_GlobalEffectRT,sampler_GlobalEffectRT,a).z;
                float Ripple = smoothstep(0.6,0.605,textureColor);
                

                //------------------------------基本水面颜色区域
                //获取到了相机空间下的z坐标值00
                depthvalue = LinearEyeDepth(depthvalue,_ZBufferParams);
                //获取水面深度    
                float waterplaneDepth = i.posCS.w;
                float edgedepth = depthvalue -waterplaneDepth;
                float4 waterColor = lerp(_Edgecolor,_Maincolor,edgedepth/_depth);

                //---------------------------------焦散效果
                float2 causticUV = UVMove(uv0, _causticSpeed, _causticScale);
                float caustic = SAMPLE_TEXTURE2D(_caustTexture, sampler_caustTexture,causticUV).r;
                float4 causticMask = saturate (1.0- (depthvalue - waterplaneDepth)/2 ) * caustic * _causticColor;

                //-----------------------------获取水底场景图像
                float2 ReflactionUV = UVMove(uv0, _RefractionSpeed, _RefractionScale);
                float ReflactionNoise = SAMPLE_TEXTURE2D(_NoiseTexture, sampler_NoiseTexture, ReflactionUV).r;
                //根据深度来控制折射的一个强弱变化
                float reflactionUVDepth = (depthvalue - waterplaneDepth)/_reflactionUVDepthAmount;
                half3 SceneColor = GetSceneColor(posWS, float2(ReflactionNoise * _NoiseX, ReflactionNoise * _NoiseY) * reflactionUVDepth);
                
                
                //----------------------------水花
                float2 FilterMoveUV =  UVMove(uv0, _FoamSpeed, _FoamScale);
                float FilterNoise = SAMPLE_TEXTURE2D(_NoiseTexture,sampler_NoiseTexture, FilterMoveUV).r;
                float FilterSceneMoveDepth =  (depthvalue -waterplaneDepth)/_FoamAmount;
                float waterfilter =step(FilterSceneMoveDepth,FilterNoise);

                
                //----------------------------颜色混合
                float4 lerpColor = lerp(waterColor + causticMask, _FoamColor, waterfilter);
                
                lerpColor.rgb = lerp(SceneColor, lerpColor, lerpColor.a);

                lerpColor.rgb = lerp(lerpColor.rgb,_RippleColor.rgb,Ripple);
                
                //----------------------------
                float3 fragementOutColor = lerpColor.rgb;    
                return float4(fragementOutColor,1);
                
            }
                
            ENDHLSL
        }


    }
    
    
    
}
