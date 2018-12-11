using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System.Linq;
using System;

public class XSToonEditor : ShaderGUI
{

    public enum DisplayType
    {
        Basic,
        Advanced
    }


    // Styles for most options on the texture - shows name and mouseover description
    //public static GUIContent nameText = new GUIContent("name", "desc");
    private static class Styles
    {
        public static GUIContent mainText = new GUIContent("Main Options", "The main options for the Shader");
        public static GUIContent rampText = new GUIContent("Shadow Ramp", "Shadow ramp texture, horizontal or vertical, Black to White gradient that controls how shadows look - examples are included in the Shadow Ramps folder");
        public static GUIContent specMapText = new GUIContent("Specular Map", "Specular Map, This controls where the specular pattern can show. Should be a black and white image");
        public static GUIContent specPatternText = new GUIContent("Specular Pattern", "Specular Pattern, This is the pattern that shows in specular reflections. Control how much shows with the Smoothness and Intensity");
        public static GUIContent MainTexText = new GUIContent("Main Texture", "Main texture (RGB) and Transparency (A)");
        public static GUIContent normalText = new GUIContent("Normal Map", "Normal Map, used for controlling how light bends to fake small details, such as a cloth pattern");
        public static GUIContent emissText = new GUIContent("Emissive Map", "The texture used to control where emission happens, I recommend a black and white image, white for on, black for off");
        public static GUIContent simLightText = new GUIContent("Light Direction", "The fake lighting direction. This will only show if you disable all realtime lights in your scene. The shader detects if there is no realtime light, and uses this as a fake direction for lighting automatically");
        public static GUIContent SmoothnessText = new GUIContent("Glossiness", "How smooth the material is - this affects the size of the area that the pattern shows when reflecting light");
        public static GUIContent sintensityText = new GUIContent("Intensity", "The intensity of the specular reflections, higher is more visible");
        public static GUIContent stilingText = new GUIContent("Tiling", "The tiling of the specular reflection's pattern, used to make the pattern smaller or larger");
        public static GUIContent rimWidthText = new GUIContent("Rim Width", "The width of the rimlight, there is no catch-all value - you will probably need to figure out what works on a per model basis");
        public static GUIContent rimIntText = new GUIContent("Rim Intensity", "The intensity of the rimlight, this is how bright this rimlight is in comparison to the main texture");
        public static GUIContent rimLightTypeText = new GUIContent("Rim Style", "The style of rimlight, which is an edge light around the model in the lit up areas, sharp or smooth.");
        public static GUIContent cullingModeText = new GUIContent("Culling Mode", "Changes which side of the mesh is visible. Off is two-sided.");
        public static GUIContent cutoutText = new GUIContent("Cutout Amount", "This option only works on the 'Cutout' varient of the shader, and will do nothing on the others.");
        public static GUIContent advancedOptions = new GUIContent("Advanced Options", "This is where advanced options will go, anything that isn't part of the base experience, they are not for the faint of heart. Don't break anything :)");
        public static GUIContent MetalMap = new GUIContent("Metallic Map", "Black to white texture that defines areas that can be metallic, full white = full metallic, full black = no metallic, if you use this, set Metallic to 1");
        public static GUIContent roughMap = new GUIContent("Roughness Map", "Black to white texture that defines the roughness of the object white = 100% rough, black = 100% smooth. If you use this, set Roughness to 1");
        public static GUIContent bakedCube = new GUIContent("Baked Cubemap", "This is the cubemap that will be sampled for reflections if there are no reflection probes in the scene, if there are, the shader will sampler those instead.");
        public static GUIContent shadowTypeText = new GUIContent("Recieved Shadows", "Received Realtime Shadow style, sharp or smooth, match this up with your shadow ramp for optimal results.");
        public static GUIContent ReflMask = new GUIContent("Reflection Mask", "Mask for reflections, the same as the metallic mask, black to white image.");
        public static GUIContent StyleIntensity = new GUIContent("Intensity", "The intensity of the stylized reflection.");
        public static GUIContent Saturation = new GUIContent("Saturation", "Saturation of the main texture.");
        public static GUIContent Matcap = new GUIContent("Matcap Texture", "A matcap texture. These generally look like orbs with some sort of lighting on them. You can find some in 'Textures > Matcap' as examples.");
        public static GUIContent normalTiling = new GUIContent("Tiling", "Normal map tiling, adjust the X and Y to make the normals larger or smaller.");
        public static GUIContent MatcapCubemap = new GUIContent("Cubemap", "A Cubemap. If you've imported your own, make sure to check the import settings for it and set the 'Convolution' type to 'Glossy Reflection.'");
        public static GUIContent MatcapMask = new GUIContent("Mask", "The mask for the matcap. Black for off, white for on.");
        public static GUIContent detailNormal = new GUIContent("Detail Normal", "Detail Normals. These get blended on top of your regular normal for upclose detailing.");
        public static GUIContent detailMask = new GUIContent("Detail Mask", "Detail normal mask. Black to white, white = area with detail normals, black = area without. (This only affects the Detail Normal)");
        public static GUIContent occlusionMap = new GUIContent("Occlusion Map", "Occlusion map. Used to bake shadowing into areas through various methods. Black would be an area with forced shadows - white would be an area without.");
        public static GUIContent thicknessMap = new GUIContent("Thickness Map", "Used to show 'Thickness' in an area by stopping light from coming through. Black to white texture, Black means less light comes through. Only affects Subsurface Scattering.");
        public static GUIContent outlineTex = new GUIContent("Outline Masks", "The Outline Mask is used to control where the outlines can show, and the width of the outline. Setting this to fully black will make the outline completely gone, where fully white would be full width.");
    }

