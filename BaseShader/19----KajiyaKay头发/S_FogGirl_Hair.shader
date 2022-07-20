Shader "NPR/Hair"
{
	Properties
	{
		[Header(MainTex)]
		_MainColor("Main Color", Color) = (1,1,1,1)
		_MainTex("Diffuse (RGB) Alpha (A)", 2D) = "white" {}

		[Space(10)][Header(Shadow)]
		_LightMap("通道遮罩（G阴影B高光）",2D) = "white"{}
		_DarkAlpha("暗部阴影透明度", Range(0,1)) = 0.8
		_CharaSkinDark("SkinDarkness", color) = (0.9568, 0.7738, 0.7372, 1)

		[Space(10)][Header(Rim)]
		[HDR]_RimShieldColor("边缘光颜色", color) = (0.5656,1.3421,2.1185,0)
		_RimPower("边缘光范围", Range(0,50)) = 1
		//_SSSValue("次表变散射", Range(0,2)) = 0

		[Space(10)][Header(Outline)]
		_OutLine("Outline Width", Range(0,10)) = 0.5

		[Space(10)][Header(Anisotropy)]
		//_NormalTex ("Normal Map", 2D) = "Black" {}
		//_NormalScale("Normal Scale", Range(0, 10)) = 1
		_SpecMask("高光遮罩系数", Range(0, 1)) = 0.45
		_Specular("Specular Amount", Range(0, 5)) = 1.0
		_SpecularColor("Specular Color1", Color) = (1,1,1,1)
		_SpecularColor2("Specular Color2", Color) = (0.5,0.5,0.5,1)
		_SpecularMultiplier("Specular Power1", float) = 100.0
		_SpecularMultiplier2("Secondary Specular Power", float) = 100.0

		_PrimaryShift("Specular Primary Shift", float) = 0.0
		_SecondaryShift("Specular Secondary Shift", float) = .7
		_AnisoDir("SpecShift(G),Spec Mask (B)", 2D) = "white" {}
		_TangentValue("Tangent Value", Range(0, 10)) = 1

		[Space(10)][Header(CutOff)]
		_Cutoff("Alpha Cut-Off Threshold", float) = 0
		[Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", Float) = 2
	}

	SubShader
	{
		//在半透明之前渲染
		Tags {"Queue" = "Geometry" "IgnoreProjector" = "True" }

		CGINCLUDE
		#include "Lighting.cginc"
		#include "UnityCG.cginc"
		ENDCG


		Pass
		{
			Cull Front
			Lighting Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest

			

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				half4 color : COLOR;
				float2	uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				half4 color : COLOR;
				float2	uv : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};

			half4 _Color;

			//half4 _CharaLight;
			//half4 _CharaSkinDark;
			//half4 _CharaDark;
			half4 _Color2;
			half _LmcSwitch;
			float _OutLine;
			v2f vert(appdata v)
			{
				v2f o;
				float4 pos;

				pos.xyz = UnityObjectToViewPos(v.vertex);
				pos.w = 1;
				float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
				normal.z -= 0.1;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				float dis = pow(-mul(UNITY_MATRIX_MV._m20_m21_m22_m23, v.vertex), 0.75);
				o.color = v.color;
				//_OutlineWidth = 0.05;
				float lineWidth = lerp(0.00, 0.0026, v.color.b) * dis * _OutLine; //(1 - _LmcSwitch * 0.5);
				o.vertex = pos + float4(normalize(normal),0) * lineWidth;
				o.vertex = mul(UNITY_MATRIX_P, o.vertex);
				o.uv = v.uv;
				return o;
			}

			//UNITY_DECLARE_TEX2D(_MainTex);
			sampler2D _MainTex;

			fixed _DisPercentage;
			half4 _RimShieldColor;
			half4 _DisColor;

			//UNITY_DECLARE_TEX2D(_LightModel);
			sampler2D _LightModel;
			//UNITY_DECLARE_TEX2D_NOSAMPLER(_LmColor);
			sampler2D _LmColor;
			half _DisScale;
			float4 _PlanEuqa;


			//half _CardinalValue;
			float3 _LmCamPos;
			//half _NoLightmap;
			half _SunOutDoor;
			float _LmScale;

			float4 _RimShieldColor2;

			inline half lum(half3 c)
			{
				return dot(c, half3(0.22, 0.707, 0.071));
			}

			half4 frag(v2f i) : SV_Target
			{

				half4 diffuseMapColor = 1;
				//half4 hairColor = UNITY_SAMPLE_TEX2D(_MainTex, i.uv);
				half4 hairColor = tex2D(_MainTex, i.uv);
				//_Color = lerp(lerp(_Color2, _Color, hairColor.b), hairColor, hairColor.a);

				//diffuseMapColor.rgb *= lerp(fixed3(1,0.75,0.75) * 1.2, 1, diffuseMapColor.a);
				diffuseMapColor.rgb *= fixed3(1,0.75,0.75) * 1.5;
				//float2 lmUv = (i.worldPos.xz - _LmCamPos.xz) / _LmScale + 0.5;

				//half lmsTex = UNITY_SAMPLE_TEX2D_SAMPLER(_LmColor, _LightModel, lmUv).a;
				//half lmsTex = tex2D(_LmColor, lmUv).a;

				half4 lineColor = diffuseMapColor;
				float lumC = lum(lineColor.rgb);
				lineColor.rgb = (lineColor.rgb * 0.7 + lumC * 0.3) * (1 - lumC * 0.2);
				lineColor.rgb *= lerp(lumC, lineColor.rgb, 1.5) * (lerp(0.8, 0.4, lumC) * lerp(unity_AmbientSky * 0.5 + 0.5, 1, 1)); //* _CharaLight.rgb;
				lineColor.a = 1;
				//lineColor.rgb += _RimShieldColor.rgb * _RimShieldColor.a;

				return  lineColor;
			}
			ENDCG
		}
		//Pass
		//{
			//	ZWrite On //写入深度，被遮挡的像素在下个Pass将不能通过深度测试
			//	ColorMask 0 //不输出颜色
		//}


		Pass
		{
			//Tags { "LightMode" = "ForwardBase" }
			ZWrite On
			Cull[_Cull]
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma target 3.0

			sampler2D _MainTex, _AnisoDir;// ,_NormalTex;
			float4 _MainTex_ST, _AnisoDir_ST;// , _NormalTex_ST;

			half _SpecularMultiplier, _PrimaryShift,_Specular,_SecondaryShift,_SpecularMultiplier2;
			half4 _SpecularColor, _MainColor,_SpecularColor2;

			half _Cutoff;
			half _NormalScale;
			sampler2D _LightMap;
			half3 _LightmapColor;
			half _LightmapForce;
			float4 _LightMap_ST;
			half4 _CharaSkinDark;
			float _DarkAlpha;
			half _RimPower;
			half _SSSValue;
			half4 _RimShieldColor;
			half _SpecMask;
			half _TangentValue;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				float4 TtoW0 : TEXCOORD1;
				float4 TtoW1 : TEXCOORD2;
				float4 TtoW2 : TEXCOORD3;
				float3 worldNormal : TEXCOORD4;
				float4 vertex : SV_POSITION;
			};

			//获取头发高光
			fixed StrandSpecular(fixed3 T, fixed3 V, fixed3 L, fixed exponent)
			{
				fixed3 H = normalize(L + V);
				fixed dotTH = dot(T, H);
				fixed sinTH = sqrt(1 - dotTH * dotTH);
				fixed dirAtten = smoothstep(-1, 0, dotTH);
				return dirAtten * pow(sinTH, exponent) * _TangentValue;
			}

			//沿着法线方向调整Tangent方向
			fixed3 ShiftTangent(fixed3 T, fixed3 N, fixed shift)
			{
				return normalize(T + shift * N  );
			}

			v2f vert(appdata_full v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				//o.uv.zw = TRANSFORM_TEX(v.texcoord, _NormalTex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);

				fixed3 worldBinormal = cross(o.worldNormal, worldTangent) * v.tangent.w;

				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, o.worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, o.worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, o.worldNormal.z, worldPos.z);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 albedo = tex2D(_MainTex, i.uv);
				half3 diffuseColor = albedo.rgb * _MainColor.rgb;

				half4 cm = tex2D(_LightMap, i.uv.xy);

				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 worldTangent = normalize(half3(i.TtoW0.x, i.TtoW1.x, i.TtoW2.x)) ;

				//fixed3 worldTangent = SphereTangent(worldPos, i.worldNormal);
				fixed3 worldBinormal = normalize(half3(i.TtoW0.y, i.TtoW1.y, i.TtoW2.y));



				//fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				float3 viewVec = _WorldSpaceCameraPos.xyz - worldPos;
				float3 worldViewDir = normalize(viewVec);

				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);  //worldPos

				float nl = saturate(dot(i.worldNormal, worldLightDir));
				float nv = max(0, dot(i.worldNormal , worldViewDir));
				half3 H = normalize(worldLightDir + worldViewDir);

				float shadowedLight = lerp(-0.8, 1, nl * cm.g * 2);

				float whiteDiff = pow(saturate(shadowedLight),0.25);

				fixed3 rim = _RimShieldColor.rgb * _RimShieldColor.a * pow(1 - nv, _RimPower);

				float halfLambert = 0.5*nl + 0.5;

				fixed3 spec = tex2D(_AnisoDir, i.uv).rgb;

				//计算切线方向的偏移度
				half shiftTex = spec.g;
				half3 t1 = ShiftTangent(worldBinormal, i.worldNormal, _PrimaryShift + shiftTex);
				half3 t2 = ShiftTangent(worldBinormal, i.worldNormal, _SecondaryShift + shiftTex);



				//计算高光强度
				half3 spec1 = StrandSpecular(t1, worldViewDir, worldLightDir, _SpecularMultiplier) * _SpecularColor;
				half3 spec2 = StrandSpecular(t2, worldViewDir, worldLightDir, _SpecularMultiplier2) * _SpecularColor2;


				fixed4 finalColor = 0;

				//高光遮罩
				spec1 *= cm.b * nl * step(_SpecMask, nl);
				spec2 *= cm.b * nl * step(_SpecMask, nl);
				
				diffuseColor = lerp(diffuseColor,  _CharaSkinDark, (1 - whiteDiff) * _DarkAlpha);
				

				//spec1 = lerp(0, spec1 + spec2, 0.1);
				//spec1 = pow(spec1, 2.0) * 2;

				finalColor.rgb = diffuseColor + spec1 * _Specular;//第一层高光
				finalColor.rgb += spec2 * _SpecularColor2  * _Specular * spec.b;//第二层高光，spec.b用于添加噪点 去掉cm.b
				finalColor.rgb += rim;//_LightColor0.rgb + rim;//受灯光影响


				finalColor.a = albedo.a;

				return finalColor;
			};
			ENDCG
		}
	}

	FallBack off
}