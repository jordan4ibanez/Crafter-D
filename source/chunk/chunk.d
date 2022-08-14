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
    return (position.z * yStride) + (position.y * chunkSizeX) + position.x;
}

// Overload
int positionToIndex(int x, int y, int z) {
    return (x * yStride) + (z * chunkSizeY) + y;
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
bool collide(int x, int y, int z) {
    return (collideX(x) && collideY(y) && collideZ(z));
}

struct Chunk {
    private uint[chunkArrayLength]  block;
    private ubyte[chunkArrayLength] light;
    private ubyte[chunkArrayLength] rotation;
    private Model[8] chunkModelStack; 
    // Height map needs to be added in

    private string biome;
    private Vector2I position = Vector2I(0,0);
    private bool positionLock = false;

    this(string biomeName, Vector2I position) {
        this.setBiome(biomeName);
    }

    // Model manipulation
    void setModel(int yStack, Model newModel) {
        this.chunkModelStack[yStack] = newModel;
    }
    void removeModel(int yStack) {
        UnloadModel(this.chunkModelStack[yStack]);
    }
    Model getModel(int yStack) {
        return this.chunkModelStack[yStack];
    }
    void drawModel(int yStack) {
        DrawModel(this.chunkModelStack[yStack], Vector3(0,0,0),1,Colors.WHITE);
    }

    // Complex boilerplate with boundary checks
    uint getBlock(int x, int y, int z) {
        if (collide(x,y,z)) {
            return(this.block[positionToIndex(x,y,z)]);
        } else {
            // failed for some reason
            writeln("Getblock FAILED!");
            return 0;
        }
    }
    void setBlock(int x, int y, int z, uint newBlock) {
        if (collide(x,y,z)) {
            this.block[positionToIndex(x,y,z)] = newBlock;
        }
    }
    // Overloads
    uint getBlock(int index) {
        return this.block[index];
    }
    void setBlock(int index, int newBlock){
        this.block[index] = newBlock;
    }

    ubyte getRotation(int x, int y, int z) {
        if (collide(x,y,z)) {
            return(this.rotation[positionToIndex(x,y,z)]);
        } else {
            // failed for some reason
            writeln("Getblock FAILED!");
            return 0;
        }
    }
    void setRotation(int x, int y, int z, ubyte newRotation) {
        if (collide(x,y,z)) {
            this.rotation[positionToIndex(x,y,z)] = newRotation;
        }
    }

    string getBiome() {
        return this.biome;
    }
    void setBiome(string newBiome) {
        this.biome = newBiome;
    }

    Vector2I getPosition() {
        return this.position;
    }
    // One way switch for setting position
    void setPosition(int x, int z) {
        if (!this.positionLock) {
            this.positionLock = true;
            this.position = Vector2I(x,z);
        }
    }
}