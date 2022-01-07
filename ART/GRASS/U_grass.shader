Shader"Myshader/Grass"
{
    Properties
    {   
       _BaseColor("Base Color",Color)=(1,1,1,1)
       _speed("速度",float)=1.0
       _range("范围",float)=1.0
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
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            
            uniform half4  _BaseColor;
            uniform float _speed;
            uniform float _range;
            struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 col:COLOR;
                
            };

            struct v2f
            {
                float2 uv0 : TEXCOORD0;
                float4 posCS : SV_POSITION;
                float3 posWS : TEXCOORD1;
                float4 vertexcolor:Color;

            };


            v2f vert (Attributes v)
            {
                v2f o;
                o.vertexcolor = v.col;
                o.posWS = TransformObjectToWorld(v.vertex.xyz);
                v.vertex.x = v.vertex.x + sin(o.posWS.y + _Time.z * _speed) * v.col.r * _range;
                o.posCS = TransformObjectToHClip(v.vertex.xyz);
                o.uv0 = v.uv;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                return _BaseColor * i.vertexcolor.r;
            }
            ENDHLSL
        }
    }
}
