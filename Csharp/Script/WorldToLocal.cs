using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

public class WorldToLocal : MonoBehaviour
{
    
    public Transform objLocalPos;
    public Vector2 objWorldPos;

    public Vector2 localPos;
    private void OnDrawGizmos()
    {   
        //局部坐标系
        Vector2 objPos = transform.position;
        Vector2 right = transform.right;
        Vector2 up = transform.up;
        //转换函数
        Vector2 WorldToLocal(Vector2 worldPos)
        {
            Vector2 relDir = objWorldPos - objPos;

            float x = Vector2.Dot(relDir, right);
            float y = Vector2.Dot(relDir, up);

            return new Vector2(x, y);
            


        }

        //得到局部坐标下的该点坐标值
        objLocalPos.localPosition = WorldToLocal(objWorldPos);

        localPos = objLocalPos.localPosition;


        DrawBasisVectors(objPos,right,up);
        DrawBasisVectors(Vector2.zero,Vector2.right,Vector2.up);
        
        //绘制出该点
        Gizmos.color = Color.cyan;
        Gizmos.DrawSphere(objWorldPos,0.1f);
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
