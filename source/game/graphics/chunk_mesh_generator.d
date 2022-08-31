module game.graphics.chunk_mesh_generator;

// Normal external libraries
import std.algorithm;
import std.stdio;
import std.range: popFront;
import std.array: insertInPlace, appender, Appender;
import std.algorithm: canFind;
import vector_2i;
import vector_2d;
import vector_3i;
import vector_3d;
import std.math: abs;

// Concurrency external libraries
import std.concurrency;
import std.algorithm.mutation: copy;
import core.time: Duration;
import asdf;

// Normal internal engine libraries
import Window = engine.window.window;

// Normal internal game libraries
import game.chunk.chunk_container;
import game.chunk.chunk;
import game.chunk.thread_chunk_package;
import game.graphics.block_graphics_definition;
import game.graphics.thread_mesh_message;

import ThreadLibrary = engine.thread.thread_library;


/*
This section is wrong

How this works:

The entry point is the chunk factory. It gets processed via internalGenerateChunk().

It then comes here and becomes part of the newStack!

A chunk mesh is created using the api in block graphics.

Next we need to update the neighbors if they exist. This gets sent into updatingStack.

Updating stack does not update the neighbors. This avoids a recursion crash.

That's about it really

wrongness ends here
*/

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

The meshes are built using D's built in appender which is more efficient than individual
insertions, ie, "~=". This was shown to me originally by Mayonix, and explained further 
by brianush1 and Schveiguy. Taken from the documentation:

" Implements an output range that appends data to an array. This is recommended over 
array ~= data when appending many elements because it is more efficient. Appender maintains 
its own array metadata locally, so it can avoid global locking for each append where capacity
is non-zero. "

*/

struct MeshUpdate{
    Vector3i position;
    bool updating;
    this(Vector3i position, bool updating){
        this.position = position;
        this.updating = updating;
    }
}


// Allow main thread to register new blocks into this one
void registerBlockGraphicsDefinition(uint id, float[][] blockBox, Vector2i[] blockTextures){
    // This may look like we're talking right below, but that thread could be anywhere
    // Avoid an access violation
    BlockGraphicDefinition newDefinition = BlockGraphicDefinition(
            id,
            blockBox,
            blockTextures
        );
    send(ThreadLibrary.getChunkMeshGeneratorThread(), cast(shared(BlockGraphicDefinition))newDefinition);
}


