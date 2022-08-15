module graphics.chunk_mesh_factory;

import graphics.chunk_mesh_generation;
import helpers.structs;
import std.algorithm;
import std.stdio;
import std.range: popFront;
import chunk.chunk_factory;
import chunk.chunk;

// Mesh Generation Factory

Vector3I[] stack;

void newChunkMeshUpdate(Vector3I position) {
    if (!stack.canFind(position)) {
        // writeln("NEW CHUNK MESH UPDATE! ", position);
        stack ~= position;
    } else {
        writeln(position, " already exists!");
    }
}

void processChunkMeshUpdateStack(){
    // See if there are any new chunk generations
    if (stack.length > 0) {

        Vector3I poppedValue = stack[0];
        stack.popFront();
        writeln("popped: ", poppedValue);

        // Ship them to the chunk generator process
        internalGenerateChunkMesh(poppedValue);
    }
}

void internalGenerateChunkMesh(Vector3I position) {
    // Get chunk neighbors
    // These do not exist by default
    Chunk neighborNegativeX = getChunk(Vector2I(position.x - 1, position.z));
    Chunk neighborPositiveX = getChunk(Vector2I(position.x + 1, position.z));
    Chunk neighborNegativeZ = getChunk(Vector2I(position.x, position.z - 1));
    Chunk neighborPositiveZ = getChunk(Vector2I(position.x, position.z + 1));

    generateChunkMesh(
        getMutableChunk(Vector2I(position.x, position.z)),
        neighborNegativeX,
        neighborPositiveX,
        neighborNegativeZ,
        neighborPositiveZ,
        cast(ubyte)position.y
    );

    // Update neighbors
    /*
    newChunkMeshUpdate(Vector3I(position.x - 1, position.y, position.z));
    newChunkMeshUpdate(Vector3I(position.x + 1, position.y, position.z));
    newChunkMeshUpdate(Vector3I(position.x, position.y, position.z - 1));
    newChunkMeshUpdate(Vector3I(position.x, position.y, position.z + 1));
    */
}