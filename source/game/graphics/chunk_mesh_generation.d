module game.graphics.chunk_mesh_generation;

import std.stdio;
import vector_2d;
import vector_2i;
import vector_3d;
import vector_3i;


import game.chunk.chunk;
import game.graphics.block_graphics;
import engine.mesh.texture;

// This can just be called during runtime, no need to have a function
void loadTextureAtlas() {
    newTexture("textures/world_texture_map.png");
}

void debugCreateBlockGraphics(){
    // Stone
    registerBlockGraphicsDefinition(
        1,
        [
            // [0,0,0,1,0.5,1],
            // [0,0,0,0.5,1,0.5]
        ],
        [
            Vector2i(0,0),
            Vector2i(0,0),
            Vector2i(0,0),
            Vector2i(0,0),
            Vector2i(0,0),
            Vector2i(0,0)
        ]
    );

    // Grass
    registerBlockGraphicsDefinition(
        2,
        [],
        [
            Vector2i(1,0),
            Vector2i(1,0),
            Vector2i(1,0),
            Vector2i(1,0),
            Vector2i(3,0),
            Vector2i(2,0)
        ]
    );

    // Dirt
    registerBlockGraphicsDefinition(
        3,
        [],
        [
            Vector2i(3,0),
            Vector2i(3,0),
            Vector2i(3,0),
            Vector2i(3,0),
            Vector2i(3,0),
            Vector2i(3,0)
        ]
    );
}

immutable Vector3i[6] checkPositions = [
    Vector3i(-1, 0, 0),
    Vector3i( 1, 0, 0),
    Vector3i( 0, 0,-1),
    Vector3i( 0, 0, 1),
    Vector3i( 0,-1, 0),
    Vector3i( 0, 1, 0)
];


void generateChunkMesh(
    ref Chunk chunk,
    Chunk neighborNegativeX,
    Chunk neighborPositiveX,
    Chunk neighborNegativeZ,
    Chunk neighborPositiveZ,
    ubyte yStack) {

    float[] vertices;
    ushort[] indices;
    // float[] normals;
    float[] textureCoordinates;
    // For dispatching colors ubyte[]

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
                // writeln(x," ", y, " ", z);

                Vector3i position = Vector3i(x,y,z);

                uint currentBlock = chunk.getBlock(position);
                ubyte currentRotation = chunk.getRotation(position);

                bool[6] renderingPositions = [false,false,false,false,false,false];

                for (int w = 0; w < 6; w++) {
                    Vector3i selectedPosition = checkPositions[w];

                    // Can add structs together like their base components
                    Vector3i currentCheckPosition = position.add(selectedPosition);

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
                }

                if (currentBlock != 0) {  // Replace 0 check with block graphics definition check
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
        }
    }

    // writeln("vertex: ", vertexCount, " | triangle: ", triangleCount);

    // Discard old gpu data, OpenGL will silently fail internally with invalid VAO, this is wanted
    // This causes a crash for some reason
    chunk.removeModel(yStack);

    // No more processing is required, it's nothing
    // if (vertexCount == 0) {
        // return;
    // }

    Mesh thisChunkMesh = Mesh();

    thisChunkMesh.triangleCount = triangleCount;
    thisChunkMesh.vertexCount = vertexCount;

    thisChunkMesh.vertices  = vertices.ptr;
    thisChunkMesh.indices   = indices.ptr;
    // thisChunkMesh.normals   = normals.ptr;
    thisChunkMesh.texcoords = textureCoordinates.ptr;

    UploadMesh(&thisChunkMesh, false);

    Model thisChunkModel = LoadModelFromMesh(thisChunkMesh);

    thisChunkModel.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture = TEXTURE_ATLAS;

    chunk.setModel(yStack, thisChunkModel);

}
