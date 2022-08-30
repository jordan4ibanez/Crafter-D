module game.chunk.chunk;

import std.stdio;
import vector_2i;
import vector_3i;
import vector_3d;
import engine.mesh.mesh;

import std.algorithm.mutation: copy;

/*
Notes:

Chunks are technically 1D in memory.

They utilize 1D to 3D spatial striping to be fast.

0,0,0 starts at index 0. 15,127,15 is at index 32767.

 */


// Pre-calculation
immutable int chunkSizeX = 16;
immutable int chunkSizeY = 128;
immutable int chunkSizeZ = 16;

// This needs to be divisible by 8 so (chunkSizeY / this) == 8
// This is only used for dividing the chunk meshes up into bite sized pieces
immutable int chunkStackSizeY = 16;

immutable int chunkArrayLength = chunkSizeX * chunkSizeY * chunkSizeZ;
immutable int yStride = chunkSizeX * chunkSizeY;

// 1D index to Vector3 position
Vector3i indexToPosition(int index) {
    return Vector3i(
        index % 16,
        (index % yStride) / chunkSizeX,
        index / yStride        
    );
}

// Vector3 position to 1D index
int positionToIndex(Vector3i position) {
    return (position.x * yStride) + (position.z * chunkSizeY) + position.y;
}


// Basic inline collision detection
bool collideX(int value) {
    return (value >= 0 && value < chunkSizeX);
}
bool collideY(int value) {
    return (value >= 0 && value < chunkSizeY);
}
bool collideZ(int value) {
    return (value >= 0 && value < chunkSizeZ);
}
// All at once
// True: Is within the chunk
bool collide(Vector3i position) {
    return (collideX(position.x) && collideY(position.y) && collideZ(position.z));
}

struct Chunk {
    private bool thisExists = false;
    private uint[]  block;
    private ubyte[] light;
    private ubyte[] rotation;
    private Mesh[] chunkMeshStack;
    // Height map needs to be added in

    private string biome;
    private Vector2i chunkPosition;
    private bool positionLock = false;

    this(string biomeName, Vector2i position) {
        this.biome = biomeName;
        this.chunkPosition = Vector2i(position.x, position.y);
        this.positionLock = true;
        this.thisExists = true;
        this.block = new uint[chunkArrayLength];
        this.light = new ubyte[chunkArrayLength];
        this.rotation = new ubyte[chunkArrayLength];
        this.chunkMeshStack = new Mesh[8];
    }

    // Creates an entirely new chunk in memory
    Chunk clone() {
        Chunk cloningChunk = Chunk();
        cloningChunk.biome = this.biome;
        cloningChunk.chunkPosition = Vector2i(this.chunkPosition);
        cloningChunk.block = new uint[chunkArrayLength];
        this.block.copy(cloningChunk.block);
        cloningChunk.light = new ubyte[chunkArrayLength];
        this.light.copy(cloningChunk.light);
        cloningChunk.rotation = new ubyte[chunkArrayLength];
        this.rotation.copy(cloningChunk.rotation);
        cloningChunk.positionLock = true;
        cloningChunk.thisExists = true;
        cloningChunk.chunkMeshStack = new Mesh[8];
        return cloningChunk;
    }

    bool exists() {
        return this.thisExists;
    }

    // Mesh manipulation
    void setMesh(int yStack, Mesh newMesh) {
        // This will check if the mesh was ever initialized automatically
        this.chunkMeshStack[yStack].cleanUp();
        this.chunkMeshStack[yStack] = newMesh;
    }
    /*
    void removeModel(int yStack) {
        this.chunkMeshStack[yStack].cleanUp();
    }
     // This is disabled because it should just be called not manipulated
    Model getModel(int yStack) {
        return this.chunkMeshStack[yStack];
    }
    */
    // DO NOT USE THIS
    void drawMesh(int yStack) {
        // writeln("DO NOT USE DRAW MODEL INTERNALLY! IT NEEDS TO BATCH!");
        this.chunkMeshStack[yStack].render(
            Vector3d(
                this.chunkPosition.x * chunkSizeX,
                0,
                this.chunkPosition.y * chunkSizeZ
            ),
            Vector3d(0,0,0),
            1,
            1
        );
    }

    uint[] getRawBlocks() {
        return block;
    }
    ubyte[] getRawLights() {
        return light;
    }
    ubyte[] getRawRotations() {
        return rotation;
    }

    // Complex boilerplate with boundary checks
    uint getBlock(Vector3i position) {
        if (collide(position)) {
            return(this.block[positionToIndex(position)]);
        } else {
            // failed for some reason
            writeln("Getblock FAILED!");
            return 0;
        }
    }
    void setBlock(Vector3i position, uint newBlock) {
        if (collide(position)) {
            this.block[positionToIndex(position)] = newBlock;
        }
    }
    // Overloads
    uint getBlock(int index) {
        return this.block[index];
    }
    void setBlock(int index, int newBlock){
        this.block[index] = newBlock;
    }

    ubyte getRotation(Vector3i position) {
        if (collide(position)) {
            return(this.rotation[positionToIndex(position)]);
        } else {
            // failed for some reason
            writeln("Getblock FAILED!");
            return 0;
        }
    }
    void setRotation(Vector3i position, ubyte newRotation) {
        if (collide(position)) {
            this.rotation[positionToIndex(position)] = newRotation;
        }
    }

    string getBiome() {
        return this.biome;
    }

    Vector2i getPosition() {
        return this.chunkPosition;
    }
}