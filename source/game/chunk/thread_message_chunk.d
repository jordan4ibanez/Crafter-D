module game.chunk.thread_message_chunk;

import vector_2i;

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
}