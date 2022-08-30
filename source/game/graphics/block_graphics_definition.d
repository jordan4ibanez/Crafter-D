module game.graphics.block_graphics_definition;

import vector_2i;
import std.stdio;

shared struct BlockGraphicDefinition {
    uint id = 0;
    float[][] blockBox;
    Vector2i[] blockTextures;

    this(uint id, float[][] blockBox, Vector2i[] blockTextures) {
        this.id = id;
        for (int i = 0; i < blockBox.length; i++){
            writeln("wrong blockbox length");
            assert(blockBox[i].length == 6, "wrong blockbox length");
        }
        assert(blockTextures.length == 6, "wrong blocktextures length");
        this.blockBox = cast(shared(float[][]))blockBox;
        this.blockTextures = cast(shared(Vector2i[]))blockTextures;
    }
}