module game.chunk.chunk_factory;


import std.stdio;
import std.range : popFront, popBack;
import std.algorithm : canFind;

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
private Chunk[Vector2I] container;

// Generation stack
private Vector2I[] stack;

// External entry point into adding new chunks to the map
void generateChunk(Vector2I position) {
    // Do not dispatch a new chunk generation into stack if it's already there
    if (!stack.canFind(position)) {
        stack ~= position;
    }
}

// Gets a chunk from the container
Chunk getChunk(Vector2I position) {
    if (position in container) {
        return container[position];
    }
    // Return non-existent chunk
    return Chunk();
}

Chunk fakeChunk = Chunk();
// Gets a mutable chunk from the container
ref Chunk getMutableChunk(Vector2I position) {
    if (position in container) {
        return container[position];
    }
    assert(true == true, "WARNING HAVE HIT A NULL POSITION");
    // This becomes garbage data
    return fakeChunk;
}

// Polls the generation stack 
void processTerrainGenerationStack() {

    // See if there are any new chunk generations
    if (stack.length > 0) {

        Vector2I poppedValue = stack[0];
        stack.popFront();
        // writeln("popped: ", poppedValue);

        // Ship them to the chunk generator process
        internalGenerateChunk(poppedValue);
    }
}

// Internal chunk generation dispatch
private void internalGenerateChunk(Vector2I newPosition) {

    // random debug for prototyping processes
    Chunk generatedChunk = Chunk("default", newPosition);

    // World generator processes new chunk
    generateTerrain(generatedChunk);

    // Insert the chunk into the container
    container[newPosition] = generatedChunk;

    // Finally add a new chunk mesh update
    for (ubyte y = 0; y < 8; y++) {
        newChunkMeshUpdate(Vector3I(newPosition.x, y, newPosition.y));
    }

    // The factory is now done processing the chunk
}

void renderWorld() {
    foreach (Chunk thisChunk; container) {
        for (ubyte i = 0; i < 8; i++) {
            thisChunk.drawModel(i);
        }
    }
}


// Everything past this is for debugging components of this static class
void debugFactoryContainer() {
    writeln("factory container: ", container);
}
