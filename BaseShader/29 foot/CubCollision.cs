using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class CubCollision : MonoBehaviour
{
    public GameObject plane;

    public Animation ani;

    void OnCollisionEnter(Collision ctl)
    {
        ContactPoint contact = ctl.contacts[0];
        Quaternion rot = Quaternion.FromToRotation(Vector3.up, contact.normal);
        Vector3 pos = contact.point;
        plane.transform.position = pos;
        ani = plane.GetComponent<Animation>();
        ani.Play();
        Debug.Log(pos);
        //Invoke("FalseCompont",5.0f);
        
  
    }
    
 
    
    void OnCollisionExit(Collision ctl)
    {
        Debug.Log("碰撞结束");
    }
    

}
