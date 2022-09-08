module game.chunk.chunk_data_container;

// External normal libraries
import std.stdio;
import std.range : popFront, popBack;
import std.algorithm : canFind;
import std.array: assocArray;
import vector_2i;
import vector_3i;
import bindbc.opengl;
import Math = math;

// External concurrency libraries
import std.concurrency;
import std.algorithm.mutation: copy;
import core.time: Duration;
import asdf;
import core.sync.mutex;

// Internal engine libraries
import ThreadLibrary = engine.thread.thread_library;
import engine.mesh.mesh;
import engine.opengl.shaders;
import engine.texture.texture;
import engine.helpers.nothrow_writeln;

// Internal game libraries
import game.chunk.chunk;
import game.graphics.chunk_mesh_generator;
import game.graphics.chunk_mesh_data_container;
/*
This handles the chunks in the world. A static factory/container for Chunks using D's special
properties to treat the entire file as a static class

This is meant to be handled functionally
*/

// this might need to be divided into 2 separate containers, thread local, and thread shared
ConcurrentChunkHashMap chunkData;

static this() {
    chunkData = new ConcurrentChunkHashMap();
}

// External entry point into adding new chunks to the map
void generateChunk(Vector2i position) nothrow {
    try {
    send(ThreadLibrary.getWorldGeneratorThread(), position);
    } catch(Exception e) {nothrowWriteln(e);}
}

public shared synchronized class ConcurrentChunkHashMap {

    // Hashmap container for generated chunks
    private Chunk[Vector2i] container;

    private Mutex mewtex;

    this() {
        this.mewtex = new shared Mutex();
    }

    // Gets a chunk from the container
    shared(Chunk) getChunk(Vector2i position) nothrow @safe {
        mewtex.lock_nothrow();
        shared Chunk clone;
        if (position in container) {
            shared Chunk original = container[position];
            clone = original;
        }
        // writeln("WARNING, A GARBAGE CHUNK HAS BEEN DISPATCHED");
        // Return non-existent chunk
        mewtex.unlock_nothrow();
        return clone;
    }

    // Gets a shared chunk from the container
    /*
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
    */

    // Gets a mutable chunk from the container
    ref shared(Chunk) getMutableChunk(Vector2i position) nothrow @safe {
        mewtex.lock_nothrow();
        if (position in container) {
            mewtex.unlock_nothrow();
            return container[position];
        }
        // This is where serious problems could happen if existence is not checked
        // writeln("WARNING, A MUTABLE GARBAGE CHUNK HAS BEEN DISPATCHED");
        // This becomes garbage data
        mewtex.unlock_nothrow();
        return *new shared Chunk();
    }

    // Internal chunk generation dispatch
    // This will be reused to receive chunks from the world generator

    void receiveChunksFromWorldGenerator() nothrow shared {
        bool received = true;
        while(received) {
            received = false;
            try {
            receiveTimeout(
                Duration(),
                (immutable Chunk immutableGeneratedChunk) {
                    
                    received = true;

                    Chunk original = cast(Chunk)immutableGeneratedChunk;
                    Chunk generatedChunk = original;

                    Vector2i newPosition = generatedChunk.getPosition();
                    string clonedBiome = generatedChunk.getBiome();

                    chunkMeshData.insertBlankSlate(
                        clonedBiome,
                        newPosition
                    );

                    mewtex.lock_nothrow();
                    container[newPosition] = cast(shared(Chunk))generatedChunk;
                    mewtex.unlock_nothrow();

                    // Finally add a new chunk mesh update into the chunk mesh generator
                    Tid cmg = ThreadLibrary.getChunkMeshGeneratorThread();

                    for (ubyte y = 0; y < 8; y++) {
                        // This creates A LOT of data, but hopefully it will not be too much for D
                        // Dump it right into the chunk mesh generator thread
                        send(cmg, MeshUpdate(Vector3i(newPosition.x, y, newPosition.y), true));
                        // All that cloned chunk data goes into the other thread and we won't worry about it
                        // Hopefully
                    }
                },
            );
            } catch(Exception e) {nothrowWriteln(e);}
        }
    }
}