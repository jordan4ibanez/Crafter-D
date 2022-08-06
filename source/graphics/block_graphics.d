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
 
private enum Quad {
    FRONT = [
        // Lower left tri
        Vector3(0,1,0), // Top left
        Vector3(0,0,0), // Bottom left
        Vector3(0,0,1), // Bottom right
        // Upper right tri
        Vector3(0,1,0), // Top left
        Vector3(0,0,1), // Bottom right
        Vector3(0,1,1)  // Top right
    ]
}
alias FRONT = Quad.FRONT;

/*
private enum FacePosition {
    TOP,
    BOTTOM,
    LEFT,
    RIGHT,
    FRONT,
    BACK
}
*/

// The texture coordinates of the tris
private enum TexturePosition {
    TOP_LEFT     = Vector2I(0,0),
    TOP_RIGHT    = Vector2I(1,0),
    BOTTOM_LEFT  = Vector2I(0,1),
    BOTTOM_RIGHT = Vector2I(1,1)
}
alias TOP_LEFT     = TexturePosition.TOP_LEFT;
alias TOP_RIGHT    = TexturePosition.TOP_RIGHT;
alias BOTTOM_LEFT  = TexturePosition.BOTTOM_LEFT;
alias BOTTOM_RIGHT = TexturePosition.BOTTOM_RIGHT;

// This starts at 0,0
// Automatically dispatches texture coordinates
// Needs to be precalculated for adjustment on custom blocks like stairs
Vector2 getTexturePosition(Vector2I indexPosition, TexturePosition texturePosition) {
    return Vector2(
        ((indexPosition.x + texturePosition.x) * textureTileSize) / textureMapSize,
        ((indexPosition.y + texturePosition.y) * textureTileSize) / textureMapSize
    );
}

// Automatically dispatches face positions for the quad position
void insertVertexPositions(ref float[] vertices, Quad quad) {
    foreach (Vector3 position; quad) {
        vertices ~= position.x;
        vertices ~= position.y;
        vertices ~= position.z;
    }
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

        // Texture coordinates
        Vector2 textureTopLeft     = getTexturePosition(grassPosition, TOP_LEFT);
        Vector2 textureTopRight    = getTexturePosition(grassPosition, TOP_RIGHT);
        Vector2 textureBottomLeft  = getTexturePosition(grassPosition, BOTTOM_LEFT);
        Vector2 textureBottomRight = getTexturePosition(grassPosition, BOTTOM_RIGHT);


        // Wound counter clockwise

        // TRI 1: Lower left


        insertVertexPositions(vertices, FRONT);

        writeln(vertices);
        
        // Top left
        // x, y, z

        // x, y, z
        normals ~= 1;
        normals ~= 0;
        normals ~= 0;
        // x, y
        textureCoordinates ~= textureTopLeft.x;
        textureCoordinates ~= textureTopLeft.y;

        // Bottom left
        // x, y, z

        // x, y, z
        normals ~= 1;
        normals ~= 0;
        normals ~= 0;
        // x, y
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
        textureCoordinates ~= textureBottomRight.x;
        textureCoordinates ~= textureBottomRight.y;

        // TRI 2: Upper right

        // Top left
        // x, y, z

        // x, y, z
        normals ~= 1;
        normals ~= 0;
        normals ~= 0;
        // x, y
        textureCoordinates ~= textureTopLeft.x;
        textureCoordinates ~= textureTopLeft.y;

        // Bottom Right
        // x, y, z

        // x, y, z
        normals ~= 1;
        normals ~= 0;
        normals ~= 0;
        // x, y
        textureCoordinates ~= textureBottomRight.x;
        textureCoordinates ~= textureBottomRight.y;

        // Top Right
        // x, y, z

        // x, y, z
        normals ~= 1;
        normals ~= 0;
        normals ~= 0;
        // x, y
        textureCoordinates ~= textureTopRight.x;
        textureCoordinates ~= textureTopRight.y;



        myMesh.vertices = vertices.ptr;
        //myMesh.normals = normals.ptr;
        myMesh.texcoords = textureCoordinates.ptr;

        UploadMesh(&myMesh, false);

        return myMesh;
    }
}

alias test = BlockGraphics.test;