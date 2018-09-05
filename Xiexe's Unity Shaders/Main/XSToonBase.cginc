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

		 float4 _EmissiveColor;
		 sampler2D _EmissiveTex;
		 float4 _EmissiveTex_ST;
		 float _EmissiveStrength;
		 sampler2D _ShadowRamp;
		 sampler2D _Normal;
		 float2 _NormalTiling;
		 float _UseUV2forNormalsSpecular;
		 float4 _SimulatedLightDirection;
		 sampler2D _MainTex;
		 float4 _MainTex_ST;
		 float4 _Color;
		 float _RimWidth;
		 float3 _Xiexe;
		 float _RimIntensity;
		 sampler2D _SpecularMap;
		 sampler2D _SpecularPattern;
		 float2 _SpecularPatternTiling;
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
		 sampler2D _MetallicMap;
		 sampler2D _RoughMap;
		 samplerCUBE _BakedCube;
		 float _UseReflections;
		 float _UseOnlyBakedCube;
		 float _ShadowType;
		 float _ReflType;
		 float _StylelizedIntensity;
		 float _Saturation;
		 float _MatcapStyle;
		 float _RampColor;


		float3 ShadeSH9( float3 normal )
		{
			return ShadeSH9(half4(normal, 1.0));
		}

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


		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;

			half4 c = 0;
		//light and show attenuation
			#if DIRECTIONAL
				float steppedAtten = round(data.atten);
				float ase_lightAtten = lerp(steppedAtten, data.atten, _ShadowType);
			#else
				float3 ase_lightAttenRGB = smoothstep(0, 0.4, (gi.light.color / ( ( _LightColor0.rgb ) + 0.000001 )));
				float ase_lightAtten = (max( max( ase_lightAttenRGB.r, ase_lightAttenRGB.g ), ase_lightAttenRGB.b ));
			#endif


		//assign the first and second texture coordinates to a variable thats easier to type out/access
			float2 texcoord1 = i.uv_texcoord;
			float2 texcoord2 = i.uv2_texcoord2;
			
		//set up uvs for all main texture maps
			float2 uv_MainTex = i.uv_texcoord * _MainTex_ST.xy + _MainTex_ST.zw;

		//swap UV sets based on if we're using UV2 or not
			float2 UVSet = lerp(texcoord1,texcoord2,_UseUV2forNormalsSpecular);

			float3 normalMap = UnpackNormal( tex2D( _Normal, (((UVSet - float2( 0.5,0.5)) * _NormalTiling) + float2(0.5,0.5))));
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 ase_vertexNormal = mul( unity_WorldToObject, float4( ase_worldNormal, 0 ) );
			float4 worldNormals = mul(unity_ObjectToWorld,float4( ase_vertexNormal , 0.0 ));
			float4 WSvertexNormals = lerp( float4( WorldNormalVector( i , normalMap ) , 0.0 ) , worldNormals , 0.3);
			// float4 WSvertexNormals = lerpedNormals;

			//We're sampling ShadeSH9 at 0,0,0 to just get the color. In the future, this may be upgraded to get directionality as well.
			half3 shadeSH9 = ShadeSH9(float4(0,0,0,1));
			//Do another shadeSH9 sample to get directionality from light probes, but only from the strongest averaged direction.
			//This gets rid of the small artifcat normally present in ShadeSH9, which is the small round cut in the back of the shadow.
			half3 shadeSH9Light = ShadeSH9(float4(WSvertexNormals.xyz,1));
			half3 reverseShadeSH9Light = ShadeSH9(float4(-WSvertexNormals.xyz,1));
			half3 shadeSH9Map = (shadeSH9Light - reverseShadeSH9Light)/2;
			float3 lightColor = _LightColor0; 

			//Worldspace light direction and simulated light directions
			float3 worldLightDir = normalize( UnityWorldSpaceLightDir( i.worldPos ) );
			float4 simulatedLight = normalize(float4(shadeSH9Map,1));//normalize( _SimulatedLightDirection );

		//figure out whether we are in a realtime lighting scnario, or baked, and return it as a 0, or 1 (1 for realtime, 0 for baked)
			float light_Env = float(any(_WorldSpaceLightPos0.xyz));

		//we use the simulated light direction if we're in a baked scenario
			float4 light_Dir = simulatedLight.xyzz;

		//otherwise, we use the actual light direction
			if( light_Env == 1)
			{
				light_Dir = float4( worldLightDir , 0.0 );
			}

			//After some searching I discovered that NdotL is actually a way to hide the horrible artifacting you get from 
			//selfshadowing, which is provided by light Attenuation. So I do both a Smooth and Sharp calc for NdotL, and then
			//choose one based on the Shadow Type you choose. 
			float NdotL = dot( WSvertexNormals , float4( light_Dir.xyz , 0.0 ) );
			float roundedNdotL = ceil(dot( WSvertexNormals , float4( light_Dir.xyz , 0.0 ) )); 
			float finalNdotL = lerp(roundedNdotL, NdotL, _ShadowType);
			
			//We don't need to use the rounded NdotL for this, as all it's doing is remapping for our shadowramp. The end result should be the same with either.
			float remappedRamp = NdotL * 0.5 + 0.5;
			float remappedRampBaked = ((shadeSH9Map + 1) * 0.5);
			float2 horizontalRamp = float2(remappedRamp , 0.0);
			float2 verticalRamp = float2(0.0 , remappedRamp);
			
			float4 ase_vertex4Pos = mul( unity_WorldToObject, float4( i.worldPos , 1 ) );
			float4 vertexWorldPos = mul(unity_ObjectToWorld,ase_vertex4Pos);
			float3 stereoWorldViewDir = StereoWorldViewDir(vertexWorldPos);
		//Stereo VdotN / NdotV
			float VdotN = dot(WSvertexNormals, float4(stereoWorldViewDir, 0.0));

		//rimlight typing
			float smoothRim = (smoothstep(0, 0.9, pow((1.0 - saturate(VdotN)), (1.0 - _RimWidth))) * _RimIntensity);
			float sharpRim = (step(0.9, pow((1.0 - saturate(VdotN)), (1.0 - _RimWidth))) * _RimIntensity);
			float finalRim = lerp(sharpRim, smoothRim, _RimlightType);


	//Do reflections
		#ifdef _REFLECTIONS_ON
		
		//making variables for later use for texture sampling. We want to create them empty here, so that we can save on texture samples by only
		//sampling when we need to, we assign the texture samples as needed. I.E. We don't need the metallic map for the stylized reflections, so why sample it?
		//Instead, throw it through as black. 
			float4 reflection = float4(0,0,0,0);
			float4 metalMap = float4(0,0,0,0);
			float4 roughMap = float4(0,0,0,0);

		//reflectedDir = reflections bouncing off the surface into the eye
			float3 reflectedDir = reflect(-viewDir, WSvertexNormals);
		//reflectionDir = reflections bouncing off of the eye as if it were the light source
			float3 reflectionDir = reflect(-light_Dir, WSvertexNormals);

		//PBR
			#ifdef _PBRREFL_ON
				metalMap = (tex2D(_MetallicMap, uv_MainTex) * _Metallic);
				roughMap = tex2D(_RoughMap, uv_MainTex);
				float roughness = saturate((_ReflSmoothness * (roughMap.r)));
				reflection = (UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectedDir, roughness * 6));
				
			// if a reflection probe doesn't exist, fill it with our fallback instead.	
				if (any(reflection.xyz) == 0)
					{
						reflection = texCUBElod(_BakedCube, float4(reflectedDir, roughness * 6));
					}
				#endif
		//Stylized	
				#ifdef _STYLIZEDREFLECTION_ON
					#ifdef _ANISTROPIC_ON
					//Anistropic Stripe
						metalMap = (tex2D(_MetallicMap, uv_MainTex) * _Metallic);
						float3 tangent = i.tangentDir;
						half3 h = normalize(light_Dir + viewDir);
						float ndh = max(0, dot (WSvertexNormals, h));
						half3 binorm = cross(WSvertexNormals, tangent);
						fixed ndv = dot(viewDir, WSvertexNormals);
						float aX = dot(h, tangent) / 0.75;
						float aY = dot(h, binorm) / _Metallic;
						reflection = sqrt(max(0.0, NdotL / ndv)) * exp(-2.0 * (aX * aX + aY * aY) / (1.0 + ndh)) * (_ReflSmoothness) * 2.0;
						reflection = ceil(smoothstep(0.5-_ReflSmoothness*0.5, 0.5+_ReflSmoothness*0.5, reflection)) * metalMap;
					#else
					//Dot Stylized	
						metalMap = (tex2D(_MetallicMap, uv_MainTex) * _Metallic);
						float reflectionUntouched = step(0.9, (pow(DotClamped(stereoWorldViewDir, reflectionDir), ((1-_ReflSmoothness))))) * metalMap;
						reflection = (round(reflectionUntouched * 10) / 10);
					#endif
				#endif
		//Matcap	
				#ifdef _MATCAP_ON
						roughMap = tex2D(_RoughMap, uv_MainTex);
					#ifdef _MATCAP_CUBEMAP_ON
						reflection = texCUBElod(_BakedCube, float4(reflectedDir, _ReflSmoothness * 6));
					#else
						float3 sampleY = float3(0,1,0);

						float3 VcrossY = cross(viewDir, sampleY);
						float3 VCYcrossV = cross(VcrossY, viewDir);

						float4x4 tmat = tMatrixFunc(viewDir, VcrossY, VCYcrossV);

						float4 remapUV = mul(WSvertexNormals, tmat);
						remapUV = remapUV * 0.5 + 0.5;
						reflection = tex2Dlod(_MetallicMap, float4(remapUV.yz, 0, (_ReflSmoothness * 6)));
					#endif
				#endif
			#endif

		//Recieved Shadows and lighting
			float3 shadowRamp = tex2D( _ShadowRamp, lerp(float2(remappedRamp,remappedRamp), float2(remappedRampBaked,remappedRampBaked), 1-light_Env)).xyz;	
			
			//we initialize finalshadow here, but we will be editing this based on the lighting env below
			float3 finalShadow = saturate(((ase_lightAtten * .5) - (1-shadowRamp.r)));

		//We default to baked lighting situations, so we use these values
			float3 indirectLight = shadeSH9;
			float3 finalLight = indirectLight * shadowRamp;

		//If our lighting environment matches the number for realtime lighting, use these numbers instead
			if (light_Env == 1) 
			{
				#if _WORLDSHADOWCOLOR_ON
					finalShadow = saturate(((finalNdotL * ase_lightAtten * .5) - (1-shadowRamp.r)));
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
						finalShadow = saturate(((finalNdotL * ase_lightAtten * .5) - (1-shadowRamp.r)));
						lightColor = lightColor * (finalShadow);
						finalLight = lightColor + (indirectLight);
					#endif
				#endif
			}
		//get the main texture and multiply it by the color tint, and do saturation on the main texture
			float4 MainTex = pow(tex2D( _MainTex, uv_MainTex ), _Saturation);
			float4 MainColor = MainTex * _Color;
		
		//grab the specular map texture sample, get the dot product of the vertex normals vs the stereo correct view direction, and create specular reflections and a rimlight based on that and a texture we feed in.
			float4 specularMap = tex2D( _SpecularMap, UVSet );
			float NdotV = dot(reflect(light_Dir , WSvertexNormals), float4((stereoWorldViewDir * -1.0), 0.0));
		
		//Specular
			//sample specular pattern
			float specularPatternTex = tex2D(_SpecularPattern, (((UVSet - float2( 0.5,0.5)) * _SpecularPatternTiling) + float2(0.5,0.5))).r;
			//use the specular pattern in place of the specular area
			float specularRefl = (((specularMap.g * (1.0 - specularMap.r)) * specularPatternTex) * (_SpecularIntensity * 2) * saturate(pow(saturate(NdotV) , _SpecularArea)));
		
		//calculate the final lighting for our lighting model
																		//Can probably be cleaned to look nicer
			float3 finalAddedLight = (finalRim + specularRefl) * saturate((saturate(MainColor + 0.5) * pow(finalLight, 2) * (shadowRamp))).rgb;
		    float3 finalColor = MainColor.xyz;

		//if we have reflections turned on, return the final color with reflections
			#ifdef _REFLECTIONS_ON
			//Do PBR
				#ifdef _PBRREFL_ON
					float3 finalreflections = (reflection * (MainColor * 2));
					finalColor = (MainColor * ((1-_Metallic * metalMap.r)));
					finalColor += finalreflections;
				#endif
			//Do Stylized
				#ifdef _STYLIZEDREFLECTION_ON
					finalColor = MainColor + ((reflection * ((MainColor) * finalLight)) * _StylelizedIntensity);
				#endif
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
			#endif

		//return the RGB of all the stuff from above as c	
			c.rgb = finalColor * (finalLight + finalAddedLight);
		
		//get the alpha, based on if we have cutout, or alphablending enabled from our editor script, and finally return everything
            #ifdef opaque
        		c.a = 1;
            #endif
			
		//alphablend
            #ifdef alphablend
				c.a = (MainTex.a * _Color.a);
            #endif

		//cutout
			#ifdef cutout
				clip(MainTex.a - _Cutoff);
				c.a = 1;
			#endif

		//dithered
			#ifdef dithered
				 // Screen-door transparency: Discard pixel if below threshold.
				 // This may be replaced in the future, as there are better ways to do this. 
    			float4x4 thresholdMatrix =
    			{  1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
    			  13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
    			   4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
    			  16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
   				};
   				float4x4 _RowAccess = { 1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1 };
				float2 screenPos = i.screenPos.xy;
				float2 pos = screenPos / i.screenPos.w;
				pos *= _ScreenParams.xy; // pixel position
   					
				 #ifdef UNITY_SINGLE_PASS_STEREO
				 	clip((MainTex.a * _Color.a) - thresholdMatrix[fmod((pos.x * 2), 4)] * _RowAccess[fmod(pos.y, 4)]);
				 #else
					clip((MainTex.a * _Color.a) - thresholdMatrix[fmod(pos.x, 4)] * _RowAccess[fmod(pos.y, 4)]);
				 #endif
			#endif

			return c;
		}