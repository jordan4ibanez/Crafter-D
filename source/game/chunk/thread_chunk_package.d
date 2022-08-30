module game.chunk.thread_chunk_package;

import game.chunk.chunk;
import game.chunk.thread_message_chunk;

shared struct ThreadChunkPackage {
    bool exists = false;
    ubyte yStack = 0;
    ThreadMessageChunk thisChunk;

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
         ubyte yStack) {
            this.thisChunk = ThreadMessageChunk(thisChunk);
            this.neighborNegativeX = ThreadMessageChunk(neighborNegativeX);
            this.neighborPositiveX = ThreadMessageChunk(neighborPositiveX);
            this.neighborNegativeZ = ThreadMessageChunk(neighborNegativeZ);
            this.neighborPositiveZ = ThreadMessageChunk(neighborPositiveZ);
            this.exists = true;
            this.yStack = yStack;
    }
}