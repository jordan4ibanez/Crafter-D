module game.chunk.chunk;

import std.stdio;
import vector_2i;
import vector_3i;
import vector_3d;

import engine.mesh.mesh;
import game.chunk.block_data;

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
    private BlockData[] data;

    // Height map needs to be added in

    private string biome;
    private Vector2i chunkPosition;
    private bool positionLock = false;

    this(string biomeName, Vector2i position) {
        this.biome = biomeName;
        this.chunkPosition = *new Vector2i(position.x, position.y);
        this.positionLock = true;
        this.thisExists = true;
        this.data = new BlockData[chunkArrayLength];
        
    }

    bool exists() {
        return this.thisExists;
    }
    

    BlockData[] getRawData() {
        return data;
    }

    // Complex boilerplate with boundary checks
    ushort getBlock(Vector3i position) {
        if (collide(position)) {
            return(this.data[positionToIndex(position)].id);
        } else {
            // failed for some reason
            writeln("Getblock FAILED!");
            return 0;
        }
    }

    void setBlock(Vector3i position, ushort newBlock) {
        if (collide(position)) {
            this.data[positionToIndex(position)].id = newBlock;
        }
    }
    // Overloads
    ushort getBlock(int index) {
        return this.data[index].id;
    }
    void setBlock(int index, ushort newBlock){
        this.data[index].id = newBlock;
    }

    ubyte getRotation(Vector3i position) {
        if (collide(position)) {
            return(this.data[positionToIndex(position)].rotation);
        } else {
            // failed for some reason
            writeln("Getblock FAILED!");
            return 0;
        }
    }
    void setRotation(Vector3i position, ubyte newRotation) {
        if (collide(position)) {
            this.data[positionToIndex(position)].rotation = newRotation;
        }
    }

    string getBiome() {
        return this.biome;
    }

    Vector2i getPosition() {
        return this.chunkPosition;
    }
}