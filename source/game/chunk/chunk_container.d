module game.chunk.chunk_container;

// External normal libraries
import std.stdio;
import std.range : popFront, popBack;
import std.algorithm : canFind;
import vector_2i;
import vector_3i;

// External concurrency libraries
import std.concurrency;
import std.algorithm.mutation: copy;
import core.time: Duration;
import asdf;

// Internal engine libraries
import ThreadLibrary = engine.thread.thread_library;

// Internal game libraries
import game.chunk.chunk;
import game.chunk.thread_message_chunk;
import game.graphics.chunk_mesh_generator;
import game.chunk.thread_chunk_package;
/*
This handles the chunks in the world. A static factory/container for Chunks using D's special
properties to treat the entire file as a static class

This is meant to be handled functionally
*/

// Hashmap container for generated chunks
private Chunk[Vector2i] container;

// External entry point into adding new chunks to the map
void generateChunk(Vector2i position) {
    Vector2i newPosition = Vector2i(position);
    send(ThreadLibrary.getWorldGeneratorThread(), newPosition);
    writeln("sending ", position, " to world generator");
}

// Gets a chunk from the container
Chunk getChunk(Vector2i position) {
    if (position in container) {
        return container[position].clone();
    }
    // writeln("WARNING, A GARBAGE CHUNK HAS BEEN DISPATCHED");
    // Return non-existent chunk
    return Chunk();
}

private Chunk fakeChunk = Chunk();
// Gets a mutable chunk from the container
ref Chunk getMutableChunk(Vector2i position) {
    if (position in container) {
        return container[position];
    }
    // This is where serious problems could happen if existence is not checked
    writeln("WARNING, A MUTABLE GARBAGE CHUNK HAS BEEN DISPATCHED");
    // This becomes garbage data
    return fakeChunk;
}

// Internal chunk generation dispatch
// This will be reused to receive chunks from the world generator

void receiveChunksFromWorldGenerator() {

    // Make this adjustable in the settings
    immutable int maxChunkReceives = 10;

    for (int i = 0; i < maxChunkReceives; i++){
        receiveTimeout(
            Duration(),
            (ThreadMessageChunk generatedChunkMessage) {
                Chunk receivedChunk = Chunk(generatedChunkMessage);   
                Vector2i newPosition = generatedChunkMessage.chunkPosition;
                container[newPosition] = receivedChunk;
                // Finally add a new chunk mesh update into the chunk mesh generator
                for (ubyte y = 0; y < 8; y++) {
                    // This creates A LOT of data, but hopefully it will not be too much for D
                    ThreadChunkPackage packageData = ThreadChunkPackage(
                        receivedChunk,
                        getChunk(Vector2i(newPosition.x - 1, newPosition.y)),
                        getChunk(Vector2i(newPosition.x + 1, newPosition.y)),
                        getChunk(Vector2i(newPosition.x, newPosition.y - 1)),
                        getChunk(Vector2i(newPosition.x, newPosition.y + 1)),
                        y, // yStack
                        false // Is it updating?
                    );

                    // Dump it right into the chunk mesh generator thread
                    send(ThreadLibrary.getChunkMeshGeneratorThread(), packageData);

                    // All that cloned chunk data goes into the other thread and we won't worry about it
                    // Hopefully
                }
            },
        );
    }
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
