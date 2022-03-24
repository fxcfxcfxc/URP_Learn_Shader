using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LocalToWorld : MonoBehaviour
{
    public Vector2 objLocalPos;
    public Vector2 objWorldPos;
    private void OnDrawGizmos()
    {   
        //得到该gameobject transform组件的position属性，本地坐标
        Vector2 objPos = transform.position;
        Vector2 right = transform.right;
        Vector2 up = transform.up;
        
        
        //参数：本地坐标
        Vector2 LocalToWorld(Vector2 localpt)
        {
            Vector2 worldoffset = right * localpt.x + up * localpt.y;
            return (Vector2) transform.position + worldoffset;

        }
            
        //计算世界坐标
        Vector2 worldPos = LocalToWorld(objLocalPos);
        objWorldPos = worldPos;

        //定义两个空间
        DrawBasisVectors(objPos,right,up);
        DrawBasisVectors(Vector2.zero,Vector2.right,Vector2.up);
        
        //顶一个点位置 本地空间
        Gizmos.color = Color.cyan;
        Gizmos.DrawSphere(worldPos,0.1f);
    }

    void DrawBasisVectors(Vector2 pos, Vector2 right, Vector2 up)
    {
        Gizmos.color = Color.red;
        Gizmos.DrawRay(pos,right);

        Gizmos.color = Color.green;

        Gizmos.DrawRay(pos, up);

        Gizmos.color = Color.white;

    }

}
