module game.graphics.block_graphics;

import std.stdio;
import std.math: abs;
import vector_2d;
import vector_2i;
import vector_3d;
import vector_3i;


// Defines how many textures are in the texture map
const double TEXTURE_MAP_TILES = 32;
// Defines the width/height of each texture
const double TEXTURE_TILE_SIZE = 16;
// Defines the total width/height of the texture map in pixels
const double TEXTURE_MAP_SIZE = TEXTURE_TILE_SIZE * TEXTURE_MAP_TILES;

/*

GOAL OF SECOND ITERATION:

1. Simplify
- The functional api needs to be easier to follow

2. Code reduction
- The code needs to have less repetition

3. Data reduction
- The computer should process less data to get the same result

4. Code quality
- Each function should have a goal and achieve that goal well

5. Code reduction
- The code needs to have less repetition



VISUAL DOCUMENTATION:

A face, made of two tris:

0 -x -y                      3 +x -y
  |----------------------------|
  |                          / |
  |                       /    |
  |                    /       |
  |                 /          |
  |              /             |
  |           /                |
  |        /                   |
  |     /                      |
  |  /                         |
  |----------------------------|
1 -x +y                     2 +x +y

Using the 4 vertex positions, we can iterate a face by recycling 2 of the points
into 2 tris. The indices array will make this possible.

The array will look like so: [ 3, 0, 1, 1, 2, 3 ]. This is the indices array.
The indices array tell OpenGL which order to create triangles when rendering.

So [ 3, 0, 1 ] is the top left tri, and [ 1, 2, 3 ] is the bottom right tri.

OpenGL will complete the triangle. So in tri 1, it automatically connects 1 to 3.

This is using this counter clockwise wound tri in this form so the gpu can leverage
pointer index reuse for the majority of the quad, and keep a mostly linear iteration.
This may seem like a micro optimization, but for millions of faces, this will make
quite a noticeable difference. The only outlier in this is the initial position.

|-----------------------------------------------------------------------|
| Very important note: All faces will follow this pattern to save data! |
|                                                                       |
|-----------------------------------------------------------------------|



GOAL OF BLOCKBOX:

A "blockbox" as I'm calling it, is a re-implementation of Minetest's "nodebox" as I've
studied it. The basic gist of a block box is to allow a floating point boundary between
0 (because blocks are based in position 0 on all axis) and 1 (which is the max that they
can reach without running into another block). The basic implementation will be this:

A block box consists of arrays of floating point numbers.

[
    [minx, miny, minz, maxx, maxy, maxz]... so on and so forth
]

If you wanted a normal drawtype blockbox, it would be like so:
[
    [0,0,0,1,1,1]
]
Though, this is not recommended, as I am still deciding on whether or not to cull out
blockbox faces when they are exactly on the edge matching up with a normal block.

A simple staircase would be like so:
[
    [0,0,0,1,0.5,1], // The base of the stair
    [0,0,0,0.5,1,1]  // The top step
]

The blockbox will also have a built in bounds check when it is registered through a block
registration (the world portion, this is the graphics portion of it).

Another major goal of the block box is to automate the texturing from the base texture.
So if you had a half height, or half width block, it would automatically show exactly half
the pixels without stretching or squishing. Basically like you are cutting the texture out
of the texture map pixel perfect and putting it on the face of the block, no matter the rotation.

*/


// Immutable face vertex positions
// This is documented as if you were facing the quad with it's texture position aligned to you
// Idices order = [ 3, 0, 1, 1, 2, 3 ]
immutable Vector3d[4][6] FACE = [
    // Axis base:        X 0
    // Normal direction: X -1
    [
        Vector3d(0,1,0), // Top Left     | 0
        Vector3d(0,0,0), // Bottom Left  | 1
        Vector3d(0,0,1), // Bottom Right | 2
        Vector3d(0,1,1), // Top Right    | 3   
    ],
    // Axis base:        X 1
    // Normal direction: X 1
    [
        Vector3d(1,1,1), // Top Left     | 0
        Vector3d(1,0,1), // Bottom Left  | 1
        Vector3d(1,0,0), // Bottom Right | 2
        Vector3d(1,1,0), // Top Right    | 3
    ],

    // Axis base:        Z 0
    // Normal direction: Z -1
    [
        Vector3d(1,1,0), // Top Left     | 0
        Vector3d(1,0,0), // Bottom Left  | 1
        Vector3d(0,0,0), // Bottom Right | 2
        Vector3d(0,1,0), // Top Right    | 3
    ],
    // Axis base:        Z 1
    // Normal direction: Z 1
    [
        Vector3d(0,1,1), // Top Left     | 0
        Vector3d(0,0,1), // Bottom Left  | 1
        Vector3d(1,0,1), // Bottom Right | 2
        Vector3d(1,1,1), // Top Right    | 3
    ],

    // Axis base:        Y 0
    // Normal direction: Y -1
    [
        Vector3d(1,0,1), // Top Left     | 0
        Vector3d(0,0,1), // Bottom Left  | 1
        Vector3d(0,0,0), // Bottom Right | 2
        Vector3d(1,0,0), // Top Right    | 3
    ],
    // Axis base:        Y 1
    // Normal direction: Y 1
    [
        Vector3d(1,1,0), // Top Left     | 0
        Vector3d(0,1,0), // Bottom Left  | 1
        Vector3d(0,1,1), // Bottom Right | 2
        Vector3d(1,1,1), // Top Right    | 3
    ]
];

