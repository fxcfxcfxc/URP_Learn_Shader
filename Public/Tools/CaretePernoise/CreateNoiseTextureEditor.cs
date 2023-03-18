using System;
using Unity.Mathematics;
using Unity.VisualScripting;
using UnityEditor;
using UnityEngine;
using UnityEngine.Windows;

namespace Tools.CaretePernoise
{
    public class CreateNoiseTextureEditor : EditorWindow
    {
        [MenuItem("MyTools/ 自定义噪声工具")]
        static void OpenWindow()
        {
            Rect wr = new Rect(0, 0, 400, 600);
            CreateNoiseTextureEditor cnte = (CreateNoiseTextureEditor)GetWindowWithRect(typeof(CreateNoiseTextureEditor), wr, true,"Noise Tool");
            cnte.Show();
        }

        public enum NoiseType
        {
            Perlin, Value, Simplex, Worley
        };

        public enum GenerationMode
        {
            None,Abs,Sin
        };

        public enum TextureSize
        {
            x64=64, x128=128, x256=256, x512=512
        };

        private ComputeShader noiseComputershader;
        private NoiseType noiseType = NoiseType.Perlin;
        private GenerationMode mode = GenerationMode.None;
        private RenderTextureFormat format = RenderTextureFormat.ARGB32;
        private TextureSize size = TextureSize.x512;
        private float scale = 10f;

        private RenderTexture rt;
        private int kernel;
        private Texture2D texture;
        private string path = "Assets/test.tga";
        
        //------------------------------事件-----------------------
        private void OnGUI()
        {
            noiseComputershader = EditorGUILayout.ObjectField("Computer Shader",noiseComputershader,typeof(ComputeShader),true) as ComputeShader;

            noiseType = (NoiseType)EditorGUILayout.EnumPopup("噪声类型：", noiseType);
            mode = (GenerationMode)EditorGUILayout.EnumPopup("生成类型：", mode);
            format = (RenderTextureFormat)EditorGUILayout.EnumPopup("贴图类型",format);
            size = (TextureSize)EditorGUILayout.EnumPopup("贴图大小:", size);
            scale = EditorGUILayout.Slider("噪声大小:", scale, 1f, 40f);
                
            if (GUILayout.Button("生成噪波预览"))
            {
                if (noiseComputershader == null)
                {
                    ShowNotification(new GUIContent( " computer shader 不能为空"));
                }
                else
                {
                    Init();
                }
            }

            if (rt != null)
            {
                int x = 390;
                Rect rect = new Rect(5, 180, x, x);
                GUI.DrawTexture(rect,rt);
            }

            if (GUILayout.Button("保存到文件夹中"))
            {
                if (rt != null)
                {
                    SaveTexture();
                }
                else
                {
                    ShowNotification( new GUIContent( "保存成功"));
                }
            }    
        }

        private void OnDisable()
        {
            if(rt == null) return;
            rt.Release();
        }

        //--------------------------------------------------------
        private void Init()
        {
            //根据用户选择的配置生成rt
            rt = CreateRT((int)size);
            
            //传值computershader
            kernel = noiseComputershader.FindKernel("PerlinNoise");
            noiseComputershader.SetTexture(kernel, "Texture", rt);
            noiseComputershader.SetInt( "size", (int)size);
            noiseComputershader.SetFloat("scale",scale * 10f);
            noiseComputershader.SetInt("Type",(int)noiseType);
            noiseComputershader.SetInt("State",(int)mode);
            noiseComputershader.Dispatch(kernel, (int)size/ 8, (int)size/8,1);

        }

        private   RenderTexture CreateRT(int size)
        {
            RenderTexture tempRt = new RenderTexture(size,size,0,format);
            tempRt.enableRandomWrite = true;
            tempRt.wrapMode = TextureWrapMode.Repeat;
            tempRt.Create();
            return tempRt;
        }

        private  void SaveTexture()
         {
             RenderTexture previous = RenderTexture.active;
             RenderTexture.active = rt;
             texture = new Texture2D(rt.width, rt.height);
             texture.ReadPixels(new Rect(0,0, rt.width,rt.height), 0,0);
             texture.Apply();
             RenderTexture.active = previous;
             byte[] bytes = texture.EncodeToTGA();
             File.WriteAllBytes(path, bytes);
         }
    }
}