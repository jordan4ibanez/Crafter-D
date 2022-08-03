module world.chunk;

import raylib;
import std.stdio;

/*
Notes:

Chunks are technically 1D in memory.

They utilize 1D to 3D spatial striping to be fast.

0,0,0 starts at index 0. 15,127,15 is at index 32767.

 */


// Pre-calculation
const int xSize = 16;
const int ySize = 128;
const int zSize = 16;

const int chunkArrayLength = xSize * ySize * zSize;
const int yStride = xSize * ySize;

// 1D index to Vector3 position
Vector3I indexToPosition(int index) {
    return Vector3I(
        index % 16,
        (index % yStride) / xSize,
        index / yStride        
    );
}

// Vector3 position to 1D index
int positionToIndex(Vector3I position) {
    return (position.z * yStride) + (position.y * xSize) + position.x;
}

// Overload
int positionToIndex(int x, int y, int z) {
    return (x * yStride) + (z * ySize) + y;
}


// Micro struct for exact chunk math
struct Vector3I {
    int x = 0;
    int y = 0;
    int z = 0;
}

// Micro struct for chunk ID
struct Position2I {
    int x = 0;
    int z = 0;
}

// Basic inline collision detection
bool collideX(int value) {
    return (value >= 0 && value < xSize);
}
bool collideY(int value) {
    return (value >= 0 && value < ySize);
}
bool collideZ(int value) {
    return (value >= 0 && value < zSize);
}
// All at once
bool collide(int x, int y, int z) {
    return (collideX(x) && collideY(y) && collideZ(z));
}

public class Chunk {
    private int[chunkArrayLength]  block;
    private byte[chunkArrayLength] light;
    private byte[chunkArrayLength] rotation;
    // Height map needs to be added in

    private string biome;
    private Position2I position = Position2I(0,0);
    private bool positionLock = false;

    this(string biomeName, Position2I position) {
        this.setBiome(biomeName);
    }

    void runADebug(int index) {


        Vector3I test = indexToPosition(index);

        int test2 = positionToIndex(test);

        assert(index == test2, "ERROR! INDEX MISMATCH!!");

        writeln("---------\n","Start: ", index ,"\n", test, "\n", test2, "\n-----------");
    }

    // Complex boilerplate with boundary checks
    int getBlock(int x, int y, int z) {
        if (collide(x,y,z)) {
            return(this.block[positionToIndex(x,y,z)]);
        } else {
            // failed for some reason
            writeln("Getblock FAILED!");
            return -1;
        }
    }
    void setBlock(int x, int y, int z, int newBlock) {
        if (collide(x,y,z)) {
            this.block[positionToIndex(x,y,z)] = newBlock;
        }
    }
    // Overloads
    int getBlock(int index) {
        return this.block[index];
    }
    void setBlock(int index, int newBlock) {
        this.block[index] = newBlock;
    }

    string getBiome() {
        return this.biome;
    }
    void setBiome(string newBiome) {
        this.biome = newBiome;
    }

    Position2I getPosition() {
        return this.position;
    }
    // One way switch for setting position
    void setPosition(int x, int z) {
        if (!this.positionLock) {
            this.positionLock = true;
            this.position = Position2I(x,z);
        }
    }
}