module chunk.chunk_factory;


import std.stdio;
import chunk.chunk;
import std.range : popFront, popBack;
import std.algorithm : canFind;
import helpers.structs;
import chunk.world_generation;
import graphics.chunk_mesh_generation;
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

// Will poll the generation stack 
void processStack() {

    // See if there are any new chunk generations
    if (stack.length > 0) {

        Vector2I poppedValue = stack[0];
        stack.popFront();
        writeln("popped: ", poppedValue);

        // Ship them to the chunk generator process
        internalGenerateChunk(poppedValue);
    }
}

// Internal chunk generation dispatch
private void internalGenerateChunk(Vector2I newPosition) {
    writeln("I'm generating a new chunk at: ", newPosition);

    // random debug for prototyping processes
    Chunk generatedChunk = Chunk("default", newPosition);

    generateTerrain(generatedChunk);

    // This is debug for testing
    for (ubyte i = 0; i < 8; i++) {
        generateChunkMesh(generatedChunk, i);
    }

    // Finally insert the chunk into the container
    container[newPosition] = generatedChunk;

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
