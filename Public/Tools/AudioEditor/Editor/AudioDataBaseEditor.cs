using System;
using System.Collections.Generic;
using Scenes;
using Unity.VisualScripting;
using UnityEditor;
using UnityEditor.AnimatedValues;
using UnityEngine;
using UnityEngine.Audio;
using UnityEditor.AnimatedValues;
using System.Linq;

namespace SK.Framework
{
    
    [CustomEditor(typeof(AudioDatabase))]
    public class AudioDataBaseEditor : Editor
    {
        private AudioDatabase database;
        private AnimBool foldout;
        private int currentIndex = -1;
        private Dictionary<AudioData, AudioSource> players;


        private void OnEnable()
        {
            database = target as AudioDatabase;
            foldout = new AnimBool(false, Repaint);
            players = new Dictionary<AudioData, AudioSource>();
            EditorApplication.update += Update;
        }


        private void OnDestroy()
        {
            EditorApplication.update -= Update;
            foreach (var player in players)
            {
                DestroyImmediate(player.Value.gameObject);
                
            }
            
            players.Clear();
            
        }


        void Update()
        {
            Repaint();
            foreach (var player in players)
            {
                if (!player.Value.isPlaying)
                {
                    DestroyImmediate(player.Value.gameObject);
                    players.Remove(player.Key);
                    break;
                }
            }
            
        }


