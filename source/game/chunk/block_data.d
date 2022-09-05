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

    ushort getID() {
        return this.id;
    }
    ubyte getState() {
        return this.state;
    }
    ubyte getTorchLight() {
        return this.torchLight;
    }
    ubyte getNaturalLight() {
        return this.naturalLight;
    }
    ubyte getRotation() {
        return this.rotation;
    }

    void setID(ushort newID) {
        this.id = newID;
    }
    void setState(ubyte newState) {
        this.state = newState;
    }
    void setTorchLight(ubyte newTorchLight) {
        this.torchLight = newTorchLight;
    }
    void setNaturalLight(ubyte newNaturalLight) {
        this.naturalLight = newNaturalLight;
    }
    void setRotation(ubyte newRotation) {
        this.rotation = newRotation;
    }
}