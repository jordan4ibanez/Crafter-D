module game.block.block_definition;

struct BlockDefinition {
    uint id = 0;
    bool solid = true;
    bool liquid = false;
    bool climbable = false;
    bool lightSource = false;
}