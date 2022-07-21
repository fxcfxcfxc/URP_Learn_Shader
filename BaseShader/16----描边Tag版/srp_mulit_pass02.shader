                                                              Shader"Myshader/srp_mulit_pass"
{
    Properties
    {   
       _BaseColor("Base Color",Color)=(1,1,1,1)
       _outlineCol("描边颜色",color)=(1.0,0.0,0.0,1.0)
       _outlineWidth("描边宽度",float)=1.0
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
            #pragma multi_compile_fog
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            
            uniform half4  _BaseColor;

            struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 posCS : SV_POSITION;
                float2 uv0 : TEXCOORD0;
            };


            v2f vert (Attributes v)
            {
                v2f o;
                o.posCS = TransformObjectToHClip(v.vertex.xyz);
                o.uv0 = v.uv;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                return _BaseColor;
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
            uniform float4 _outlineCol;
            uniform float  _outlineWidth;
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            
             struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                 float4 uv2 : TEXCOORD1;
                 float4 uv3 : TEXCOORD2;
                float3 normal :NORMAL;
                 float4 tangent: TANGENT;
                float4 color : COLOR;
                
            };

            struct v2f
            {   
                float4 posCS : SV_POSITION;
                float2 uv0 : TEXCOORD0;
           
            };
            
            
            
            v2f vert_outline (Attributes v)
            {
                v2f o;
                //==========================================平均法线存储方案============================
                //------方案一： 平均过的法线存储到UV
                //v.normal  = float3(-v.uv2.x,  v.uv2.y,  v.uv3.x);//取反x？

                //-------方案二：平均过的法线存储到切线
                // v.normal = v.tangent; // 记得物体导入中设置 : 切线来自 自定义导入

                //-------方案三 ： 存储到uv2.xy color。x
                //v.color.x = ( v.color.x * (0.57735+0.57735) ) -0.57735; //由于color会clamp到0，1 在外面提前映射到0，1 在 映射回来
                //v.normal = float3(-v.uv2.x, v.uv2.y, v.color.x);
         
                //==========================方案一 ：在物体空间的法线外扩==================================
                //v.vertex.xyz = v.vertex.xyz  + _outlineWidth * normalize(v.normal);
                //o.posCS = TransformObjectToHClip(v.vertex.xyz);//顶点转化到裁剪空间
    
                
                //===========================方案二：在观察空间法线外扩================================
                //float3 posVS = TransformWorldToView( TransformObjectToWorld(v.vertex.xyz) );
                //float3 nDirVS =  TransformWorldToViewDir( TransformObjectToWorldNormal(v.normal) );
                //posVS  = posVS  + _outlineWidth * nDirVS;
                //o.posCS = TransformWViewToHClip(posVS);
                
            
                //============================方案三：NDC空间法线外扩================================
                o.posCS = TransformObjectToHClip(v.vertex.xyz);
                
                float3 nDirWS = TransformObjectToWorldNormal(v.normal.xyz);
                float3 nDirClip = TransformWorldToHClipDir(nDirWS,true);//世界空间-》观察空间-》裁剪空间
                float3 nDirNDC =  nDirClip * o.posCS.w; //齐次裁剪空间 ->NDC
                

                //---修复ndc转到屏幕空间时，因为屏幕比列带来的顶点压缩变化，不一致  就会导致描边宽度不一致
                //将NDC右上角位置的顶点变换到观察空间
                float4 nearUpperRight = mul(unity_CameraInvProjection, float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));
                //求得屏幕宽高的比例值
                float aspect = abs(nearUpperRight.y / nearUpperRight.x);
                nDirNDC.x =nDirNDC.x * aspect;
                
                //顶点扩张
                o.posCS.xy = o.posCS.xy + nDirNDC.xy * _outlineWidth * 0.1;
            

                
                //==================================
                o.uv0 = v.uv;
                return o;
            }

            half4 frag_outline (v2f i) : SV_Target
            {
                return _outlineCol;
            }
        
            ENDHLSL
        }
    }
}
