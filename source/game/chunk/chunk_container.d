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
import game.graphics.chunk_mesh_generation;
import game.graphics.chunk_mesh_factory;
/*
This handles the chunks in the world. A static factory/container for Chunks using D's special
properties to treat the entire file as a static class

This is meant to be handled functionally
*/

// Hashmap container for generated chunks
private Chunk[Vector2i] container;

// External entry point into adding new chunks to the map
void generateChunk(Vector2i position) {
    shared(string) serializedPosition = "Vector3i" ~ position.serializeToJson();
    send(ThreadLibrary.getWorldGeneratorThread(), serializedPosition);
}

// Gets a chunk from the container
Chunk getChunk(Vector2i position) {
    if (position in container) {
        return container[position];
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
            (string newData) {
                // Received a chunk from world generator
                if (newData[0..14] == "generatedChunk") {
                    // Recompile into a Chunk
                    ThreadMessageChunk newMessage = newData[14..newData.length].deserialize!(ThreadMessageChunk);
                    Chunk receivedChunk = Chunk(newMessage);                
                    Vector2i newPosition = newMessage.chunkPosition;
                    // Shove it into the container
                    container[newPosition] = receivedChunk;
                    // Finally add a new chunk mesh update
                    for (ubyte y = 0; y < 8; y++) {
                        newChunkMeshUpdate(Vector3i(newPosition.x, y, newPosition.y));
                    }
                }
            }
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
