module code_vault.block_graphics;

import std.stdio;
import raylib;
import helpers.structs;
import std.math: abs;

/*

IMPORTANT NOTE:

When registering a block with a custom block box, you must multiply the texture coordinates to align
with the defined pixel count size of the box. You must also do the same thing to the faces.

*/


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

Face[] faceArray = [QUAD_BACK, QUAD_FRONT, QUAD_LEFT, QUAD_RIGHT, QUAD_BOTTOM, QUAD_TOP];


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
// An additional dispatcher for texture coordinates
// This one does much more math to get precise values
Vector2 getTexturePositionBlockBox(
    Vector2I indexPosition,
    TexturePosition texturePosition,
    float minX,
    float maxX,
    float minY,
    float maxY,
    bool invertX,
    bool invertY) {


    /*
    BlockBox([
                BlockBoxDefinition(Vector3(0,0,0), Vector3(1,0.5,1)),
                BlockBoxDefinition(Vector3(0,0,0), Vector3(0.5,1,1)),
            ])

    */
    
    // Can't use a switch here sadly
    if (texturePosition == TEXTURE_TOP_LEFT) {
        
        float posX;
        float posY;

        if (invertX) {
            posX = ((indexPosition.x + 1 - maxX) * textureTileSize) / textureMapSize;
        } else {
            posX = ((indexPosition.x + minX) * textureTileSize) / textureMapSize;
        }

        if (invertY) {
            posY = ((indexPosition.y + minY) * textureTileSize) / textureMapSize;
        } else {
            posY = ((indexPosition.y + 1 - maxY) * textureTileSize) / textureMapSize;
        }
        return Vector2(posX, posY);
    }
    else if (texturePosition == TEXTURE_TOP_RIGHT) {

        float posX;
        float posY;
        if (invertX) {
            posX = ((indexPosition.x + 1 - minX) * textureTileSize) / textureMapSize;
        } else {
            posX = ((indexPosition.x + maxX) * textureTileSize) / textureMapSize;
        }

        if (invertY) {
            posY = ((indexPosition.y + minY) * textureTileSize) / textureMapSize;
        } else {
            posY = ((indexPosition.y + 1 - maxY) * textureTileSize) / textureMapSize;
        }
        return Vector2(posX, posY);
    }
    else if (texturePosition == TEXTURE_BOTTOM_LEFT) {
        float posX;
        float posY;

        if (invertX) {
            posX = ((indexPosition.x + 1 - maxX) * textureTileSize) / textureMapSize;
        } else {
            posX = ((indexPosition.x + minX) * textureTileSize) / textureMapSize;
        }

        if (invertY) {
            posY = ((indexPosition.y + maxY) * textureTileSize) / textureMapSize;
        } else {
            posY = ((indexPosition.y + 1 - minY) * textureTileSize) / textureMapSize;
        }
        return Vector2(posX, posY);

    }
    else if (texturePosition == TEXTURE_BOTTOM_RIGHT) {
        float posX;
        float posY;

        if (invertX) {
            posX = ((indexPosition.x + 1 - minX) * textureTileSize) / textureMapSize;
        } else {
            posX = ((indexPosition.x + maxX) * textureTileSize) / textureMapSize;
        }

        if (invertY) {
            posY = ((indexPosition.y + maxY) * textureTileSize) / textureMapSize;
        } else {
            posY = ((indexPosition.y + 1 - minY) * textureTileSize) / textureMapSize;
        }
        return Vector2(posX, posY);
    }

    // Failed
    return Vector2();
}

// Tells what faces to generate
struct PositionsBool {
    bool back;
    bool front;
    bool left;
    bool right;
    bool bottom;
    bool top;
    this(bool back, bool front, bool left, bool right, bool bottom, bool top) {
        this.back   = back;
        this.front  = front;
        this.left   = left;
        this.right  = right;
        this.bottom = bottom;
        this.top    = top;
    }
    // Simple bolt on iterator
    bool[6] getIterator() {
        return [this.back,this.front,this.left,this.right,this.bottom, this.top];
    }

