Shader "Unlit/hdr"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
       

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            #define TAU 6.28318530718
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
     
                return o;
            }

            float2 DirToRectilinear(float3 dir)
            {
                float x = atan2(dir.z,dir.x)/ TAU + 0.5;
                float y =dir.y * 0.5 + 0.5;
                return float2(x,y);
                
            }
            fixed3 frag (v2f i) : SV_Target
            {
                // sample the texture
                float3 col = tex2D(_MainTex, float4(DirToRectilinear(i.uv),0.0,0.0));
      
                return col;
            }
            ENDCG
        }
    }
}
