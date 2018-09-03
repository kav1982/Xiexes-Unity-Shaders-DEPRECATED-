using UnityEngine; 
using UnityEditor;

using System.Collections; 
using System.IO;

public class XSGradientEditor : EditorWindow {

	public Gradient gradient;
	[MenuItem ("Xiexe/Tools/Gradient Editor")]
	// Use this for initialization
	static void Init(){
		XSGradientEditor window = EditorWindow.GetWindow<XSGradientEditor>(true, "XSToon: Gradient Editor", true);
		window.minSize = new Vector2(300,60);
		window.maxSize = new Vector2(300,60);
	}

	void OnGUI(){
		if(gradient == null)
		{
			gradient = new Gradient();
		}
			EditorGUI.BeginChangeCheck();
			SerializedObject serializedGradient = new SerializedObject(this);
			SerializedProperty colorGradient = serializedGradient.FindProperty("gradient");
			EditorGUILayout.PropertyField(colorGradient, true, null);
			serializedGradient.ApplyModifiedProperties();
			if(gradient != null)
			{
				int width = 128;
				int height = 8;

				Texture2D tex = new Texture2D(width, height, TextureFormat.RGB24, false);


				for (int y = 0; y < tex.height; y++)
				{
					for(int x = 0; x < tex.width; x++)
					{
						tex.SetPixel(x, y, gradient.Evaluate((float)x/(float)width));
					}
				}

				XSStyles.Separator();
				if(GUILayout.Button("Save Ramp")){

					string[] guids1 = AssetDatabase.FindAssets("XSShaderGenerator", null);
					string untouchedString = AssetDatabase.GUIDToAssetPath(guids1[0]);
					string[] splitString = untouchedString.Split('/');

					ArrayUtility.RemoveAt(ref splitString, splitString.Length - 1);
					ArrayUtility.RemoveAt(ref splitString, splitString.Length - 1);
					
					string finalFilePath = string.Join("/", splitString);

					string path = EditorUtility.SaveFilePanel("Save Ramp as PNG", finalFilePath + "/Textures/Shadow Ramps/Generated", "gradient.png", "png");
					if(path.Length != 0)
					{
						GenTexture(tex, path);				
					}
			}
		}
	}

	static void GenTexture(Texture2D tex, string path)
	{
		var pngData = tex.EncodeToPNG();
		if (pngData != null){
			File.WriteAllBytes(path, pngData);
			AssetDatabase.Refresh();
			ChangeImportSettings(path);
		}
		
	}
	static void ChangeImportSettings(string path){

		string s = path.Substring(path.LastIndexOf("Assets"));
		TextureImporter texture = (TextureImporter)TextureImporter.GetAtPath(s);
		if (texture != null)
        {
			texture.wrapMode = TextureWrapMode.Clamp;
			texture.SaveAndReimport();
			AssetDatabase.Refresh();
        }
		else
		{
			Debug.Log("Asset Path is Null, can't set to Clamped.\n You'll need to do it manually.");
		}
	}
}