    bool get(int i) {
        switch(i){
            case 0: return this.back;
            case 1: return this.front;
            case 2: return this.left;
            case 3: return this.right;
            case 4: return this.bottom;
            case 5: return this.top;
            default:{
                return false;
            }
        }
    }
}
BlockBoxDefinition translateBlockBoxRotation(BlockBoxDefinition thisBlockBox, byte rotation) {
    final switch (rotation) {

        // Rotation 0 degrees clockwise facing down
        case 0: {
            // Doesn't have to do anything
            return thisBlockBox;
        }
        // Rotation 90 degrees clockwise facing down
        case 1: {
            Vector3 oldMin = thisBlockBox.min;
            Vector3 oldMax = thisBlockBox.max;
            Vector3 newMin = Vector3(
                abs(oldMax.z - 1),
                oldMin.y,
                oldMin.x
            );

            Vector3 newMax = Vector3(
                abs(oldMin.z - 1),
                oldMax.y,
                oldMax.x
            );

            return BlockBoxDefinition(newMin, newMax);  
        }
        // Rotation 180 degrees clockwise facing down
        case 2: {
            Vector3 oldMin = thisBlockBox.min;
            Vector3 oldMax = thisBlockBox.max;

            Vector3 newMin = Vector3(
                abs(oldMax.x - 1),
                oldMin.y,
                abs(oldMax.z - 1)
            );

            Vector3 newMax = Vector3(
                abs(oldMin.x - 1),
                oldMax.y,
                abs(oldMin.z - 1)
            );
            
            return BlockBoxDefinition(newMin, newMax);
        }
        // Rotation 270 degrees clockwise facing down
        case 3: {
            Vector3 oldMin = thisBlockBox.min;
            Vector3 oldMax = thisBlockBox.max;

            Vector3 newMin = Vector3(
                oldMin.z,
                oldMin.y,
                abs(oldMax.x - 1)
            );

            Vector3 newMax = Vector3(
                oldMax.z,
                oldMax.y,
                abs(oldMin.x - 1)
            );
            
            return BlockBoxDefinition(newMin, newMax);                 
        }
        // Loops back to 0
    }
}

