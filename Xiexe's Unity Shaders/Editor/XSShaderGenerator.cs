using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using System.IO;
using System.Text;

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
		

		EditorGUILayout.Space();
		EditorGUILayout.Space();

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
			GetPathOfFolder();
			Debug.Log("Generated Shader(s)");
		}
		
		// //THE BIG BAD DEBUGGIN BUTTON
		// if (GUILayout.Button("FindPathDebug")){
		// 	GetPathOfFolder();
		// }
    }

//Get the folder path of the root of my shader packages - we do this by finding a known uniwue file, in this case our generator, and then stepping back the known amount of folders, in this case, 2.
//we then call the create function with our final root path in mind. 
	static void GetPathOfFolder(){

		string[] guids1 = AssetDatabase.FindAssets("XSShaderGenerator", null);
		string untouchedString = AssetDatabase.GUIDToAssetPath(guids1[0]);
      	string[] splitString = untouchedString.Split('/');

		ArrayUtility.RemoveAt(ref splitString, splitString.Length - 1);
		ArrayUtility.RemoveAt(ref splitString, splitString.Length - 1);
		
		string finalFilePath = string.Join("/", splitString);
		Create(finalFilePath);
	}

//In the create function we pass on the file path and we check to see which shaders are to be created, and run the function for each one that's been checked off.
	static void Create(string finalFilePath)
		{
			if(cutout == true){
				WriteCutout(finalFilePath);
				Debug.Log("Generate Cutout");
			}
			if(transparent == true){
				WriteTransparent(finalFilePath);
				Debug.Log("Generate Transparent");
			}
			if(transparentShadowed == true){
				WriteTransparentShadow(finalFilePath);
				Debug.Log("Generate Transparent w/ Shadows");
			}
			if(transparentFade == true){
				WriteTransparentFade(finalFilePath);
				Debug.Log("Generate Transparent Fade");
			}
			if(transparentFadeShadowed == true){
				WriteTransparentFadeShadow(finalFilePath);
				Debug.Log("Generate Transparent Fade w/ Shadows");
			}
			if(transparentDithered == true){
				WriteTransparentDither(finalFilePath);
				Debug.Log("Generate Dithered");
			}
		}


