module chunk.chunk_factory;


import std.stdio;
import chunk.chunk;
import std.range : popFront, popBack;
import std.algorithm : canFind;
import helpers.structs;

// This handles the chunks in the world. A static factory/container for Chunks
// This is meant to be handled functionally
public static class ChunkFactory {

    // Hashmap container for generated chunks
    private static Chunk[Vector2I] container;

    // Generation stack
    private static Vector2I[] stack;

    // Entry point into adding new chunks to the map
    public static void newChunkGeneration(int x, int z) {
        Vector2I newGenerationPosition = Vector2I(x,z);

        // Do not dispatch a new chunk generation into stack if it's already there
        if (!this.stack.canFind(newGenerationPosition)) {
            stack ~= newGenerationPosition;
        }
    }

    // Will poll the generation stack 
    public static void processStack() {

        // See if there are any new chunk generations
        if (this.stack.length > 0) {

            Vector2I poppedValue = this.stack[0];
            this.stack.popFront();
            writeln("popped: ", poppedValue);

            // Ship them to the chunk generator process
            generateChunk(poppedValue);
        }
    }

    private static void generateChunk(Vector2I newPosition) {
        writeln("I'm generating a new chunk at: ", newPosition);

        // random debug for prototyping processes
        Chunk generatedChunk = new Chunk("default", newPosition);

        // Generation process goes here
        // It will take the object, do work with it, then give it back

        // Finally insert the chunk into the container
        this.container[newPosition] = generatedChunk;

        // The factory is now done processing the chunk
    }


    // Everything past this is for debugging components of this static class
    public static void debugFactoryContainer() {
        writeln("factory container: ", this.container);
    }
}