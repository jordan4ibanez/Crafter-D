module engine.thread.thread_library;

// Stack class acts like a mini library for locking the thread ids

import std.concurrency;
import std.algorithm.mutation: copy;
import core.time: Duration;
import asdf;

// The locks are important in case anyone starts modding the game, DO NOT want these getting changed

private Tid worldGenerator;
private Tid chunkMeshGenerator;
private bool worldGeneratorLock = false;
private bool chunkMeshGeneratorLock = false;

void setWorldGeneratorThread(Tid worldGenThread) {
    if (!worldGeneratorLock) {
        worldGeneratorLock = true;
        worldGenerator = worldGenThread;
    }
}
Tid getWorldGeneratorThread() {
    return worldGenerator;
}

void setChunkMeshGeneratorThread(Tid chunkMeshGenThread) {
    if (!chunkMeshGeneratorLock) {
        chunkMeshGeneratorLock = true;
        ChunkMeshGenerator = chunkMeshGenThread;
    }
}
Tid getChunkMeshGeneratorThread() {
    return meshGenerator;
}

void killAllThreads() {
    send(worldGenerator, true);
    send(chunkMeshGenerator, true);
}