using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

public class AnimEvent : MonoBehaviour
{
    void hide()
    {
        Destroy(this.gameObject);
    }
}
