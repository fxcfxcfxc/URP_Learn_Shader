Shader "Unlit/NewUnlitShader"
{
    Properties
    {   
        [Header(_________________________________Texture)]
        _Stars("_StarsTexture",2D)="black"{}
        _BaseNoise("_BaseNoise",2D)="black"{}
        _Distort("_Distort",2D)="black"{}
        _SecNoise("_SecNoise",2D)="black"{}
        
        
        [Header(________________________________SunAndMoon)]
        _SunColor("SunColor",Color)= (1, 1, 1, 1)
        _MoonColor("_MoonColor",Color)=(1, 1, 1, 1)
        _SunRadius("_SunRadius",float)= 0.1
        _MoonRadius("_MoonRadius",float)= 0.1
        _MoonOffset("_MoonOffset",Range(0, 0.1))= 0.01

        
        
        [Header(________________________________DayMainColor)]
        _DayTopColor("_DayTopColor",Color)=(1, 1, 1, 1)
        _DayBottomColor("_DayBottomColor",Color)= (1, 1, 1, 1)
         _HorizonColorDay("_HorizonColorDay",Color)=(1, 1, 1, 1)
        
        [Header(________________________________NightMainColor)]
        _NightTopColor("_NighBottomColor",Color)= (1, 1, 1, 1)
        _NighBottomColor("_NightTopColor",Color) = (1, 1, 1, 1)
         _HorizonColorNight("_HorizonColorNight",Color)=(1, 1, 1, 1)
    

        
        [Header(________________________________Clouds)]    
        _scrollSpeed("scrollSpeed",float)=0.3
        _Scale("_Scale",float)=1.0
        _DistortScale("_DistortScale",float)=1.0
        _Distortion("_Distortion",float)=1.0
        _SecNoiseScale("_SecNoiseScale",float)=1.0
        _CloundCutoff("_CloundCutoff",float) = 0.5
        _Fuzziness("_Fuzziness",float)=0.2
        _CloudColorDayEdge("_CloudColorDayEdge",Color)=(1,1,1,1)
        _CloudColorDayMain("_CloudColorDayMain",Color)=(1,1,1,1)
        
        
    
        

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


            float _SunRadius, _MoonRadius,_MoonOffset,_scrollSpeed,_Scale, _DistortScale,_Distortion, _SecNoiseScale;
            float4 _DayBottomColor, _DayTopColor,_NighBottomColor,_NightTopColor, _HorizonColorDay;
            float _CloundCutoff, _Fuzziness;

            float4 _CloudColorDayEdge, _CloudColorDayMain, _SunColor, _MoonColor, _HorizonColorNight;
            
            sampler2D _SecNoise;
            sampler2D  _Stars;
            sampler2D _BaseNoise;
            sampler2D _Distort;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float3 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 WorldPos: TEXCOORD1;
            };

   
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.WorldPos =mul( unity_ObjectToWorld,v.vertex );
                o.uv = v.uv;
             
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
   

                //日月基础颜色
                float3 day = lerp(_DayBottomColor, _DayTopColor, saturate(i.uv.y));
                float3 night = lerp(_NighBottomColor, _NightTopColor, saturate(i.uv.y) );
                float3 skyBaseColor = lerp(night, day, saturate( _WorldSpaceLightPos0.y ) );

                //地平线     
                float edge = abs(i.uv.y);
                float4 horizonGlowDay = saturate (  (1 - edge * 3) * saturate( _WorldSpaceLightPos0.y * 10)) * _HorizonColorDay;
                float4 horizonGlowNight = saturate (  (1 - edge* 3) * saturate( -_WorldSpaceLightPos0.y * 10)) * _HorizonColorNight;
                float4 horizonGlow = horizonGlowDay +  horizonGlowNight;
               

                //添加星星
                float2 skyUV = i.WorldPos.xz / i.WorldPos.y;
                float3 stars = tex2D(_Stars, skyUV- (_Time.x * 0.2));
                stars *= 1 - saturate(_WorldSpaceLightPos0.y);

                //云层
                float baseNoise = tex2D(_BaseNoise, (skyUV -  _Time.x) * _Scale);
                float noise1 = tex2D(_Distort,( (skyUV + baseNoise)   - (_Time.x * _scrollSpeed) ) * _DistortScale);
                float noise2 = tex2D( _SecNoise, ((skyUV+(noise1 * _Distortion)) - (_Time.x * (_scrollSpeed * 0.5))) * _SecNoiseScale );
                float finalNoise = saturate(noise1 * noise2) *  3 * saturate(i.WorldPos.y);
                float clouds = saturate( smoothstep(_CloundCutoff,_CloundCutoff + _Fuzziness, finalNoise));
                float4 cloudsColored = lerp( _CloudColorDayEdge, _CloudColorDayMain, clouds) * clouds;
                float cloudsmask = (1 - clouds) * edge;


                //太阳
                float sun = distance(i.uv.xyz, _WorldSpaceLightPos0);
                float sunDisc = saturate( (1 - saturate(sun / _SunRadius) )  * 50  );


                //月亮
                float moon = distance(i.uv.xyz, -_WorldSpaceLightPos0);
                float moonDisc = saturate ( (1- (moon/ _MoonRadius)) * 50 );
                
                float crescentMoon = distance(float3(i.uv.x + _MoonOffset, i.uv.yz), - _WorldSpaceLightPos0);
                float crescentMoonDisc = saturate( (1- (crescentMoon / _MoonRadius)) * 50);
                moonDisc = saturate( moonDisc - crescentMoonDisc ) ;
                float4 moonAndSun =  (moonDisc  * _MoonColor  + sunDisc * _SunColor ) * cloudsmask;

               

                
                float3 outcolor = skyBaseColor +horizonGlow.rgb  + moonAndSun.rgb +stars + cloudsColored.rgb;
                //float3 outcolor = cloudsColored.rgb;
            
                
                
                return float4 (outcolor,1);
                
                
            }
            ENDCG
        }
    }
}
