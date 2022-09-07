module game.chunk.chunk_container;

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
import game.chunk.thread_chunk_package;
import game.graphics.thread_mesh_message;
/*
This handles the chunks in the world. A static factory/container for Chunks using D's special
properties to treat the entire file as a static class

This is meant to be handled functionally
*/

ConcurrentHashMap chunkData = new ConcurrentHashMap();

// External entry point into adding new chunks to the map
void generateChunk(Vector2i position) nothrow {
    try {
    send(ThreadLibrary.getWorldGeneratorThread(), position);
    } catch(Exception e) {nothrowWriteln(e);}
}

public shared synchronized class ConcurrentHashMap {

    // Hashmap container for generated chunks
    private Chunk[Vector2i] container;

    // Gets a chunk from the container
    shared(Chunk) getChunk(Vector2i position) pure nothrow @safe {
        shared Chunk clone;
        if (position in container) {
            shared Chunk original = container[position];
            clone = original;
        }
        // writeln("WARNING, A GARBAGE CHUNK HAS BEEN DISPATCHED");
        // Return non-existent chunk
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
    ref shared(Chunk) getMutableChunk(Vector2i position) pure nothrow @safe {
        if (position in container) {
            return container[position];
        }
        // This is where serious problems could happen if existence is not checked
        // writeln("WARNING, A MUTABLE GARBAGE CHUNK HAS BEEN DISPATCHED");
        // This becomes garbage data
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

                    Chunk generatedChunk = cast(Chunk)immutableGeneratedChunk;


                    Vector2i newPosition = generatedChunk.getPosition();
                    container[newPosition] = cast(shared(Chunk))generatedChunk;

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

    void receiveMeshesFromChunkMeshGenerator() nothrow {
        bool received = true;
        while (received){
            received = false;
            try{
            receiveTimeout(
                Duration(),
                (shared(ThreadMeshMessage) newMesh) {               
                    received = true;

                    ThreadMeshMessage thisNewMesh = cast(ThreadMeshMessage) newMesh;

                    Vector3i position = thisNewMesh.position;

                    Chunk mutableChunk = cast(Chunk) getMutableChunk(Vector2i(position.x, position.z));

                    // New mesh is blank! Remove
                    if (thisNewMesh.vertices.length == 0) {        
                        mutableChunk.removeMesh(position.y);
                    } else {
                        mutableChunk.setMesh(position.y, Mesh(
                            thisNewMesh.vertices,
                            thisNewMesh.indices,
                            thisNewMesh.textureCoordinates,
                            thisNewMesh.colors,
                            thisNewMesh.textureName
                        ));
                    }
                }
            );
            } catch (Exception e){nothrowWriteln(e);}
        }
    }

    void renderWorld() nothrow {
        try {
        getShader("main").setUniformI("textureSampler", 0);
        getShader("main").setUniformF("light", 1);

        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, getTexture("textures/world_texture_map.png"));

        foreach (shared(Chunk) thisChunk; container) {
            Chunk castedChunk = cast(Chunk) thisChunk;
            for (ubyte i = 0; i < 8; i++) {
                castedChunk.drawMesh(i);
            }
        }
        } catch (Exception e) {nothrowWriteln(e);}
    }
}