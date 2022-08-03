Shader"Myshader/BaseMoudle"
{
    Properties
    {  


        //_normalMap("normalMap",2D)="bump"{}
        _MainNoisexture("_MainNoisexture",2D)="black"{}
        _Noisexture("_Noisexture",2D)="black"{}
        
        [Header(__________________________________noise01)]
  
        _SpeedNoiseX("_SpeedNoiseX",float) =0.2
        _SpeedNoiseY("_SpeedNoiseY",float) =0.2
        _SpeedNoiseScale("_SpeedNoiseScale",float)=1.0
        
        
        
        [Header(__________________________________noise02)]
        _MainScale("_MainScale",float) =1.0
        _DistorStrength("_DistorStrength",float) =1.0
        _SpeedMainX("_SpeedMainX",float) =1.0
        _SpeedMainY("_SpeedMainY",float) =1.0
        _VertexDistorStrength("_VertexDistorStrength",float) =0.5
        
        
        [Header(__________________________________Color)]
        _Color("Color",color) = (1,1,1,1)
        _Color2("Color2",color) = (1,1,1,1)
        _offset("_offset",Range(0,1)) = 1
        _Strength("_Strength",float)= 1.0
        
        [Header(__________________________________Edge)]
        _depthScale("_depthScale",float) = 200
        _EdgeBlur("_EdgeBlur",Range(-1,1))= 0
         _edgeColor("_edgeColor",color)= (1,1,1,1)
        _edgeColorStrength("_edgeColorStrength",float)=1.0
        
         [Header(__________________________________Top)]
        _Cutoff("_Cutoff",Range(0,1) )=0.5
        _TopSmooth("_TopSmooth",Range(0,1))=0.1
        _TopColor("_TopColor",color)=(1,1,1,1)
        _TopColorStrength("_TopColorStrength",float)= 3
        
        [Header(__________________________________move)]
        _Speed("_Speed",Range(0,1.0)) = 0.01
        _Amount("_Amount",Range(0,1.0)) = 0.01
        _Height("_Height",Range(0,1.0)) = 0.01
        
        
    }
    SubShader
    {   
        
        //==================== Sub tag设置======================================
        Tags
        {   
            
           "RenderType"="Opaque"
           "RenderPipeline"="UniversalPipeline"
        
        }
        LOD 100
        
        
        //=========================================多pass公用输入数据===================
        HLSLINCLUDE
        //-----------------------库
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
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
            //cull off
            //zwrite off
  
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma target 3.5    
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            #include "Assets/UnityShader_URP/BaseShader/CustomHLSLFunction/CustomHlslFunction.hlsl"

            //---------------------设置SRP Batch ,变量声明
            CBUFFER_START(UnityPerMaterial)
            uniform float _testrange,_SpeedNoiseX,_SpeedNoiseY,_SpeedNoiseScale;
            float _MainScale, _DistorStrength, _SpeedMainX,_SpeedMainY,_VertexDistorStrength;
            float _offset,_Strength , _depthScale, _EdgeBlur, _edgeColorStrength;
            float4 _Color, _Color2, _edgeColor, _TopColor;
            float _Cutoff, _TopSmooth, _TopColorStrength, _Speed, _Amount, _Height;
 
            CBUFFER_END

            //---------------------纹理声明
            TEXTURE2D(_Noisexture);
            SAMPLER(sampler_Noisexture);

            // TEXTURE2D(_normalMap);
            // SAMPLER(sampler_normalMap);
            //
            TEXTURE2D(_MainNoisexture);
            SAMPLER(sampler_MainNoisexture);
            
            //------------------------自定义封装函数
            /*
            封装函数格式参考
            // funcion：按照法线方向 偏移 Tangent 方向
            float3 ShiftTangent(float3 T,float3 N,float3 shift)
            {
                return normalize(T + shift *N);
                
            }
            */

            

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

                //MVP  object world-》  world space-》 camera space-》clip space  posCS 的范围【-w,w】
                v.vertex.y +=  (  sin(_Time.z * _Speed + (v.vertex.x * v.vertex.z * _Amount) ) * _Height ) * v.color.r;
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
                //片元 屏幕空间UV（unity帮我们处理了 裁剪空间下的坐标，经过透视除法，NDC，屏幕坐标映射，所以这里直接是屏幕位置）
                float2 posScreen = i.posCS.xy / _ScreenParams.xy;
                //片元z深度  clip空间 【-w,w】
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
                //float3 textureColor = SAMPLE_TEXTURE2D(_DiffTexture,sampler_DiffTexture,uv0);

                //法线贴图(得到贴图中存储的切线空间下的法线信息)
                //float3 nDirTS = UnpackNormal( SAMPLE_TEXTURE2D(_normalMap,sampler_normalMap,i.uv0) );
                
                
                //----------------------------------------------------计算
                //-----------基础uv
                float2 noiseUV = PannerUV(posWS.xz,_SpeedNoiseScale, _SpeedNoiseX, _SpeedNoiseY);
                float2 noiseUV2 = PannerUV(posWS.xz,_SpeedNoiseScale * 0.5,_SpeedNoiseX, _SpeedNoiseY);
                float noiseTexture = SAMPLE_TEXTURE2D(_Noisexture,sampler_Noisexture, noiseUV).r;
                float noiseTexture2 = SAMPLE_TEXTURE2D(_Noisexture,sampler_Noisexture, noiseUV2).r;
                float noisemove = saturate( (noiseTexture + noiseTexture2 ) *0.5 );

                //----------基础流动和颜色    
                float2 uvMain = posWS.xz * _MainScale;
                uvMain += noisemove * _DistorStrength;
                uvMain += float2(_Time.x * _SpeedMainX, _Time.x * _SpeedMainY) + (vertexColor.r * _VertexDistorStrength);
                half4 col = SAMPLE_TEXTURE2D(_MainNoisexture,sampler_MainNoisexture, uvMain) * vertexColor.r;
                col+= noisemove ;
                float4 color = lerp(_Color , _Color2, col * _offset) * _Strength;

                
                //---------高亮边缘
                float edgeline =  1- GetDepthEdge(posScreen, _depthScale,i.posCS.w);
                float edge = smoothstep(1-col, (1-col) + _EdgeBlur, edgeline)  * vertexColor.r;

                
                //mask
                color = color * (1-edge);
                //加上颜色
                color +=(edge * _edgeColor) * _edgeColorStrength;
    
                //---------主要高亮
                float top = smoothstep(_Cutoff,_Cutoff+ _TopSmooth,col) * vertexColor.r;
                color *= (1-top);
                color += top * _TopColor * _TopColorStrength;
                
                float3 fragementOutColor = color.rgb ;    
                return float4(fragementOutColor,1);
                
            }
                
            ENDHLSL
        }


    }
    
    
    
}
