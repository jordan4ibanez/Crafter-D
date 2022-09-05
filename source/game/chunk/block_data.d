module game.chunk.block_data;

import std.bitmanip;

//32 bit
struct BlockData {
    mixin(
        bitfields!(
            ushort, "id",          16,
            ubyte, "state",        4,
            ubyte, "torchLight",   4,
            ubyte, "naturalLight", 4,
            ubyte, "rotation",     4,
        )
    );
}