// Immutable index order
immutable ushort[] INDICES = [ 3, 0, 1, 1, 2, 3 ];

// Normals allow modders to bolt on lighting
immutable Vector3d[6] NORMAL = [
    Vector3d(-1, 0, 0), // Back   | 0
    Vector3d( 1, 0, 0), // Front  | 1
    Vector3d( 0, 0,-1), // Left   | 2
    Vector3d( 0, 0, 1), // Right  | 3
    Vector3d( 0,-1, 0), // Bottom | 4
    Vector3d( 0, 1, 0)  // Top    | 5
];

// Immutable texture position
immutable Vector2d[4] TEXTURE_POSITION = [
    Vector2d(0,0), // Top left     | 0
    Vector2d(0,1), // Bottom Left  | 1
    Vector2d(1,1), // Bottom right | 2
    Vector2d(1,0)  // Top right    | 3
];

// Texture culling for blockboxes
/*
A switcher for blockbox texture culling
This assigns the texture position to use whatever is defined

Settings:

0 - Min.x
1 - Min.y
2 - Min.z

3 - Max.x
4 - Max.y
5 - Max.z

// These are the same values, but inverted via: abs(value - 1)
6 - Min.x - 0 Translation from normal
7 - Min.y - 1
8 - Min.z - 2

9 - Max.x - 3
10 - Max.y- 4
11 - Max.z- 5

*/
immutable Vector2i[4][6] TEXTURE_CULL = [
    // Back face
    // Z and Y affect this
    [
        Vector2i(2,10),
        Vector2i(2,7),
        Vector2i(5,7),
        Vector2i(5,10)
    ],
    // Front face
    // Z and Y affect this
    [
        Vector2i(11,10),
        Vector2i(11,7),
        Vector2i(8,7),
        Vector2i(8,10)
    ],
    // Left face
    // X and Y affect this
    [
        Vector2i(9,10),
        Vector2i(9,7),
        Vector2i(6,7),
        Vector2i(6,10)
    ],
    // Right face
    // X and Y affect this
    [
        Vector2i(0,10),
        Vector2i(0,7),
        Vector2i(3,7),
        Vector2i(3,10)
    ],
    // Bottom face
    // X and Z affect this
    [
        Vector2i(11,9),
        Vector2i(11,6),
        Vector2i(8,6),
        Vector2i(8,9)
    ],
    // Top face
    // X and Z affect this
    [
        Vector2i(2,9),
        Vector2i(2,6),
        Vector2i(5,6),
        Vector2i(5,9)
    ]
];

// An automatic index builder
void buildIndices(ref int[] indices, ref int vertexCount) {
    for (int i = 0; i < 6; i++) {
        indices ~= INDICES[i] + vertexCount;
    }
    vertexCount += 4;
}

// An automatic rotation translator for what faces are not generated
immutable int[4][4] rotationTranslation = 
[
    // index 0 is always unused for [][here]
    // Back
    [0,2,1,3],
    // Front
    [1,3,0,2],
    // Left
    [2,1,3,0],
    // Right
    [3,0,2,1],
];
int translateRotationRender(int currentFace, ubyte currentRotation){
    // Don't bother if not on the X or Z axis or if no rotation
    if (currentFace > 3 || currentRotation == 0) {
        return currentFace;
    }
    return rotationTranslation[currentFace][currentRotation];
}


