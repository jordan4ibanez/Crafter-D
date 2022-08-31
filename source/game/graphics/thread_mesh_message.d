module game.graphics.thread_mesh_message;

import vector_3i;

struct ThreadMeshMessage {
    float[] vertices;
    int[] indices;
    float[] textureCoordinates;
    float[] colors;
    string textureName;
    Vector3i position;
    this(
        float[] vertices,
        int[] indices,
        float[] textureCoordinates,
        float[] colors,
        string textureName,
        Vector3i position) {
        this.vertices = vertices;
        this.indices = indices;
        this.textureCoordinates = textureCoordinates;
        this.colors = colors;
        this.textureName = textureName;
        this.position = position;
    }
}