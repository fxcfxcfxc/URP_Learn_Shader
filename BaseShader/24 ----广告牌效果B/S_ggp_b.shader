Shader"Myshader/GGP_b"
{
    Properties
    {   
        _MainTexture("海报贴图",2d)="white"{}
        _MaskTexture("数据图RGBA",2d)="white"{}
        _ColX("列",int)=3
        _RowY("行",int)=1
        _TotalIndex("总索引",int)=4
        _TimeSpeed("动画速度",float)=0.5
        _LedGridStrength("Led灯强度",float)=1.0
        _GloableStrength("全局灯光",float)=1.0
                
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
        
            Name "GGP_b"
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

            uniform int _ColX,_RowY,_TotalIndex;
            uniform float _TimeSpeed,_LedGridStrength,_GloableStrength;

            
            CBUFFER_END

            //------------------纹理声明
            TEXTURE2D(_MainTexture);
            SAMPLER(sampler_MainTexture);

            TEXTURE2D(_MaskTexture);
            SAMPLER(sampler_MaskTexture);
            



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

                //每个轴向偏移的单位距离
                float offsetX = 1.0 / _ColX;
                float offsetY = 1.0 / _RowY;

                //速度
                float timeSpeed = _Time.y * _TimeSpeed;

                //offsetX随着时间 偏移距离增加  速度*时间
                float offsetXCount =  round(fmod(timeSpeed,_TotalIndex));
                float offsetXCount2 =  round(fmod(offsetXCount,_TotalIndex));
                
                float offsetXCount3 = offsetXCount2 * offsetX;

                //offsetY时间偏移次数距离
                float offsetYCount =offsetY -  round(fmod(offsetXCount  - offsetXCount2,offsetY));
                float offsetYCount3 = offsetYCount * offsetY;
    
                //offset 随时间UV的偏移
                float2 offsetUV = float2(offsetXCount3,offsetYCount3);

                //计算最终UV
                float2 finalUV = float2(offsetX,offsetY) * i.uv0 + offsetUV;

                float2 maskTexUV = float2(i.uv0.x *0.06,i.uv0.y) + float2(0.25,0) * timeSpeed;
                float maskTexColG = SAMPLE_TEXTURE2D(_MaskTexture,sampler_MaskTexture,maskTexUV).g;

                //混合撕裂翻页效果
                float3 mainTexCol = SAMPLE_TEXTURE2D(_MainTexture,sampler_MainTexture,finalUV + maskTexColG);

                //混合网格效果
                float2 maskTexUVR  = float2(i.uv0.x * 0.5,i.uv0.y) * 2;
                float maskTexColR = SAMPLE_TEXTURE2D(_MaskTexture,sampler_MaskTexture,maskTexUVR).r * _LedGridStrength;

                float3 pixelColor = (mainTexCol + maskTexColR) * _GloableStrength;
         
                return float4(pixelColor, 1);
            }
                
            ENDHLSL
        }
        
 
   
    }
}
