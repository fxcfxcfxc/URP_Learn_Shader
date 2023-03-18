using System.Collections;
using System.Collections.Generic;
using Scenes;
using UnityEngine;
using UnityEngine.Audio;


[CreateAssetMenu(fileName = "New Audio Database", order = 215)]
public class AudioDatabase : ScriptableObject
{

    public string databaseName;

    public AudioMixerGroup outputAudioMixerGroup;

    public List<AudioData> datasets = new List<AudioData>(0);
}