        public  override void OnInspectorGUI()
        {
            var newDatabaseName = EditorGUILayout.TextField("Database Name", database.databaseName);
            if (newDatabaseName != database.databaseName)
            {
                Undo.RecordObject(database, "Name");
                database.databaseName = newDatabaseName;
                EditorUtility.SetDirty(database);

            }
            
            //音频库输出混音器
            var newOutputAudioMixerGroup = EditorGUILayout.ObjectField("OutPut Audio Mixer Group",
                database.outputAudioMixerGroup, typeof(AudioMixerGroup), false) as AudioMixerGroup;

            if (newOutputAudioMixerGroup != database.outputAudioMixerGroup)
            {
                Undo.RecordObject(database, "Output");
                database.outputAudioMixerGroup = newOutputAudioMixerGroup;
                EditorUtility.SetDirty(database);
            }
            
            //音频数据折叠拦
            foldout.target = EditorGUILayout.Foldout(foldout.target, "Datasets");
            if (EditorGUILayout.BeginFadeGroup(foldout.faded))
            {
                for(int i=0; i < database.datasets.Count; i++)
                {
                    var data = database.datasets[i];
                    GUILayout.BeginHorizontal();
                    
                    //绘制音频图标
                    GUILayout.Label( EditorGUIUtility.IconContent("SceneViewAudio"), GUILayout.Width(20f));
                    
                    //音频数据名称
                    var newName = EditorGUILayout.TextField(data.name, GUILayout.Width(120f));
                    if (newName != data.name)
                    {
                        Undo.RecordObject(database, "Data Name");
                        data.name = newName;
                        EditorUtility.SetDirty(database);
                    }
                    
                    //使用音频名称button 按钮， 点击后使用pingobject 方法定位 该音频资源
                    Color colorCache = GUI.color;
                    GUI.color = currentIndex == i ? Color.cyan : colorCache;
                    if (GUILayout.Button(data.clip != null ? data.clip.name : "Null"))
                    {
                        currentIndex = i;
                        EditorGUIUtility.PingObject(data.clip);
                    }

                    GUI.color = colorCache;
                    
                    // 若该音频 正在播放 计算其播放进度
                    string progress = players.ContainsKey(data) ? ToTimeFormat(players[data].time) : "00:00";
                    GUI.color = new Color(GUI.color.r, GUI.color.g, GUI.color.b, players.ContainsKey(data) ? .9f : .5f);
                    
                    //显示消息 ： 播放进度 /音频时长（）
                    GUILayout.Label($"(  { progress}  / {  (data.clip != null ?   ToTimeFormat(  data.clip.length): "00:00"     )  })" ,
                        new GUIStyle(GUI.skin.label) {alignment = TextAnchor.LowerRight, fontSize = 8, fontStyle = FontStyle.Italic}, GUILayout.Width(60f) );
                    
                    GUI.color = colorCache;
                    
                    
                    //播放按钮
                     if ( GUILayout.Button( EditorGUIUtility.IconContent( "PlayButton" ),GUILayout.Width(20f) ) )
                    {
                        if (!players.ContainsKey(data))
                        {
                            //创建一个物体并添加audioSource
                            var source = EditorUtility
                                .CreateGameObjectWithHideFlags("Audio Player", HideFlags.HideAndDontSave)
                                .AddComponent<AudioSource>();
                            source.clip = data.clip;
                            source.outputAudioMixerGroup = database.outputAudioMixerGroup;
                            source.Play();
                            players.Add(data, source);
                        }
                    }
                     
                     //停止播放按钮
                     if (GUILayout.Button(EditorGUIUtility.IconContent(" PauseButton ") ,GUILayout.Width(20f)))
                     {
                         if (players.ContainsKey(data))
                         {
                             DestroyImmediate(  players[data].gameObject);
                             players.Remove(data);
                             
                         }
                     }
                     
                     //删除按钮
                     if (GUILayout.Button(EditorGUIUtility.IconContent("Toolbar Minus"), GUILayout.Width(20f)))
                     {
                         Undo.RecordObject(database, "Delete");
                         database.datasets.Remove(data);
                         if (players.ContainsKey(data))
                         {
                             DestroyImmediate( players[data].gameObject );
                             players.Remove(data);
                         }
                         
                         EditorUtility.SetDirty(database);
                         Repaint();
                     }
                     
                     GUILayout.EndHorizontal();
                     
                     // 拖拽
                     
                     GUILayout.BeginHorizontal();
                     {
                         GUILayout.Label(GUIContent.none, GUILayout.ExpandWidth(true));
                         Rect lastRect = GUILayoutUtility.GetLastRect();
                         var dropRect = new Rect(lastRect.x + 2f, lastRect.y - 2f, 120f, 20f);

                         bool containsMouse = dropRect.Contains(Event.current.mousePosition);

                         if (containsMouse)
                         {
                             switch (Event.current.type)
                             {
                                 case EventType.DragUpdated:
                                    bool containsAudioClip = DragAndDrop.objectReferences.OfType<AudioClip>().Any();
                                    DragAndDrop.visualMode = containsAudioClip
                                        ? DragAndDropVisualMode.Copy
                                        : DragAndDropVisualMode.Rejected;
                                     
                                     
                                    Event.current.Use();
                                     
                                     Repaint();
                                     break;
                                 case EventType.DragPerform:
                                     IEnumerable<AudioClip> audioClips =
                                         DragAndDrop.objectReferences.OfType<AudioClip>();
                                     foreach (var audioClip in audioClips)
                                     {
                                         if (database.datasets.Find(m=> m.clip == audioClip) ==null)
                                         {
                                             Undo.RecordObject(database, "Add");
                                             database.datasets.Add(new AudioData() {name = audioClip.name, clip = audioClip});
                                             EditorUtility.SetDirty(database);
                                         }
                                     }
                                     
                                     
                                     Event.current.Use();
                                     Repaint();
                                     break;
                                     
                                     
                             }
                            
                             
                         }

                         Color color = GUI.color;

                         GUI.color = new Color(GUI.color.r, GUI.color.g, GUI.color.b, containsMouse ? .9f : .5f);
                         
                         GUI.Box(dropRect, "Drop Audio", new GUIStyle(GUI.skin.box) {fontSize = 10});

                         GUI.color = color;

                     }
                     
                     GUILayout.EndHorizontal();

                }
                
                
                EditorGUILayout.EndFadeGroup();
                serializedObject.ApplyModifiedProperties();
            }

        }

        string ToTimeFormat(float time)
        {
            int seconds = (int)time;
            int minutes = seconds / 60;
            seconds %= 60;
            return string.Format("{0:D2}:{1:D2}", minutes, seconds);
        }
    }
}