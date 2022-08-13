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
    ]
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