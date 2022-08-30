module game.chunk.thread_chunk_package;

import game.chunk.chunk;

struct ThreadChunkPackage {
    bool exists = false;
    Chunk thisChunk;

    Chunk neighborNegativeX;
    Chunk neighborPositiveX;
    Chunk neighborNegativeZ;
    Chunk neighborPositiveZ;

    this(Chunk thisChunk,
         Chunk neighborNegativeX,
         Chunk neighborPositiveX,
         Chunk neighborNegativeZ,
         Chunk neighborPositiveZ) {
            this.thisChunk = thisChunk;
            this.neighborNegativeX = neighborNegativeX;
            this.neighborPositiveX = neighborPositiveX;
            this.neighborNegativeZ = neighborNegativeZ;
            this.neighborPositiveZ = neighborPositiveZ;
            this.exists = true;
        }
}