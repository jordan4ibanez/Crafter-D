module graphics.block_graphics_take_two;

import std.stdio;
import raylib;
import helpers.structs;
import std.math: abs;


// Defines how many textures are in the texture map
const double textureMapTiles = 32;
// Defines the width/height of each texture
const double textureTileSize = 16;
// Defines the total width/height of the texture map in pixels
const double textureMapSize = textureTileSize * textureMapTiles;

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
immutable Vector3[4][6] FACE = [
    // Axis base:        X 0
    // Normal direction: X -1
    [
        Vector3(0,1,0), // Top Left     | 0
        Vector3(0,0,0), // Bottom Left  | 1
        Vector3(0,0,1), // Bottom Right | 2
        Vector3(0,1,1), // Top Right    | 3   
    ],
    // Axis base:        X 1
    // Normal direction: X 1
    [
        Vector3(1,1,1), // Top Left     | 0
        Vector3(1,0,1), // Bottom Left  | 1
        Vector3(1,0,0), // Bottom Right | 2
        Vector3(1,1,0), // Top Right    | 3
    ],

    // Axis base:        Z 0
    // Normal direction: Z -1
    [
        Vector3(1,1,0), // Top Left     | 0
        Vector3(1,0,0), // Bottom Left  | 1
        Vector3(0,0,0), // Bottom Right | 2
        Vector3(0,1,0), // Top Right    | 3
    ],
    // Axis base:        Z 1
    // Normal direction: Z 1
    [
        Vector3(0,1,1), // Top Left     | 0
        Vector3(0,0,1), // Bottom Left  | 1
        Vector3(1,0,1), // Bottom Right | 2
        Vector3(1,1,1), // Top Right    | 3
    ],

    // Axis base:        Y 0
    // Normal direction: Y -1
    [
        Vector3(1,0,1), // Top Left     | 0
        Vector3(0,0,1), // Bottom Left  | 1
        Vector3(0,0,0), // Bottom Right | 2
        Vector3(1,0,0), // Top Right    | 3
    ],
    // Axis base:        Y 1
    // Normal direction: Y 1
    [
        Vector3(1,1,0), // Top Left     | 0
        Vector3(0,1,0), // Bottom Left  | 1
        Vector3(0,1,1), // Bottom Right | 2
        Vector3(1,1,1), // Top Right    | 3
    ]
];

// Immutable index order
immutable ushort[] INDICES = [ 3, 0, 1, 1, 2, 3 ];

// Normals allow modders to bolt on lighting
immutable Vector3[6] NORMAL = [
    Vector3(-1, 0, 0), // Back   | 0
    Vector3( 1, 0, 0), // Front  | 1
    Vector3( 0, 0,-1), // Left   | 2
    Vector3( 0, 0, 1), // Right  | 3
    Vector3( 0,-1, 0), // Bottom | 4
    Vector3( 0, 1, 0)  // Top    | 5
];

// Immutable texture position
immutable Vector2[4] TEXTURE_POSITION = [
    Vector2(0,0), // Top left     | 0
    Vector2(0,1), // Bottom Left  | 1
    Vector2(1,1), // Bottom right | 2
    Vector2(1,0)  // Top right    | 3
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
immutable Vector2I[4][6] TEXTURE_CULL = [
    // Back face
    // Z and Y affect this
    [
        Vector2I(2,10),
        Vector2I(2,7),
        Vector2I(5,7),
        Vector2I(5,10)
    ],
    // Front face
    // Z and Y affect this
    [
        Vector2I(11,10),
        Vector2I(11,7),
        Vector2I(8,7),
        Vector2I(8,10)
    ],
    // Left face
    // X and Y affect this
    [
        Vector2I(0,0),
        Vector2I(0,0),
        Vector2I(0,0),
        Vector2I(0,0)
    ],
    // Right face
    // X and Y affect this
    [
        Vector2I(0,0),
        Vector2I(0,0),
        Vector2I(0,0),
        Vector2I(0,0)
    ],
    // Bottom face
    // X and Z affect this
    [
        Vector2I(0,0),
        Vector2I(0,0),
        Vector2I(0,0),
        Vector2I(0,0)
    ],
    // Top face
    // X and Z affect this
    [
        Vector2I(0,0),
        Vector2I(0,0),
        Vector2I(0,0),
        Vector2I(0,0)
    ]
];


void buildIndices(ref ushort[] indices, ref int vertexCount) {
    for (ushort i = 0; i < 6; i++) {
        indices ~= cast(ushort)(INDICES[i] + vertexCount);
    }
    vertexCount += 4;
}



void buildBlock(
    ref float[] vertices,
    ref float[] textureCoordinates,
    ref ushort[] indices,
    ref int triangleCount,
    ref int vertexCount,
    immutable float[][] blockBox
){

    Vector3 max = Vector3( 1,  1,  1 );
    Vector3 min = Vector3( 0,  0,  0 );

    // Very important this is held on the stack
    immutable float[6] textureCullArray = [min.x, min.y, min.z, max.x, max.y, max.z];

    int i = 2;

    // Allows normal blocks to be indexed with blank blockbox
    //for (int w = 0; w <= blockBox.length; w++) {
        //for (int i = 0; i < 6; i++) {

            // Assign the indices
            buildIndices(indices, vertexCount);

            for (int f = 0; f < 4; f++) {

                // Assign the vertex positions
                vertices ~= (FACE[i][f].x == 0 ? min.x : max.x);
                vertices ~= (FACE[i][f].y == 0 ? min.y : max.y);
                vertices ~= (FACE[i][f].z == 0 ? min.z : max.z);

                // Assign texture coordinates// Assign texture coordinates

                // Normal drawtype
                /*
                textureCoordinates ~= TEXTURE_POSITION[f].x;
                textureCoordinates ~= TEXTURE_POSITION[f].y;
                */

                // Blockbox drawtype
                Vector2I textureCull = TEXTURE_CULL[i][f];

                // This can be written as a ternary, but easier to understand like this
                final switch (textureCull.x > 5) {
                    case true: {
                        textureCoordinates ~= abs(textureCullArray[textureCull.x - 6] - 1);
                        break;
                    }
                    case false: {
                        textureCoordinates ~= textureCullArray[textureCull.x];
                        break;
                    }
                }
                final switch (textureCull.y > 5) {
                    case true: {
                        textureCoordinates ~= abs(textureCullArray[textureCull.y - 6] - 1);
                        break;
                    }
                    case false: {
                        textureCoordinates ~= textureCullArray[textureCull.y];
                        break;
                    }
                }

            }
            // Tick up tri count
            triangleCount += 2;
        //}
        // Automatic breakout
        //if (w >= blockBox.length) {
            //break;
        //}
    //}
}


public static Mesh testAPI(uint ID) {

        //BlockGraphicDefinition currentDefinition = this.definitions[ID];
        // BlockTextures currentBlockTextures = currentDefinition.blockTextures;
        // BlockBox currentBlockBox = currentDefinition.blockBox;

        Mesh myMesh = Mesh();

        float[] vertices;
        ushort[] indices;
        // float[] normals;
        float[] textureCoordinates;

        int triangleCount = 0;
        int vertexCount   = 0;

        buildBlock(vertices, textureCoordinates,indices,triangleCount,vertexCount,[]);

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