module graphics.block_graphics_try_three;

import std.stdio;
import raylib;
import helpers.structs;
import std.math: abs;

// Defines how many textures are in the texture map
const double TEXTURE_MAP_TILES = 32;
// Defines the width/height of each texture
const double TEXTURE_TILE_SIZE = 16;
// Defines the total width/height of the texture map in pixels
const double TEXTURE_MAP_SIZE = TEXTURE_TILE_SIZE * TEXTURE_MAP_TILES;

// Immutable face vertex positions
// This is documented as if you were facing the quad with it's texture position aligned to you
// Idices order = [ 3, 0, 1, 1, 2, 3 ]
immutable Vector3[4][6] FACE = [
    // Axis base:        X 0
    // Normal direction: X -1
    [
        Vector3(0,1,0), // Top Left     | 0
        Vector3(0,0,0), // Bottom Left  | 1
        Vector3(0,0,1), // Bottom Right | 2
        Vector3(0,1,1), // Top Right    | 3   
    ],
    // Axis base:        Y 0
    // Normal direction: Y -1
    [
        Vector3(1,0,1), // Top Left     | 0
        Vector3(0,0,1), // Bottom Left  | 1
        Vector3(0,0,0), // Bottom Right | 2
        Vector3(1,0,0), // Top Right    | 3
    ],
    // Axis base:        Z 0
    // Normal direction: Z -1
    [
        Vector3(1,1,0), // Top Left     | 0
        Vector3(1,0,0), // Bottom Left  | 1
        Vector3(0,0,0), // Bottom Right | 2
        Vector3(0,1,0), // Top Right    | 3
    ],


    // Axis base:        X 1
    // Normal direction: X 1
    [
        Vector3(1,1,1), // Top Left     | 0
        Vector3(1,0,1), // Bottom Left  | 1
        Vector3(1,0,0), // Bottom Right | 2
        Vector3(1,1,0), // Top Right    | 3
    ],
    // Axis base:        Y 1
    // Normal direction: Y 1
    [
        Vector3(1,1,0), // Top Left     | 0
        Vector3(0,1,0), // Bottom Left  | 1
        Vector3(0,1,1), // Bottom Right | 2
        Vector3(1,1,1), // Top Right    | 3
    ],
    // Axis base:        Z 1
    // Normal direction: Z 1
    [
        Vector3(0,1,1), // Top Left     | 0
        Vector3(0,0,1), // Bottom Left  | 1
        Vector3(1,0,1), // Bottom Right | 2
        Vector3(1,1,1), // Top Right    | 3
    ],
];

// Immutable index order
immutable ushort[] INDICES = [ 3, 0, 1, 1, 2, 3 ];

// Normals allow modders to bolt on lighting
immutable Vector3[6] NORMAL = [
    Vector3(-1, 0, 0), // Back   | 0
    Vector3( 0,-1, 0), // Bottom | 1
    Vector3( 0, 0,-1), // Left   | 2
    Vector3( 1, 0, 0), // Front  | 3
    Vector3( 0, 1, 0), // Top    | 4
    Vector3( 0, 0, 1)  // Right  | 5
];

// Immutable texture position
immutable Vector2[4] TEXTURE_POSITION = [
    Vector2(0,0), // Top left     | 0
    Vector2(0,1), // Bottom Left  | 1
    Vector2(1,1), // Bottom right | 2
    Vector2(1,0)  // Top right    | 3
];

immutable Vector2I[4][6] TEXTURE_CULL = [
    // Back face
    // -X
    // Z and Y affect this
    [
        Vector2I(2,10),
        Vector2I(2,7),
        Vector2I(5,7),
        Vector2I(5,10)
    ],
    // Bottom face
    // -Y
    // X and Z affect this
    [
        Vector2I(11,9),
        Vector2I(11,6),
        Vector2I(8,6),
        Vector2I(8,9)
    ],
    // Left face
    // -Z
    // X and Y affect this
    [
        Vector2I(9,10),
        Vector2I(9,7),
        Vector2I(6,7),
        Vector2I(6,10)
    ],


    // Front face
    // +X
    // Z and Y affect this
    [
        Vector2I(11,10),
        Vector2I(11,7),
        Vector2I(8,7),
        Vector2I(8,10)
    ],
    // Top face
    // +Y
    // X and Z affect this
    [
        Vector2I(2,9),
        Vector2I(2,6),
        Vector2I(5,6),
        Vector2I(5,9)
    ],
    // Right face
    // +Z
    // X and Y affect this
    [
        Vector2I(0,10),
        Vector2I(0,7),
        Vector2I(3,7),
        Vector2I(3,10)
    ],
];

// An automatic index builder
void buildIndices(ref ushort[] indices, ref int vertexCount) {
    for (ushort i = 0; i < 6; i++) {
        indices ~= cast(ushort)(INDICES[i] + vertexCount);
    }
    vertexCount += 4;
}



