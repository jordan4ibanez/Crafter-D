module graphics.chunk_mesh_generation;

import raylib;
import std.stdio;
import graphics.block_graphics;
import chunk.chunk;
import helpers.structs;

void debugCreateBlockGraphics(){
    // Stone
    registerBlockGraphicsDefinition(
        1,
        [
            // [0,0,0,1,0.5,1],
            // [0,0,0,0.5,1,0.5]
        ],
        [
            Vector2I(0,0),
            Vector2I(0,0),
            Vector2I(0,0),
            Vector2I(0,0),
            Vector2I(0,0),
            Vector2I(0,0)
        ]
    );

    // Grass
    registerBlockGraphicsDefinition(
        2,
        [],
        [
            Vector2I(1,0),
            Vector2I(1,0),
            Vector2I(1,0),
            Vector2I(1,0),
            Vector2I(3,0),
            Vector2I(2,0)
        ]
    );

    // Dirt
    registerBlockGraphicsDefinition(
        3,
        [],
        [
            Vector2I(3,0),
            Vector2I(3,0),
            Vector2I(3,0),
            Vector2I(3,0),
            Vector2I(3,0),
            Vector2I(3,0)
        ]
    );
}

immutable Vector3I[6] checkPositions = [
    Vector3I(-1, 0, 0),
    Vector3I( 1, 0, 0),
    Vector3I( 0, 0,-1),
    Vector3I( 0, 0, 1),
    Vector3I( 0,-1, 0),
    Vector3I( 0, 1, 0)
];


Mesh generateChunkMesh(Chunk chunk) {
    Mesh myMesh = Mesh();

    float[] vertices;
    ushort[] indices;
    // float[] normals;
    float[] textureCoordinates;
    // For dispatching colors ubyte[]

    int triangleCount = 0;
    int vertexCount   = 0;

    // Work goes here

    for (int i = 0; i < chunkArrayLength; i++) {
        Vector3I position = indexToPosition(i);

        uint currentBlock = chunk.getBlock(position.x,position.y,position.z);
        ubyte currentRotation = chunk.getRotation(position.x, position.y, position.z);

        bool[6] renderingPositions = [false,false,false,false,false,false];

        for (int w = 0; w < 6; w++) {
            Vector3I selectedPosition = checkPositions[w];

            Vector3I currentCheckPosition = Vector3I(
                position.x + selectedPosition.x,
                position.y + selectedPosition.y,
                position.z + selectedPosition.z,
            );

            if (!collide(currentCheckPosition.x, currentCheckPosition.y, currentCheckPosition.z)) {
                renderingPositions[w] = true;
            } else {
                if (chunk.getBlock(currentCheckPosition.x, currentCheckPosition.y, currentCheckPosition.z) == 0) {
                    renderingPositions[w] = true;
                }
            }
        }

        if (currentBlock != 0) {
            buildBlock(
                currentBlock,
                vertices,
                textureCoordinates,
                indices,
                triangleCount,
                vertexCount,
                position,
                currentRotation,
                renderingPositions
            );
        }
    }



    writeln("vertex: ", vertexCount, " | triangle: ", triangleCount);


    myMesh.triangleCount = triangleCount;
    myMesh.vertexCount = vertexCount;

    myMesh.vertices  = vertices.ptr;
    myMesh.indices   = indices.ptr;
    // myMesh.normals   = normals.ptr;
    myMesh.texcoords = textureCoordinates.ptr;

    UploadMesh(&myMesh, false);


    return myMesh;    
}