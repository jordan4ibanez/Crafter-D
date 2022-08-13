module chunk.world_generation;

import std.stdio;
import chunk.chunk;
import fast_noise;
import std.math.rounding;
import helpers.structs;


private int SEED = 12_345_678;

void generateTerrain (ref Chunk thisChunk) {

    FNLState noise = fnlCreateState(SEED);
    noise.noise_type = FNLNoiseType.FNL_NOISE_OPENSIMPLEX2S;

    Vector2I chunkPosition = thisChunk.getPosition();

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
            int currentPositionX = x + basePositionX;
            int currentPositionZ = z + basePositionZ;

            // Noise at position
            float currentNoise = fnlGetNoise2D(&noise, currentPositionX, currentPositionZ);

            // Get the height fluctuation of the current position
            int currentHeightFlux = cast(int)floor(fluxHeight * currentNoise);

            // Now add it to the defined baseHeight of the biome
            int realHeight = baseHeight + currentHeightFlux;

            // Debug
            writeln("the height at ", currentPositionX, ",", currentPositionZ, " is ", realHeight);

            // Here will go a stack fill with predefined layers and whatnot

            for (int y = realHeight; y >= 0; y--){
                // writeln("set 1 to: ", x, " ", y, " ", z);
                thisChunk.setBlock(x,y,z,1);
            }
        }
    }


    // This is the cavegen prototype, this is going to take a lot of tuning
    /*
    for (int i = 0; i < chunkArrayLength; i++) {
        Vector3I currentPosition = indexToPosition(i);
        //float currentNoise = fnlGetNoise3D(&noise, currentPosition.x, currentPosition.y, currentPosition.z);
        // writeln("noise at ", currentPosition.x, ",", currentPosition.y, ",", currentPosition.z, " is ", currentNoise);
    }
    */
}