//Here we do all the creating, passing in all of the things we need, such as the file path. 
	static void WriteCutout(string finalFilePath)
	{
		string name = "XSToonCutout";
		string dest = finalFilePath + destFile + name + ".txt";
		string final = finalFilePath + finalPath + name + ".shader";

		string searchForName = "!name";
		string searchForTags = "!shadertags";
		string searchForRender = "!definerendermode";
		string serachForFallback = "!fallback";

		string[] lines = File.ReadAllLines(finalFilePath + temp);
		
		StreamWriter writer = new StreamWriter(dest, true);
			for (int i = 0; i < lines.Length; i++)
				{
					if (lines[i].Contains(searchForName))
					{
						writer.WriteLine("Shader \"Xiexe/Toon/XSToonCutout\"");
					}
					else if (lines[i].Contains(searchForTags)){
						writer.WriteLine("Tags{ \"RenderType\" = \"TransparentCutout\"  \"Queue\" = \"AlphaTest\" \"IsEmissive\" = \"true\"}");
					}
					else if (lines[i].Contains(searchForRender)){
						writer.WriteLine("#define cutout");
					}
					else if (lines[i].Contains(serachForFallback)){
						writer.WriteLine("Fallback \"Transparent/Cutout/Diffuse\"");
					}
					else{
						writer.WriteLine(lines[i]);
					}
				}
		writer.Close();
		ConvertToShader(dest, final, name);
	}

	static void WriteTransparent(string finalFilePath)
	{
		string name = "XSToonTransparent";
		string dest = finalFilePath + destFile + name + ".txt";
		string final = finalFilePath + finalPath + name + ".shader";


		string searchForName = "!name";
		string searchForTags = "!shadertags";
		string searchForRender = "!definerendermode";
		string serachForFallback = "!fallback";

		string[] lines = File.ReadAllLines(finalFilePath + temp);
		
		StreamWriter writer = new StreamWriter(dest, true);
			for (int i = 0; i < lines.Length; i++)
				{
					if (lines[i].Contains(searchForName))
					{
						writer.WriteLine("Shader \"Xiexe/Toon/XSToonTransparent\"");
					}
					else if (lines[i].Contains(searchForTags)){
						writer.WriteLine("Tags{ \"RenderType\" = \"Transparent\"  \"Queue\" = \"Transparent\" \"IsEmissive\" = \"true\"}");
					}
					else if (lines[i].Contains(searchForRender)){
						writer.WriteLine("#define alphablend");
					}
					else if (lines[i].Contains(serachForFallback)){
						writer.WriteLine("Fallback \"Transparent/Diffuse\"");
					}
					else{
						writer.WriteLine(lines[i]);
					}
				}
		writer.Close();
		ConvertToShader(dest, final, name);
	}

	static void WriteTransparentShadow(string finalFilePath)
	{
		string name = "XSToonTransparentShadowed";
		string dest = finalFilePath + destFile + name + ".txt";
		string final = finalFilePath + finalPath + name + ".shader";
	
		string searchForName = "!name";
		string searchForTags = "!shadertags";
		string searchForRender = "!definerendermode";
		string serachForFallback = "!fallback";

		string[] lines = File.ReadAllLines(finalFilePath + temp);
		
		StreamWriter writer = new StreamWriter(dest, true);
			for (int i = 0; i < lines.Length; i++)
				{
					if (lines[i].Contains(searchForName))
					{
						writer.WriteLine("Shader \"Xiexe/Toon/XSToonTransparentShadowed\"");
					}
					else if (lines[i].Contains(searchForTags)){
						writer.WriteLine("Tags{ \"RenderType\" = \"Transparent\"  \"Queue\" = \"Transparent\" \"IsEmissive\" = \"true\"}");
					}
					else if (lines[i].Contains(searchForRender)){
						writer.WriteLine("#define alphablend");
					}
					else if (lines[i].Contains(serachForFallback)){
						writer.WriteLine("Fallback \"Transparent/Diffuse\"");
					}
					else{
						writer.WriteLine(lines[i]);
					}
				}
		writer.Close();
		ConvertToShader(dest, final, name);
	}

	static void WriteTransparentFade(string finalFilePath)
	{
		string name = "XSToonFade";
		string dest = finalFilePath + destFile + name + ".txt";
		string final = finalFilePath + finalPath + name + ".shader";	
	
		string searchForName = "!name";
		string searchForTags = "!shadertags";
		string searchForRender = "!definerendermode";
		string serachForFallback = "!fallback";

		string[] lines = File.ReadAllLines(finalFilePath + temp);
		
		StreamWriter writer = new StreamWriter(dest, true);
			for (int i = 0; i < lines.Length; i++)
				{
					if (lines[i].Contains(searchForName))
					{
						writer.WriteLine("Shader \"Xiexe/Toon/XSToonTransparentFade\"");
					}
					else if (lines[i].Contains(searchForTags)){
						writer.WriteLine("Tags{ \"RenderType\" = \"Transparent\"  \"Queue\" = \"Transparent\" \"IsEmissive\" = \"true\"}");
					}
					else if (lines[i].Contains(searchForRender)){
						writer.WriteLine("#define alphablend");
					}
					else if (lines[i].Contains(serachForFallback)){
						writer.WriteLine("Fallback \"Transparent/Diffuse\"");
					}
					else{
						writer.WriteLine(lines[i]);
					}
				}
		writer.Close();
		ConvertToShader(dest, final, name);
	}

	static void WriteTransparentFadeShadow(string finalFilePath)
	{
		string name = "XSToonFadeShadowed";
		string dest = finalFilePath + destFile + name + ".txt";
		string final = finalFilePath + finalPath + name + ".shader";	
	
		string searchForName = "!name";
		string searchForTags = "!shadertags";
		string searchForRender = "!definerendermode";
		string serachForFallback = "!fallback";

		string[] lines = File.ReadAllLines(finalFilePath + temp);
		
		StreamWriter writer = new StreamWriter(dest, true);
			for (int i = 0; i < lines.Length; i++)
				{
					if (lines[i].Contains(searchForName))
					{
						writer.WriteLine("Shader \"Xiexe/Toon/XSToonTransparentFadeShadowed\"");
					}
					else if (lines[i].Contains(searchForTags)){
						writer.WriteLine("Tags{ \"RenderType\" = \"Transparent\"  \"Queue\" = \"Transparent\" \"IsEmissive\" = \"true\"}");
					}
					else if (lines[i].Contains(searchForRender)){
						writer.WriteLine("#define alphablend");
					}
					else if (lines[i].Contains(serachForFallback)){
						writer.WriteLine("Fallback \"Transparent/Diffuse\"");
					}
					else{
						writer.WriteLine(lines[i]);
					}
				}
		writer.Close();
		ConvertToShader(dest, final, name);
	}

	static void WriteTransparentDither(string finalFilePath)
	{
		string name = "XSToonTransparentDithered";	
		string dest = finalFilePath + destFile + name + ".txt";
		string final = finalFilePath + finalPath + name + ".shader";	
	
		string searchForName = "!name";
		string searchForTags = "!shadertags";
		string searchForRender = "!definerendermode";
		string serachForFallback = "!fallback";

		string[] lines = File.ReadAllLines(finalFilePath + temp);
		
		StreamWriter writer = new StreamWriter(dest, true);
			for (int i = 0; i < lines.Length; i++)
				{
					if (lines[i].Contains(searchForName))
					{
						writer.WriteLine("Shader \"Xiexe/Toon/XSToonTransparentDithered\"");
					}
					else if (lines[i].Contains(searchForTags)){
						writer.WriteLine("Tags{ \"RenderType\" = \"TransparentCutout\"  \"Queue\" = \"AlphaTest\" \"IsEmissive\" = \"true\"}");
					}
					else if (lines[i].Contains(searchForRender)){
						writer.WriteLine("#define dithered");
					}
					else if (lines[i].Contains(serachForFallback)){
						writer.WriteLine("Fallback \"Transparent/Diffuse\"");
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
