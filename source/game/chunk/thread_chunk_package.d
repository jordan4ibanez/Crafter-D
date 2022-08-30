module game.chunk.thread_chunk_package;

import game.chunk.chunk;

// This is used strictly for the chunk mesh generator!
// It's sole purpose is to tell the chunkmesh generator what the world is
// so it can create mesh data
struct ThreadChunkPackage {
    bool exists = false;
    ubyte yStack = 0;    
    bool updating = false;
    
    Chunk thisChunk;
    Chunk neighborNegativeX;
    Chunk neighborPositiveX;
    Chunk neighborNegativeZ;
    Chunk neighborPositiveZ;

    // This accumulates converted chunks into one huge package
    this(Chunk thisChunk,
         Chunk neighborNegativeX,
         Chunk neighborPositiveX,
         Chunk neighborNegativeZ,
         Chunk neighborPositiveZ,
         ubyte yStack,
         bool updating) {
            this.thisChunk = thisChunk;
            this.neighborNegativeX = neighborNegativeX;
            this.neighborPositiveX = neighborPositiveX;
            this.neighborNegativeZ = neighborNegativeZ;
            this.neighborPositiveZ = neighborPositiveZ;
            this.exists = true;
            this.yStack = yStack;
            this.updating = updating;
    }
}