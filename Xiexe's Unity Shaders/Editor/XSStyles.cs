using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using System.IO;

public class XSStyles : MonoBehaviour {
	public static string uiPath;
	private static GUISkin skin;

	[UnityEditor.Callbacks.DidReloadScripts]
    private static void setupIcons(){
        string[] guids1 = AssetDatabase.FindAssets("XSShaderGenerator", null);
		string untouchedString = AssetDatabase.GUIDToAssetPath(guids1[0]);
		string[] splitString = untouchedString.Split('/');

		ArrayUtility.RemoveAt(ref splitString, splitString.Length - 1);
		ArrayUtility.RemoveAt(ref splitString, splitString.Length - 1);
					
		uiPath = string.Join("/", splitString) + "/Editor/Resources/";
        //-----

		skin = (GUISkin)Resources.Load("XSGuiSkin");

        Debug.Log(uiPath);
    }

	public static class Styles{
		public static GUIContent version = new GUIContent("XSToon v1.4 BETA 7", "The currently installed version of XSToon.");
	}

	// Labels
	public static void DoHeader(GUIContent HeaderText){
			GUILayout.Label(HeaderText, new GUIStyle(EditorStyles.boldLabel)
        {
            alignment = TextAnchor.MiddleCenter,
            wordWrap = true,
            fontSize = 12
        });
	}

	public static void doLabel(string text){
			GUILayout.Label(text, new GUIStyle(EditorStyles.label)
        {
            alignment = TextAnchor.MiddleCenter,
            wordWrap = true,
            fontSize = 12
        });
	}

	
	public static void doLabelSmall(string text){
			GUILayout.Label(text, new GUIStyle(EditorStyles.label)
        {
            alignment = TextAnchor.LowerLeft,
            wordWrap = true,
            fontSize = 10
        });
	}
	// ---- 

	static public GUIStyle _LineStyle;
	static public GUIStyle LineStyle
	{
		get
		{
			if(_LineStyle == null)
			{
				_LineStyle = new GUIStyle();
				_LineStyle.normal.background = EditorGUIUtility.whiteTexture;
				_LineStyle.stretchWidth = true;
			}
			
			return _LineStyle;
		}
	}

	//GUI Buttons
	static public void callGradientEditor(){
		GUILayout.BeginHorizontal();
            GUILayout.FlexibleSpace();
                GUI.skin = null;
				if(GUILayout.Button("Open Gradient Editor", GUILayout.Width(200), GUILayout.Height(20))){
                    XSGradientEditor.Init();
                }
        GUILayout.EndHorizontal();
	}

	//------

	//Help Box
	public static void HelpBox(string message, MessageType type){
		EditorGUILayout.HelpBox(message, type);
	}
	
	//GUI Lines
	static public void Separator()
	{
		GUILayout.Space(4);
		GUILine(new Color(.3f,.3f,.3f), 1);
		GUILine(new Color(.9f,.9f,.9f), 1);
		GUILayout.Space(4);
	}

	static public void SeparatorBig()
	{
		GUILayout.Space(10);
		GUILine(new Color(.3f,.3f,.3f), 2);
		GUILayout.Space(1);
		GUILine(new Color(.3f,.3f,.3f), 2);
		GUILine(new Color(.85f,.85f,.85f), 1);
		GUILayout.Space(10);
	}

	static public void GUILine(float height = 2f)
	{
		GUILine(Color.black, height);
	}

	static public void GUILine(Color color, float height = 2f)
	{
		Rect position = GUILayoutUtility.GetRect(0f, float.MaxValue, height, height, LineStyle);
		
		if(Event.current.type == EventType.Repaint)
		{
			Color orgColor = GUI.color;
			GUI.color = orgColor * color;
			LineStyle.Draw(position, false, false, false, false);
			GUI.color = orgColor;
		}
	}
	// --------------



	//Help Buttons
	public static void helpPopup(bool showBox, string title, string message, string button)
	{
		GUI.skin = skin;
		if(GUILayout.Button("", "helpButton", GUILayout.Width(16), GUILayout.Height(16))){
            showBox = true;
            if(showBox == true){
                EditorUtility.DisplayDialog(title,
					                        message, button);
            }
		}
	}

	//Find Asset Path
	public static void findAssetPath(string finalFilePath)
	{
		string[] guids1 = AssetDatabase.FindAssets("XSShaderGenerator", null);
		string untouchedString = AssetDatabase.GUIDToAssetPath(guids1[0]);
		string[] splitString = untouchedString.Split('/');

		ArrayUtility.RemoveAt(ref splitString, splitString.Length - 1);
		ArrayUtility.RemoveAt(ref splitString, splitString.Length - 1);
					
		finalFilePath = string.Join("/", splitString);
		//return finalFilePath;
	}
}
