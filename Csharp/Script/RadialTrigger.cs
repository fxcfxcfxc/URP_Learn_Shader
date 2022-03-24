using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
#if UNITY_EDITOR
using UnityEngine;
#endif

public class RadialTrigger : MonoBehaviour
{
    public Transform objtf;
    [Range(0f,4f)]
    public float myRadial = 1.0f;
    
    #if UNITY_EDITOR
    private void OnDrawGizmos()
    {
        //得到两个点的位置
        Vector2 emtryPos = objtf.position;
        Vector2 origin = transform.position;
        
        //计算距离
        float myDistance = Vector2.Distance(emtryPos, origin);
        Handles.DrawWireDisc(origin,new Vector3(0, 0, 1),myRadial);
        
        //与半径对比,判断敌人进入圈类
        if (myDistance <= myRadial )
        {
            Handles.color = Color.red;
            //Debug.Log("有敌人靠近");
        }
        else
        {
            Handles.color = Color.green;
        }
        Handles.DrawWireDisc(origin,new Vector3(0, 0, 1),myRadial);


    }
    
    #endif
}
