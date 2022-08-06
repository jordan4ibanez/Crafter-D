module graphics.block_graphics;

import std.stdio;
import raylib;

// Makes writing a block definition easier
struct Vector2I {
    int x = 0;
    int y = 0;
}


private struct BlockGraphicsDefinition {
    Vector3[][2] position;
}

// Defines how many textures are in the texture map
const double textureMapTiles = 32;
// Defines the width/height of each texture
const double textureTileSize = 16;
// Defines the total width/height of the texture map in pixels
const double textureMapSize = textureTileSize * textureMapTiles;

/*
This is debug prototyping
This will be automatically defined in the BlockGraphicsDefinition
Function name suggestion: translateTopLeft()
In full version, the static class will simply get this info from --
--> the BlockGraphicsDefinition based on ID of the block
*/
 
private enum FacePosition {
    TOP,
    BOTTOM,
    LEFT,
    RIGHT,
    FRONT,
    BACK
}

// This starts at 0,0
Vector2 getTopLeft(Vector2I indexPosition) {
    return Vector2(
        (indexPosition.x * textureTileSize) / textureMapSize,
        (indexPosition.y * textureTileSize) / textureMapSize
    );
}
Vector2 getTopRight(Vector2I indexPosition) {
    return Vector2(
        ((indexPosition.x + 1) * textureTileSize) / textureMapSize,
        (indexPosition.y * textureTileSize) / textureMapSize
    );
}
// Y starts at 0 (top of texture) and goes down to 1 (bottom of texture)
Vector2 getBottomLeft(Vector2I indexPosition) {
    return Vector2(
        (indexPosition.x * textureTileSize) / textureMapSize,
        ((indexPosition.y + 1) * textureTileSize) / textureMapSize
    );
}
Vector2 getBottomRight(Vector2I indexPosition) {
    return Vector2(
        ((indexPosition.x + 1) * textureTileSize) / textureMapSize,
        ((indexPosition.y + 1) * textureTileSize) / textureMapSize
    );
}

public static class BlockGraphics {
    public static Mesh test() {

        // Texture will be taken from the grass side texture
        Vector2I grassPosition = Vector2I(0,0);

        Mesh myMesh = Mesh();

        myMesh.triangleCount = 2;
        // 3 is the number of vertex points per triangle
        myMesh.vertexCount = myMesh.triangleCount * 3;

        float[] vertices;
        float[] normals;
        float[] textureCoordinates;

        // For dispatching colors ubyte[]

        // Wound counter clockwise

        // TRI 1: Lower left
        
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
        Vector2 textureTopLeft = getTopLeft(grassPosition);
        textureCoordinates ~= textureTopLeft.x;
        textureCoordinates ~= textureTopLeft.y;

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
        Vector2 textureBottomLeft = getBottomLeft(grassPosition);
        textureCoordinates ~= textureBottomLeft.x;
        textureCoordinates ~= textureBottomLeft.y;

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
        Vector2 textureBottomRight = getBottomRight(grassPosition);
        textureCoordinates ~= textureBottomRight.x;
        textureCoordinates ~= textureBottomRight.y;

        // TRI 2: Upper right

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
        textureCoordinates ~= textureTopLeft.x;
        textureCoordinates ~= textureTopLeft.y;

        // Bottom Right
        // x, y, z
        vertices ~= 0;
        vertices ~= 0;
        vertices ~= -1;
        // x, y, z
        normals ~= 1;
        normals ~= 0;
        normals ~= 0;
        // x, y
        textureCoordinates ~= textureBottomRight.x;
        textureCoordinates ~= textureBottomRight.y;

        // Top Right
        // x, y, z
        vertices ~= 0;
        vertices ~= 1;
        vertices ~= -1;
        // x, y, z
        normals ~= 1;
        normals ~= 0;
        normals ~= 0;
        // x, y
        Vector2 textureTopRight = getTopRight(grassPosition);
        textureCoordinates ~= textureTopRight.x;
        textureCoordinates ~= textureTopRight.y;



        myMesh.vertices = vertices.ptr;
        //myMesh.normals = normals.ptr;
        myMesh.texcoords = textureCoordinates.ptr;

        UploadMesh(&myMesh, false);

        getTopLeft(Vector2I(1,0));

        return myMesh;
    }
}

alias test = BlockGraphics.test;