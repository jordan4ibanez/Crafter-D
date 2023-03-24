module engine.thread_test.thread_test;

import doml.vector_2i;
import std.concurrency;
import std.parallelism;
import std.algorithm.mutation;
import std.conv;

// This is a test thing for a single map, multiple dimensions will make this ultimately flexible via an associative array
shared SafeMap map = new SafeMap();


/// You can never work directly on this data container
synchronized class SafeMap {
    
    private Chunk[Vector2i] elements;

    /// Adds a chunk or OVERRIDES a chunk
    void add(Vector2i key, shared(Chunk) chunk) {
        this.elements[key] = chunk;
    }

    /// Gives you a COPY of the chunk
    shared(Chunk) get(Vector2i key) {
        if (key !in elements) {
            throw new Exception("Map: Tried to get a null chunk in " ~ to!string(key) ~ "!");
        }
        return elements[key].copy();
    }
}

/// Place holder
synchronized class Chunk {

    private int[] data = new int[128];

    shared(Chunk) copy() {
        shared(Chunk) returningChunk = new Chunk();
        returningChunk.data.copy(this.data);
        return returningChunk;
    }

}