    void DoFooter()
    {
        GUILayout.Label(XSStyles.Styles.version, new GUIStyle(EditorStyles.centeredGreyMiniLabel)
        {
            alignment = TextAnchor.MiddleCenter,
            wordWrap = true,
            fontSize = 12
        });

        EditorGUILayout.BeginHorizontal();
        GUILayout.FlexibleSpace();
        XSStyles.discordButton(20, 20);
        GUILayout.Space(2);
        XSStyles.patreonButton(20, 20);
        XSStyles.githubButton(20, 20);
        GUILayout.FlexibleSpace();
        EditorGUILayout.EndHorizontal();
    }
    MaterialEditor m_MaterialEditor;
    MaterialProperty shadowRamp;
    MaterialProperty specMap;
    MaterialProperty specPattern;
    MaterialProperty tint;
    MaterialProperty mainTex;
    MaterialProperty normal;
    MaterialProperty specIntensity;
    MaterialProperty specArea;
    MaterialProperty rimWidth;
    MaterialProperty rimIntensity;
    MaterialProperty emissiveToggle;
    MaterialProperty emissiveTex;
    MaterialProperty emissiveColor;
    MaterialProperty advMode;
    MaterialProperty alphaCutoff;
    MaterialProperty culling;
    MaterialProperty rimStyle;
    MaterialProperty colorMask;
    MaterialProperty stencil;
    MaterialProperty stencilComp;
    MaterialProperty stencilOp;
    MaterialProperty stencilFail;
    MaterialProperty stencilZFail;
    MaterialProperty ztest;
    MaterialProperty zwrite;
    MaterialProperty reflSmooth;
    MaterialProperty metal;
    MaterialProperty metalMap;
    MaterialProperty roughMap;
    MaterialProperty bakedCube;
    MaterialProperty useRefl;
    MaterialProperty shadowType;
    MaterialProperty reflType;
    MaterialProperty saturation;
    MaterialProperty matcapStyle;
    MaterialProperty stylizedType;
    MaterialProperty rampColor;
    MaterialProperty rimColor;
    MaterialProperty aX;
    MaterialProperty aY;
    MaterialProperty specStyle;
    MaterialProperty detailNormal;
    MaterialProperty detailMask;
    MaterialProperty normalStrength;
	MaterialProperty detailNormalStrength;
    MaterialProperty occlusionMap;
    MaterialProperty occlusionStrength;
    MaterialProperty ThicknessMap;
    MaterialProperty SSSDist;
	MaterialProperty SSSPow;
    MaterialProperty SSSCol;
	MaterialProperty SSSIntensity;
	MaterialProperty invertThickness;
	MaterialProperty ThicknessMapPower;
    MaterialProperty UseSSS;
    MaterialProperty UseSpecular;
	MaterialProperty RampBaseAnchor;
    MaterialProperty UseUV2Emiss;
    MaterialProperty EmissScaleWithLight;
    MaterialProperty EmissTintToColor;
    MaterialProperty EmissionPower;
    MaterialProperty OutlineThickness;
    MaterialProperty OutlineColor;
    MaterialProperty OutlineTextureMap;
    MaterialProperty _AORAMPMODE_ON;
    MaterialProperty _OcclusionColor;
	MaterialProperty _DetailNormalUv2;
	MaterialProperty _NormalUv2;
	MaterialProperty _MetallicUv2;
	MaterialProperty _SpecularUv2;
	MaterialProperty _SpecularPatternUv2;
    MaterialProperty _AOUV2;