// This is a super function that acts like a separate main() function
// Thread spawner starts here
void startMeshGeneratorThread(Tid parentThread) {


/*
 __       __  .______   .______          ___      .______     ____    ____ 
|  |     |  | |   _  \  |   _  \        /   \     |   _  \    \   \  /   / 
|  |     |  | |  |_)  | |  |_)  |      /  ^  \    |  |_)  |    \   \/   /  
|  |     |  | |   _  <  |      /      /  /_\  \   |      /      \_    _/   
|  `----.|  | |  |_)  | |  |\  \----./  _____  \  |  |\  \----.   |  |     
|_______||__| |______/  | _| `._____/__/     \__\ | _| `._____|   |__|     
*/

// Gotta tell the main thread what has been created
Tid mainThread = parentThread;

// Defines how many textures are in the texture map
immutable double TEXTURE_MAP_TILES = 32;
// Defines the width/height of each texture
immutable double TEXTURE_TILE_SIZE = 16;
// Defines the total width/height of the texture map in pixels
immutable double TEXTURE_MAP_SIZE = TEXTURE_TILE_SIZE * TEXTURE_MAP_TILES;


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

BlockGraphicDefinition[uint] definitions;

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




/*
.______    __    __   __   __       _______   _______ .______      
|   _  \  |  |  |  | |  | |  |     |       \ |   ____||   _  \     
|  |_)  | |  |  |  | |  | |  |     |  .--.  ||  |__   |  |_)  |    
|   _  <  |  |  |  | |  | |  |     |  |  |  ||   __|  |      /     
|  |_)  | |  `--'  | |  | |  `----.|  '--'  ||  |____ |  |\  \----.
|______/   \______/  |__| |_______||_______/ |_______|| _| `._____|
*/



int translateRotationRender(int currentFace, ubyte currentRotation){
    // Don't bother if not on the X or Z axis or if no rotation
    if (currentFace > 3 || currentRotation == 0) {
        return currentFace;
    }
    return rotationTranslation[currentFace][currentRotation];
}


// An automatic index builder
void buildIndices(Appender!(int[]) indices, ref int vertexCount) {
    for (int i = 0; i < 6; i++) {
        indices.put(INDICES[i] + vertexCount);
    }
    vertexCount += 4;
}

// Assembles a block mesh piece and appends the necessary data
void buildBlock(
    uint ID,
    Appender!(float[]) vertices,
    Appender!(float[]) textureCoordinates,
    Appender!(int[]) indices,
    Appender!(float[]) lights,
    ref int triangleCount,
    ref int vertexCount,
    Vector3i position,
    ubyte rotation,
    bool[6] renderArray
){
    if (ID == 0) {  // Replace 0 check with block graphics definition check                
        return;
    }
    BlockGraphicDefinition graphicsDefiniton = definitions[ID];

    float[][] blockBox = cast(float[][])graphicsDefiniton.blockBox;
    Vector2i[] textureDefinition = cast(Vector2i[])graphicsDefiniton.blockTextures;

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
                lights.put(1.0);
            }

            // Assign the indices
            buildIndices(indices, vertexCount);

            for (int f = 0; f < 4; f++) {
                // Assign the vertex positions with rotation
                final switch (rotation) {
                    case 0: {
                        vertices.put((FACE[i][f].x == 0 ? min.x : max.x) + position.x);
                        vertices.put((FACE[i][f].y == 0 ? min.y : max.y) + position.y);
                        vertices.put((FACE[i][f].z == 0 ? min.z : max.z) + position.z);
                        break;
                    }
                    case 1: {
                        // Notice: Axis order X and Z are swapped
                        vertices.put(abs((FACE[i][f].z == 0 ? min.z : max.z) - 1) + position.x);
                        vertices.put(    (FACE[i][f].y == 0 ? min.y : max.y)      + position.y);
                        vertices.put(    (FACE[i][f].x == 0 ? min.x : max.x)      + position.z);
                        break;
                    }
                    case 2: {
                        vertices.put(abs((FACE[i][f].x == 0 ? min.x : max.x) - 1) + position.x);
                        vertices.put(    (FACE[i][f].y == 0 ? min.y : max.y)      + position.y);
                        vertices.put(abs((FACE[i][f].z == 0 ? min.z : max.z) - 1) + position.z);
                        break;
                    }
                    case 3: {
                        // Notice: Axis order X and Z are swapped
                        vertices.put(    (FACE[i][f].z == 0 ? min.z : max.z)      + position.x);
                        vertices.put(    (FACE[i][f].y == 0 ? min.y : max.y)      + position.y);
                        vertices.put(abs((FACE[i][f].x == 0 ? min.x : max.x) - 1) + position.z);
                        break;
                    }
                }

                // Assign texture coordinates// Assign texture coordinates               

                final switch (isBlockBox) {
                    case false: {
                        // Normal drawtype
                        textureCoordinates.put(((TEXTURE_POSITION[f].x + currentTexture.x) * TEXTURE_TILE_SIZE) / TEXTURE_MAP_SIZE);
                        textureCoordinates.put(((TEXTURE_POSITION[f].y + currentTexture.y) * TEXTURE_TILE_SIZE) / TEXTURE_MAP_SIZE);
                        break;
                    }
                    case true: {
                        // Blockbox drawtype
                        Vector2i textureCull = TEXTURE_CULL[i][f];

                        // This can be written as a ternary, but easier to understand like this
                        final switch (textureCull.x > 5) {
                            case true: {
                                textureCoordinates.put(((abs(textureCullArray[textureCull.x - 6] - 1) + currentTexture.x) * TEXTURE_TILE_SIZE) / TEXTURE_MAP_SIZE);
                                break;
                            }
                            case false: {
                                textureCoordinates.put(((textureCullArray[textureCull.x] + currentTexture.x) * TEXTURE_TILE_SIZE) / TEXTURE_MAP_SIZE);
                                break;
                            }
                        }
                        final switch (textureCull.y > 5) {
                            case true: {
                                textureCoordinates.put(((abs(textureCullArray[textureCull.y - 6] - 1) + currentTexture.y) * TEXTURE_TILE_SIZE) / TEXTURE_MAP_SIZE);
                                break;
                            }
                            case false: {
                                textureCoordinates.put(((textureCullArray[textureCull.y] + currentTexture.y) * TEXTURE_TILE_SIZE) / TEXTURE_MAP_SIZE);
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


/*
 _______    ___       ______  _______      ______  __    __   _______   ______  __  ___  _______ .______      
|   ____|  /   \     /      ||   ____|    /      ||  |  |  | |   ____| /      ||  |/  / |   ____||   _  \     
|  |__    /  ^  \   |  ,----'|  |__      |  ,----'|  |__|  | |  |__   |  ,----'|  '  /  |  |__   |  |_)  |    
|   __|  /  /_\  \  |  |     |   __|     |  |     |   __   | |   __|  |  |     |    <   |   __|  |      /     
|  |    /  _____  \ |  `----.|  |____    |  `----.|  |  |  | |  |____ |  `----.|  .  \  |  |____ |  |\  \----.
|__|   /__/     \__\ \______||_______|    \______||__|  |__| |_______| \______||__|\__\ |_______|| _| `._____|
*/



immutable Vector3i[6] checkPositions = [
    Vector3i(-1, 0, 0),
    Vector3i( 1, 0, 0),
    Vector3i( 0, 0,-1),
    Vector3i( 0, 0, 1),
    Vector3i( 0,-1, 0),
    Vector3i( 0, 1, 0)
];


void generateChunkMesh(
    Chunk chunk,
    Chunk neighborNegativeX,
    Chunk neighborPositiveX,
    Chunk neighborNegativeZ,
    Chunk neighborPositiveZ,
    ubyte yStack) {


    
    Appender!(float[]) vertices = appender!(float[]);
    Appender!(int[]) indices = appender!(int[]);
    // float[] normals;
    Appender!(float[]) textureCoordinates = appender!(float[]);
    // translate lights from ubyte to float
    // writeln("you should probably implement the lighting eventually");
    Appender!(float[]) lights = appender!(float[]);
    
    int triangleCount = 0;
    int vertexCount   = 0;

    // Work goes here
    immutable int yMin = yStack * chunkStackSizeY;
    immutable int yMax = (yStack + 1) * chunkStackSizeY;

    bool neighborNegativeXExists = neighborNegativeX.exists();
    bool neighborPositiveXExists = neighborPositiveX.exists();
    bool neighborNegativeZExists = neighborNegativeZ.exists();
    bool neighborPositiveZExists = neighborPositiveZ.exists();    


    for (int x = 0; x < chunkSizeX; x++){
        for (int z = 0; z < chunkSizeZ; z++) {
            for (int y = yMin; y < yMax; y++) {
                //writeln(x," ", y, " ", z);

                Vector3i position = Vector3i(x,y,z);

                uint currentBlock = chunk.getBlock(position);
                ubyte currentRotation = chunk.getRotation(position);

                bool[6] renderingPositions = [false,false,false,false,false,false];                

                for (int w = 0; w < 6; w++) {
                    Vector3i selectedPosition = checkPositions[w];

                    // Can add structs together like their base components
                    Vector3i currentCheckPosition = Vector3i(
                        position.x + selectedPosition.x,
                        position.y + selectedPosition.y,
                        position.z + selectedPosition.z,
                    );

                    // If it's not within the current chunk
                    if (!collide(currentCheckPosition)) {

                        // Gets X neighbor block values, if they exist
                        switch (currentCheckPosition.x) {
                            case 16: {
                                if (
                                    (neighborPositiveXExists &&
                                    neighborPositiveX.getBlock(
                                        Vector3i(
                                            currentCheckPosition.x - chunkSizeX,
                                            currentCheckPosition.y,
                                            currentCheckPosition.z
                                        )
                                    ) == 0) || // Replace 0 check with block graphics definition check
                                    !neighborPositiveXExists) {
                                    renderingPositions[w] = true;
                                }
                                break;
                            }
                            case -1: {
                                if (
                                    (neighborNegativeXExists &&
                                    neighborNegativeX.getBlock(
                                        Vector3i(
                                            currentCheckPosition.x + chunkSizeX,
                                            currentCheckPosition.y,
                                            currentCheckPosition.z
                                        )
                                    ) == 0) ||  // Replace 0 check with block graphics definition check
                                    !neighborNegativeXExists) {
                                    renderingPositions[w] = true;
                                }
                                break;
                            }
                            default: {}
                        }

                        // Gets Z neighbor block values, if they exist
                        switch (currentCheckPosition.z) {
                            case 16: {
                                if (
                                    (neighborPositiveZExists &&
                                    neighborPositiveZ.getBlock(
                                        Vector3i(
                                            currentCheckPosition.x,
                                            currentCheckPosition.y,
                                            currentCheckPosition.z - chunkSizeZ
                                        )
                                    ) == 0) || // Replace 0 check with block graphics definition check
                                    !neighborPositiveZExists) {
                                    renderingPositions[w] = true;
                                }
                                break;
                            }
                            case -1: {
                                if (
                                    (neighborNegativeZExists &&
                                    neighborNegativeZ.getBlock(
                                        Vector3i(
                                            currentCheckPosition.x,
                                            currentCheckPosition.y,
                                            currentCheckPosition.z + chunkSizeZ
                                        )
                                    ) == 0) ||  // Replace 0 check with block graphics definition check
                                    !neighborNegativeZExists) {
                                    renderingPositions[w] = true;
                                }
                                break;
                            }
                            default: {}
                        }
                    } else {
                        if (chunk.getBlock(currentCheckPosition) == 0) {  // Replace 0 check with block graphics definition check
                            renderingPositions[w] = true;
                        }
                    }

                    // This is added on for a visualization
                    // Possibly keep this, so players can see the bottom of world if they fall through
                    if (currentCheckPosition.y == -1) {
                        renderingPositions[w] = true;
                    }
                }

                if (currentBlock != 0) {  // Replace 0 check with block graphics definition check

                    buildBlock(
                        currentBlock,
                        vertices,
                        textureCoordinates,
                        indices,
                        lights,
                        triangleCount,
                        vertexCount,
                        position,
                        currentRotation,
                        renderingPositions
                    );
                }
            }
        }
    }

    // writeln("vertex: ", vertexCount, " | triangle: ", triangleCount);
    // chunk.removeModel(yStack);    

    // maybe reuse this calculation in an overload?
    // thisChunkMesh.triangleCount = triangleCount;
    // thisChunkMesh.vertexCount = vertexCount;    

    // writeln("length compare: ", lights.length, " ", vertices.length);
    
    Vector2i chunkPosition = chunk.getPosition();

    send(mainThread, cast(shared(ThreadMeshMessage))ThreadMeshMessage(
        cast(float[])vertices[],
        cast(int[])indices[],
        cast(float[])textureCoordinates[],
        cast(float[])lights[],
        "textures/world_texture_map.png",
        Vector3i(
            chunkPosition.x,
            yStack,
            chunkPosition.y
        )
    ));
}





/*
  ______      __    __   _______  __    __   _______ 
 /  __  \    |  |  |  | |   ____||  |  |  | |   ____|
|  |  |  |   |  |  |  | |  |__   |  |  |  | |  |__   
|  |  |  |   |  |  |  | |   __|  |  |  |  | |   __|  
|  `--'  '--.|  `--'  | |  |____ |  `--'  | |  |____ 
 \_____\_____\\______/  |_______| \______/  |_______|
*/



writeln("Starting thread mesh generator");

// New meshes call this update to fully update neighbors on heap
// This needs to be a package of current and neighbors
MeshUpdate[] newStack = new MeshUpdate[0];

// Preexisting meshes call this update to only update necessary neighbors on heap
// This needs to be a package of current and neighbors
MeshUpdate[] updatingStack = new MeshUpdate[0];

void internalGenerateChunkMesh(MeshUpdate thePackage) {

    Vector3i position = Vector3i(
        thePackage.position.x,
        thePackage.position.y,
        thePackage.position.z
    );

    Chunk thisChunk = cast(Chunk)getSharedChunk(Vector2i(position.x, position.z));
    
    // Get chunk neighbors
    // These do not exist by default
    Chunk neighborNegativeX = cast(Chunk)getSharedChunk(Vector2i(position.x - 1, position.z));
    Chunk neighborPositiveX = cast(Chunk)getSharedChunk(Vector2i(position.x + 1, position.z));
    Chunk neighborNegativeZ = cast(Chunk)getSharedChunk(Vector2i(position.x, position.z - 1));
    Chunk neighborPositiveZ = cast(Chunk)getSharedChunk(Vector2i(position.x, position.z + 1));

    generateChunkMesh(
        thisChunk,
        neighborNegativeX,
        neighborPositiveX,
        neighborNegativeZ,
        neighborPositiveZ,
        cast(ubyte)position.y
    );

    // Update neighbors
    if (thePackage.updating) {
        if (neighborNegativeX.exists()) {
            // updateChunkMesh(Vector3i(position.x - 1, position.y, position.z));
            // writeln("send out request for update!");
            MeshUpdate newUpdate = MeshUpdate(
                Vector3i(
                    position.x - 1,
                    position.y,
                    position.z
                ),
                false
            );
            if (!updatingStack.canFind(newUpdate)) {
                //updatingStack.insertInPlace(0, newUpdate);
                updatingStack ~= newUpdate;
            }
                    
        }
        if (neighborPositiveX.exists()) {
            // updateChunkMesh(Vector3i(position.x + 1, position.y, position.z));
            MeshUpdate newUpdate = MeshUpdate(
                Vector3i(
                    position.x + 1,
                    position.y,
                    position.z
                ),
                false
            );
            if (!updatingStack.canFind(newUpdate)) {
                updatingStack ~= newUpdate;
            }
        }
        if (neighborNegativeZ.exists()) {
            // updateChunkMesh(Vector3i(position.x, position.y, position.z - 1));
            MeshUpdate newUpdate = MeshUpdate(
                    Vector3i(
                    position.x,
                    position.y,
                    position.z - 1
                ),
                false
            );
            if (!updatingStack.canFind(newUpdate)) {
                updatingStack ~= newUpdate;
            }
        }
        if (neighborPositiveZ.exists()) {
            // updateChunkMesh(Vector3i(position.x, position.y, position.z + 1));
            MeshUpdate newUpdate = MeshUpdate(
                Vector3i(
                    position.x,
                    position.y,
                    position.z + 1
                ),
                false
            );
            if (!updatingStack.canFind(newUpdate)) {
                updatingStack ~= newUpdate;
            }
        }
    }
}

void processChunkMeshUpdateStack(){
    // See if there are any new chunk generations
    if (newStack.length > 0) {

        MeshUpdate newPackage = newStack[0];
        newStack.popFront();
        // writeln("New Chunk Mesh: ", poppedValue);

        // Ship them to the chunk generator process
        internalGenerateChunkMesh(newPackage);
    }
    
    // See if there are any existing chunk mesh updates
    if (updatingStack.length > 0) {

        MeshUpdate updatingPackage = updatingStack[0];
        updatingStack.popFront();
        // writeln("Updating Chunk Mesh: ", poppedValue);

        // Ship them to the chunk generator process
        internalGenerateChunkMesh(updatingPackage);
    }
}

void receiveChunkTransfer(MeshUpdate packageData) {
    if (packageData.updating) {
        // insertInPlace(0, packageData);
        updatingStack ~= packageData;
    } else {
        newStack ~= packageData;
    }
}

bool didGenLastLoop = false;
while(!Window.externalShouldClose()) {

    // A cpu saver routine
    if (!didGenLastLoop) {
        didGenLastLoop = false;
        receive(
            (MeshUpdate newUpdate) {
                receiveChunkTransfer(newUpdate);
            },
            // This will always reactivate so no need to duplicate
            (shared(BlockGraphicDefinition) newDefinition) {
                // writeln("GOT NEW GRAPHICS DEFINITION! ID:", newDefinition.id);
                definitions[newDefinition.id] = cast(BlockGraphicDefinition)newDefinition;
                didGenLastLoop = true;
            },
            // If you send this thread a bool, it continues, then breaks
            (bool kill) {}
        );
    } else {
        didGenLastLoop = false;
        receiveTimeout(
            Duration(),
            (MeshUpdate newUpdate) {
                receiveChunkTransfer(newUpdate);
            },
            // If you send this thread a bool, it continues, then breaks
            (bool kill) {}
        );
    }

    if(updatingStack.length > 0 || newStack.length > 0) {
        didGenLastLoop = true;
        processChunkMeshUpdateStack();
    }
}

writeln("thread mesh generator closed!");

}// Thread spawner ends here