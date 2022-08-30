module game.graphics.thread_mesh_message;

import vector_3i;

shared struct ThreadMeshMessage {
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
        this.vertices = new float[vertices.length];
        for (int i = 0; i < vertices.length; i++) {
            this.vertices[i] = vertices[i];
        }
        this.indices = new int[indices.length];
        for (int i = 0; i < indices.length; i++) {
            this.indices[i] = indices[i];
        }
        this.textureCoordinates = new float[textureCoordinates.length];
        for (int i = 0; i < textureCoordinates.length; i++) {
            this.textureCoordinates[i] = textureCoordinates[i];
        }
        this.colors = new float[colors.length];
        for (int i = 0; i < colors.length; i++) {
            this.colors[i] = colors[i];
        }
        this.textureName = textureName;
        this.position = position;
    }
}