module graphics.chunk_mesh_generation;

import raylib;
import std.stdio;
import graphics.block_graphics;
import chunk.chunk;
import helpers.structs;

private Texture TEXTURE_ATLAS;
private bool lock = false;

void loadTextureAtlas() {
    // Avoid memory leak
    if (!lock) {
        TEXTURE_ATLAS = LoadTexture("textures/world_texture_map.png");
        lock = true;
    }
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

                Vector3I position = Vector3I(x,y,z);

                uint currentBlock = chunk.getBlock(position);
                ubyte currentRotation = chunk.getRotation(position);

                bool[6] renderingPositions = [false,false,false,false,false,false];

                for (int w = 0; w < 6; w++) {
                    Vector3I selectedPosition = checkPositions[w];

                    // Can add structs together like their base components
                    Vector3I currentCheckPosition = position.add(selectedPosition);

                    // If it's not within the current chunk
                    if (!collide(currentCheckPosition)) {

                        // Gets X neighbor block values, if they exist
                        switch (currentCheckPosition.x) {
                            case 16: {
                                if (
                                    (neighborPositiveXExists &&
                                    neighborPositiveX.getBlock(
                                        Vector3I(
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
                                        Vector3I(
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
                                        Vector3I(
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
                                        Vector3I(
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

    writeln("vertex: ", vertexCount, " | triangle: ", triangleCount);

    // Discard old gpu data, OpenGL will silently fail internally with invalid VAO, this is wanted
    // This causes a crash for some reason
    // chunk.removeModel(yStack);

    // No more processing is required, it's nothing
    if (vertexCount == 0) {
        return;
    }

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