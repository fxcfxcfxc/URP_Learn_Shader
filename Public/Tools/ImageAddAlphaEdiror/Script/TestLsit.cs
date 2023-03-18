using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestLsit : MonoBehaviour
{
    public float a;
    public List<character> character = new List<character>();
}

[System.Serializable]
public struct character
{
    public GameObject face;
    public string name;
    public GameObject gameObject;
    public float outline;

    public bool eanbelself;

}