// Automatically dispatches and constructs precalculated data
void insertVertexPositions(
    ref float[] vertices,
    ref float[] textureCoordinates,
    ref float[] normals,
    ref int triangleCount,
    BlockGraphicDefinition blockGraphicDefinition,
    PositionsBool positionsBool,
    Vector3I position,
    byte rotation
    ) {

    /*
    back   0
    front  1
    left   2
    right  3
    bottom 4
    top    5
    */

    DrawType drawType = blockGraphicDefinition.drawType;
    BlockTextures textureCoordinate = blockGraphicDefinition.blockTextures;
    BlockBox blockBox = blockGraphicDefinition.blockBox;

    // This is very complex, I wish you the best understanding it

    /*
    texture
    0 back
    1 front
    2 left
    3 right

    face
    0 back
    1 front
    2 left
    3 right
    */

    int[][] faceRotationSelections = [
      // 0,1,2,3
        [0,1,2,3], //  Case 0 is always ignored
        [3,2,0,1],
        [1,0,3,2],
        [2,3,1,0]
    ];

    int textureRotation(int currentFace, byte currentRotation) {
        if (currentFace > 3 || currentRotation == 0) {
            return currentFace;
        }
        return faceRotationSelections[rotation][currentFace];
    }


    // Check drawtype
    switch (drawType) {

        // It's air, pass
        case AIR_DRAWTYPE: {/*does nothing*/ break;}

        // It's a normal block
        // Needs to get block rotation in the future
        case NORMAL_DRAWTYPE: {

            // Iterate all 6 faces
            for (int i = 0; i < 6; i++) {

                // If it's culled out, move onto the next face
                if (!positionsBool.get(i)) {
                    continue;
                }

                Face thisQuad = faceArray[i];

                foreach (Vector3 vertexPosition; thisQuad.vertex) {
                    vertices ~= vertexPosition.x;
                    vertices ~= vertexPosition.y;
                    vertices ~= vertexPosition.z;
                }

                triangleCount += 2;

                foreach (TexturePosition texturePosition; thisQuad.textureCoordinate) {
                    Vector2 floatPosition = getTexturePosition(textureCoordinate.get(i), texturePosition);
                    textureCoordinates ~= floatPosition.x;
                    textureCoordinates ~= floatPosition.y;
                }

                // Matches the vertex positions amount
                for (int w = 0; w < 6; w++) {
                    normals ~= thisQuad.normal.x;
                    normals ~= thisQuad.normal.y;
                    normals ~= thisQuad.normal.z;
                }
            }
            break;
        }


        // Block box
        case BLOCK_BOX_DRAWTYPE: {

            foreach (BlockBoxDefinition thisBlockBox; blockBox.boxes) {

                BlockBoxDefinition rotatedBlockBox = translateBlockBoxRotation(thisBlockBox, rotation);

                Vector3 min = rotatedBlockBox.min;
                Vector3 max = rotatedBlockBox.max;

                // Iterate all 6 faces
                for (int i = 0; i < 6; i++) {

                    // If it's culled out, move onto the next face
                    
                    // Important note, make a block box with a face size equal to normal cull out like normal with adjacent block

                    if (!positionsBool.get(i)) {
                        continue;
                    }

                    Face thisQuad = faceArray[i];

                    foreach (Vector3 vertexPosition; thisQuad.vertex) {
                        vertices ~= (vertexPosition.x == 0 ? min.x : max.x);
                        vertices ~= (vertexPosition.y == 0 ? min.y : max.y);
                        vertices ~= (vertexPosition.z == 0 ? min.z : max.z);
                    }

                    triangleCount += 2;
                    

                    int textureRotationSwitch = textureRotation(i, rotation);

                    
                    // Cannot derive any pattern from 3D to 2D so this will unfortunately
                    // be a manual interop
                    // These are the texture points of the two tris, that's why there are 6 cases

                    // Sides match against the texture rotation switch

                    switch(textureRotationSwitch){
                        // Back
                        case 0:{
                            foreach (TexturePosition texturePosition; thisQuad.textureCoordinate) {
                                Vector2 floatPosition = getTexturePositionBlockBox(
                                    textureCoordinate.get(textureRotationSwitch),
                                    texturePosition,
                                    min.z, max.z, min.y, max.y, false, false);
                                textureCoordinates ~= floatPosition.x;
                                textureCoordinates ~= floatPosition.y;
                            }
                            break;
                        }
                        // Front
                        case 1:{
                            foreach (TexturePosition texturePosition; thisQuad.textureCoordinate) {
                                Vector2 floatPosition = getTexturePositionBlockBox(
                                    textureCoordinate.get(textureRotationSwitch),
                                    texturePosition,
                                    min.z, max.z, min.y, max.y, true, false);
                                textureCoordinates ~= floatPosition.x;
                                textureCoordinates ~= floatPosition.y;
                            }
                            break;
                        }
                        // Left
                        case 2:{
                            foreach (TexturePosition texturePosition; thisQuad.textureCoordinate) {
                                Vector2 floatPosition = getTexturePositionBlockBox(
                                    textureCoordinate.get(textureRotationSwitch),
                                    texturePosition,
                                    min.x, max.x, min.y, max.y, true, false);
                                textureCoordinates ~= floatPosition.x;
                                textureCoordinates ~= floatPosition.y;
                            }
                            break;
                        }
                        // Right
                        case 3:{
                            foreach (TexturePosition texturePosition; thisQuad.textureCoordinate) {
                                Vector2 floatPosition = getTexturePositionBlockBox(
                                    textureCoordinate.get(textureRotationSwitch),
                                    texturePosition,
                                    min.x, max.x, min.y, max.y, false, false);
                                textureCoordinates ~= floatPosition.x;
                                textureCoordinates ~= floatPosition.y;
                            }
                            break;
                        }
                        default:{}
                    }

                    // Bottom and top are standard for now
                    switch (i){
                        // Bottom
                        case 4:{
                            foreach (TexturePosition texturePosition; thisQuad.textureCoordinate) {
                                Vector2 floatPosition = getTexturePositionBlockBox(
                                    textureCoordinate.get(i),
                                    texturePosition,
                                    min.z, max.z, min.x, max.x, false, false);
                                textureCoordinates ~= floatPosition.x;
                                textureCoordinates ~= floatPosition.y;
                            }
                            break;
                        }
                        // Top
                        case 5:{
                            foreach (TexturePosition texturePosition; thisQuad.textureCoordinate) {
                                Vector2 floatPosition = getTexturePositionBlockBox(
                                    textureCoordinate.get(i),
                                    texturePosition,
                                    min.z, max.z, min.x, max.x, false, false);
                                textureCoordinates ~= floatPosition.x;
                                textureCoordinates ~= floatPosition.y;
                            }
                            break;
                        }
                        default:{}
                    }
                    

                    // Matches the vertex positions amount
                    for (int w = 0; w < 6; w++) {
                        normals ~= thisQuad.normal.x;
                        normals ~= thisQuad.normal.y;
                        normals ~= thisQuad.normal.z;
                    }
                }
            }
            break;
        }
        default: {/*does nothing*/}
    }
}

