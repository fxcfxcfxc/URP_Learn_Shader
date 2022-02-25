Shader"Myshader/Kajiya-Kay"
{
    Properties
    {   
        [Space(10)][Header(_________________Texture)]
        _diffuseTexture("基础颜色贴图",2d)="black"{}
        _MaskTexture("遮罩数据贴图 R:空 G：AO B：高光范围遮罩",2d)="white"{}
        _offsetTexture("偏移贴图",2d)="white"{}
        
        [Space(10)][Header(__________________AdjustBaseColor)]
        _MainColor("基础颜色混合",Color)=(1.0,1.0,1.0,1.0)
        _ShadowColor("暗部颜色",Color)=(0.5, 0.5, 0.5, 1.0) 
        
        [Space(10)][Header(_________________Specular1)]
        _TangentValue("高光整体强度",Range(0,30))=1.5
        _specularColor("第一层高光颜色",Color)=(1.0, 0.8, 0.6, 1.0)
        _specularStrength("第一层高光范围",Range(0,500))=70
        _Shift1("第一层高光位置偏移",Range(-1,1))=-0.5
        
        [Space(10)][Header(_________________Specular2)]
        _specularColor2("第二层高光颜色",Color)=(1.0, 1.0 ,1.0 ,1.0)
        _specularStrength2("第二层高光范围",Range(0,500))=100
        _Shift2("第二层高光位置偏移",Range(-1,1))=0.0
        
        
        [Space(10)][Header(__________________Outline)]
        _OutlineCol("描边颜色",Color)=(1.0,0.0,0.0,1.0)
        _OutlineWidth("描边宽度",float)=0.04
        
    }
    SubShader
    {
        Tags
        {
           "RenderType"="Opaque"
           "RenderPipeline"="UniversalPipeline"
        
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
        
        
        //-----------------------------------PASS0/Kajita_Kay------------------
        Pass
        {
        
            Name "Kajita_Kay"
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
            
            uniform float  _TangentValue;
            uniform float  _specularStrength;
            uniform float4 _specularColor;
            uniform float  _specularStrength2;
            uniform float4 _specularColor2;
            uniform float  _Shift1;
            uniform float3 _MainColor;
            uniform float3 _ShadowColor;
            uniform float  _OutlineWidth;
            uniform float3 _OutlineCol;
            
            CBUFFER_END

            //------------------纹理声明
            TEXTURE2D(_diffuseTexture);
            SAMPLER(sampler_diffuseTexture);

            TEXTURE2D(_offsetTexture);
            SAMPLER(sampler_offsetTexture);
      
            TEXTURE2D(_MaskTexture);
            SAMPLER(sampler_MaskTexture);
            

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

            // funcion：按照法线方向 偏移 Tangent 方向
            float3 ShiftTangent(float3 T,float3 N,float3 shift)
            {
                return normalize(T + shift *N);
                
            }

            // funcion： 获取头发高光
            float3 StrandSpecular(float3 T,float3 V,float3 L,float exponent)
            {
                float3 H = normalize(L+V);
                float dotTH = dot(T,H);
                float sinTH = sqrt(1-dotTH * dotTH);
                float dirAtten = smoothstep(-1, 0, dotTH);
                return dirAtten * pow(sinTH,exponent) * _TangentValue;
                
                
                
            }

            
            
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
                //准备基本数据
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

                //准备纹理数据
                float3 diffuseTexColor  = SAMPLE_TEXTURE2D(_diffuseTexture,sampler_diffuseTexture,i.uv0);
                float3 offsetTexColor   = SAMPLE_TEXTURE2D(_offsetTexture,sampler_offsetTexture,i.uv0);
                float3 _MaskTexColor    = SAMPLE_TEXTURE2D(_MaskTexture,sampler_MaskTexture,i.uv0);

                //-------------------------------------明暗漫反射
                //明暗
                float aoMask = _MaskTexColor.g;
                float shadow = lerp(-0.8,1,nDotl * aoMask * 2);//?
                float shadowMod = pow(saturate(shadow),0.25);
                
                //颜色
                float3 diffuse = lerp(_ShadowColor,diffuseTexColor * _MainColor,shadowMod);

                //--------------------------------------边缘光

                
                //--------------------------------------高光
                //切线偏移方向强度
                float offsetT = offsetTexColor.g;
                float3 t1 = ShiftTangent(bDirWS,nDirWS,_Shift1 + offsetT);
                
                //计算高光
                float3 spec1 = StrandSpecular(t1,vDirWS,lDirWS,_specularStrength) *_specularColor;

                //高光遮罩范围限制
                float specularMask = _MaskTexColor.b;
                float3 spec1Mod = spec1 * nDotl * specularMask;

                //-------------------------------------输出
                //合并颜色
                float3 merge = diffuse +  spec1Mod;
                float3 pixelColor = merge;
                return float4(pixelColor,1);
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
