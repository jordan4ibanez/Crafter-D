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

// This is only used for sending to things, like networking and thread messages
shared struct ThreadMessageChunk {
    bool exists = false;
    uint[]  block;
    ubyte[] light;
    ubyte[] rotation;
    // Height map needs to be added in

    string biome;
    Vector2i chunkPosition;

    // This data can only be created from a parent Chunk
    this(Chunk parentChunk) {
        if (!parentChunk.exists()) {
            return;
        }
        this.biome = parentChunk.getBiome();
        this.chunkPosition = Vector2i(parentChunk.getPosition());
        this.block = new uint[chunkArrayLength];
        uint[] parentBlocks = parentChunk.getRawBlocks();
        for (int i = 0; i < chunkArrayLength; i++) {
            this.block[i] = parentBlocks[i];
        }
        this.light = new ubyte[chunkArrayLength];
        ubyte[] parentLights = parentChunk.getRawLights();
        for (int i = 0; i < chunkArrayLength; i++) {
            this.light[i] = parentLights[i];
        }
        this.rotation = new ubyte[chunkArrayLength];
        ubyte[] parentRotations = parentChunk.getRawRotations();
        for (int i = 0; i < chunkArrayLength; i++) {
            this.rotation[i] = parentRotations[i];
        }
        this.exists = parentChunk.exists();
    }
}