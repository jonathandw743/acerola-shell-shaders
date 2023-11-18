using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CreateShells : MonoBehaviour
{
    public float height;
    public int numLayers;
    public int width;
    public int depth;

    public Material shellMaterial;
    public Material groundMaterial;

    // Start is called before the first frame update
    void Start()
    {
        GameObject[] shells = new GameObject[numLayers + 1];

        for (int i = 0; i < shells.Length; i++)
        {
            shells[i] = new GameObject("layer" + i.ToString());
            shells[i].transform.parent = transform;
            Mesh currMesh = shells[i].AddComponent<MeshFilter>().mesh;
            MeshRenderer currMeshRenderer = shells[i].AddComponent<MeshRenderer>();
            currMeshRenderer.material = shellMaterial;
            currMeshRenderer.material.SetFloat("_HeightFactor", (float)i / (float)numLayers);
            currMeshRenderer.material.SetFloat("_AbsoluteMaxHeight", height);
            currMeshRenderer.material.GetTexture("_ColorTex").filterMode = FilterMode.Point;

            float currLayerHeight = i * (height / numLayers);

            //Vector3[] vertices = new Vector3[4] {
            //    new Vector3(-10, currLayerHeight, -10),
            //    new Vector3(width + 10, currLayerHeight, -10),
            //    new Vector3(-10, currLayerHeight, depth + 10),
            //    new Vector3(width + 10, currLayerHeight, depth + 10)
            //}
            Vector3[] vertices = new Vector3[4] {
                new Vector3(0, currLayerHeight, 0),
                new Vector3(width, currLayerHeight, 0),
                new Vector3(0, currLayerHeight, depth),
                new Vector3(width, currLayerHeight, depth)
            };
            int[] triangles = new int[6] {
                0,2,1,1,2,3
            };
            Vector2[] uv = new Vector2[4] {
                //Vector2.zero,
                //Vector2.right,
                //Vector2.down,
                //Vector2.one
                new Vector2(0, 0),
                new Vector2(width, 0),
                new Vector2(0, depth),
                new Vector2(width, depth),
            };
            currMesh.vertices = vertices;
            currMesh.triangles = triangles;
            currMesh.uv = uv;

            currMesh.RecalculateBounds();
            currMesh.RecalculateNormals();
            currMesh.RecalculateTangents();
        }

        shells[numLayers] = new GameObject("ground");
        shells[numLayers].transform.parent = transform;
        Mesh groundMesh = shells[numLayers].AddComponent<MeshFilter>().mesh;
        MeshRenderer groundMeshRenderer = shells[numLayers].AddComponent<MeshRenderer>();
        groundMeshRenderer.material = groundMaterial;

        Vector3[] groundVertices = new Vector3[4] {
                new Vector3(0, 0, 0),
                new Vector3(width, 0, 0),
                new Vector3(0, 0, depth),
                new Vector3(width, 0, depth)
            };
        int[] groundTriangles = new int[6] {
                0,2,1,1,2,3
            };
        groundMesh.vertices = groundVertices;
        groundMesh.triangles = groundTriangles;

        groundMesh.RecalculateBounds();
        groundMesh.RecalculateNormals();
        groundMesh.RecalculateTangents();
    }

    // Update is called once per frame
    void Update()
    {
        foreach (MeshRenderer mr in GetComponentsInChildren<MeshRenderer>())
        {
            mr.material.SetVector("_MainCameraPos", Camera.main.transform.position);
        }
    }
}
