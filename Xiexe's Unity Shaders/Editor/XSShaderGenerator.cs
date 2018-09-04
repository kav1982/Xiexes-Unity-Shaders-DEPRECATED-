using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using System.IO;
using System.Text;
using System.Linq;

public class XSShaderGenerator : EditorWindow
{

    [MenuItem("Xiexe/Tools/Shader Generator")]
    public static void ShowWindow()
    {
        XSShaderGenerator window = EditorWindow.GetWindow<XSShaderGenerator>(true, "XSToon: Shader Generator", true);
		window.minSize = new Vector2(350f, 300f);
		window.maxSize = new Vector2(350f, 300f);
    }
	
	//partial paths for generating temp and final shader finals, 
	//we add on to these later as needed after reverse engineering where our folder is located on disk.
	private static string destFile = "/Main/";
	private static string finalPath = "/Main/";
	private static string temp = "/Editor/Templates/XSBaseShaderTemplate.txt";

//Set up variables for later use.
	//Names Var
	private static string cutoutName = "XSToonCutout";
	private static string transparentName = "XSToonTransparent";
	private static string transparentShadowedName = "XSToonTransparentShadowed";
	private static string transparentFadeName = "XSToonFade";
	private static string transparentFadeShadowedName = "XSToonFadeShadowed";
	private static string transparentDitheredName = "XSToonTransparentDithered";

	//Strings for Name
	private static string cutoutStringName = "Shader \"Xiexe/Toon/XSToonCutout\"";
	private static string transparentStringName = "Shader \"Xiexe/Toon/XSToonTransparent\"";
	private static string transparentShadowedStringName = "Shader \"Xiexe/Toon/XSToonTransparentShadowed\"";
	private static string transparentFadeStringName = "Shader \"Xiexe/Toon/XSToonFade\"";
	private static string transparentFadeShadowedStringName = "Shader \"Xiexe/Toon/XSToonFadeShadowed\"";
	private static string transparentDitheredStringName = "Shader \"Xiexe/Toon/XSToonTransparentDithered\"";
	
	//Strings for Tags
	private static string cutoutTags = "	Tags{ \"RenderType\" = \"TransparentCutout\"  \"Queue\" = \"AlphaTest\" \"IsEmissive\" = \"true\"}";
	private static string transparentTags = "	Tags{ \"RenderType\" = \"Transparent\"  \"Queue\" = \"Transparent\" \"IsEmissive\" = \"true\"}";
	private static string transparentShadowedTags = "	Tags{ \"RenderType\" = \"Transparent\"  \"Queue\" = \"AlphaTest+50\" \"IsEmissive\" = \"true\"}";
	private static string transparentFadeTags = "	Tags{ \"RenderType\" = \"Transparent\"  \"Queue\" = \"Transparent\" \"IsEmissive\" = \"true\"}";
	private static string transparentFadeShadowedTags = "	Tags{ \"RenderType\" = \"Transparent\"  \"Queue\" = \"AlphaTest+50\" \"IsEmissive\" = \"true\"}";
	private static string transparentDitheredTags = "	Tags{ \"RenderType\" = \"TransparentCutout\"  \"Queue\" = \"AlphaTest\" \"IsEmissive\" = \"true\"}";

	//Strings for RenderMode
	private static string cutoutRender = "	#define cutout";
	private static string transparentRender = "	#define alphablend";
	private static string transparentShadowedRender =  "	#define alphablend";
	private static string transparentFadeRender =  "	#define alphablend";
	private static string transparentFadeShadowedRender =  "	#define alphablend";
	private static string transparentDitheredRender = "	#define dithered";

	//Strings for Fallback
	private static string cutoutFallback = "	Fallback \"Transparent/Cutout/Diffuse\"";
	private static string transparentFallback = "	Fallback \"Transparent/Diffuse\"";
	private static string transparentShadowedFallback = "	Fallback \"Transparent/Diffuse\"";
	private static string transparentFadeFallback = "	Fallback \"Transparent/Diffuse\"";
	private static string transparentFadeShadowedFallback = "	Fallback \"Transparent/Diffuse\"";
	private static string transparentDitheredFallback = "	Fallback \"Transparent/Cutout/Diffuse\"";

	//Strings for Pragma
	private static string cutoutPragma = "	#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows nometa";
	private static string transparentPragma = "	#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows nometa";
	private static string transparentShadowedPragma = "	#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows nometa";
	private static string transparentFadePragma = "	#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows nometa alpha:fade";
	private static string transparentFadeShadowedPragma= "	#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows nometa alpha:fade";
	private static string transparentDitheredPragma = "	#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows nometa";
	
	//Strings for Blend
	private static string cutoutBlend = "";
	private static string transparentBlend = "Blend One OneMinusSrcAlpha";
	private static string transparentShadowedBlend = "Blend One OneMinusSrcAlpha";
	private static string transparentFadeBlend = "Blend One OneMinusSrcAlpha";
	private static string transparentFadeShadowedBlend = "Blend One OneMinusSrcAlpha";
	private static string transparentDitheredBlend = "";

