Shader"Myshader/AttackRange"
{
    Properties
    {  
        _ShadowSTex ("Cookie", 2D) = "white" {}
		_MainColor ("ScanColor", Color) = (1,1,1,1)
		_Border ("Border", Range(0, 0.5)) = 0.2

		_ScanSpeed ("ScanSpeed", float) = 0.5
		_ScanSize ("ScanSize", Range(0, 0.5)) = 0.2
		_ScanInterval ("ScanInterval", float) = 3


        
    }
    SubShader
    {
        Tags
        {   
            
           "RenderType"="Transparent"
           "RenderPipeline"="UniversalPipeline"
        
        }
        LOD 100
        
        
        //------------------------------------多pass公用输入数据------------
        HLSLINCLUDE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
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
        
            Name "attackRange"
            Tags
            {
                //渲染路径
               "LightMode" = "UniversalForward"
            }
            ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Offset -1, -1
  
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            //------------------设置SRP Batch ,变量声明
            CBUFFER_START(UnityPerMaterial)
            float4x4 unity_Projector;

            float4 _MainColor;
			float _Border;
			float _ScanSize;
			float _ScanSpeed;
			float _ScanInterval;
 
            CBUFFER_END

            //------------------纹理声明
            TEXTURE2D(_ShadowSTex);
            SAMPLER(sampler_ShadowSTex);

            

            /*
            封装函数格式参考
            // funcion：按照法线方向 偏移 Tangent 方向
            float3 ShiftTangent(float3 T,float3 N,float3 shift)
            {
                return normalize(T + shift *N);
                
            }
            */

            //-------------------------------顶点——》片段--------------
            struct v2f
            {
                float4 pos : SV_POSITION;
				float4 uvShadow : TEXCOORD1;
       
            };
            
            //-------------------------------顶点着色器-----------
            v2f vert (Attributes v)
            {
                
                v2f o;
                
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.uvShadow = ComputeScreenPos(v.vertex);

                return o;
            }

            float Rectangle(float2 samplePos, float2 halfSize)
            {
	            float2 edgeDistance = abs(samplePos) - halfSize;
	            float2 outsideDistance = length(max(0, edgeDistance));
	            float2 insideDistance = min(0, max(edgeDistance.x, edgeDistance.y));
				float2 softRect = outsideDistance + insideDistance;
				float change = fwidth(softRect) * 0.5;
                float hardRect = smoothstep(-change, change, softRect);
                return hardRect;
            }


            

            //------------------------------片段着色器--------------
            half4 frag (v2f i) : SV_Target
            {
                //投影
            	float fullMask = SAMPLE_TEXTURE2D(_ShadowSTex, sampler_ShadowSTex, i.uvShadow.xyz/i.uvShadow.w).r;
				//float fullMask = tex2Dproj (_ShadowTex, UNITY_PROJ_COORD(i.uvShadow)).a;
            	//tex2Dproj将输入的UV xy坐标除以其w坐标
				//去除边缘拉伸
				const float BORDER = 0.001;
				if (i.uvShadow.x / i.uvShadow.w < BORDER
				|| i.uvShadow.x / i.uvShadow.w > 1 - BORDER  
				|| i.uvShadow.y / i.uvShadow.w < BORDER
				|| i.uvShadow.y / i.uvShadow.w > 1 - BORDER)
                {
                    fullMask = 0;
                }

				float2 uv = i.uvShadow - 0.5f;
				float len = length(uv);
				//正方形
				float borderRect = saturate(Rectangle(uv, 0.5 - _Border));
				//正方形波
				float dis = (abs(uv.x) + abs(uv.y)) + _Time.y * _ScanSpeed;
				dis *= _ScanInterval;
				dis = dis - floor(dis);
				float rectWave1 = Rectangle(uv, dis);
				float rectWave2 = Rectangle(uv, dis + _ScanSize);
				float rectWave = saturate(rectWave1 - rectWave2);

				float alpha = (borderRect + rectWave) * fullMask;

				return float4(_MainColor.rgb, alpha);

            }
                
            ENDHLSL
        }


    }
}