// Assembles a block mesh piece and appends the necessary data
void buildBlock(
    ref float[] vertices,
    ref float[] textureCoordinates,
    ref ushort[] indices,
    ref int triangleCount,
    ref int vertexCount,
    BlockGraphicDefinition graphicsDefiniton
){

    ubyte rotation = 0;

    float[6][] blockBox = graphicsDefiniton.blockBox;
    Vector2I[6] textureDefinition = graphicsDefiniton.blockTextures;

    Vector3 max = Vector3( 1,  1,  1 );
    Vector3 min = Vector3( 0,  0,  0 );

    // This needs to check for custom meshes and drawtypes
    bool isBlockBox = (blockBox.length > 0);    

    // Allows normal blocks to be indexed with blank blockbox
    for (int w = 0; w <= blockBox.length; w++) {

        // Automatic breakout
        if (w >= blockBox.length && isBlockBox) {
            break;
        }

        // If it is a blockbox, override defaults
        if (isBlockBox) {
            min = Vector3(blockBox[w][0], blockBox[w][1], blockBox[w][2]);
            max = Vector3(blockBox[w][3], blockBox[w][4], blockBox[w][5]);
        }

        // Override min and max here if applicable

        for (int i = 0; i < 6; i++) {

            // Very important this is held on the stack
            float[6] textureCullArray = [min.x, min.y, min.z, max.x, max.y, max.z];

            Vector2I currentTexture = textureDefinition[i];

            // Assign the indices
            buildIndices(indices, vertexCount);

            for (int f = 0; f < 4; f++) {

                // int r = rotateTopAndBottomTexture(i, rotation, f);

                // Assign the vertex positions
                vertices ~= (FACE[i][f].x == 0 ? min.x : max.x);
                vertices ~= (FACE[i][f].y == 0 ? min.y : max.y);
                vertices ~= (FACE[i][f].z == 0 ? min.z : max.z);

                // Assign texture coordinates// Assign texture coordinates

                final switch (isBlockBox) {

                    case false: {
                        // Normal drawtype
                        textureCoordinates ~= ((TEXTURE_POSITION[f].x + currentTexture.x) * TEXTURE_TILE_SIZE) / TEXTURE_MAP_SIZE;
                        textureCoordinates ~= ((TEXTURE_POSITION[f].y + currentTexture.y) * TEXTURE_TILE_SIZE) / TEXTURE_MAP_SIZE;
                        break;
                    }
                    case true: {
                        // Blockbox drawtype
                        Vector2I textureCull = TEXTURE_CULL[i][f];

                        // This can be written as a ternary, but easier to understand like this
                        final switch (textureCull.x > 5) {
                            case true: {
                                textureCoordinates ~= ((abs(textureCullArray[textureCull.x - 6] - 1) + currentTexture.x) * TEXTURE_TILE_SIZE) / TEXTURE_MAP_SIZE;
                                break;
                            }
                            case false: {
                                textureCoordinates ~= ((textureCullArray[textureCull.x] + currentTexture.x) * TEXTURE_TILE_SIZE) / TEXTURE_MAP_SIZE;
                                break;
                            }
                        }
                        final switch (textureCull.y > 5) {
                            case true: {
                                textureCoordinates ~= ((abs(textureCullArray[textureCull.y - 6] - 1) + currentTexture.y) * TEXTURE_TILE_SIZE) / TEXTURE_MAP_SIZE;
                                break;
                            }
                            case false: {
                                textureCoordinates ~= ((textureCullArray[textureCull.y] + currentTexture.y) * TEXTURE_TILE_SIZE) / TEXTURE_MAP_SIZE;
                                break;
                            }
                        }
                        break;
                    }
                }
            }
            // Tick up tri count
            triangleCount += 2;
        }
    }
}





struct BlockGraphicDefinition {
    float[6][] blockBox;
    Vector2I[6] blockTextures;

    this(float[6][] blockBox, Vector2I[6] blockTextures) {
        this.blockBox = blockBox;
        this.blockTextures = blockTextures;
    }
}


public static class BlockGraphics {
    BlockGraphicDefinition[uint] definitions;
    
    void registerBlockGraphicsDefinition(uint id, float[6][] blockBox, Vector2I[6] blockTextures){
        this.definitions[id] = BlockGraphicDefinition(
            blockBox, blockTextures
        );
    }
    
}

public static Mesh testAPI(uint ID) {

    //BlockGraphicDefinition currentDefinition = this.definitions[ID];
    // BlockTextures currentBlockTextures = currentDefinition.blockTextures;
    // BlockBox currentBlockBox = currentDefinition.blockBox;

    BlockGraphicDefinition definition = BlockGraphicDefinition(
        [
            [0,0,0,1,0.5,1],
            [0,0,0,0.5,1,1]
        ],
        [
            Vector2I(4,0),
            Vector2I(5,0),
            Vector2I(6,0),
            Vector2I(7,0),
            Vector2I(8,0),
            Vector2I(9,0)
        ]
    );

    Mesh myMesh = Mesh();

    float[] vertices;
    ushort[] indices;
    // float[] normals;
    float[] textureCoordinates;

    int triangleCount = 0;
    int vertexCount   = 0;

    buildBlock(vertices, textureCoordinates,indices,triangleCount,vertexCount,definition);

    writeln("vertex: ", vertexCount, " | triangle: ", triangleCount);


    // For dispatching colors ubyte[]

    // 0 0 degrees, 1 90 degrees, 2, 180 degrees, 3 270 degrees
    // byte rotation = 3;

    myMesh.triangleCount = triangleCount;
    // 3 is the number of vertex points per triangle
    myMesh.vertexCount = vertexCount;

    myMesh.vertices  = vertices.ptr;
    myMesh.indices   = indices.ptr;
    // myMesh.normals   = normals.ptr;
    myMesh.texcoords = textureCoordinates.ptr;

    UploadMesh(&myMesh, false);

    return myMesh;
}