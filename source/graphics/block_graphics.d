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
struct Face {
    Vector3[6] vertex;
    TexturePosition[6] textureCoordinate;

    this(Vector3[6] vertexData, TexturePosition[6] textureCoordinateData) {
        this.vertex = vertexData;
        this.textureCoordinate = textureCoordinateData;                
    }
}

private enum Quad {
    RIGHT = Face(
        [
            // Lower left tri
            Vector3(0,1,0), // Top left
            Vector3(0,0,0), // Bottom left
            Vector3(0,0,1), // Bottom right
            // Upper right tri
            Vector3(0,1,0), // Top left
            Vector3(0,0,1), // Bottom right
            Vector3(0,1,1)  // Top right
        ],
        [
            TEXTURE_TOP_LEFT,
            TEXTURE_BOTTOM_LEFT,
            TEXTURE_BOTTOM_RIGHT,

            TEXTURE_TOP_LEFT,
            TEXTURE_BOTTOM_RIGHT,
            TEXTURE_TOP_RIGHT
        ]
    ),
    LEFT = Face(
        [
            // Lower left tri
            Vector3(1,0,1), // Bottom right
            Vector3(1,0,0), // Bottom left
            Vector3(1,1,0), // Top left
            // Upper right tri
            Vector3(1,1,1), // Top right
            Vector3(1,0,1), // Bottom right
            Vector3(1,1,0)  // Top left
        ],
        [
            TEXTURE_BOTTOM_RIGHT,
            TEXTURE_BOTTOM_LEFT,
            TEXTURE_TOP_LEFT,

            TEXTURE_TOP_RIGHT,
            TEXTURE_BOTTOM_RIGHT,
            TEXTURE_TOP_LEFT
        ]
    )
}
alias QUAD_RIGHT = Quad.RIGHT;
alias QUAD_LEFT  = Quad.LEFT;

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

alias TEXTURE_TOP_LEFT     = TexturePosition.TOP_LEFT;
alias TEXTURE_TOP_RIGHT    = TexturePosition.TOP_RIGHT;
alias TEXTURE_BOTTOM_LEFT  = TexturePosition.BOTTOM_LEFT;
alias TEXTURE_BOTTOM_RIGHT = TexturePosition.BOTTOM_RIGHT;

// This starts at 0,0
// Automatically dispatches texture coordinates
// Needs to be precalculated for adjustment on custom blocks like stairs
Vector2 getTexturePosition(Vector2I indexPosition, TexturePosition texturePosition) {
    return Vector2(
        ((indexPosition.x + texturePosition.x) * textureTileSize) / textureMapSize,
        ((indexPosition.y + texturePosition.y) * textureTileSize) / textureMapSize
    );
}

// Automatically dispatches and constructs precalculated data
void insertVertexPositions(ref float[] vertices, ref float[] textureCoordinates, ref int triangleCount,
    Vector2I blockTexturePosition, Quad thisQuad) {

    foreach (Vector3 position; thisQuad.vertex) {
        vertices ~= position.x;
        vertices ~= position.y;
        vertices ~= position.z;
    }
    triangleCount += 2;

    foreach (TexturePosition position; thisQuad.textureCoordinate) {

        Vector2 floatPosition = getTexturePosition(blockTexturePosition, position);
        textureCoordinates ~= floatPosition.x;
        textureCoordinates ~= floatPosition.y;        
    }
}

public static class BlockGraphics {
    public static Mesh test() {

        // Texture will be taken from the grass side texture
        Vector2I grassPosition = Vector2I(0,0);

        Mesh myMesh = Mesh();

        float[] vertices;
        float[] normals;
        float[] textureCoordinates;

        int triangleCount = 0;

        // For dispatching colors ubyte[]

        // Texture coordinates
        Vector2 textureTopLeft     = getTexturePosition(grassPosition, TEXTURE_TOP_LEFT);
        Vector2 textureTopRight    = getTexturePosition(grassPosition, TEXTURE_TOP_RIGHT);
        Vector2 textureBottomLeft  = getTexturePosition(grassPosition, TEXTURE_BOTTOM_LEFT);
        Vector2 textureBottomRight = getTexturePosition(grassPosition, TEXTURE_BOTTOM_RIGHT);


        // Wound counter clockwise

        // TRI 1: Lower left

        insertVertexPositions(vertices, textureCoordinates, triangleCount, grassPosition, QUAD_LEFT);
        writeln(vertices);
        
        // Top left
        // x, y, z

        // x, y, z
        normals ~= 1;
        normals ~= 0;
        normals ~= 0;
        // x, y
        // textureCoordinates ~= textureTopLeft.x;
        // textureCoordinates ~= textureTopLeft.y;

        // Bottom left
        // x, y, z

        // x, y, z
        normals ~= 1;
        normals ~= 0;
        normals ~= 0;
        // x, y
        // textureCoordinates ~= textureBottomLeft.x;
        // textureCoordinates ~= textureBottomLeft.y;

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
        // textureCoordinates ~= textureBottomRight.x;
        // textureCoordinates ~= textureBottomRight.y;

        // TRI 2: Upper right

        // Top left
        // x, y, z

        // x, y, z
        normals ~= 1;
        normals ~= 0;
        normals ~= 0;
        // x, y
        // textureCoordinates ~= textureTopLeft.x;
        // textureCoordinates ~= textureTopLeft.y;

        // Bottom Right
        // x, y, z

        // x, y, z
        normals ~= 1;
        normals ~= 0;
        normals ~= 0;
        // x, y
        // textureCoordinates ~= textureBottomRight.x;
        // textureCoordinates ~= textureBottomRight.y;

        // Top Right
        // x, y, z

        // x, y, z
        normals ~= 1;
        normals ~= 0;
        normals ~= 0;
        // x, y
        // textureCoordinates ~= textureTopRight.x;
        // textureCoordinates ~= textureTopRight.y;

        myMesh.triangleCount = triangleCount;
        // 3 is the number of vertex points per triangle
        myMesh.vertexCount = triangleCount * 3;


        myMesh.vertices = vertices.ptr;
        //myMesh.normals = normals.ptr;
        myMesh.texcoords = textureCoordinates.ptr;

        UploadMesh(&myMesh, false);

        return myMesh;
    }
}

alias test = BlockGraphics.test;