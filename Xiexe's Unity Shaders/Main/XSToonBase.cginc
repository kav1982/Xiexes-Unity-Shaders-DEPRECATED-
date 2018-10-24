		#include "UnityStandardBRDF.cginc"
		#include "UnityPBSLighting.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#ifdef UNITY_PASS_SHADOWCASTER
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
			INTERNAL_DATA
			float2 uv2_texcoord2;
			float3 worldPos;
			float4 screenPos;
			float3 tangentDir;
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

		sampler2D _MainTex;
		sampler2D _EmissiveTex;
		sampler2D _ShadowRamp;
		sampler2D _Normal;
		sampler2D _SpecularMap;
		sampler2D _SpecularPattern;
		sampler2D _MetallicMap;
		sampler2D _RoughMap;
		samplerCUBE _BakedCube;
		float4 _MainTex_ST;
		float4 _EmissiveTex_ST;
		float4 _ShadowRamp_ST;
		float4 _Normal_ST;
		float4 _SpecularMap_ST;
		float4 _SpecularPattern_ST;
		float4 _MetallicMap_ST;
		float4 _RoughMap_ST;
		float4 _BakedCube_ST;

		float4 _EmissiveColor;
		float4 _SimulatedLightDirection;
	 	float4 _Color;
		float3 _RimColor;
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

	//Custom Helper Functions		
		float4x4 tMatrixFunc(float3 x, float3 y, float3 z)
		{
			float4x4 tMatrix = {x.x,y.x,z.x,0,
								x.y,y.y,z.y,0,
								x.z,y.z,z.z,0,
								0  ,0  ,0  ,0};
			return tMatrix;					
		}

		float3 StereoWorldViewDir( float3 worldPos )
		{
			#if UNITY_SINGLE_PASS_STEREO
			float3 cameraPos = float3((unity_StereoWorldSpaceCameraPos[1]+ unity_StereoWorldSpaceCameraPos[1])*.5); 
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
					float ase_lightAtten = lerp(steppedAtten, data.atten, _ShadowType);
				#else
					float3 ase_lightAttenRGB = smoothstep(0, 0.4, (gi.light.color / ( ( _LightColor0.rgb ) + 0.000001 )));
					float ase_lightAtten = (max( max( ase_lightAttenRGB.r, ase_lightAttenRGB.g ), ase_lightAttenRGB.b ));
				#endif
		//-----
			
		//Set up UVs
				float2 texcoord1 = i.uv_texcoord;
				float2 texcoord2 = i.uv2_texcoord2;
				float2 UVSet = lerp(texcoord1,texcoord2,_UseUV2forNormalsSpecular);
				float2 uv_MainTex = i.uv_texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
				float2 uv_Normal = UVSet * _Normal_ST.xy + _Normal_ST.zw;
				float2 uv_Specular = UVSet * _SpecularMap_ST.xy + _SpecularMap_ST.zw;
		//-----

		//Set up Normals, viewDir, tanget, binorm
				float3 normalMap = UnpackNormal(tex2D( _Normal, uv_Normal));
				float4 worldNormal = normalize(lerp(float4(WorldNormalVector(i, normalMap), 0), float4(WorldNormalVector(i, float3(0, 0, 1)), 0), 0.3));
				float3 tangent = i.tangentDir;
				half3 binorm = cross(worldNormal, tangent);
				float3 stereoWorldViewDir = StereoWorldViewDir(i.worldPos);
		//-----

		//Setup Direct and Indirect Light
				float3 lightColor = _LightColor0; 

				//We're sampling ShadeSH9 at 0,0,0 to just get the color.
				half3 indirectDiffuse = ShadeSH9(float4(0,0,0,1));

				//Do another shadeSH9 sample to get directionality from light probes, but only from the strongest averaged direction.
				//This gets rid of the small artifcat normally present in ShadeSH9, which is the small round cut in the back of the shadow.
				half3 indirectDiffuseLight = ShadeSH9(float4(worldNormal.xyz,1));
				half3 reverseindirectDiffuseLight = ShadeSH9(float4(-worldNormal.xyz,1));
				half3 noAmbientindirectDiffuseLight = (indirectDiffuseLight - reverseindirectDiffuseLight)/2;
				float3 indirectLightSH = noAmbientindirectDiffuseLight * 0.5 + 0.533;
				float averagedindirect = length(indirectLightSH)/sqrt(3.0);

				//Worldspace light direction and simulated light directions
				float3 worldLightDir = normalize( UnityWorldSpaceLightDir( i.worldPos ) );
				float4 simulatedLight = normalize(indirectLightSH.xyzz);//normalize( _SimulatedLightDirection );

				//figure out whether we are in a realtime lighting scnario, or baked, and return it as a 0, or 1 (1 for realtime, 0 for baked)
				float light_Env = float(any(_WorldSpaceLightPos0.xyz));

				//we use the simulated light direction if we're in a baked scenario
				float4 light_Dir = simulatedLight.xyzz;

				//otherwise, we use the actual light direction
				if( light_Env == 1)
				{
					light_Dir = float4( worldLightDir , 0.0 );
				}

				half3 halfVector = normalize(light_Dir + viewDir);
		//-----
			
		//Set up Dot Products
				//ndl
				float NdL = DotClamped(worldNormal, float4(light_Dir.xyz, 0));
				float roundedNdL = ceil(NdL); 
				float finalNdL = lerp(roundedNdL, NdL, _ShadowType);
				//vdn and stereo vdn
				float VdN = DotClamped(viewDir, worldNormal);
				float SVdN = DotClamped(worldNormal, float4(stereoWorldViewDir, 0.0));
				//ndh
				float NdH = DotClamped(worldNormal, halfVector);
				//rdl
				float RdV = saturate(dot(reflect(light_Dir, worldNormal), float4(-viewDir, 0)));
				//tdh
				float tdh = dot(tangent, halfVector);
				//bdh
				float bdh = dot(binorm, halfVector);
		//-----

		//Do Recieved Shadows and lighting
				//We don't need to use the rounded NdL for this, as all it's doing is remapping for our shadowramp. The end result should be the same with either.
				float remappedRamp = NdL * 0.5 + 0.5;
				float remappedRampBaked = averagedindirect;

				//rimlight typing
				float smoothRim = (smoothstep(0, 0.9, pow((1.0 - saturate(SVdN)), (1.0 - _RimWidth))) * _RimIntensity);
				float sharpRim = (step(0.9, pow((1.0 - saturate(SVdN)), (1.0 - _RimWidth))) * _RimIntensity);
				float3 finalRim = lerp(sharpRim, smoothRim, _RimlightType) * _RimColor;

				float3 shadowRamp = tex2D( _ShadowRamp, lerp(float2(remappedRamp,remappedRamp), float2(remappedRampBaked,remappedRampBaked), 1-light_Env)).xyz;	
				
				//Initialize finalshadow here, but we will be editing this based on the lighting env below
				float3 finalShadow = saturate(((ase_lightAtten * .5) - (1-shadowRamp.r)));

				//We default to baked lighting situations, so we use these values
				float3 indirectLight = indirectDiffuse;
				float3 finalLight = indirectLight * shadowRamp;

				//If our lighting environment matches the number for realtime lighting, use these numbers instead
				if (light_Env == 1) 
				{
					#if _WORLDSHADOWCOLOR_ON
						finalShadow = saturate(((finalNdL * ase_lightAtten * .5) - (1-shadowRamp.r)));
						lightColor = lightColor * (finalShadow);
						finalLight = lightColor + (indirectLight);
					#else
						#if DIRECTIONAL
							float3 rampBaseColor = tex2D(_ShadowRamp, float2(0,0));
							float3 lightAtten = ase_lightAtten + rampBaseColor;
							shadowRamp = tex2D(_ShadowRamp, float2(remappedRamp,remappedRamp));
							finalShadow = min(saturate(lightAtten), shadowRamp.xyz);
							lightColor = lightColor;
							finalLight = (saturate(indirectLight * 0.25) + lightColor) * finalShadow;
						#else
							finalShadow = saturate(((finalNdL * ase_lightAtten * .5) - (1-shadowRamp.r)));
							lightColor = lightColor * (finalShadow);
							finalLight = lightColor + (indirectLight);
						#endif
					#endif
				}

				float4 MainTex = pow(tex2D( _MainTex, uv_MainTex ), _Saturation);
				float4 MainColor = MainTex * _Color;
			
			//Specular
				float4 specularMap = tex2D(_SpecularMap, uv_Specular);
				float specularPatternTex = tex2D(_SpecularPattern, (((UVSet - float2( 0.5,0.5)) * _SpecularPatternTiling) + float2(0.5,0.5))).r;
				float3 specularHighlight = float3(0,0,0);
					#ifdef _ANISTROPIC_ON
						//Anistropic
							float smooth = saturate(D_GGXAnisotropic(tdh, bdh, NdH, _anistropicAX, _anistropicAY));
							float sharp = (round(smooth) * 2) / 2;
							specularHighlight = lerp(smooth, sharp, _SpecularStyle);
						#else
						//Dot	
							float reflectionUntouched = saturate(pow(RdV, _SpecularArea * 128));
							specularHighlight = lerp(reflectionUntouched, round(reflectionUntouched),  _SpecularStyle);
						#endif

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
				#ifdef _PBRREFL_ON
					metalMap = (tex2D(_MetallicMap, uv_MainTex) * _Metallic);
					roughMap = tex2D(_RoughMap, uv_MainTex);
					float roughness = saturate((_ReflSmoothness * (roughMap.r)));
					float4 envSample = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectedDir, roughness * 6);
					reflection = DecodeHDR(envSample, unity_SpecCube0_HDR);
					
				// if a reflection probe doesn't exist, fill it with our fallback instead.	
					if (any(reflection.xyz) == 0)
						{
							reflection = texCUBElod(_BakedCube, float4(reflectedDir, roughness * 6));
						}
					#endif
			//--

			//Matcap	
				//Note: This matcap is intended for VR. 
					#ifdef _MATCAP_ON
							roughMap = tex2D(_RoughMap, uv_MainTex);
						#ifdef _MATCAP_CUBEMAP_ON
							reflection = texCUBElod(_BakedCube, float4(reflectedDir, _ReflSmoothness * 6));
						#else
							float3 sampleY = float3(0,1,0);
							float3 VcrossY = cross(viewDir, sampleY);
							float3 VCYcrossV = cross(VcrossY, viewDir);
							float4x4 tmat = tMatrixFunc(viewDir, VcrossY, VCYcrossV);
							float4 remapUV = mul(worldNormal, tmat);
							remapUV = remapUV * 0.5 + 0.5;
							reflection = tex2Dlod(_MetallicMap, float4(remapUV.yz, 0, (_ReflSmoothness * 6)));
						#endif
					#endif
				#endif
			//--

		//-----
			
		//Do Final Lighting
																			//Can probably be cleaned to look nicer
				float3 finalAddedLight = (finalRim + specularRefl) * saturate((saturate(MainColor + 0.5) * pow(finalLight, 2) * (shadowRamp))).rgb;
				float3 finalColor = MainColor.xyz;

				//Add Reflections
				#ifdef _REFLECTIONS_ON
				
				//Do PBR
					#ifdef _PBRREFL_ON
						float3 finalreflections = (reflection * (MainColor * 2));
						finalColor = (MainColor * ((1-_Metallic * metalMap.r)));
						finalColor += finalreflections;
					#endif
				//--

				//Do Matcap
					#ifdef _MATCAP_ON
						//Additive
						if(_MatcapStyle == 0)
						{
							finalColor = MainColor + (reflection * _Metallic * (roughMap.r));
						}
						//Multiplicitive
						if(_MatcapStyle == 1)
						{
							finalColor = MainColor * (reflection * _Metallic * (roughMap.r));
						}
						//Subtractive
						if(_MatcapStyle == 2)
						{
							finalColor = MainColor - (reflection * _Metallic * (roughMap.r));
						} 
					#endif
				//--
				
				#endif
				//-----
			c.rgb = finalColor * (finalLight + finalAddedLight);
		//-----
		
		//Do Alpha Modes
			//D
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

			return c;
		}