module engine.thread.thread_library;

// Stack class acts like a mini library for locking the thread ids

import std.concurrency;
import std.algorithm.mutation: copy;
import core.time: Duration;
import asdf;

// The locks are important in case anyone starts modding the game, DO NOT want these getting changed

private Tid worldGenerator;
private Tid meshGenerator;
private bool worldGeneratorLock = false;
private bool meshGeneratorLock = false;

void setWorldGeneratorThread(Tid worldGenThread) {
    if (!worldGeneratorLock) {
        worldGeneratorLock = true;
        worldGenerator = worldGenThread;
    }
}
Tid getWorldGeneratorThread() {
    return worldGenerator;
}

void setMeshGeneratorThread(Tid meshGenThread) {
    if (!meshGeneratorLock) {
        meshGeneratorLock = true;
        meshGenerator = meshGenThread;
    }
}

void killAllThreads() {
    send(worldGenerator, true);
    send(meshGenerator, true);
}