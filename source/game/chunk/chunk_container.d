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
import engine.mesh.mesh;

// Internal game libraries
import game.chunk.chunk;
import game.graphics.chunk_mesh_generator;
import game.chunk.thread_chunk_package;
import game.graphics.thread_mesh_message;
/*
This handles the chunks in the world. A static factory/container for Chunks using D's special
properties to treat the entire file as a static class

This is meant to be handled functionally
*/

// Hashmap container for generated chunks
private Chunk[Vector2i] container;

// External entry point into adding new chunks to the map
void generateChunk(Vector2i position) {
    send(ThreadLibrary.getWorldGeneratorThread(), position);
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
            (shared(Chunk) sharedGeneratedChunk) {

                Chunk generatedChunk = cast(Chunk)sharedGeneratedChunk;

                Vector2i newPosition = generatedChunk.getPosition();
                container[newPosition] = generatedChunk;

                // Finally add a new chunk mesh update into the chunk mesh generator
                
                for (ubyte y = 0; y < 8; y++) {
                    // This creates A LOT of data, but hopefully it will not be too much for D
                    // Dump it right into the chunk mesh generator thread
                    Tid cmg = ThreadLibrary.getChunkMeshGeneratorThread();
                    send(cmg, "startingTransfer");
                    send(cmg, cast(shared(Chunk))generatedChunk.clone());
                    send(cmg, cast(shared(Chunk))getChunk(Vector2i(newPosition.x - 1, newPosition.y)));
                    send(cmg, cast(shared(Chunk))getChunk(Vector2i(newPosition.x + 1, newPosition.y)));
                    send(cmg, cast(shared(Chunk))getChunk(Vector2i(newPosition.x, newPosition.y - 1)));
                    send(cmg, cast(shared(Chunk))getChunk(Vector2i(newPosition.x, newPosition.y + 1)));
                    send(cmg, y);
                    send(cmg, false);

                    // All that cloned chunk data goes into the other thread and we won't worry about it
                    // Hopefully
                }
            },
        );
    }
}

void receiveMeshesFromChunkMeshGenerator() {
    immutable int updates = 10;
    for (int i = 0; i < updates; i++) {
        receiveTimeout(
            Duration(),
            (ThreadMeshMessage newMesh) {                
                ThreadMeshMessage thisNewMesh = newMesh;

                Vector3i position = thisNewMesh.position;

                Chunk mutableChunk = getMutableChunk(Vector2i(position.x, position.z));

                Mesh newChunkMesh = Mesh(
                    cast(float[])thisNewMesh.vertices,
                    cast(int[])thisNewMesh.indices,
                    cast(float[])thisNewMesh.textureCoordinates,
                    cast(float[])thisNewMesh.colors,
                    thisNewMesh.textureName
                );

                mutableChunk.setMesh(position.y, newChunkMesh);
            }
        );
    }
}

void receiveMeshUpdatesFromChunkMeshGenerator() {
    receiveTimeout(
        Duration(),
        
    );
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