// Assembles a block mesh piece and appends the necessary data
private void internalBlockBuilder(
    ref float[] vertices,
    ref float[] textureCoordinates,
    ref int[] indices,
    ref float[] lights,
    ref int triangleCount,
    ref int vertexCount,
    BlockGraphicDefinition graphicsDefiniton,
    Vector3i position,
    ubyte rotation,
    bool[6] renderArray
){

    float[][] blockBox = graphicsDefiniton.blockBox;
    Vector2i[] textureDefinition = graphicsDefiniton.blockTextures;

    Vector3d max = Vector3d( 1,  1,  1 );
    Vector3d min = Vector3d( 0,  0,  0 );

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
            min = Vector3d(blockBox[w][0], blockBox[w][1], blockBox[w][2]);
            max = Vector3d(blockBox[w][3], blockBox[w][4], blockBox[w][5]);
        }

        // Index faces
        for (int i = 0; i < 6; i++) {

            // Don't render this face if it's a normal block
            if (!isBlockBox && !renderArray[translateRotationRender(i, rotation)]) {
                continue;
            }

            immutable float[6] textureCullArray = [min.x, min.y, min.z, max.x, max.y, max.z];

            Vector2i currentTexture = textureDefinition[i];

            // Replace this with light integration
            for (int q = 0; q < 12; q++) {
                lights ~= 1.0;
            }

            // Assign the indices
            buildIndices(indices, vertexCount);

            for (int f = 0; f < 4; f++) {
                // Assign the vertex positions with rotation
                final switch (rotation) {
                    case 0: {
                        vertices ~= (FACE[i][f].x == 0 ? min.x : max.x) + position.x;
                        vertices ~= (FACE[i][f].y == 0 ? min.y : max.y) + position.y;
                        vertices ~= (FACE[i][f].z == 0 ? min.z : max.z) + position.z;
                        break;
                    }
                    case 1: {
                        // Notice: Axis order X and Z are swapped
                        vertices ~= abs((FACE[i][f].z == 0 ? min.z : max.z) - 1) + position.x;
                        vertices ~=     (FACE[i][f].y == 0 ? min.y : max.y)      + position.y;
                        vertices ~=     (FACE[i][f].x == 0 ? min.x : max.x)      + position.z;
                        break;
                    }
                    case 2: {
                        vertices ~= abs((FACE[i][f].x == 0 ? min.x : max.x) - 1) + position.x;
                        vertices ~=     (FACE[i][f].y == 0 ? min.y : max.y)      + position.y;
                        vertices ~= abs((FACE[i][f].z == 0 ? min.z : max.z) - 1) + position.z;
                        break;
                    }
                    case 3: {
                        // Notice: Axis order X and Z are swapped
                        vertices ~=     (FACE[i][f].z == 0 ? min.z : max.z)      + position.x;
                        vertices ~=     (FACE[i][f].y == 0 ? min.y : max.y)      + position.y;
                        vertices ~= abs((FACE[i][f].x == 0 ? min.x : max.x) - 1) + position.z;
                        break;
                    }
                }

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
                        Vector2i textureCull = TEXTURE_CULL[i][f];

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

private struct BlockGraphicDefinition {
    float[][] blockBox;
    Vector2i[] blockTextures;

    this(float[][] blockBox, Vector2i[] blockTextures) {
        for (int i = 0; i < blockBox.length; i++){
            assert(blockBox[i].length == 6, "wrong blockbox length");
        }
        assert(blockTextures.length == 6, "wrong blocktextures length");
        this.blockBox = blockBox.dup;
        this.blockTextures = blockTextures.dup;
    }
}


private BlockGraphicDefinition[uint] definitions;

void registerBlockGraphicsDefinition(uint id, float[][] blockBox, Vector2i[] blockTextures){
    definitions[id] = BlockGraphicDefinition(
        blockBox,
        blockTextures
    );
}

void buildBlock(
    uint ID,
    ref float[] vertices,
    ref float[] textureCoordinates,
    ref int[] indices,
    ref float[] lights,
    ref int triangleCount,
    ref int vertexCount,
    Vector3i position,
    ubyte rotation,
    bool[6] renderArray
    ) {

        if (ID == 0) {  // Replace 0 check with block graphics definition check                
            return;
        }

        BlockGraphicDefinition definition = definitions[ID];

        internalBlockBuilder(
            vertices,
            textureCoordinates,
            indices,
            lights,
            triangleCount,
            vertexCount,
            definition,
            position,
            rotation,
            renderArray
        );
}

