module game.chunk.world_generator;

// External normal libraries
import std.stdio;
import fast_noise;
import vector_2i;
import vector_3i;
import std.math.rounding;
import std.range;

// External concurrency libraries
import std.concurrency;
import std.algorithm.mutation: copy;
import core.time: Duration;
import asdf;

// Internal engine libraries
import Window = engine.window.window;

// Internal game libraries
import game.chunk.chunk;
import game.chunk.thread_message_chunk;

// This function is a thread
void doWorldGeneration(Tid parentThread) {

    immutable bool debugNow = false;

    if (debugNow) {
        writeln("World generator has started");
    }

    // Uses this to talk back to the main thread
    Tid mainThread = parentThread;

    int SEED = 12_345_678;

    // Generation stack on heap
    Vector2i[] generationStack = new Vector2i[0];
    // Output to be passed back to main thread
    ThreadMessageChunk[] outputStack = new ThreadMessageChunk[0];

    // Loaded biomes go here
    // Example: Biome[] biomes = new Biome[0];
    // Then send the biomes over in an array and decyper

    // Polls the generation stack 
    Chunk processTerrainGenerationStack() {
        Vector2i poppedValue = generationStack[0];
        generationStack.popFront();
        if (debugNow) {
            writeln("Generating: ", poppedValue);
        }
        // This needs a special struct which holds biome data!
        return Chunk("default", poppedValue);
    }

    FNLState noise = fnlCreateState(SEED);
    noise.noise_type = FNLNoiseType.FNL_NOISE_OPENSIMPLEX2S;

    void generateChunk() {

        Chunk thisChunk = processTerrainGenerationStack();

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

        if (debugNow) {
            writeln("generated chunk: ", thisChunk.getPosition(), ", adding to output stack!");
        }
        ThreadMessageChunk newMessage = ThreadMessageChunk(thisChunk);
        outputStack ~= newMessage;

        // writeln("NEW CHUNK WAS THIS: ", thisChunk);
        // writeln("THE OUTPUT IS NOW: ", outputStack);

        // thisChunk goes *poof*
    }

    // This runs at an extremely high framerate, find some way to slow it down when not in use...maybe?
    while (!Window.externalShouldClose()) {

        // Listen for input from main thread
        receiveTimeout(
            Duration(),
            (string stringData) {
                if (debugNow) {
                    writeln("world generator got: ", stringData);
                }
                // Got data of Vector3i
                if (stringData[0..8] == "Vector3i") {
                    if (debugNow) {
                        writeln("was type of Vector3i");
                    }
                    generationStack ~= stringData[8..stringData.length].deserialize!(Vector2i);
                }
            }
        );
        
        // See if there are any new chunk generations
        if (generationStack.length > 0) {
            // Generate the new chunks and put them into the output stack
            generateChunk();
        } 

        // See if there are any generated chunks ready to be sent out
        if (outputStack.length > 0) {
            shared(string) outputChunk = "generatedChunk" ~ outputStack[0].serializeToJson();
            if (debugNow) {
                writeln("sending this chunk back to the main thread: ", outputStack[0].chunkPosition);
            }
            outputStack.popFront();
            send(mainThread, outputChunk);
        }
    }

    writeln("World generator has closed!");

}