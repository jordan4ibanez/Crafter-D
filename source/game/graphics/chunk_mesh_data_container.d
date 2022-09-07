module game.graphics.chunk_mesh_data_container;

import std.stdio;
import std.concurrency;
import core.time: Duration;
import bindbc.opengl;

import vector_2i;
import vector_3d;
import vector_3i;

import game.graphics.thread_mesh_message;
import game.graphics.chunk_mesh_stack;

import engine.mesh.mesh;
import engine.texture.texture;
import engine.helpers.nothrow_writeln;
import engine.opengl.shaders;



ChunkMeshStackHashMap chunkMeshData;


static this() {
    chunkMeshData = new ChunkMeshStackHashMap();
}

public class ChunkMeshStackHashMap {

    private ChunkMeshStack[Vector2i] container;

    void insertBlankSlate(string biomeName, Vector2i position) nothrow {
        try {
        if (!(position in container)) {
            container[position] = ChunkMeshStack(biomeName,position);
            writeln("new chunk mesh data: ", position);
        }
        } catch (Exception e) {nothrowWriteln(e);}
    }

    // Gets a mutable chunk data stack from the container
    ref ChunkMeshStack getMutableChunkStack(Vector2i position) nothrow @safe {
        if (position in container) {
            return container[position];
        }
        // This is where serious problems could happen if existence is not checked
        // writeln("WARNING, A MUTABLE GARBAGE CHUNK HAS BEEN DISPATCHED");
        // This becomes garbage data
        return *new ChunkMeshStack();
    }

    void receiveMeshesFromChunkMeshGenerator() nothrow {
        bool received = true;
        while (received){
            received = false;
            try{
            receiveTimeout(
                Duration(),
                (ThreadMeshMessage newMesh) {               
                    received = true;

                    ThreadMeshMessage thisNewMesh = newMesh;

                    Vector3i position = thisNewMesh.position;

                    ChunkMeshStack mutableChunkStack = getMutableChunkStack(Vector2i(position.x, position.z));

                    // New mesh is blank! Remove
                    if (thisNewMesh.vertices.length == 0) {        
                        mutableChunkStack.removeMesh(position.y);
                    } else {
                        mutableChunkStack.setMesh(position.y, Mesh(
                            cast(float[])thisNewMesh.vertices,
                            cast(int[])thisNewMesh.indices,
                            cast(float[])thisNewMesh.textureCoordinates,
                            cast(float[])thisNewMesh.colors,
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

        foreach (ChunkMeshStack thisChunkMeshStack; container) {
            for (ubyte i = 0; i < 8; i++) {
                thisChunkMeshStack.drawMesh(i);
            }
        }

        } catch (Exception e) {nothrowWriteln(e);}
    }
}