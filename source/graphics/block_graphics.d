module graphics.block_graphics;

import std.stdio;
import raylib;

/*

IMPORTANT NOTE:

When registering a block with a custom block box, you must multiply the texture coordinates to align
with the defined pixel count size of the box. You must also do the same thing to the faces.

*/


// Makes writing a block definition easier
struct Vector2I {
    int x = 0;
    int y = 0;
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
    // Blocks are square in face, rigid, axis aligned. Only need one direction per face
    Vector3 normal;


    this(Vector3[6] vertexData, TexturePosition[6] textureCoordinateData, Vector3 normals) {
        this.vertex = vertexData;
        this.textureCoordinate = textureCoordinateData;
        this.normal = normal;
    }
}

/*
Quick notes on face directions

All normals are rooted in point 0 to 1 for ease of use
when translating literal data into visual data. Allows
maximum ease of use when designing collision detection.
Also allows flooring a position and casting it to int to
get the position a lot easier.

-X is the back
+X is the front

*/
private enum Quad {
    BACK = Face(
        // Vertex
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
        // Texture positions
        [
            TEXTURE_TOP_LEFT,
            TEXTURE_BOTTOM_LEFT,
            TEXTURE_BOTTOM_RIGHT,

            TEXTURE_TOP_LEFT,
            TEXTURE_BOTTOM_RIGHT,
            TEXTURE_TOP_RIGHT
        ],
        // Normal
        Vector3(-1,0,0)
    ),
    FRONT = Face(
        // Vertex
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
        // Texture positions
        [
            TEXTURE_BOTTOM_LEFT,
            TEXTURE_BOTTOM_RIGHT,
            TEXTURE_TOP_RIGHT,

            TEXTURE_TOP_LEFT,
            TEXTURE_BOTTOM_LEFT,
            TEXTURE_TOP_RIGHT
        ],
        // Normal
        Vector3(1,0,0)
    ),
    LEFT = Face(
        // Vertex
        [
            // Lower left tri
            Vector3(1,0,0), // Bottom right
            Vector3(0,0,0), // Bottom left
            Vector3(0,1,0), // Top left
            // Upper right tri
            Vector3(1,1,0), // Top right
            Vector3(1,0,0), // Bottom right
            Vector3(0,1,0)  // Top left
        ],
        // Texture positions
        [
            TEXTURE_BOTTOM_LEFT,
            TEXTURE_BOTTOM_RIGHT,
            TEXTURE_TOP_RIGHT,

            TEXTURE_TOP_LEFT,
            TEXTURE_BOTTOM_LEFT,
            TEXTURE_TOP_RIGHT
        ],
        // Normal
        Vector3(0,0,-1)
    ),
    RIGHT = Face(
        // Vertex
        [
            // Lower left tri
            Vector3(0,1,1), // Top left
            Vector3(0,0,1), // Bottom left
            Vector3(1,0,1), // Bottom right
            // Upper right tri
            Vector3(0,1,1), // Top left
            Vector3(1,0,1), // Bottom right
            Vector3(1,1,1)  // Top right
        ],
        // Texture positions
        [
            TEXTURE_TOP_LEFT,
            TEXTURE_BOTTOM_LEFT,
            TEXTURE_BOTTOM_RIGHT,

            TEXTURE_TOP_LEFT,
            TEXTURE_BOTTOM_RIGHT,
            TEXTURE_TOP_RIGHT
            
        ],
        // Normal
        Vector3(0,0,1)
    ),
    BOTTOM = Face(
        // Vertex
        [
            // Lower left tri
            Vector3(0,0,1), // Top left
            Vector3(0,0,0), // Bottom left
            Vector3(1,0,0), // Bottom right
            
            // Upper right tri
            Vector3(1,0,1),  // Top right
            Vector3(0,0,1), // Top left
            Vector3(1,0,0), // Bottom right
            
        ],
        // Texture positions
        [
            TEXTURE_BOTTOM_LEFT,
            TEXTURE_BOTTOM_RIGHT,
            TEXTURE_TOP_RIGHT,

            TEXTURE_TOP_LEFT,
            TEXTURE_BOTTOM_LEFT,
            TEXTURE_TOP_RIGHT,
        ],
        // Normal
        Vector3(0,-1,0)
    ),
    TOP = Face(
        // Vertex
        [
            // Lower left tri
            Vector3(1,1,0), // Bottom right
            Vector3(0,1,0), // Bottom left
            Vector3(0,1,1), // Top left
            
            // Upper right tri
            Vector3(1,1,0), // Bottom right
            Vector3(0,1,1), // Top left
            Vector3(1,1,1),  // Top right        
            
        ],
        // Texture positions
        [
            TEXTURE_TOP_LEFT,            
            TEXTURE_BOTTOM_LEFT,
            TEXTURE_BOTTOM_RIGHT,

            TEXTURE_TOP_LEFT,
            TEXTURE_BOTTOM_RIGHT,
            TEXTURE_TOP_RIGHT,
        ],
        // Normal
        Vector3(0,1,0)
    ),
}
alias QUAD_BACK   = Quad.BACK;
alias QUAD_FRONT  = Quad.FRONT;
alias QUAD_LEFT   = Quad.LEFT;
alias QUAD_RIGHT  = Quad.RIGHT;
alias QUAD_BOTTOM = Quad.BOTTOM;
alias QUAD_TOP    = Quad.TOP;


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
void insertVertexPositions(ref float[] vertices, ref float[] textureCoordinates, ref float[] normals, 
                                ref int triangleCount, Vector2I blockTexturePosition, Quad thisQuad) {

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

    // Matches the vertex positions amount
    for (int i = 0; i < 6; i++) {
        normals ~= thisQuad.normal.x;
        normals ~= thisQuad.normal.y;
        normals ~= thisQuad.normal.z;
    }
}

