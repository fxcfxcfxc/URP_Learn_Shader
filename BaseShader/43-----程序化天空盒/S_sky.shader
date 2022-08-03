Shader "Unlit/NewUnlitShader"
{
    Properties
    {
        _SunRadius("_SunRadius",float)= 0.1
        _MoonRadius("_MoonRadius",float)= 0.1
        _MoonOffset("_MoonOffset",Range(0, 0.1))= 0.01
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


            float _SunRadius, _MoonRadius,_MoonOffset;
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

   
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
             
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float sun = distance(i.uv.xyz, _WorldSpaceLightPos0);
                float sunDisc = saturate( (1 - saturate(sun / _SunRadius) )  * 50  );
        
                float moon = distance(i.uv.xyz, -_WorldSpaceLightPos0);
                float moonDisc = saturate ( (1- (moon/ _MoonRadius)) * 50 );
                
                float crescentMoon = distance(float3(i.uv.x + _MoonOffset, i.uv.yz), - _WorldSpaceLightPos0);
                float crescentMoonDisc = saturate( (1- (crescentMoon / _MoonRadius)) * 50);
                moonDisc = saturate( moonDisc - crescentMoonDisc ) ;


                float3 outcolor = moonDisc + sunDisc;
                return float4 (outcolor,1);
            }
            ENDCG
        }
    }
}
