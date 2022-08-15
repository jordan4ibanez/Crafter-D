module chunk.chunk;

import raylib;
import std.stdio;
import helpers.structs;

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
Vector3I indexToPosition(int index) {
    return Vector3I(
        index % 16,
        (index % yStride) / chunkSizeX,
        index / yStride        
    );
}

// Vector3 position to 1D index
int positionToIndex(Vector3I position) {
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
bool collide(Vector3I position) {
    return (collideX(position.x) && collideY(position.y) && collideZ(position.z));
}

struct Chunk {
    private bool thisExists = false;
    private uint[chunkArrayLength]  block;
    private ubyte[chunkArrayLength] light;
    private ubyte[chunkArrayLength] rotation;
    private Model[8] chunkModelStack; 
    // Height map needs to be added in

    private string biome;
    private Vector2I chunkPosition = Vector2I(0,0);
    private bool positionLock = false;

    this(string biomeName, Vector2I position) {
        this.biome = biomeName;
        this.chunkPosition = position;
        this.positionLock = true;
        this.thisExists = true;
    }

    bool exists() {
        return this.thisExists;
    }

    // Model manipulation
    void setModel(int yStack, Model newModel) {
        this.chunkModelStack[yStack] = newModel;
    }
    void removeModel(int yStack) {
        UnloadModel(this.chunkModelStack[yStack]);
    }
    /* // This is disabled because it should just be called not manipulated
    Model getModel(int yStack) {
        return this.chunkModelStack[yStack];
    }
    */
    void drawModel(int yStack) {
        DrawModel(
            this.chunkModelStack[yStack],
            Vector3(
                this.chunkPosition.x * chunkSizeX,
                0,
                this.chunkPosition.y * chunkSizeZ
            ),
            1,
            Colors.WHITE
        );
    }

    // Complex boilerplate with boundary checks
    uint getBlock(Vector3I position) {
        if (collide(position)) {
            return(this.block[positionToIndex(position)]);
        } else {
            // failed for some reason
            writeln("Getblock FAILED!");
            return 0;
        }
    }
    void setBlock(Vector3I position, uint newBlock) {
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

    ubyte getRotation(Vector3I position) {
        if (collide(position)) {
            return(this.rotation[positionToIndex(position)]);
        } else {
            // failed for some reason
            writeln("Getblock FAILED!");
            return 0;
        }
    }
    void setRotation(Vector3I position, ubyte newRotation) {
        if (collide(position)) {
            this.rotation[positionToIndex(position)] = newRotation;
        }
    }

    string getBiome() {
        return this.biome;
    }

    Vector2I getPosition() {
        return this.chunkPosition;
    }
}