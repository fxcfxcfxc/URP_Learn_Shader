using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Trig : MonoBehaviour
{
    private float TAU = 6.29185308f;
    public int dotCount = 16;
    
    
    //如果您想绘制能够选择并且始终绘制的辅助图标，则可以实现 OnDrawGizmos。
    private void OnDrawGizmos()
    {   
        //封装方法 角度转位置
        Vector2 angToVector(float ang)
        {
            float drawX = Mathf.Cos(ang);
            float drawY = Mathf.Sin(ang);
            return new Vector2(drawX, drawY);

        }

        for (int i =1;i <= dotCount;i++)
        {
            float t = i / (float) dotCount;
            float angRad = t * TAU;//得到角度
            Vector2 drawPos = angToVector(angRad);
         
            
            Gizmos.DrawSphere(drawPos,0.04f);

        }
    }
}
