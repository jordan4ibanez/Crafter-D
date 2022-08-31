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
private shared(Chunk[Vector2i]) container;

// External entry point into adding new chunks to the map
void generateChunk(Vector2i position) {
    send(ThreadLibrary.getWorldGeneratorThread(), position);
}

// Gets a chunk from the container
Chunk getChunk(Vector2i position) {
    if (position in container) {
        Chunk original = cast(Chunk)container[position];
        Chunk clone = original.clone();
        return clone;
    }
    // writeln("WARNING, A GARBAGE CHUNK HAS BEEN DISPATCHED");
    // Return non-existent chunk
    return Chunk();
}

// Gets a shared chunk from the container
shared(Chunk) getSharedChunk(Vector2i position) {
    if (position in container) {
        Chunk original = cast(Chunk)container[position];
        Chunk clone = original.clone();
        return cast(shared(Chunk))clone;
    }
    // writeln("WARNING, A GARBAGE CHUNK HAS BEEN DISPATCHED");
    // Return non-existent chunk
    return cast(shared(Chunk))Chunk();
}

private Chunk fakeChunk = Chunk();
// Gets a mutable chunk from the container
ref Chunk getMutableChunk(Vector2i position) {
    if (position in container) {
        return cast(Chunk)container[position];
    }
    // This is where serious problems could happen if existence is not checked
    writeln("WARNING, A MUTABLE GARBAGE CHUNK HAS BEEN DISPATCHED");
    // This becomes garbage data
    return fakeChunk;
}

// Internal chunk generation dispatch
// This will be reused to receive chunks from the world generator

void receiveChunksFromWorldGenerator() {

    bool receieved = true;

    while(receieved) {
        receieved = false;
        receiveTimeout(
            Duration(),
            (shared(Chunk) sharedGeneratedChunk) {

                receieved = true;

                Chunk generatedChunk = cast(Chunk)sharedGeneratedChunk;
                Chunk clonedChunk = generatedChunk.clone();


                Vector2i newPosition = clonedChunk.getPosition();
                container[newPosition] = cast(shared(Chunk))clonedChunk;

                // Finally add a new chunk mesh update into the chunk mesh generator
                
                for (ubyte y = 0; y < 8; y++) {
                    // This creates A LOT of data, but hopefully it will not be too much for D
                    // Dump it right into the chunk mesh generator thread
                    Tid cmg = ThreadLibrary.getChunkMeshGeneratorThread();
                    send(cmg, MeshUpdate(Vector3i(newPosition.x, y, newPosition.y), true));
                    // All that cloned chunk data goes into the other thread and we won't worry about it
                    // Hopefully
                }
            },
        );
    }
}

void receiveMeshesFromChunkMeshGenerator() {
    
    bool received = true;
    while(received) {
        received = false;
        receiveTimeout(
            Duration(),
            (shared(ThreadMeshMessage) newMesh) {               
                received = true;

                ThreadMeshMessage thisNewMesh = cast(ThreadMeshMessage) newMesh;

                Vector3i position = thisNewMesh.position;

                Chunk mutableChunk = getMutableChunk(Vector2i(position.x, position.z));

                mutableChunk.setMesh(position.y, Mesh(
                    thisNewMesh.vertices,
                    thisNewMesh.indices,
                    thisNewMesh.textureCoordinates,
                    thisNewMesh.colors,
                    thisNewMesh.textureName
                ));
            }
        );
    }
}

void renderWorld() {
    foreach (shared(Chunk) thisChunk; container) {
        Chunk castedChunk = cast(Chunk) thisChunk;
        for (ubyte i = 0; i < 8; i++) {
            castedChunk.drawMesh(i);
        }
    }
}


// Everything past this is for debugging components of this static class
void debugFactoryContainer() {
    writeln("factory container: ", container);
}
