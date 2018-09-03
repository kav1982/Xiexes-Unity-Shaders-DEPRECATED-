using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using System.IO;

public class XSStyles : MonoBehaviour {
	public static class Styles{
		public static GUIContent version = new GUIContent("XSToon v1.4 BETA 6", "The currently installed version of XSToon.");
	}


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



}
