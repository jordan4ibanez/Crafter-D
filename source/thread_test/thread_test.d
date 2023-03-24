module thread_test.thread_test;

import doml.vector_2i;
import std.concurrency;
import std.parallelism;

shared SafeMap map;

synchronized class SafeMap {
    
    private Chunk[Vector2i] elements;

    // void push(T value) {
    //     elements ~= value;
    // }

    // /// Return T.init if queue empty
    // T pop() {
    //     import std.array : empty;
    //     T value;
    //     if (elements.empty)
    //         return value;
    //     value = elements[0];
    //     elements = elements[1 .. $];
    //     return value;
    // }
}

synchronized class Chunk {

}