	//Set up Search tags for later use.
	private static string searchForName = "!name";
	private static string searchForTags = "!shadertags";
	private static string searchForRender = "!definerendermode";
	private static string searchForFallback = "!fallback";
	private static string searchForPragma = "!pragma";
	private static string searchForBlend = "!blend";

	//set up toggles for different variants
	private static bool cutout = false;
	private static bool transparent = false;
	private static bool transparentShadowed = false;
	private static bool transparentFade = false;
	private static bool transparentFadeShadowed = false;
	private static bool transparentDithered = false;

    void OnGUI()
    {	
		EditorGUI.BeginChangeCheck();
		XSStyles.DoHeader(XSStyles.Styles.version);
		XSStyles.doLabel("This generator will generate the chosen variants of the shader - this process could take awhile, and may seem to freeze Unity. It's not frozen, it's actually compiling the shaders. Sorry for the compile times!");

		XSStyles.Separator();
		XSStyles.doLabel("Generate Variants");
			cutout = GUILayout.Toggle(cutout, "Cutout");
			transparent = GUILayout.Toggle(transparent, "Transparent");
			transparentShadowed = GUILayout.Toggle(transparentShadowed, "Transparent Shadowed");
			transparentFade = GUILayout.Toggle(transparentFade, "Transparent Fade");
			transparentFadeShadowed = GUILayout.Toggle(transparentFadeShadowed, "Transparent Fade Shadowed");
			transparentDithered = GUILayout.Toggle(transparentDithered, "Transparent Dithered");
		
		EditorGUILayout.Space();
		EditorGUILayout.Space();

		if (GUILayout.Button("Generate Shader(s)")){
			GetPathOfFolder(cutout, transparent, transparentShadowed, transparentFade, transparentFadeShadowed, transparentDithered);
			Debug.Log("Generated Shader(s)");
		}
		
		// //THE BIG BAD DEBUGGIN BUTTON
		// if (GUILayout.Button("POPUP")){
		// 	GetPathOfFolder(finalFilePath, cutout, transparent, transparentShadowed, transparentFade, transparentFadeShadowed, transparentDithered);
		// }
    }

//Get the folder path of the root of my shader packages - we do this by finding a known uniwue file, in this case our generator, and then stepping back the known amount of folders, in this case, 2.
//we then call the create function with our final root path in mind. 
	static void GetPathOfFolder(bool cutout, bool transparent, bool transparentShadowed, bool transparentFade, bool transparentFadeShadowed, bool transparentDithered)
	{

		string[] guids1 = AssetDatabase.FindAssets("XSShaderGenerator", null);
		string untouchedString = AssetDatabase.GUIDToAssetPath(guids1[0]);
      	string[] splitString = untouchedString.Split('/');

		ArrayUtility.RemoveAt(ref splitString, splitString.Length - 1);
		ArrayUtility.RemoveAt(ref splitString, splitString.Length - 1);
		
		string finalFilePath = string.Join("/", splitString);
		CheckForShader(finalFilePath, cutout, transparent, transparentShadowed, transparentFade, transparentFadeShadowed, transparentDithered);
	}

//After getting the path of our folders, we need to check to see if the shader already exists - if it does, we need to do a popup
//That asks if you want to overwrite it, or not. 
	static void CheckForShader(string finalFilePath, bool cutout, bool transparent, bool transparentShadowed, bool transparentFade, bool transparentFadeShadowed, bool transparentDithered)
	{
		string shaderPath = finalFilePath + destFile;
		string[] existingShaders = {};
		
		int existsBox = 0;

		if (File.Exists(shaderPath + "XSToonCutout.shader") && cutout == true){
			ArrayUtility.Add(ref existingShaders, "XSToonCutout");
			existsBox = 1;
		}

		if (File.Exists(shaderPath + "XSToonTransparent.shader") && transparent == true){
			ArrayUtility.Add(ref existingShaders, "XSToonTransparent");
			existsBox = 1;
		}

		if (File.Exists(shaderPath + "XSToonTransparentShadowed.shader") && transparentShadowed == true){
			ArrayUtility.Add(ref existingShaders, "XSToonTransparentShadowed");
			existsBox = 1;
		}

		if (File.Exists(shaderPath + "XSToonFade.shader") && transparentFade == true){
			ArrayUtility.Add(ref existingShaders, "XSToonFade");
			existsBox = 1;
		}
		if (File.Exists(shaderPath + "XSToonFadeShadowed.shader") && transparentFadeShadowed == true){
			ArrayUtility.Add(ref existingShaders, "XSToonFadeShadowed");
			existsBox = 1;
		}
		if (File.Exists(shaderPath + "XSToonTransparentDithered.shader") && transparentDithered == true){
			ArrayUtility.Add(ref existingShaders, "XSToonTransparentDithered");
			existsBox = 1;
		}

		string joined = "\n\n - " + string.Join(", ", existingShaders);
		
		if(existsBox == 0){
			Create(finalFilePath);
		}
		else if(existsBox == 1) {
			bool option = EditorUtility.DisplayDialog("Replace Shaders?",
					"One or more of the selected Shaders already exist! Are you sure you want to overwrite them?" + joined
					, "Do it!", "Don't do it!");
			
			switch (option)
			{
				case true:
					Debug.Log("Continue To Generate");
						for (int i = 0; i < existingShaders.Length; i++)
						{
							File.Delete(shaderPath + existingShaders[i] + ".shader");
						}
					Create(finalFilePath);
					break;
				
				case false: 
					Debug.Log("Cancelled Generation");
					break;
				
				default:
					Debug.LogError("Unrecognized option.");
					break;
				}
			}
		}
//In the create function we pass on the file path and we check to see which shaders are to be created, and run the function for each one that's been checked off.
	static void Create(string finalFilePath)
		{
			int index;
			if(cutout == true){
				index = 0;
				WriteShader(finalFilePath, index);
				Debug.Log("Generate Cutout");
			}
			if(transparent == true){
				index = 1;
				WriteShader(finalFilePath, index);
				Debug.Log("Generate Transparent");
			}
			if(transparentShadowed == true){
				index = 2;
				WriteShader(finalFilePath, index);
				Debug.Log("Generate Transparent w/ Shadows");
			}
			if(transparentFade == true){
				index = 3;
				WriteShader(finalFilePath, index);
				Debug.Log("Generate Transparent Fade");
			}
			if(transparentFadeShadowed == true){
				index = 4;
				WriteShader(finalFilePath, index);
				Debug.Log("Generate Transparent Fade w/ Shadows");
			}
			if(transparentDithered == true){
				index = 5;
				WriteShader(finalFilePath, index);
				Debug.Log("Generate Dithered");
			}
		}


//Here we do all the creating, passing in all of the things we need, such as the file path. 
	static void WriteShader(string finalFilePath, int index)
	{
		
		string[] lines = File.ReadAllLines(finalFilePath + temp);
		
		string[] chosenShaderName = {cutoutName, transparentName, 
								transparentShadowedName, transparentFadeName, 
								transparentFadeShadowedName, transparentDitheredName
								};

		string[] chosenShaderStringName = {cutoutStringName, transparentStringName, 
								transparentShadowedStringName, transparentFadeStringName, 
								transparentFadeShadowedStringName, transparentDitheredStringName
								};

		string[] chosenShaderTags = {cutoutTags, transparentTags,
								transparentShadowedTags, transparentFadeTags,
								transparentFadeShadowedTags, transparentDitheredTags
								};

		string[] chosenShaderRender = {cutoutRender, transparentRender,
								transparentShadowedRender, transparentFadeRender,
								transparentFadeShadowedRender, transparentDitheredRender
								};

		string[] chosenShaderFallback = {cutoutFallback, transparentFallback,
								transparentShadowedFallback, transparentFadeFallback,
								transparentFadeShadowedFallback, transparentDitheredFallback
								};
		
		string[] chosenShaderBlend = {cutoutBlend, transparentBlend,
								transparentShadowedBlend, transparentFadeBlend,
								transparentFadeShadowedBlend, transparentDitheredBlend
								};
		
		string[] chosenShaderPragma = {cutoutPragma, transparentPragma,
								transparentShadowedPragma, transparentFadePragma,
								transparentFadeShadowedPragma, transparentDitheredPragma
								};

		string name = chosenShaderName[index];
		string dest = finalFilePath + destFile + name + ".txt";
		string final = finalFilePath + finalPath + name + ".shader";
 

		StreamWriter writer = new StreamWriter(dest, true);
			for (int i = 0; i < lines.Length; i++)
				{
					if (lines[i].Contains(searchForName))
					{
						writer.WriteLine(chosenShaderStringName[index].ToString());
					}
					else if (lines[i].Contains(searchForTags))
					{
						writer.WriteLine(chosenShaderTags[index].ToString());
					}
					else if (lines[i].Contains(searchForRender))
					{
						writer.WriteLine(chosenShaderRender[index].ToString());
					}
					else if (lines[i].Contains(searchForFallback))
					{
						writer.WriteLine(chosenShaderFallback[index].ToString());
					}
					else if (lines[i].Contains(searchForBlend))
					{
						writer.WriteLine(chosenShaderBlend[index].ToString());
					}
					else if (lines[i].Contains(searchForPragma))
					{
						writer.WriteLine(chosenShaderPragma[index].ToString());
					}
					else{
						writer.WriteLine(lines[i]);
					}
				}
		writer.Close();
		ConvertToShader(dest, final, name);
	}

//Now that we've created our shader as a .txt, we need to convert it to a .shader file. 
//This is kind of hacky, but "moving" it to the same folder and changing the extension works. 
//As far as I could find, there was no other efficient way to just change the file extension.
	static void ConvertToShader(string dest, string final, string name)
	{
		FileUtil.MoveFileOrDirectory(dest, final);
		AssetDatabase.ImportAsset(final);
	}
}
