module graphics.block_graphics;

import raylib;

private struct BlockGraphicsDefinition {
    Vector3[][2] position;
}

public static class BlockGraphics {
    public static Mesh test() {

        // Learning to draw a triangle with raylib
        Mesh myMesh = Mesh();

        myMesh.triangleCount = 1;
        myMesh.vertexCount = 3;

        float[] vertices;
        float[] normals;
        float[] textureCoordinates;
        
        // Top left
        // x, y, z
        vertices ~= 0;
        vertices ~= 1;
        vertices ~= 0;
        // x, y, z
        normals ~= 1;
        normals ~= 0;
        normals ~= 0;
        // x, y
        textureCoordinates ~= 0;
        textureCoordinates ~= 0;


        // Bottom left
        // x, y, z
        vertices ~= 0;        
        vertices ~= 0;
        vertices ~= 0;
        // x, y, z
        normals ~= 1;
        normals ~= 0;
        normals ~= 0;
        // x, y
        textureCoordinates ~= 0;
        textureCoordinates ~= 0;

        // Bottom right
        // x, y, z
        vertices ~= 0;
        vertices ~= 0;
        vertices ~= -1;
        // x, y, z
        normals ~= 1;
        normals ~= 0;
        normals ~= 0;
        // x, y
        textureCoordinates ~= 0;
        textureCoordinates ~= 0;

        myMesh.vertices = vertices.ptr;
        //myMesh.normals = normals.ptr;
        myMesh.texcoords = textureCoordinates.ptr;

        UploadMesh(&myMesh, false);

        return myMesh;
    }
}

alias test = BlockGraphics.test;