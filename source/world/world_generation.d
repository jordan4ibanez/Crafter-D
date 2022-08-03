module world.world_generation;

import std.stdio;
import world.chunk;
import world.chunk;
import fast_noise;

// This is another static factory class. Used for, you guessed it, world generation
public static class WorldGenerator {

    private static int seed = 12_345_678;

    // IMPORTANT: THIS NEEDS TO INTAKE THE 2D POSITION!
    public static void generate () {

        FNLState noise = fnlCreateState(this.seed);
        noise.noise_type = FNLNoiseType.FNL_NOISE_OPENSIMPLEX2S;

        for (int i = 0; i < chunkArrayLength; i++) {
            Vector3I currentPosition = indexToPosition(i);
            float currentNoise = fnlGetNoise3D(&noise, currentPosition.x, currentPosition.y, currentPosition.z);
            writeln("noise at ", currentPosition.x, ",", currentPosition.y, ",", currentPosition.z, " is ", currentNoise);
        }
    }
    
}