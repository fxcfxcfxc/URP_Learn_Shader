using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.UIElements;

public class ImageAphlaEdior : EditorWindow
{
    [MenuItem("MyTools/Image Alpha Editor")]
    static void OpenEditorWindow()
    {
        ImageAphlaEdior  wnd = GetWindow<ImageAphlaEdior>();
        wnd.titleContent = new GUIContent("Image Alpha Editor");
        wnd.maxSize = new Vector2(320, 600);
        wnd.minSize = wnd.maxSize;

    }
    
    private void CreateGUI()
    {
        VisualElement root = rootVisualElement;
        var visualTree =
            AssetDatabase.LoadAssetAtPath<VisualTreeAsset>(
                "Assets/Tools/ImageAddAlphaEdiror/Resource/imageEditor.uxml");
        VisualElement tree = visualTree.Instantiate();
        root.Add(tree);

    }
    
    
}