    public Texture ramp;

    //help buttons for editor
    public static GUISkin _xsSkin;
    public static string uiPath;
//    bool showHelp = false;
    bool outlined = false;
    private float oldSpec;

    static bool outlines = false;
    static bool normals = false;
    static bool shadows = false;
    static bool emission = false;
    static bool specular = false;
    static bool reflections = false;
    static bool subsurface = false;
    static bool advancedSettings = false;
    static bool rimlighting = false;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
        XSStyles.setupIcons();
        Material material = materialEditor.target as Material;
        {
            //Find all the properties within the shader
            shadowRamp = ShaderGUI.FindProperty("_ShadowRamp", props);
            specMap = ShaderGUI.FindProperty("_SpecularMap", props);
            specPattern = ShaderGUI.FindProperty("_SpecularPattern", props);
            tint = ShaderGUI.FindProperty("_Color", props);
            mainTex = ShaderGUI.FindProperty("_MainTex", props);
            normal = ShaderGUI.FindProperty("_Normal", props);
            specIntensity = ShaderGUI.FindProperty("_SpecularIntensity", props);
            specArea = ShaderGUI.FindProperty("_SpecularArea", props);
            rimWidth = ShaderGUI.FindProperty("_RimWidth", props);
            rimIntensity = ShaderGUI.FindProperty("_RimIntensity", props);
            emissiveToggle = ShaderGUI.FindProperty("_Emissive", props);
            emissiveTex = ShaderGUI.FindProperty("_EmissiveTex", props);
            emissiveColor = ShaderGUI.FindProperty("_EmissiveColor", props);
            alphaCutoff = ShaderGUI.FindProperty("_Cutoff", props);
            culling = ShaderGUI.FindProperty("_Culling", props);
            rimStyle = ShaderGUI.FindProperty("_RimlightType", props);
            advMode = ShaderGUI.FindProperty("_advMode", props);
            reflSmooth = ShaderGUI.FindProperty("_ReflSmoothness", props);
            metal = ShaderGUI.FindProperty("_Metallic", props);
            metalMap = ShaderGUI.FindProperty("_MetallicMap", props);
            roughMap = ShaderGUI.FindProperty("_RoughMap", props);
            bakedCube = ShaderGUI.FindProperty("_BakedCube", props);
            shadowType = ShaderGUI.FindProperty("_ShadowType", props);
            reflType = ShaderGUI.FindProperty("_ReflType", props);
            saturation = ShaderGUI.FindProperty("_Saturation", props);
            useRefl = ShaderGUI.FindProperty("_UseReflections", props);
            matcapStyle = ShaderGUI.FindProperty("_MatcapStyle", props);
            stylizedType = ShaderGUI.FindProperty("_StylizedReflStyle", props);
            rampColor = ShaderGUI.FindProperty("_RampColor", props);
            rimColor = ShaderGUI.FindProperty("_RimColor", props);
            aX = ShaderGUI.FindProperty("_anistropicAX", props);
            aY = ShaderGUI.FindProperty("_anistropicAY", props);
            specStyle = ShaderGUI.FindProperty("_SpecularStyle", props);
            detailNormal = ShaderGUI.FindProperty("_DetailNormal", props);
            detailMask = ShaderGUI.FindProperty("_DetailMask", props);
            normalStrength = ShaderGUI.FindProperty("_NormalStrength", props);
            detailNormalStrength = ShaderGUI.FindProperty("_DetailNormalStrength", props);
            occlusionMap = ShaderGUI.FindProperty("_OcclusionMap", props);
            occlusionStrength = ShaderGUI.FindProperty("_OcclusionStrength", props);
            ThicknessMap = ShaderGUI.FindProperty("_ThicknessMap", props); 
            SSSDist = ShaderGUI.FindProperty("_SSSDist", props);
            SSSPow = ShaderGUI.FindProperty("_SSSPow", props);
            SSSIntensity = ShaderGUI.FindProperty("_SSSIntensity", props);
            SSSCol = ShaderGUI.FindProperty("_SSSCol", props);
            invertThickness = ShaderGUI.FindProperty("_invertThickness", props);
            ThicknessMapPower = ShaderGUI.FindProperty("_ThicknessMapPower", props);
            UseSSS = ShaderGUI.FindProperty("_UseSSS", props); 
            UseSpecular = ShaderGUI.FindProperty("_UseSpecular", props);
            UseUV2Emiss = ShaderGUI.FindProperty("_EmissUv2", props);
            EmissScaleWithLight = ShaderGUI.FindProperty("_ScaleWithLight", props);
            EmissTintToColor = ShaderGUI.FindProperty("_EmissTintToColor", props);
            EmissionPower = ShaderGUI.FindProperty("_EmissionPower", props);
            if (material.shader == Shader.Find("Xiexe/Toon/XSToonCutoutOutlined") || material.shader == Shader.Find("Xiexe/Toon/XSToonOutlined"))
            {
                OutlineColor = ShaderGUI.FindProperty("_OutlineColor", props);
                OutlineThickness = ShaderGUI.FindProperty("_OutlineThickness", props);
                OutlineTextureMap = ShaderGUI.FindProperty("_OutlineTextureMap", props);
                outlined = true;      
            }
            else 
            {
                outlined = false;
                outlines = false;
            }
            _AORAMPMODE_ON = ShaderGUI.FindProperty("_AORAMPMODE_ON", props);
            _OcclusionColor = ShaderGUI.FindProperty("_OcclusionColor", props);

            _DetailNormalUv2 = ShaderGUI.FindProperty("_DetailNormalUv2", props);
            _NormalUv2 = ShaderGUI.FindProperty("_NormalUv2", props);
            _MetallicUv2 = ShaderGUI.FindProperty("_MetallicUv2", props);
            _SpecularUv2 = ShaderGUI.FindProperty("_SpecularUv2", props);
            _SpecularPatternUv2 = ShaderGUI.FindProperty("_SpecularPatternUv2", props);
            _AOUV2 = ShaderGUI.FindProperty("_AOUV2", props);

            //advanced options
            colorMask = ShaderGUI.FindProperty("_colormask", props);
            stencil = ShaderGUI.FindProperty("_Stencil", props);
            stencilComp = ShaderGUI.FindProperty("_StencilComp", props);
            stencilOp = ShaderGUI.FindProperty("_StencilOp", props);
            stencilFail = ShaderGUI.FindProperty("_StencilFail", props);
            stencilZFail = ShaderGUI.FindProperty("_StencilZFail", props);
            zwrite = ShaderGUI.FindProperty("_ZWrite", props);
            ztest = ShaderGUI.FindProperty("_ZTest", props);

            RampBaseAnchor = ShaderGUI.FindProperty("_RampBaseAnchor", props);

            //Show Properties in Inspector
            //materialEditor.ShaderProperty(, .displayName);   

            EditorGUI.BeginChangeCheck();
            {

                EditorGUI.BeginChangeCheck();

                EditorGUI.showMixedValue = advMode.hasMixedValue;
                var aMode = (DisplayType)advMode.floatValue;

                EditorGUI.BeginChangeCheck();
                aMode = (DisplayType)EditorGUILayout.Popup("Shader Mode", (int)aMode, Enum.GetNames(typeof(DisplayType)));

                if (EditorGUI.EndChangeCheck())
                {
                    materialEditor.RegisterPropertyChangeUndo("Shader Mode");
                    advMode.floatValue = (float)aMode;
                    EditorGUI.showMixedValue = false;
                }

                materialEditor.ShaderProperty(culling, culling.displayName);

                //main
                    //Rect rect = (0,0);
                    XSStyles.Separator();
                    EditorGUILayout.BeginHorizontal();
                        materialEditor.TexturePropertySingleLine(Styles.MainTexText, mainTex, tint);
                        XSStyles.helpPopup(XSStyles.mainURL);
                    EditorGUILayout.EndHorizontal();
                    GUI.skin = null;
                        materialEditor.ShaderProperty(saturation, Styles.Saturation, 3);

                       
                //cutoff
                    if (material.shader == Shader.Find("Xiexe/Toon/XSToonCutout") || material.shader == Shader.Find("Xiexe/Toon/XSToonCutoutOutlined"))
                    {
                        materialEditor.ShaderProperty(alphaCutoff, Styles.cutoutText);
                    }
                //-----
                
                //outlines
                if(outlined == true)
                { 
                    XSStyles.Separator();
                    EditorGUILayout.BeginHorizontal();
                        outlines = EditorGUILayout.Foldout(outlines, "OUTLINES", true);
                        XSStyles.helpPopup(XSStyles.outlineURL);
                    EditorGUILayout.EndHorizontal();
                    GUI.skin = null;                    
                    if (outlines)
                    {
                        XSStyles.SeparatorThin();
                        materialEditor.TexturePropertySingleLine(Styles.outlineTex, OutlineTextureMap);
                        materialEditor.ShaderProperty(OutlineColor, "Outline Color");
                        materialEditor.ShaderProperty(OutlineThickness, "Outline Scale");
                    }
                }  
                //-----

                //normal map
                    XSStyles.Separator();
                    EditorGUILayout.BeginHorizontal();
                        normals = EditorGUILayout.Foldout(normals, "NORMAL MAPS", true);  
                        XSStyles.helpPopup(XSStyles.normalsURL);
                    EditorGUILayout.EndHorizontal();
                    GUI.skin = null;
                    if(normals)
                    {
                        XSStyles.SeparatorThin();
                        materialEditor.TexturePropertySingleLine(Styles.normalText, normal, normalStrength);
                        materialEditor.TextureScaleOffsetProperty(normal);
                        materialEditor.TexturePropertySingleLine(Styles.detailNormal, detailNormal, detailNormalStrength);
                        materialEditor.TextureScaleOffsetProperty(detailNormal);
                        materialEditor.TexturePropertySingleLine(Styles.detailMask, detailMask);
                        materialEditor.ShaderProperty(_NormalUv2, "Normal UV");
                        materialEditor.ShaderProperty(_DetailNormalUv2, "Detail UV");
                    }
                //-----
                
                //shadows
                    XSStyles.Separator();
                    EditorGUILayout.BeginHorizontal();
                        shadows = EditorGUILayout.Foldout(shadows, "SHADOWS", true); 
                        XSStyles.helpPopup(XSStyles.shadowsURL);
                    EditorGUILayout.EndHorizontal();
                    GUI.skin = null;
                    if(shadows)
                    {
                        XSStyles.SeparatorThin();
                        materialEditor.TexturePropertySingleLine(Styles.rampText, shadowRamp);
                        materialEditor.ShaderProperty(rampColor, "Ramp Mode", 2);
                        materialEditor.ShaderProperty(shadowType, Styles.shadowTypeText, 2);
                        materialEditor.TexturePropertySingleLine(Styles.occlusionMap, occlusionMap); 
                        materialEditor.ShaderProperty(_AORAMPMODE_ON, "AO Style", 2);
                        
                        if ( material.GetTexture("_OcclusionMap") && _AORAMPMODE_ON.floatValue == 1 )
                           materialEditor.ShaderProperty(occlusionStrength, "Strength", 3);
                        else
                            material.SetFloat("_OcclusionStrength", 1);

                        if(_AORAMPMODE_ON.floatValue == 0)
                            materialEditor.ShaderProperty(_OcclusionColor, "AO Color", 2);

                        materialEditor.ShaderProperty(_AOUV2, "Occlusion UV");                
                        
                        XSStyles.callGradientEditor();
                    }
                    //ambient
                        //ramp
                        //mixed
                        if (rampColor.floatValue == 0)
                        {
                            material.SetFloat("_WORLDSHADOWCOLOR_ON", 1);
                            material.SetFloat("_MIXEDSHADOWCOLOR_ON", 0);
                        }
                        if (rampColor.floatValue == 1)
                        {
                            material.SetFloat("_WORLDSHADOWCOLOR_ON", 0);
                            material.SetFloat("_MIXEDSHADOWCOLOR_ON", 0);
                        }
                        if(rampColor.floatValue == 2)
                        {
                            material.SetFloat("_WORLDSHADOWCOLOR_ON", 0);
                            material.SetFloat("_MIXEDSHADOWCOLOR_ON", 1);
                        }
                //-----  

                //Rimlighting
                    XSStyles.Separator();
                            EditorGUILayout.BeginHorizontal();
                            rimlighting = EditorGUILayout.Foldout(rimlighting, "RIMLIGHT", true); 
                            XSStyles.helpPopup(XSStyles.rimlightURL);
                        EditorGUILayout.EndHorizontal();
                        GUI.skin = null;
                        if(rimlighting)
                            {
                                XSStyles.SeparatorThin();
                                materialEditor.ShaderProperty(rimStyle, Styles.rimLightTypeText);

                            if (rimStyle.floatValue == 0)
                            {
                                materialEditor.ShaderProperty(rimWidth, Styles.rimWidthText, 2);
                                materialEditor.ShaderProperty(rimIntensity, Styles.rimIntText, 2);
                                materialEditor.ShaderProperty(rimColor, "Rimlight Tint", 2);
                            }

                            if (rimStyle.floatValue == 1)
                            {
                                materialEditor.ShaderProperty(rimWidth, Styles.rimWidthText, 2);
                                materialEditor.ShaderProperty(rimIntensity, Styles.rimIntText, 2);
                                materialEditor.ShaderProperty(rimColor, "Rimlight Tint", 2);
                            }

                            if (rimStyle.floatValue == 2)
                        {
                            material.SetFloat("_RimIntensity", 0);
                        }
                    }
                //----

                //emission
                    XSStyles.Separator();
                        EditorGUILayout.BeginHorizontal();
                        emission = EditorGUILayout.Foldout(emission, "EMISSION", true); 
                        XSStyles.helpPopup(XSStyles.emissionsURL);
                    EditorGUILayout.EndHorizontal();
                    GUI.skin = null;
                    if(emission)
                    {
                        XSStyles.SeparatorThin();
                        materialEditor.ShaderProperty(emissiveToggle, "Emission");
                        if (emissiveToggle.floatValue == 0)
                        {
                            materialEditor.TexturePropertySingleLine(Styles.emissText, emissiveTex, emissiveColor);
                            materialEditor.ShaderProperty(EmissTintToColor, "Tint To Diffuse");
                            materialEditor.ShaderProperty(EmissScaleWithLight, "Scale With Light");
                            if(EmissScaleWithLight.floatValue == 0){
                                materialEditor.ShaderProperty(EmissionPower, "Threshold", 2);
                            }
                            materialEditor.ShaderProperty(UseUV2Emiss, "Emission UV");
                        }
                        else
                        {
                            material.SetColor("_EmissiveColor", Color.black);
                        }
                    }
                //-----

                //specular
                    XSStyles.Separator();
                    EditorGUILayout.BeginHorizontal();
                        specular = EditorGUILayout.Foldout(specular, "SPECULAR", true); 
                        XSStyles.helpPopup(XSStyles.specularURL);
                    EditorGUILayout.EndHorizontal();
                        EditorGUI.BeginChangeCheck();
                    if(specular)
                    {
                        XSStyles.SeparatorThin();
                        materialEditor.ShaderProperty(UseSpecular, "Specular");
                        if (UseSpecular.floatValue == 0)
                        {    
                                materialEditor.TexturePropertySingleLine(Styles.specMapText, specMap);
                            GUI.skin = null;
                                materialEditor.TextureScaleOffsetProperty(specMap);
                                materialEditor.TexturePropertySingleLine(Styles.specPatternText, specPattern);
                                materialEditor.TextureScaleOffsetProperty(specPattern);
                                materialEditor.ShaderProperty(stylizedType, "Specular Type");
                                materialEditor.ShaderProperty(specStyle, "Specular Style");
                            if (stylizedType.floatValue == 1)
                            {
                                material.SetFloat("_ANISTROPIC_ON", 1);
                                materialEditor.ShaderProperty(aX, "Length", 3);
                                materialEditor.ShaderProperty(aY, "Width", 3);
                            }
                            else
                            {
                                material.SetFloat("_ANISTROPIC_ON", 0);
                                materialEditor.ShaderProperty(specArea, Styles.SmoothnessText, 3);
                            }
                            materialEditor.ShaderProperty(specIntensity, Styles.sintensityText, 3);
                            materialEditor.ShaderProperty(_SpecularUv2,"Specular UV");
                            materialEditor.ShaderProperty(_SpecularPatternUv2,"Pattern UV");    
                        }
                        else
                        {
                            material.SetFloat("_SpecularIntensity", 0);
                        }
                    }
                //-----

                //metallic
                    XSStyles.Separator();
                        EditorGUILayout.BeginHorizontal();
                        reflections = EditorGUILayout.Foldout(reflections, "REFLECTIONS", true); 
                        XSStyles.helpPopup(XSStyles.reflURL);
                    EditorGUILayout.EndHorizontal();
                    GUI.skin = null;
                    if(reflections)
                    {
                        XSStyles.SeparatorThin();
                        materialEditor.ShaderProperty(useRefl, "Reflections");
                        if (useRefl.floatValue == 0)
                        {
                            materialEditor.ShaderProperty(reflType, "Reflection Style");
                            material.EnableKeyword("_REFLECTIONS_ON");
                            //pbr
                            if (reflType.floatValue == 0)
                            {
                                materialEditor.TexturePropertySingleLine(Styles.bakedCube, bakedCube);
                                material.SetFloat("_PBRREFL_ON", 1);
                                material.SetFloat("_MATCAP_ON", 0);
                                material.SetFloat("_MATCAP_CUBEMAP_ON", 0);
                                materialEditor.TexturePropertySingleLine(Styles.MetalMap, metalMap);

                                if(!material.GetTexture("_MetallicMap")) 
                                    materialEditor.ShaderProperty(metal, "Metallic", 2);
                                else 
                                    material.SetFloat("_Metallic", 1);
                                
                                materialEditor.ShaderProperty(reflSmooth, "Smoothness", 2);
                                materialEditor.ShaderProperty(_MetallicUv2, "Metal/Rough UV");
                            }
                            //matcap
                            if (reflType.floatValue == 1)
                            {
                                material.SetFloat("_MATCAP_ON", 1);
                                material.SetFloat("_MATCAP_CUBEMAP_ON", 0);
                                material.SetFloat("_PBRREFL_ON", 0);
                                materialEditor.ShaderProperty(matcapStyle, "Blend Mode");
                                materialEditor.TexturePropertySingleLine(Styles.Matcap, metalMap);
                                materialEditor.TexturePropertySingleLine(Styles.MatcapMask, roughMap);
                                materialEditor.ShaderProperty(metal, "Intensity", 2);
                                materialEditor.ShaderProperty(reflSmooth, "Blur", 2);
                            }
                            //bakedcubemap
                            if (reflType.floatValue == 2)
                            {
                                material.SetFloat("_MATCAP_CUBEMAP_ON", 1);
                                material.SetFloat("_MATCAP_ON", 0);
                                material.SetFloat("_PBRREFL_ON", 0);
                                materialEditor.TexturePropertySingleLine(Styles.bakedCube, bakedCube);
                                materialEditor.TexturePropertySingleLine(Styles.MetalMap, metalMap);

                                if(!material.GetTexture("_MetallicMap")) 
                                    materialEditor.ShaderProperty(metal, "Metallic", 2);
                                else 
                                    material.SetFloat("_Metallic", 1);
                                
                                materialEditor.ShaderProperty(reflSmooth, "Smoothness", 2);
                                materialEditor.ShaderProperty(_MetallicUv2, "UVSet");
                            }
                        }
                        else
                        {
                            material.DisableKeyword("_REFLECTIONS_ON");
                            material.SetFloat("_PBRREFL_ON", 0);
                            material.SetFloat("_MATCAP_ON", 0);
                            material.SetFloat("_MATCAP_CUBEMAP_ON", 0);
                        }
                    }
                //-----

                //Subsurface Scattering
                XSStyles.Separator();
                    EditorGUILayout.BeginHorizontal();
                        subsurface = EditorGUILayout.Foldout(subsurface, "SUBSURFACE SCATTERING", true); 
                        XSStyles.helpPopup(XSStyles.sssURL);
                        GUI.skin = null;
                    EditorGUILayout.EndHorizontal();
                    if(subsurface)
                    {
                        XSStyles.SeparatorThin();
                        materialEditor.ShaderProperty(UseSSS, "Subsurface Scattering");
                        if(UseSSS.floatValue == 0)
                        {
                            materialEditor.TexturePropertySingleLine(Styles.thicknessMap, ThicknessMap);
                            materialEditor.ShaderProperty(invertThickness, "Invert", 3);
                            materialEditor.ShaderProperty(ThicknessMapPower, "Power", 3);
                            materialEditor.ShaderProperty(SSSCol, "Subsurface Color", 2);
                            materialEditor.ShaderProperty(SSSDist, "Displacement",2);
                            materialEditor.ShaderProperty(SSSPow, "Sharpness",2);
                            materialEditor.ShaderProperty(SSSIntensity, "Intensity",2);
                        }
                        else
                        {
                            material.SetFloat("_SSSIntensity", 0);
                        } 
                    }
                    else
                    {
                        if(UseSSS.floatValue == 1)
                            material.SetFloat("_SSSIntensity", 0);
                    }
                //-----



                GUI.skin = null;
                if (advMode.floatValue == 1)
                {
                     XSStyles.Separator();
                    advancedSettings = EditorGUILayout.Foldout(advancedSettings, "ADVANCED SETTINGS", true); 
                    if(advancedSettings)
                    {
                        XSStyles.SeparatorThin();
                        // GUILayout.Label(Styles.advancedOptions, EditorStyles.boldLabel);
                        //Stencil
                        GUILayout.Label("Stencil Buffer", EditorStyles.boldLabel);
                        materialEditor.ShaderProperty(colorMask, colorMask.displayName, 2);
                        materialEditor.ShaderProperty(stencil, stencil.displayName, 2);
                        materialEditor.ShaderProperty(stencilComp, stencilComp.displayName, 2);
                        materialEditor.ShaderProperty(stencilOp, stencilOp.displayName, 2);
                        materialEditor.ShaderProperty(stencilFail, stencilFail.displayName, 2);
                        materialEditor.ShaderProperty(stencilZFail, stencilZFail.displayName, 2);
                        materialEditor.ShaderProperty(ztest, ztest.displayName, 2);
                        materialEditor.ShaderProperty(zwrite, zwrite.displayName, 2);
                        materialEditor.ShaderProperty(RampBaseAnchor, "Ramp Anchor", 2);
                        
                            // Reset ZWrite/ZTest
                        XSStyles.ResetAdv(material);
                        XSStyles.ResetAdvAll(material);
                    }
                }
                if(advMode.floatValue == 0)
                    XSStyles.CallResetAdv(material);
            }
        }
        DoFooter();
    }
    public static void SetShadowRamp(MaterialProperty shadowRamp, Texture ramp)
    {
        ramp = XSGradientEditor.shadowRamp;
        shadowRamp.textureValue = ramp;
    }
}

