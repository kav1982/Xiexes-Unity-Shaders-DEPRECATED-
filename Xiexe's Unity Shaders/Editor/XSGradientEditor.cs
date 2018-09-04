using UnityEngine; 
using UnityEditor;
using System.Collections; 
using System.IO;

public class XSGradientEditor : EditorWindow {

	public Gradient gradient;
		// resolution presets
	public static Texture shadowRamp;
	public string finalFilePath;
	public enum resolutions{
		Tiny,
		Small,
		Medium,
		Large
    }
	public resolutions res;
	
	[MenuItem ("Xiexe/Tools/Gradient Editor")]
	// Use this for initialization
	static public void Init(){
		XSGradientEditor window = EditorWindow.GetWindow<XSGradientEditor>(true, "XSToon: Gradient Editor", true);
		window.minSize = new Vector2(300,160);
		window.maxSize = new Vector2(300,160);
	}

	public void OnGUI(){
		
		

		if(gradient == null)
		{
			gradient = new Gradient();
		}
			EditorGUI.BeginChangeCheck();
			SerializedObject serializedGradient = new SerializedObject(this);
			SerializedProperty colorGradient = serializedGradient.FindProperty("gradient");
			EditorGUILayout.PropertyField(colorGradient, true, null);
			serializedGradient.ApplyModifiedProperties();
		
		int width = 128;
		int height = 8;

		res = (resolutions)EditorGUILayout.EnumPopup("Resolution: ", res);
			
			switch(res){
				case resolutions.Large:
					width = 512;
					break;
				
				case resolutions.Medium:
					width = 256;
					break;
				
				case resolutions.Small:
					width = 128;
					break;
				
				case resolutions.Tiny:
					width = 64;
					break;
			}
			
			if(gradient != null)
			{

				Texture2D tex = new Texture2D(width, height, TextureFormat.RGB24, false);


				for (int y = 0; y < tex.height; y++)
				{
					for(int x = 0; x < tex.width; x++)
					{
						tex.SetPixel(x, y, gradient.Evaluate((float)x/(float)width));
					}
				}
				

				XSStyles.Separator();
				if(GUILayout.Button("Save Ramp"))
				{
					XSStyles.findAssetPath(finalFilePath);
					string path = EditorUtility.SaveFilePanel("Save Ramp as PNG", finalFilePath + "/Textures/Shadow Ramps/Generated", "gradient.png", "png");
					if(path.Length != 0)
						{
							GenTexture(tex, path);				
						}
				}
		}

		XSStyles.HelpBox("You can use this to create a custom shadow ramp. \nYou must save the asset with the save button to apply changes. \n\n - Click the Gradient box. \n - Choose resolution. \n - Save.", MessageType.Info);
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
			texture.maxTextureSize = 512;
			texture.mipmapEnabled = false;
			texture.textureCompression = TextureImporterCompression.Uncompressed;
			texture.SaveAndReimport();
			AssetDatabase.Refresh();

			// shadowRamp = (Texture)Resources.Load(path);
			// Debug.LogWarning(shadowRamp.ToString());
        }
		else
		{
			Debug.Log("Asset Path is Null, can't set to Clamped.\n You'll need to do it manually.");
		}
	}
}