//The base of this shader was made in amplify - however it has been heavily altered. 
//If you open this in amplify it will kill the shader, don't do it.

Shader "Xiexe/Toon/XSToon"
{
	Properties
	{
		//[Toggle]_UseUV2forNormalsSpecular("Use UV2 for Normals/Specular", Float) = 0

	//Enums for all options
		[Enum(Off,0,Front,1,Back,2)] _Culling ("Culling Mode", Int) = 2
		[Enum(Horizontal,0,Vertical,1)] _RampDir ("Shadow Ramp Direction", Int) = 1
		[Enum(Sharp,0,Smooth,1,Off,2)] _RimlightType("Rimlight Type", Int) = 0
		[Enum(On,0,Off,1)] _UseReflections ("Use Reflections", Int) = 1
		[Enum(Sharp,0,Smooth,1)] _ShadowType ("Recieved Shadow Type", Int) = 0
		[Enum(PBR,0,Matcap,1,Cubemap,2)] _ReflType ("Reflection Type", Int) = 0
		[Enum(Add,0,Multiply,1,Subtract,2)] _MatcapStyle ("Matcap Blend Mode", Int) = 1
		[Enum(Dot,0,Anistropic,1)] _StylizedReflStyle ("StylizedReflStyle", Int) = 0
		[Enum(Ambient, 0, Ramp, 1, Mixed, 2)] _RampColor ("Ramp Color", Int) = 2
		[Enum(Smooth,0,Sharp,1)]_SpecularStyle("Specular Style", Int) = 0
		[Enum(On,0,Off,1)]_UseSSS("Use SSS", Int) = 1
		[Enum(On,0,Off,1)]_UseSpecular("Use Specular", Int) = 1
		[Enum(On,0,Off,1)] _Emissive("Emissive?", Int) = 1
		[Enum(Yes,0, No,1)] _ScaleWithLight("ScaleEmissWithLight", Int) = 1
		
		[Enum(UV1,0, UV2,1)] _EmissUv2("Emiss UV", Int) = 0
		[Enum(UV1,0, UV2,1)] _DetailNormalUv2("Emiss UV", Int) = 0
		[Enum(UV1,0, UV2,1)] _NormalUv2("Emiss UV", Int) = 0
		[Enum(UV1,0, UV2,1)] _MetallicUv2("Emiss UV", Int) = 0
		[Enum(UV1,0, UV2,1)] _SpecularUv2("Emiss UV", Int) = 0
		[Enum(UV1,0, UV2,1)] _SpecularPatternUv2("Emiss UV", Int) = 0
		[Enum(UV1,0, UV2,1)]_AOUV2("Ao UV", int) = 0

		[Enum(Yes,0, No,1)] _EmissTintToColor("TintToColor", Int) = 1
		[Enum(Basic, 0, Integrated, 1)]_AORAMPMODE_ON("", Int) = 0
		
		
	//Textures
		_MainTex("Main Tex", 2D) = "white" {}
		[Normal]_Normal("Normal", 2D) = "bump" {}
		[Normal]_DetailNormal("Detail Normal", 2D) = "bump" {}
		_DetailMask("Detail Mask", 2D) = "white" {}
		_ShadowRamp("Shadow Ramp", 2D) = "white" {}
		_SpecularMap("Specular Map", 2D) = "white" {}
		_SpecularPattern("Specular Pattern", 2D) = "white" {}
		_MetallicMap("Metallic Map", 2D) = "white" {}
		_RoughMap("Rough Map", 2D) = "white" {}
		_BakedCube("Local Cubemap", Cube) = "black" {}
		_EmissiveTex("Emissive Tex", 2D) = "white" {}
		_OcclusionMap("AO Map", 2D) = "white" {}

		_OcclusionStrength("Occlusion Strength", Range(0,1)) = 1
		_NormalStrength("Normal Strength", float) = 1
		_DetailNormalStrength("Detail Normal Strength", float) = 1

		_SpecularPatternTiling("Specular Pattern Tiling", Vector) = (20,20,0,0)
		_Color("Color Tint", Color) = (1,1,1,1)
		_OcclusionColor("Occlusion Color", Color) = (0,0,0,0)
		_SubsurfaceColor("Subsurface Color", Color) = (0,0,0,0)
		_NormalTiling("NormalTiling", Vector) = (1,1,0,0)
		_SpecularIntensity("Specular Intensity", Float) = 0
		_SpecularArea("Specular Area", Range( 0 , 1)) = 0.5
		_RimWidth("Rim Width", Range( 0 , 1)) = 0.2
		_RimIntensity("Rim Intensity", Range(0, 10)) = 0.8
		
		[HDR]_EmissiveColor("Emissive Color", Color) = (0,0,0,0) 
		_Cutoff ("Cutout Amount", Float) = 0.5
		_ReflSmoothness ("Reflection Smoothness", Range(0.001,1)) = 1
		_Metallic ("Metallic", Range(0,1)) = 0
		_StylelizedIntensity("Stylized Refl Intensity", Range(0,10)) = 1
		_Saturation("Saturation", Range(0.1,6)) = 1
		_RimColor("Rimlight Tint", Color) = (1,1,1,1)
		[Toggle]_SolidRimColor("Solid Rim Color", Float) = 0
		_anistropicAX("aY", range(0,1)) = 0.75
		_anistropicAY("aX", range(0,1)) = 0.75

		_SSSDist("fLTDistortion", float) = 1
		_SSSPow("iLTPower", float ) = 1
		_SSSCol("SSS Color", color) = (1,1,1,1)
		_SSSIntensity("SSS intensity", range(0,5)) = 1
		_ThicknessMap("Thickness Map", 2D) = "black" {}
		[Toggle]_invertThickness("Invert Thickness Map", Float) = 0 
		_ThicknessMapPower("Thickness Map Power", range(0,1)) = 1

	//Don't delete these or comment them out, they are needed. Not sure why as of now.
		[HideInInspector] _texcoord2( "", 2D ) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1

	//Blending states, the editor script accesses these to change what state the material is in. They are needed.
		[HideInInspector] _mode ("__mode", Float) = 0.0
		[HideInInspector] _advMode ("__advMode", float) = 0.0
		[HideInInspector] _srcblend ("__src", Float) = 1.0
		[HideInInspector] _dstblend ("__dst", Float) = 0.0

	//Advanced Stuff
		[Header(Stencil)]
		_Offset("Offset", float) = 0
		[IntRange] _Stencil ("Stencil ID [0;255]", Range(0,255)) = 0
		_ReadMask ("ReadMask [0;255]", Int) = 255
		_WriteMask ("WriteMask [0;255]", Int) = 255
		[Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilOp ("Stencil Operation", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilFail ("Stencil Fail", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilZFail ("Stencil ZFail", Int) = 0
		[Enum(Off,0,On,1)] _ZWrite("ZWrite", Int) = 1
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4
		[Enum(None,0,Alpha,1,Red,8,Green,4,Blue,2,RGB,14,RGBA,15)] _colormask("Color Mask", Int) = 15 

		_RampBaseAnchor("RampBaseAnchor", Range(0,1)) = 0.5
		_EmissionPower("", Range(1,5)) = 1

		_OutlineThickness("Outline Thickness", Range(0,1)) = 0.1
		_OutlineColor("Outline Color", Color) = (0,0,0,1) 
		_OutlineTextureMap("Outline Masks (R, G, B)", 2D) = "white" {}

		//Toggles to replace keywords
		[Toggle]_ANISTROPIC_ON("", Int) = 0
		[Toggle]_PBRREFL_ON("", Int) = 0
		[Toggle]_MATCAP_ON("", Int) = 0
		[Toggle]_MATCAP_CUBEMAP_ON("", Int) = 0
		[Toggle]_WORLDSHADOWCOLOR_ON("", Int) = 0
		[Toggle]_MIXEDSHADOWCOLOR_ON("", Int) = 0
		
		
	}

	SubShader
	{


		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry" "IsEmissive" = "true"  }

		Cull [_Culling]
		ColorMask [_colormask]
		ZTest [_ZTest]
		ZWrite [_ZWrite]

		Stencil
		{
			Ref [_Stencil]
			ReadMask [_ReadMask]
			WriteMask [_WriteMask]
			Comp [_StencilComp]
			Pass [_StencilOp]
			Fail [_StencilFail]
			ZFail [_StencilZFail]
		}

		
		CGINCLUDE
		#define opaque
		#include "CGInc/XSToonBase.cginc"

		inline void LightingStandardCustomLighting_GI( inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi )
		{
			s.GIData = data;
		}

		void surf( Input i , inout SurfaceOutputCustomLightingCustom o )
		{
			o.SurfInput = i;
			o.Normal = float3(0,0,1);
		}

		ENDCG

		CGPROGRAM
		#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows nometa
		//#pragma shader_feature _ _ANISTROPIC_ON
		#pragma shader_feature _ _REFLECTIONS_ON
		// #pragma shader_feature _ _PBRREFL_ON _MATCAP_ON _MATCAP_CUBEMAP_ON
		// #pragma shader_feature _ _WORLDSHADOWCOLOR_ON _MIXEDSHADOWCOLOR_ON
		ENDCG

		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile XS_SHADOWCASTER_PASS
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "CGInc/XSShadowCaster.cginc"
			ENDCG
		}
		
		
		// Pass
		// {
		// 	Name "Outline"
		// 	Tags{ "LightMode"="ForwardBase" "IgnoreProjector" = "True" }
		// 	ZWrite Off
		// 	Cull Front
		// 	CGPROGRAM
		// 	#pragma vertex vert
		// 	#pragma fragment frag
		// 	#pragma target 3.0
		// 	#pragma multi_compile XS_OUTLINE_PASS
		// 	#include "CGInc/XSOutlinePass.cginc"
		// 	ENDCG
		// }
	}
	Fallback "Diffuse"
	CustomEditor "XSToonEditor"
}