// Quick way to access draw types
enum DrawType {
    AIR, // Nothing
    NORMAL, // Full block
    BLOCK_BOX, // Custom block
    TORCH, // Torches
    LIQUID // Water, lava, etc
}
alias AIR_DRAWTYPE       = DrawType.AIR;
alias NORMAL_DRAWTYPE    = DrawType.NORMAL;
alias BLOCK_BOX_DRAWTYPE =  DrawType.BLOCK_BOX;
// These other aliases are placeholders, still figuring out how to structure this
alias TORCH_DRAWTYPE     = DrawType.TORCH;
alias LIQUID_DRAWTYPE    = DrawType.LIQUID;

// the min and max positions of the block box
struct BlockBoxDefinition {
    Vector3 min = Vector3(0,0,0);
    Vector3 max = Vector3(0,0,0);
    this( Vector3 min, Vector3 max ){
        this.min = min;
        this.max = max;
    }
}
// The structure which holds the boxes in array
struct BlockBox {
    BlockBoxDefinition[] boxes;

    this(BlockBoxDefinition[] boxes){
        this.boxes = boxes;
    }
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

    Vector2I get(int i) {
        switch(i){
            case 0: return this.back;
            case 1: return this.front;
            case 2: return this.left;
            case 3: return this.right;
            case 4: return this.bottom;
            case 5: return this.top;
            default:{
                return Vector2I();
            }
        }
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

        // Debug cobble stairs
        registerBlockGraphic(
            // ID
            2,
            // DrawType
            BLOCK_BOX_DRAWTYPE,
            // Block Textures Definition
            BlockTextures(
                // Back
                Vector2I(4,0),
                // Front
                Vector2I(5,0),
                // Left
                Vector2I(6,0),
                // Right
                Vector2I(7,0),
                // Bottom
                Vector2I(8,0),
                // Top
                Vector2I(9,0)
            ),
            BlockBox([
                BlockBoxDefinition(Vector3(0,0,0), Vector3(1,0.5,1)),
                BlockBoxDefinition(Vector3(0,0,0), Vector3(0.5,1,1)),
            ])
        );
    }


    public static Mesh testAPI(uint ID) {

        BlockGraphicDefinition currentDefinition = this.definitions[ID];
        // BlockTextures currentBlockTextures = currentDefinition.blockTextures;
        // BlockBox currentBlockBox = currentDefinition.blockBox;

        Mesh myMesh = Mesh();

        float[] vertices;
        float[] normals;
        float[] textureCoordinates;

        int triangleCount = 0;

        // For dispatching colors ubyte[]

        // 0 0 degrees, 1 90 degrees, 2, 180 degrees, 3 270 degrees
        byte rotation = 3;

        insertVertexPositions(
            vertices,
            textureCoordinates,
            normals,
            triangleCount,
            currentDefinition,
            PositionsBool(true, true, true, true, true,true),
            Vector3I(0,0,0),
            rotation
        );

        myMesh.triangleCount = triangleCount;
        // 3 is the number of vertex points per triangle
        myMesh.vertexCount = triangleCount * 3;

        myMesh.vertices  = vertices.ptr;
        myMesh.normals   = normals.ptr;
        myMesh.texcoords = textureCoordinates.ptr;

        UploadMesh(&myMesh, false);

        return myMesh;
    }
}

alias testRegister = BlockGraphics.registerDefaultBlocksTest;
alias testAPI = BlockGraphics.testAPI;