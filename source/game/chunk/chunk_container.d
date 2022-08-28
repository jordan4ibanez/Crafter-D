module game.chunk.chunk_container;


import std.stdio;
import std.range : popFront, popBack;
import std.algorithm : canFind;
import vector_2i;
import vector_3i;

import game.chunk.chunk;
import game.chunk.world_generation;
import game.graphics.chunk_mesh_generation;
import game.graphics.chunk_mesh_factory;
/*
This handles the chunks in the world. A static factory/container for Chunks using D's special
properties to treat the entire file as a static class

This is meant to be handled functionally
*/


// Hashmap container for generated chunks
private Chunk[Vector2i] container;

// Generation stack
private Vector2i[] stack = new Vector2i[0];

// External entry point into adding new chunks to the map
void generateChunk(Vector2i position) {
    // Do not dispatch a new chunk generation into stack if it's already there
    if (!stack.canFind(position)) {
        stack ~= position;
    }
}

// Gets a chunk from the container
Chunk getChunk(Vector2i position) {
    if (position in container) {
        return container[position];
    }
    // Return non-existent chunk
    return Chunk();
}

private Chunk fakeChunk = Chunk();
// Gets a mutable chunk from the container
ref Chunk getMutableChunk(Vector2i position) {
    if (position in container) {
        return container[position];
    }
    writeln("WARNING, A GARBAGE CHUNK HAS BEEN DISPATCHED");
    // This becomes garbage data
    return fakeChunk;
}

// Polls the generation stack 
void processTerrainGenerationStack() {

    // See if there are any new chunk generations
    if (stack.length > 0) {

        Vector2i poppedValue = stack[0];
        stack.popFront();
        // writeln("Generating: ", poppedValue);

        // Ship them to the chunk generator process
        internalGenerateChunk(poppedValue);
    }
}

// Internal chunk generation dispatch
private void internalGenerateChunk(Vector2i newPosition) {

    // random debug for prototyping processes
    Chunk generatedChunk = Chunk("default", newPosition);

    // World generator processes new chunk
    generateTerrain(generatedChunk);

    // Insert the chunk into the container
    container[newPosition] = generatedChunk;

    // Finally add a new chunk mesh update
    for (ubyte y = 0; y < 8; y++) {
        newChunkMeshUpdate(Vector3i(newPosition.x, y, newPosition.y));
    }

    // The factory is now done processing the chunk
}

void renderWorld() {
    foreach (Chunk thisChunk; container) {
        for (ubyte i = 0; i < 8; i++) {
            thisChunk.drawMesh(i);
        }
    }
}


// Everything past this is for debugging components of this static class
void debugFactoryContainer() {
    writeln("factory container: ", container);
}
