using UnityEngine;
using UnityEditor;
 
namespace SK.Framework
{
    /// <summary>
    /// 动画片段预览工具
    /// </summary>
    public class AnimationClipPreviewer : EditorWindow
    {
        //菜单
        [MenuItem("MyTools/Animation Clip Previewer")]
        private static void Open()
        {
            //打开窗口
            GetWindow<AnimationClipPreviewer>("Animation Clip Previewer").Show();
        }
 
        private int currentClipIndex;
        private float previewNormalizedTime;
 
        private void OnGUI()
        {
            //未选中任何物体 return
            if (Selection.activeGameObject == null) return;
            //选中的物体不包含Animator组件 return
            var animator = Selection.activeGameObject.GetComponent<Animator>();
            if (animator == null)
            {
                EditorGUILayout.HelpBox("Not found Animator component.", MessageType.Warning);
                return;
            }
            //动画未初始化 return
            if (!animator.isInitialized)
            {
                EditorGUILayout.HelpBox("Animator is not initialized.", MessageType.Warning);
                return;
            }
            //获取所有动画片段
            var clips = animator.runtimeAnimatorController.animationClips;
            if (clips.Length == 0)
            {
                EditorGUILayout.HelpBox("Animation clips count: 0", MessageType.Info);
                return;
            }
            //获取所有动画片段名称
            var names = new string[clips.Length];
            for (int i = 0; i < names.Length; i++)
            {
                names[i] = clips[i].name;
            }
            //通过名称选择动画片段
            currentClipIndex = EditorGUILayout.Popup(currentClipIndex, names);
            //水平布局
            GUILayout.BeginHorizontal();
            {
                //预览的进度
                previewNormalizedTime = EditorGUILayout.Slider(previewNormalizedTime, 0f, 1f);
                //当前动画片段总时长
                float length = clips[currentClipIndex].length;
                //当前预览的时间点
                float currentTime = length * previewNormalizedTime;
                //文本显示时长信息 00:00/00:00
                GUILayout.Label($"{ToMSTimeFormat(currentTime)}/{ToMSTimeFormat(length)}");
                //动画采样 进行预览
                clips[currentClipIndex].SampleAnimation(animator.gameObject, currentTime);
            }
            GUILayout.EndHorizontal();
        }
 
        //将秒数转换为00:00格式字符串
        private string ToMSTimeFormat(float length)
        {
            int v = (int)length;
            int minute = v / 60;
            int second = v % 60;
            return string.Format("{0:D2}:{1:D2}", minute, second);
        }
 
        private void OnSelectionChange()
        {
            Repaint();
        }
    }
}