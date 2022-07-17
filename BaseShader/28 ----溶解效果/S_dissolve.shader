Shader"Myshader/Dissolve"
{
    Properties
    {  
        _DiffTexture("固有色贴图",2d)="white"{}
        _NoiseTexture("消融形状贴图",2d)="white"{}
        _ClipThreshold("裁剪阈值",range(0,1.0))=0.5
        _EdgeWidth("溶解边缘",float)=0.1
        [HDR]_EdgeColor("边缘颜色",Color)=(1, 0.2, 0.2, 1.0)

        
        
    }
    SubShader
    {
        Tags
        {   
            //半透明设置
           "RenderType"="TransparentCutout"
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
        
            Name "qxty front"
            Tags
            {
                //渲染路径
               "LightMode" = "UniversalForward"
            }
            cull off
            //zwrite off
  
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            //------------------设置SRP Batch ,变量声明
            CBUFFER_START(UnityPerMaterial)

            uniform float3 _EdgeColor;
            uniform float _ClipThreshold,_EdgeWidth;
 
            CBUFFER_END

            //------------------纹理声明
            TEXTURE2D(_DiffTexture);
            SAMPLER(sampler_DiffTexture);
            
            TEXTURE2D(_NoiseTexture);
            SAMPLER(sampler_NoiseTexture);
            

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
                float2 screenUV : TEXCOORD1;
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
                float3 posVS = TransformWorldToView(posWS).xyz;
                float originDist = TransformWorldToView(TransformObjectToWorld(float3(0.0, 0.0, 0.0))).z;
                o.screenUV = posVS.xy/posVS.z;
                o.screenUV = o.screenUV * originDist;
                o.nDirWS = TransformObjectToWorldNormal(v.normal.xyz);
                float3 tDirWS = mul(unity_ObjectToWorld,float4(v.tangent.xyz,0.0).xyz);
                float3 bDirWS = normalize(cross(o.nDirWS,tDirWS) * v.tangent.w);

                o.TtoW0 = float4(tDirWS.x,bDirWS.x,o.nDirWS.x,posWS.x);
                o.TtoW1 = float4(tDirWS.y,bDirWS.y,o.nDirWS.y,posWS.y);
                o.TtoW2 = float4(tDirWS.z,bDirWS.z,o.nDirWS.z,posWS.z);
                
                o.uv0 = v.uv;
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
                float vDotn =pow(1.0 - dot(vDirWS,nDirWS),4);

                float3 diffTexColor = SAMPLE_TEXTURE2D(_DiffTexture,sampler_DiffTexture,i.uv0).rgb;
                float  noiseTexColor = SAMPLE_TEXTURE2D(_NoiseTexture,sampler_NoiseTexture,i.uv0).r;
         
                float  stepNoise = step(_ClipThreshold,noiseTexColor - _EdgeWidth);
                float3 edgeColor = (1.0-stepNoise) * _EdgeColor  +diffTexColor ;
                
                float  pixelAphla = 1.0;
                float3 pixelRGB = edgeColor;

                //clip《 0片元被踢除，》0保留
                clip(noiseTexColor - _ClipThreshold);
                return float4(pixelRGB,pixelAphla);
            }
                
            ENDHLSL
        }


    }
}
