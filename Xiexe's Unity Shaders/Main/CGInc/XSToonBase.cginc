		#include "UnityStandardBRDF.cginc"
		#include "UnityPBSLighting.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#if defined(XS_SHADOWCASTER_PASS) || defined(XS_OUTLINE_PASS)
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) fixed3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif

		struct Input
		{
			float2 uv_texcoord;
			float3 worldNormal;
			float3 worldRefl;
			float3 viewDir;
			float2 uv2_texcoord2;
			float3 worldPos;
			float4 screenPos;
			float3 tangentDir;
			INTERNAL_DATA
		};

		struct SurfaceOutputCustomLightingCustom
		{
			fixed3 Albedo;
			fixed3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			fixed Alpha;
			fixed3 Tangent;
			Input SurfInput;
			UnityGIInput GIData;
		};

		UNITY_DECLARE_TEX2D(_MainTex);
		UNITY_DECLARE_TEX2D_NOSAMPLER(_EmissiveTex);
		UNITY_DECLARE_TEX2D_NOSAMPLER(_Normal);
		UNITY_DECLARE_TEX2D_NOSAMPLER(_DetailNormal);
		UNITY_DECLARE_TEX2D_NOSAMPLER(_DetailMask);
		UNITY_DECLARE_TEX2D_NOSAMPLER(_SpecularMap);
		UNITY_DECLARE_TEX2D_NOSAMPLER(_SpecularPattern);
		UNITY_DECLARE_TEX2D_NOSAMPLER(_RoughMap);
		UNITY_DECLARE_TEX2D_NOSAMPLER(_OcclusionMap);
		UNITY_DECLARE_TEX2D_NOSAMPLER(_ThicknessMap);

		sampler2D _MetallicMap;
		sampler2D _ShadowRamp;
		samplerCUBE _BakedCube;
		float4 _MainTex_ST;
		float4 _EmissiveTex_ST;
		float4 _ShadowRamp_ST;
		float4 _Normal_ST;
		float4 _DetailNormal_ST;
		float4 _SpecularMap_ST;
		float4 _SpecularPattern_ST;
		float4 _MetallicMap_ST;
		float4 _RoughMap_ST;
		float4 _BakedCube_ST;

		float4 _EmissiveColor;
		float4 _SimulatedLightDirection;
	 	float4 _Color;
		float4 _OcclusionColor;
		float3 _RimColor;
		float3 _SSSCol;
		float2 _NormalTiling;
		float2 _SpecularPatternTiling;
		float _EmissiveStrength;
		float _UseUV2forNormalsSpecular;
		float _RimWidth;
		float _RimIntensity;
		float _SpecularIntensity;
		float _SpecularArea;
		float _Cutoff;
		float _RimlightType;
		float _RampDir;
	 	float _ShadowIntensity;
		float _DitherScale;
		float _ColorBanding;
	 	float _ReflSmoothness;
	 	float _Metallic;
		float _UseReflections;
		float _UseOnlyBakedCube;
		float _ShadowType;
		float _ReflType;
		float _StylelizedIntensity;
		float _Saturation;
		float _MatcapStyle;
		float _RampColor;
		float _SolidRimColor;
		float _anistropicAX;
		float _anistropicAY;
		float _SpecularStyle;
		float _NormalStrength;
		float _DetailNormalStrength;
		float _OcclusionStrength;
		float _SSSDist;
		float _SSSPow;
		float _SSSIntensity;
		float _invertThickness;
		float _ThicknessMapPower;
		float _RampBaseAnchor;
		float _ScaleWithLight;
		float _EmissTintToColor;
		float _EmissionPower;

		int _EmissUv2;
		int _DetailNormalUv2;
		int _NormalUv2;
		int _MetallicUv2;
		int _SpecularUv2;
		int _SpecularPatternUv2;
		int _AOUV2;

		int _ANISTROPIC_ON;
		int _PBRREFL_ON;
		int _MATCAP_ON;
		int _MATCAP_CUBEMAP_ON;
		int _WORLDSHADOWCOLOR_ON;
		int _MIXEDSHADOWCOLOR_ON;
		int _AORAMPMODE_ON;

	//Custom Helper Functions		
		float2 matcapSample(float3 worldUp, float3 viewDirection, float3 normalDirection)
		{
			half3 worldViewUp = normalize(worldUp - viewDirection * dot(viewDirection, worldUp));
			half3 worldViewRight = normalize(cross(viewDirection, worldViewUp));
			half2 matcapUV = half2(dot(worldViewRight, normalDirection), dot(worldViewUp, normalDirection)) * 0.5 + 0.5;
			return matcapUV;				
		}

		float3 StereoWorldViewDir( float3 worldPos )
		{
			#if UNITY_SINGLE_PASS_STEREO
			float3 cameraPos = float3((unity_StereoWorldSpaceCameraPos[0]+ unity_StereoWorldSpaceCameraPos[1])*.5); 
			#else
			float3 cameraPos = _WorldSpaceCameraPos;
			#endif
			float3 worldViewDir = normalize((cameraPos - worldPos));
			return worldViewDir;
		}

		inline float Dither8x8Bayer( int x, int y )
		{
			const float dither[ 64 ] = {
				 1, 49, 13, 61,  4, 52, 16, 64,
				33, 17, 45, 29, 36, 20, 48, 32,
				 9, 57,  5, 53, 12, 60,  8, 56,
				41, 25, 37, 21, 44, 28, 40, 24,
				 3, 51, 15, 63,  2, 50, 14, 62,
				35, 19, 47, 31, 34, 18, 46, 30,
				11, 59,  7, 55, 10, 58,  6, 54,
				43, 27, 39, 23, 42, 26, 38, 22};
			int r = y * 8 + x;
			return dither[r] / 64;
		}

		//rgbtoHSV
		float3 rgb2hsv(float3 c)
		{
			float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
			float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
			float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

			float d = q.x - min(q.w, q.y);
			float e = 1.0e-10;
			return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
		}

		// From HDRenderPipeline
		float D_GGXAnisotropic(float TdotH, float BdotH, float NdotH, float roughnessT, float roughnessB)
		{
			float f = TdotH * TdotH / (roughnessT * roughnessT) + BdotH * BdotH / (roughnessB * roughnessB) + NdotH * NdotH;
			return 1.0 / (roughnessT * roughnessB * f * f);
		}

	//-----

		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
		//init atten, gi, and col
				UnityGIInput data = s.GIData;
				Input i = s.SurfInput;
				half4 c = 0;
				#if DIRECTIONAL
					float steppedAtten = round(data.atten);
					float attenuation = lerp(steppedAtten, data.atten, _ShadowType);
					//This is needed to make sure we don't see the cookie box for lightatten.
					attenuation = lerp(0, attenuation, _LightColor0.a);
				#else
					float3 attenuationRGB = gi.light.color / ( ( _LightColor0.rgb ) + 0.000001 );
					float attenuation = max( max( attenuationRGB.r, attenuationRGB.g ), attenuationRGB.b );
				#endif
		//-----

		//Set up UVs
				float2 texcoord1 = i.uv_texcoord;
				float2 texcoord2 = i.uv2_texcoord2;

				float2 UVSetEmission = lerp(texcoord1, texcoord2, _EmissUv2);
				float2 UVSetNormal = lerp(texcoord1, texcoord2, _NormalUv2);
				float2 UVSetDetailNormal = lerp(texcoord1, texcoord2, _DetailNormalUv2);
				float2 UVSetMetallic = lerp(texcoord1, texcoord2, _MetallicUv2);
				float2 UVSetSpecular = lerp(texcoord1, texcoord2, _SpecularUv2);
				float2 UVSetSpecularPattern = lerp(texcoord1, texcoord2, _SpecularPatternUv2);
				float2 UVSetAO = lerp(texcoord1, texcoord2, _AOUV2);

				float2 uv_MainTex = i.uv_texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
				float2 uv_Normal = UVSetNormal * _Normal_ST.xy + _Normal_ST.zw;
				float2 uv_DetailNormal = UVSetDetailNormal * _DetailNormal_ST.xy + _DetailNormal_ST.zw;
				float2 uv_Specular = UVSetSpecular * _SpecularMap_ST.xy + _SpecularMap_ST.zw;
				float2 uv_SpecularPattern = UVSetSpecularPattern * _SpecularPattern_ST.xy + _SpecularPattern_ST.zw;
				float2 uv_MetallicRough = UVSetMetallic * _MetallicMap_ST.xy + _MetallicMap_ST.zw;
		//-----

		//Set up Normals, viewDir, tanget, binorm
				float3 normalMap = UnpackNormal(UNITY_SAMPLE_TEX2D_SAMPLER(_Normal, _MainTex, uv_Normal));
					normalMap.xy *= _NormalStrength;
				float3 detailMask = UNITY_SAMPLE_TEX2D_SAMPLER(_DetailMask, _MainTex, i.uv_texcoord);
				float3 detailNormal = UnpackNormal(UNITY_SAMPLE_TEX2D_SAMPLER(_DetailNormal, _MainTex, uv_DetailNormal));
					detailNormal.xy *= _DetailNormalStrength * detailMask.r;
			//Partial Derivative blending
				float3 normal = normalize(float3(normalMap.xy*detailNormal.z + detailNormal.xy*normalMap.z, normalMap.z*detailNormal.z));
				
				float4 worldNormal = normalize(lerp(float4(WorldNormalVector(i, normal), 0), float4(WorldNormalVector(i, float3(0, 0, 1)), 0), 0.3));
				float3 tangent = i.tangentDir;
				half3 binorm = cross(worldNormal, tangent);
				float3 stereoWorldViewDir = StereoWorldViewDir(i.worldPos);
		//-----	

		//Setup Direct and Indirect Light
				//We're sampling ShadeSH9 at 0,0,0 to just get the color.
				half3 indirectColor = ShadeSH9(float4(0,0,0,1));
				float3 lightColor = _LightColor0; 


				//figure out whether we are in a realtime lighting scnario, or baked, and return it as a 0, or 1 (1 for realtime, 0 for baked)
				float light_Env = float(any(_WorldSpaceLightPos0.xyz));

				//default to realtime, and switch to baked direction if needed
				//we also have a super fallback in case of no direction.
				float3 light_Dir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				if( light_Env != 1)
				{
					//A way to get dominant light direction from Unity's Spherical Harmonics.
					light_Dir = normalize(unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz);
					
					//  #if !defined(POINT) && !defined(SPOT)
						if(length(unity_SHAr.xyz*unity_SHAr.w + unity_SHAg.xyz*unity_SHAg.w + unity_SHAb.xyz*unity_SHAb.w) == 0)
						{
							light_Dir = normalize(float4(1, 1, 1, 0));
						}
					//  #endif
				}

				half3 halfVector = normalize(light_Dir + viewDir);
		//-----
			
		//Set up Dot Products
				float NdL = dot(worldNormal, float4(light_Dir.xyz, 0));
				float roundedNdL = ceil(NdL); 
				float finalNdL = lerp(roundedNdL, NdL, _ShadowType);
				float VdN = DotClamped(viewDir, worldNormal);
				float SVdN = DotClamped(worldNormal, float4(stereoWorldViewDir, 0.0));
				float NdH = DotClamped(worldNormal, halfVector);
				float RdV = saturate(dot(reflect(light_Dir, worldNormal), float4(-viewDir, 0)));
				float tdh = dot(tangent, halfVector);
				float bdh = dot(binorm, halfVector);
		//-----

		//Do Subsurface Scattering
			//SSS method lifted from GDC 2011 conference by Colin Barre-Bresebois & Marc Bouchard and modified by me
				float3 thicknessMap = pow(UNITY_SAMPLE_TEX2D_SAMPLER(_ThicknessMap, _MainTex, uv_MainTex), max( 0.01, _ThicknessMapPower));
				float3 vSSLight = light_Dir + worldNormal * _SSSDist;
				float vdotSS = pow(saturate(dot(viewDir, -vSSLight)), max(0.2, _SSSPow)) * _SSSIntensity * lerp(1-thicknessMap, thicknessMap, _invertThickness);
				float3 sss;
				#if defined(POINT) || defined(SPOT)
					sss = attenuation * (vdotSS * _SSSCol) * (lightColor + indirectColor);
				#else
					sss = (vdotSS * _SSSCol) * (lightColor + indirectColor);
				#endif
		//-----

		//Do Recieved Shadows and lighting
				//We don't need to use the rounded NdL for this, as all it's doing is remapping for our shadowramp. The end result should be the same with either.
				float3 occlusionMap = UNITY_SAMPLE_TEX2D_SAMPLER(_OcclusionMap, _MainTex, UVSetAO);
				float remappedRamp = (NdL * 0.5 + 0.5);
				if(_AORAMPMODE_ON == 1)
				{
					remappedRamp *= (occlusionMap.x + ((1-occlusionMap.x) * (1-_OcclusionStrength)));
				}
				// #if DIRECTIONAL
				// 	remappedRamp = (NdL * 0.5 + 0.5) * occlusionMap.x;
				// #else
				// 	remappedRamp = (NdL * 0.5 + 0.5) * attenuation * occlusionMap.x;
				// #endif

				//rimlight typing
				float smoothRim = (smoothstep(0, 0.9, pow((1.0 - saturate(SVdN)), (1.0 - _RimWidth))) * _RimIntensity);
				float sharpRim = (step(0.9, pow((1.0 - saturate(SVdN)), (1.0 - _RimWidth))) * _RimIntensity);
				float3 finalRim = lerp(sharpRim, smoothRim, _RimlightType) * _RimColor;
				
				float3 shadowRamp = tex2D( _ShadowRamp, remappedRamp.xx).xyz;	
				float rampAvg = Luminance(shadowRamp);
				float indirectAvg = Luminance(indirectColor);
				float3 finalShadow;
				float3 finalLight;
				
				//Checked if we're in baked or not and use the correct values for shadowing based on that. 
				if (light_Env != 0) 
				{
					if(_WORLDSHADOWCOLOR_ON == 1)
					{
						finalShadow = saturate((rampAvg * attenuation) - (1-shadowRamp.r));
						lightColor = lightColor * finalShadow;
						finalLight = lightColor + indirectColor;
					}
					else
					{
						float3 rampBaseColor = tex2D(_ShadowRamp, float2(_RampBaseAnchor,_RampBaseAnchor));
						#if defined(DIRECTIONAL)
							float3 lightAtten = attenuation + rampBaseColor;
							finalShadow = min(saturate(lightAtten), shadowRamp.xyz);
							lightColor = lightColor;
							
							if(_MIXEDSHADOWCOLOR_ON == 1)
								finalLight = (indirectColor + lightColor) * finalShadow;
							else
								finalLight = (indirectAvg + lightColor) * finalShadow;

						#else
							finalShadow = saturate(((shadowRamp * attenuation * 2) - (1-shadowRamp.r)));
							lightColor = lightColor * (finalShadow + shadowRamp.rgb);
							float finalLength = Luminance(finalShadow);
							
							if(_MIXEDSHADOWCOLOR_ON == 1)
								finalLight = (lightColor + indirectColor) * finalLength;
							else
								finalLight = (indirectAvg + lightColor) * finalLength;

						#endif
					}
				}
				else{
					if(_WORLDSHADOWCOLOR_ON == 1)
							finalLight = indirectColor * rampAvg;
					else
					{
						if (_MIXEDSHADOWCOLOR_ON == 1)
							finalLight = indirectColor * shadowRamp;
						else
							finalLight = indirectAvg * shadowRamp;
					}
				}

				float4 MainTex = pow(UNITY_SAMPLE_TEX2D( _MainTex, uv_MainTex ), _Saturation);
				float4 MainColor = MainTex * _Color;
				if(_AORAMPMODE_ON == 0)
				{
					MainColor = lerp(MainColor * _OcclusionColor, MainColor, occlusionMap.r * _OcclusionStrength);
				}
			
			//Specular
				float4 specularMap = UNITY_SAMPLE_TEX2D_SAMPLER(_SpecularMap, _MainTex, uv_Specular);
				float specularPatternTex = UNITY_SAMPLE_TEX2D_SAMPLER(_SpecularPattern, _MainTex, uv_SpecularPattern).r;
				float3 specularHighlight = float3(0,0,0);
					if (_ANISTROPIC_ON == 1)
					{
						//Anistropic
							float smooth = saturate(D_GGXAnisotropic(tdh, bdh, NdH, _anistropicAX * 0.1, _anistropicAY * 0.1));
							float sharp = (round(smooth) * 2) / 2;
							specularHighlight = lerp(smooth, sharp, _SpecularStyle);
					}
					else
					{
						//Dot	
							float reflectionUntouched = saturate(pow(RdV, _SpecularArea * 128));
							specularHighlight = lerp(reflectionUntouched, round(reflectionUntouched),  _SpecularStyle);
					}

				float specularRefl = specularMap.g * specularPatternTex * _SpecularIntensity * 2 * specularHighlight;
			//--
		//-----

		//Do reflections
			#ifdef _REFLECTIONS_ON
				//making variables for later use for texture sampling. We want to create them empty here, so that we can save on texture samples by only
				//sampling when we need to, we assign the texture samples as needed. I.E. We don't need the metallic map for the stylized reflections, so why sample it?
				//Instead, throw it through as black. 
				float3 reflection = float4(0,0,0,0);
				float4 metalMap = float4(0,0,0,0);
				float4 roughMap = float4(0,0,0,0);

				//reflectedDir = reflections bouncing off the surface into the eye
				float3 reflectedDir = reflect(-viewDir, worldNormal);
				//reflectionDir = reflections bouncing off of the eye as if it were the light source
				float3 reflectionDir = reflect(-light_Dir, worldNormal);

			//PBR
				if(_PBRREFL_ON == 1)
				{
					metalMap = tex2D(_MetallicMap, uv_MetallicRough);
					metalMap.rgb *= _Metallic;
					roughMap = UNITY_SAMPLE_TEX2D_SAMPLER(_RoughMap, _MainTex, uv_MetallicRough);
					float roughness = (1-metalMap.a * _ReflSmoothness);
					roughness *= 1.7 - 0.7 * roughness;
					float4 envSample = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectedDir, roughness * UNITY_SPECCUBE_LOD_STEPS);
					reflection = DecodeHDR(envSample, unity_SpecCube0_HDR);
					
				// if a reflection probe doesn't exist, fill it with our fallback instead.	
					if (any(reflection.xyz) == 0)
						{
							reflection = texCUBElod(_BakedCube, float4(reflectedDir, roughness * UNITY_SPECCUBE_LOD_STEPS));
						}
				}
			//--

			//Matcap	
				//Note: This matcap is intended for VR. 
				if(_MATCAP_ON == 1)
				{
					roughMap = UNITY_SAMPLE_TEX2D_SAMPLER(_RoughMap, _MainTex, uv_MetallicRough);
					float3 upVector = float3(0,1,0);
					float2 remapUV = matcapSample(upVector, viewDir, worldNormal);
					reflection = tex2Dlod(_MetallicMap, float4(remapUV, 0, (_ReflSmoothness * UNITY_SPECCUBE_LOD_STEPS)));
				}
			//--

			//Cubemap Baked
				if(_MATCAP_CUBEMAP_ON == 1)
				{
					metalMap = tex2D(_MetallicMap, uv_MetallicRough);
					metalMap.rgb *= _Metallic;
					roughMap = UNITY_SAMPLE_TEX2D_SAMPLER(_RoughMap, _MainTex, uv_MetallicRough);
					float roughness = (1-metalMap.a * _ReflSmoothness);
					roughness *= 1.7 - 0.7 * roughness;
					reflection = texCUBElod(_BakedCube, float4(reflectedDir, roughness * UNITY_SPECCUBE_LOD_STEPS));
				}
			//--	
			#endif
		//-----
			
		//Do Final Lighting
																			//Can probably be cleaned to look nicer
				float3 finalAddedLight = (finalRim + specularRefl) * saturate((saturate(MainColor + 0.5) * pow(finalLight, 2) * (shadowRamp))).rgb;
				float3 finalColor = MainColor.xyz;

			//Add Reflections
				#ifdef _REFLECTIONS_ON
				//Do PBR
					if(_PBRREFL_ON == 1 || _MATCAP_CUBEMAP_ON == 1)		
					{
						float3 finalreflections = (reflection * (MainColor * 2));
						finalColor = (MainColor * ((1-_Metallic * metalMap.r)));
						finalColor += finalreflections;
					}
				//--
				//Do Matcap
					if(_MATCAP_ON)
					{
						//Additive
						if(_MatcapStyle == 0)
						{
							finalColor = MainColor + (reflection * _Metallic * (roughMap.r));
						}
						//Multiplicitive
						if(_MatcapStyle == 1)
						{
							finalColor = lerp(MainColor, MainColor * reflection, roughMap.r * _Metallic);
						}
						//Subtractive
						if(_MatcapStyle == 2)
						{
							finalColor = MainColor - (reflection * _Metallic * (roughMap.r));
						} 
					}
				//--
				#endif
			//--

			//Emission
				float4 emissive = _EmissiveColor * UNITY_SAMPLE_TEX2D_SAMPLER(_EmissiveTex, _MainTex, UVSetEmission) * lerp(MainColor, 1, _EmissTintToColor);
				float3 emissPow = saturate(rgb2hsv(indirectColor + lightColor) * _EmissionPower).z;
				float emissiveScaled = saturate(pow(1-(emissPow), 2.2));
				float scaleWithLight = _ScaleWithLight >= 1 ? 1 : emissiveScaled;
				#if defined(POINT) || defined(SPOT)
					scaleWithLight *= 0;
				#endif
				emissive *= scaleWithLight;
			//--

			c.rgb = finalColor * (finalLight + sss.xyz + finalAddedLight) + emissive;
		//-----
		
		//Do Alpha Modes
			//opaque
				#ifdef opaque
					c.a = 1;
				#endif
			//--
				
			//alphablend
				#ifdef alphablend
					c.a = (MainTex.a * _Color.a);
				#endif
			//--

			//cutout
				#ifdef cutout
					clip(MainTex.a - _Cutoff);
					c.a = 1;
				#endif
			//--

			//dithered
				#ifdef dithered
					float2 screenPos = i.screenPos.xy;
					float2 pos = screenPos / i.screenPos.w;
					pos *= _ScreenParams.xy; // pixel position

					float dither = Dither8x8Bayer(fmod(pos.x, 8), fmod(pos.y, 8));
					clip((MainTex.a * _Color.a) - dither);
				#endif
			//--
		//-----
			s.Alpha = MainTex.a * _Color.a;
			return c;
		}