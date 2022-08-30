module game.chunk.thread_chunk_package;

import game.chunk.chunk;
import game.chunk.thread_message_chunk;

// This is used strictly for the chunk mesh generator!
// It's sole purpose is to tell the chunkmesh generator what the world is
// so it can create mesh data
shared struct ThreadChunkPackage {
    bool exists = false;
    ubyte yStack = 0;
    ThreadMessageChunk thisChunk;
    bool updating = false;

    ThreadMessageChunk neighborNegativeX;
    ThreadMessageChunk neighborPositiveX;
    ThreadMessageChunk neighborNegativeZ;
    ThreadMessageChunk neighborPositiveZ;

    // This accumulates converted chunks into one huge package
    this(Chunk thisChunk,
         Chunk neighborNegativeX,
         Chunk neighborPositiveX,
         Chunk neighborNegativeZ,
         Chunk neighborPositiveZ,
         ubyte yStack,
         bool updating) {
            this.thisChunk = ThreadMessageChunk(thisChunk);
            this.neighborNegativeX = ThreadMessageChunk(neighborNegativeX);
            this.neighborPositiveX = ThreadMessageChunk(neighborPositiveX);
            this.neighborNegativeZ = ThreadMessageChunk(neighborNegativeZ);
            this.neighborPositiveZ = ThreadMessageChunk(neighborPositiveZ);
            this.exists = true;
            this.yStack = yStack;
            this.updating = updating;
    }
}