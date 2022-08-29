module game.chunk.thread_message_chunk;

// External normal libraries
import vector_2i;

// External concurrency libraries
import std.concurrency;
import std.algorithm.mutation: copy;
import core.time: Duration;
import asdf;

// Internal game libraries
import game.chunk.chunk;

// This is only used for serialization and sending to things, like networking and thread messages
struct ThreadMessageChunk {
    uint[]  block;
    ubyte[] light;
    ubyte[] rotation;
    // Height map needs to be added in

    private string biome;
    private Vector2i chunkPosition;

    this(string biomeName, Vector2i position) {
        this.biome = biomeName;
        this.chunkPosition = Vector2i(position.x, position.y);
        this.block = new uint[chunkArrayLength];
        this.light = new ubyte[chunkArrayLength];
        this.rotation = new ubyte[chunkArrayLength];
    }


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
}