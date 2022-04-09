using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class CubCollision : MonoBehaviour
{
    public GameObject plane;

    public Animation ani;

    private void Start()
    {   
        //判断是否有目标对象
        if (plane != null)
        {   
            //先隐藏标本水波面片
            plane.SetActive(false);
            //得到水波的动画组件
            ani = plane.GetComponent<Animation>();
        }

    }

    void OnCollisionEnter(Collision Coll)
    {
        //得到碰撞时的坐标位置
        ContactPoint contact = Coll.contacts[0];
        Quaternion rot = Quaternion.FromToRotation(Vector3.up, contact.normal);
        Vector3 pos = contact.point;
        pos.y += 0.1f;

        //再碰撞位置生成一个复制体
        GameObject copyobj = GameObject.Instantiate(plane, pos, rot);
        //由于原始的标本时隐藏的 这里显示
        copyobj.SetActive(true);
        
        //播放一次动画
        ani.Play("Take 002");
        
        //通过动画事件 ，动画片段播放结束时 会自动调用销毁game object
        
        Debug.Log(pos);
    }

    private void Update()
    {
        /*
        if ( ! ani.IsPlaying("Take 002"))
        {
            plane.SetActive(false);
            //Debug.Log(" hide");
        }
        */
   
        


    }
    
    
    /*
    void OnCollisionExit(Collision ctl)
    {
        Debug.Log("碰撞结束");
    }
    */

}
