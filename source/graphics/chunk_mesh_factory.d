module graphics.chunk_mesh_factory;

import graphics.chunk_mesh_generation;
import helpers.structs;
import std.algorithm;
import std.stdio;
import std.range: popFront;
import chunk.chunk_factory;
import chunk.chunk;
import std.array: insertInPlace;

// Mesh Generation Factory

/*
How this works:

The entry point is the chunk factory. It gets processed via internalGenerateChunk().

It then comes here and becomes part of the newStack!

A chunk mesh is created using the api in block graphics.

Next we need to update the neighbors if they exist. This gets sent into updatingStack.

Updating stack does not update the neighbors. This avoids a recursion crash.

That's about it really
*/

// New meshes call this update to fully update neighbors
Vector3I[] newStack;

// Preexisting meshes call this update to only update necessary neighbors
Vector3I[] updatingStack;

void newChunkMeshUpdate(Vector3I position) {
    if (!newStack.canFind(position)) {
        newStack ~= position;
    }
}

void updateChunkMesh(Vector3I position) {
    if (!updatingStack.canFind(position)) {
        updatingStack ~= position;
    }
}

void processChunkMeshUpdateStack(){
    // See if there are any new chunk generations
    if (newStack.length > 0) {

        Vector3I poppedValue = newStack[0];
        newStack.popFront();
        writeln("popped: ", poppedValue);

        // Ship them to the chunk generator process
        internalGenerateChunkMesh(poppedValue);
    }

    // See if there are any existing chunk mesh updates
    if (updatingStack.length > 0) {

        Vector3I poppedValue = updatingStack[0];
        updatingStack.popFront();
        writeln("popped: ", poppedValue);

        // Ship them to the chunk generator process
        internalUpdateChunkMesh(poppedValue);
    }
}

private void internalGenerateChunkMesh(Vector3I position) {
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
    
    if (neighborNegativeX.exists()) {
        updateChunkMesh(Vector3I(position.x - 1, position.y, position.z));
    }
    if (neighborPositiveX.exists()) {
        updateChunkMesh(Vector3I(position.x + 1, position.y, position.z));
    }
    if (neighborNegativeZ.exists()) {
        updateChunkMesh(Vector3I(position.x, position.y, position.z - 1));
    }
    if (neighborPositiveZ.exists()) {
        updateChunkMesh(Vector3I(position.x, position.y, position.z + 1));
    }
}

private void internalUpdateChunkMesh(Vector3I position) {
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
    // As you can see as listed above, this is the same function but without the recursive update.
    // This could have intook a boolean, but it's easier to understand it as a separate function.
}