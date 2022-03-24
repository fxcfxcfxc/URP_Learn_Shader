using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class VectorThing : MonoBehaviour
{
    //public Transform poinf;
    public float scale =1.0f;
    public float length;

    public Transform ap;
    public Transform bp;
    public float abDis;
    private void OnDrawGizmos()
    {
        Vector2 apt = ap.position;
        Vector2 bpt = bp.position;

        //得到b相对于a的方向
        Vector2 ab = bpt - apt;
        Vector2 abnormal = ab.normalized;
        Gizmos.DrawLine(apt,apt + abnormal);

        
        abDis = Vector2.Distance(apt, bpt);
        //Transform类的position属性
        Vector2 pt = transform.position;
        //magnitude方法 返回向量长度
        float ptlength = pt.magnitude;
        length = ptlength;
        //normalized方法，归一化处理，得到单位方向
        Vector2 dirToPt = pt.normalized * scale;
        //Vector2 dirTopt = pt / ptlength;
        
        //----------------三种不同
        //Vector2.Distance(a,b)
        //（a-b）.magnitude
        //sqrt( (a.x-b.x)^2 + (a.y -b.y)^2 )

        //Gizmos类的drawline方法
        Gizmos.DrawLine(Vector2.zero,dirToPt);
    }
}
