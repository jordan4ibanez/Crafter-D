module game.chunk.world_generation;

import std.stdio;
import fast_noise;
import std.math.rounding;
import vector_2i;
import vector_3i;
import engine.window.window;

import game.chunk.chunk;

// Polls the generation stack 
void processTerrainGenerationStack() {

    // See if there are any new chunk generations
    if (stack.length > 0) {

        Vector2i poppedValue = stack[0];
        stack.popFront();
        // writeln("Generating: ", poppedValue);

        // Ship them to the chunk generator process
        internalGenerateChunk(poppedValue);
    }
}


void generateTerrain (ref Chunk thisChunk) {

    int SEED = 12_345_678;

    // Generation stack
    Vector2i[] stack = new Vector2i[0];

    FNLState noise = fnlCreateState(SEED);
    noise.noise_type = FNLNoiseType.FNL_NOISE_OPENSIMPLEX2S;

    Vector2i chunkPosition = thisChunk.getPosition();

    // Get the real position of the chunk
    int basePositionX = chunkPosition.x * chunkSizeX;
    int basePositionZ = chunkPosition.y * chunkSizeZ;

    // These will be defined in a biome container

    // The base height of the chunk
    int baseHeight = 70;
    // How high or low it can fluctuate based on the noise (-1 to 1)
    int fluxHeight = 20;

    // Iterate the 2D noise of the chunk
    for (int x = 0; x < chunkSizeX; x++) {
        for (int z = 0; z < chunkSizeZ; z++) {

            // The real position in 2D space
            int realPositionX = x + basePositionX;
            int realPositionZ = z + basePositionZ;

            // Noise at position
            float currentNoise = fnlGetNoise2D(&noise, realPositionX, realPositionZ);

            // Get the height fluctuation of the current position
            int currentHeightFlux = cast(int)floor(fluxHeight * currentNoise);

            // Now add it to the defined baseHeight of the biome
            int realHeight = baseHeight + currentHeightFlux;

            // Debug
            // writeln("the height at ", realPositionX, ",", realPositionZ, " is ", realHeight);

            // Here will go a stack fill with predefined layers and whatnot

            // Grass top
            thisChunk.setBlock(Vector3i(x,realHeight,z),2);

            // Dirt filler
            for (int y = realHeight - 1; y > realHeight - 4 ; y--){
                // writeln("set 1 to: ", x, " ", y, " ", z);
                thisChunk.setBlock(Vector3i(x,y,z),3);
            }

            // Stone bottom
            for (int y = realHeight - 3; y >= 0 ; y--){
                // writeln("set 1 to: ", x, " ", y, " ", z);
                thisChunk.setBlock(Vector3i(x,y,z),1);
            }

            // "water"

            // Water height is 65, and goes to 0
            /*
            for (int y = 65; y >= 0; y--){
                if (thisChunk.getBlock(Vector3i(x,y,z)) == 0) {
                    thisChunk.setBlock(Vector3i(x,y,z),4);
                }
            }
            */
        }
    }


    // This is the cavegen prototype, this is going to take a lot of tuning
    /*
    for (int i = 0; i < chunkArrayLength; i++) {
        Vector3i currentPosition = indexToPosition(i);
        //float currentNoise = fnlGetNoise3D(&noise, currentPosition.x, currentPosition.y, currentPosition.z);
        // writeln("noise at ", currentPosition.x, ",", currentPosition.y, ",", currentPosition.z, " is ", currentNoise);
    }
    */
}