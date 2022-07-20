Shader"Myshader/YsFace"
{
    Properties
    {   
        [Space(10)][Header(_________________Texture)]
        _diffuseTexture("基础颜色贴图",2d)="black"{}
        _ShadowTexture("明暗贴图",2d)="black"{}
        
        [Space(10)][Header(_________________AdjustShadow)]
        _ShadowColor("暗部颜色",Color)=(0.3, 0.3, 0.3, 1.0)
        
        [Space(10)][Header(_________________Outline)]
        _OutlineCol("描边颜色",Color)=(1.0,0.0,0.0,1.0)
        _OutlineWidth("描边宽度",float)=0.04
  
        
    }
    
    //在SubShader进行的设置将会用于所用的Pass
    SubShader
    {
        Tags
        {
           "RenderType"="Opaque"//不透明渲染类型
           "RenderPipeline"="UniversalPipeline"//渲染管线
        
        }
        LOD 100
        
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
        
        
        //-----------------------------------PASS0------------------
        Pass
        {
        
            Name "YsFace"
            Tags
            {

               "LightMode" = "UniversalForward"
            }
            HLSLPROGRAM
            #pragma vertex vert//顶点着色 使用的函数
            #pragma fragment frag//像素着色 使用的函数
            #pragma multi_compile_fog//宏定义描述 ： shader参与雾效果

            //------------------设置SRP Batch ,变量声明
            CBUFFER_START(UnityPerMaterial)
            
            uniform float4  _ShadowColor;
      
            
            CBUFFER_END

            //------------------纹理声明
            TEXTURE2D(_diffuseTexture);
            SAMPLER(sampler_diffuseTexture);

            TEXTURE2D(_ShadowTexture);
            SAMPLER(sampler_ShadowTexture);

        
            

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

                //这样组合变量可以剩下一个位置
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

                //////准备纹理数据
                float3 diffuseTexColor  = SAMPLE_TEXTURE2D(_diffuseTexture,sampler_diffuseTexture,i.uv0);
                float3 rightshadowTexColor = SAMPLE_TEXTURE2D(_ShadowTexture,sampler_ShadowTexture,i.uv0);
                float3 leftshadowTexColor = SAMPLE_TEXTURE2D(_ShadowTexture,sampler_ShadowTexture,float2(-i.uv0.x,i.uv0.y));

                /////准备朝向判断数据
                float3 up = float3(0.0, 1.0, 0.0);
                float3 front = TransformObjectToWorldDir(float3(0.0, 0.0, 1.0));
                float3 right = cross(up,front);
                
                //判断灯光方向和角色朝右方向dot值，>0时原UV采样，<0时镜像UV X采样
                float switchShadow = dot(lDirWS.xz,right.xz);
                //代替if 语句方式 获得正确的动态采样
                float3 faceShadow = step(0,switchShadow) * rightshadowTexColor + step(switchShadow,0) * leftshadowTexColor;

                //当灯光朝向脸部前面，阈值应该为0，脸部应该全部处与明面；当灯光从背面打向角色，角色脸部应该全部处于暗面,阈值应该为1；
                float ThresholdShadow = 1-(dot(lDirWS.xz,normalize(front.xz)) * 0.5  + 0.5);

                //最终明暗
                float faceFinalShaodw = step(ThresholdShadow,faceShadow);

                //固有色
                float3 facePixelColor =  lerp(_ShadowColor * diffuseTexColor ,diffuseTexColor,faceFinalShaodw);
 
                return float4(facePixelColor,1);
            }
            
            ENDHLSL
        }
        
        //-----------------------------------PASS1/描边--------------------
        Pass
        {
            Name "Outline"
            Tags
            {
                "LightMode"  = "SRPDefaultUnlit"
                
            }
            cull front
            
            HLSLPROGRAM
            #pragma vertex vert_outline
            #pragma fragment frag_outline

            //------变量声明
            uniform float4 _OutlineCol;
            uniform float _OutlineWidth;


            //-------顶点输出结构
            struct v2f
            {   
                float4 posCS : SV_POSITION;
                float2 uv0 : TEXCOORD0;
           
            };
            
            
            //---------顶点着色器
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
                o.posCS.xy = o.posCS.xy + nDirNDC.xy * _OutlineWidth*0.01;
                o.uv0 = v.uv;
                return o;
            }

            //---------片元着色器
            half4 frag_outline (v2f i) : SV_Target
            {
                return _OutlineCol;
            }
            
            
           ENDHLSL 
        }
       
   
    }
}
