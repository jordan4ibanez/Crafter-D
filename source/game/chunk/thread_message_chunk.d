module game.chunk.thread_message_chunk;

import std.stdio;

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
    bool exists = false;
    uint[]  block;
    ubyte[] light;
    ubyte[] rotation;
    // Height map needs to be added in

    string biome;
    Vector2i chunkPosition;

    // This data can only be created from a parent Chunk
    this(Chunk parentChunk) {
        this.biome = parentChunk.getBiome();
        this.chunkPosition = Vector2i(parentChunk.getPosition());
        this.block = new uint[chunkArrayLength];
        parentChunk.getRawBlocks().copy(this.block);
        this.light = new ubyte[chunkArrayLength];
        parentChunk.getRawLights().copy(this.light);
        this.rotation = new ubyte[chunkArrayLength];
        parentChunk.getRawRotations().copy(this.rotation);
        this.exists = true;
    }
}