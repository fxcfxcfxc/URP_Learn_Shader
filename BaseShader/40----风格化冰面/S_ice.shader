Shader"Myshader/M_ice"
{
    Properties
    {  
        _DiffTexture("DiffTexture",2D)="black"{}
        //_testrange("testrange",Range(0,10))=1
        _normalMap("normalMap",2D)="bump"{}
        
        
        _SpecularSmooth("_SpecularSmooth",float)=200
        [HDR]_SpecularColor("_SpecularColor",Color)=(1,1,1,1)
        
        _Samples("_Samples",int)=8
        _LODNum("_LODNum",int)=1
        _Offset("_Offset",Range(-0.1,0.1))=0.01
        _lerp("lerp",Range(0, 1.0)) =0.8
        _ColorMul("_ColorMul",Range(0,10))=1.0
        
    }
    SubShader
    {   
        
        //==================== Sub tag设置======================================
        Tags
        {   
            
           "RenderType"="Transparent"
           "RenderPipeline"="UniversalPipeline"
           "Queue"="Transparent"
        
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
            cull off
            zwrite off
            blend One OneMinusSrcAlpha
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            //---------------------设置SRP Batch ,变量声明
            CBUFFER_START(UnityPerMaterial)
            uniform float _testrange,_SpecularSmooth , _Offset, _lerp, _ColorMul;
            int _Samples,_LODNum;
            float4 _SpecularColor;
            CBUFFER_END

            //---------------------纹理声明
            TEXTURE2D(_DiffTexture);
            SAMPLER(sampler_DiffTexture);

            TEXTURE2D(_normalMap);
            SAMPLER(sampler_normalMap);


            
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
                float2 posCS = i.posCS.xy / _ScreenParams.xy;
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
                float3 nDirTS = UnpackNormal( SAMPLE_TEXTURE2D(_normalMap,sampler_normalMap,uv0) );
                float3x3 TBN = float3x3(tDirWS, biDirWS, nDirWS);
                nDirWS = normalize( mul(nDirTS , TBN) );
                
                //----------------------------------------------------计算

                //镜面反射
                float3 hDirWS = normalize(lDirWS+ vDirWS);
                float3 blinnPhone =pow( max(0, dot(nDirWS,hDirWS) ),_SpecularSmooth) *_SpecularColor;

                //
                float4 color =0;
                float u_offset = 0;
                float v_offset = 0;
          
                for(int s = 0; s < _Samples; s++)
                {
                    float2 uvoff = float2(u_offset,v_offset);
                    color += SAMPLE_TEXTURE2D_LOD(_DiffTexture,sampler_DiffTexture,uv0+ uvoff,_LODNum);
                    u_offset +=_Offset * ( GetCameraPositionWS().x - i.posWS.x);
                    v_offset +=_Offset * ( GetCameraPositionWS().z - i.posWS.z);
                }

                
                float4 render =   ( color /= _Samples );
                
                float3 fragementOutColor = render.rgb  +  blinnPhone ;
                fragementOutColor = lerp(SAMPLE_TEXTURE2D(_DiffTexture,sampler_DiffTexture,uv0) ,fragementOutColor,_lerp) * _ColorMul;
                return float4(fragementOutColor * vertexColor.r,vertexColor.r);
            }
                
            ENDHLSL
        }


    }
    
    
    
}