// Quick way to access draw types
enum DrawType {
    AIR, // Nothing
    NORMAL, // Full block
    TORCH, // Torches
    LIQUID, // Water, lava, etc
    BLOCK_BOX // Custom block
}
alias AIR_DRAWTYPE       = DrawType.AIR;
alias NORMAL_DRAWTYPE    = DrawType.NORMAL;
// These other aliases are placeholders, still figuring out how to structure this
alias TORCH_DRAWTYPE     = DrawType.TORCH;
alias LIQUID_DRAWTYPE    = DrawType.LIQUID;
alias BLOCK_BOX_DRAWTYPE =  DrawType.BLOCK_BOX;

// the min and max positions of the block box
struct BlockBox {
    Vector3 min = Vector3( 0.0, 0.0, 0.0 );
    Vector3 max = Vector3( 1.0, 1.0, 1.0 );
}

struct BlockTextures {
    Vector2I back;
    Vector2I front;
    Vector2I left;
    Vector2I right;
    Vector2I bottom;
    Vector2I top;

    this( Vector2I back, Vector2I front, Vector2I left, Vector2I right, Vector2I bottom, Vector2I top ) {
        this.back = back;
        this.front = front;
        this.left = left;
        this.right = right;
        this.bottom = bottom;
        this.top = top;
    }
}

// Holds the block definition
struct BlockGraphicDefinition {
    uint ID;
    DrawType drawType;
    BlockTextures blockTextures;
    BlockBox blockBox;

    // Later on needs to intake block boxes and translate them into quads
    this(uint ID, DrawType drawType, BlockTextures blockTextures, BlockBox blockBox) {
        this.ID = ID;
        this.drawType = drawType;
        this.blockTextures = blockTextures;
        this.blockBox = blockBox;
    }
}

// Internal graphics API and container for block graphics
public static class BlockGraphics {

    // Simple associative array with type uint
    private static BlockGraphicDefinition[uint] definitions;

    public static void registerBlockGraphic(uint ID, DrawType drawType, BlockTextures blockTextures, BlockBox blockBox){
        this.definitions[ID] = BlockGraphicDefinition(
            ID,
            drawType,
            blockTextures,
            blockBox
        );
    }

    public static void registerDefaultBlocksTest() {
        // Air
        registerBlockGraphic(
            0,
            AIR_DRAWTYPE,
            BlockTextures(),
            BlockBox()
        );
        // Grass block
        registerBlockGraphic(
            // ID
            1,
            // DrawType
            NORMAL_DRAWTYPE,
            // Block Textures Definition
            BlockTextures(
                // Back
                Vector2I(0,0),
                // Front
                Vector2I(0,0),
                // Left
                Vector2I(0,0),
                // Right
                Vector2I(0,0),
                // Bottom
                Vector2I(2,0),
                // Top
                Vector2I(1,0)
            ),
            BlockBox()
        );
    }


    public static Mesh testAPI(uint ID) {

        BlockGraphicDefinition currentDefinition = this.definitions[ID];
        BlockTextures currentBlockTextures = currentDefinition.blockTextures;

        Mesh myMesh = Mesh();

        float[] vertices;
        float[] normals;
        float[] textureCoordinates;

        int triangleCount = 0;

        // For dispatching colors ubyte[]

        insertVertexPositions(
            vertices,
            textureCoordinates,
            normals,
            triangleCount,
            currentBlockTextures.back,
            QUAD_BACK
        );
        /*
        insertVertexPositions(vertices, textureCoordinates, normals, triangleCount, currentBlockTextures.front, QUAD_FRONT);
        insertVertexPositions(vertices, textureCoordinates, normals, triangleCount, currentBlockTextures.left, QUAD_LEFT);
        insertVertexPositions(vertices, textureCoordinates, normals, triangleCount, currentBlockTextures.right, QUAD_RIGHT);
        insertVertexPositions(vertices, textureCoordinates, normals, triangleCount, currentBlockTextures.bottom, QUAD_BOTTOM);
        insertVertexPositions(vertices, textureCoordinates, normals, triangleCount, currentBlockTextures.top, QUAD_TOP);
        */
        

        myMesh.triangleCount = triangleCount;
        // 3 is the number of vertex points per triangle
        myMesh.vertexCount = triangleCount * 3;


        myMesh.vertices = vertices.ptr;
        myMesh.normals = normals.ptr;
        myMesh.texcoords = textureCoordinates.ptr;

        UploadMesh(&myMesh, false);

        return myMesh;
    }
}

alias testRegister = BlockGraphics.registerDefaultBlocksTest;
alias testAPI = BlockGraphics.testAPI;