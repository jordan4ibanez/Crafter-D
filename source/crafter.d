module crafter;

import std.stdio;
import std.conv;

import raylib;
import entity.mob.mob;
import entity.mob.mob_definitions.zombie;
import entity.mob.mob_factory;
import entity.player.player;
import entity.player.player_factory;
import chunk.chunk;
import chunk.chunk_factory;
import chunk.world_generation;
import raymath;
import delta_time;
import graphics.chunk_mesh_generation;
import helpers.structs;
import helpers.version_info;
import graphics.chunk_mesh_factory;

void main(string[] args) {

    initVersionTitle();    

    if (args.length > 1 && args[1] == "--server") {
        // Server loop
        bool serverShouldClose = false;

        while (!serverShouldClose) {
            calculateDelta();
            writeln("wow this is a server! ", getDelta());
        }
    } else {
        //WorldGenerator.generate(128,0);

        /*
        // Debug mobs
        MobFactory.spawnMob(new Zombie());
        MobFactory.debugFactory();

        // Debug players
        PlayerFactory.spawnPlayer(new Player("singleplayer"));
        PlayerFactory.debugFactory();


        ChunkFactory.newChunkGeneration(0,0);
        ChunkFactory.processStack();
        ChunkFactory.debugFactoryContainer();

        //Chunk chunky = new Chunk("default", Position2I(0,0));
        for ( int i = 0; i < 32_768; i++ ) {
            chunky.runADebug(i);
        }
        */


        InitWindow(1280,720, getVersionTitle().ptr);
        // SetTargetFPS(400);

        // Uncomment this to get a cleaner terminal - Disables raylib logging
        SetTraceLogLevel(10_000);

        SetWindowIcon(LoadImage("textures/icon.png"));

        loadTextureAtlas();

        int debugSize = 10;

        for (int x = -debugSize; x <= debugSize; x++) {
            for (int z = -debugSize; z <= debugSize; z++) {
                generateChunk(Vector2I(x,z));
            }
        }

        // Debug camera
        Camera camera = Camera(
            Vector3(0,100,-1),
            Vector3(1,0,-2),
            Vector3(0,1,0),
            73,
            CameraProjection.CAMERA_PERSPECTIVE
        );

        SetCameraMode(camera, CameraMode.CAMERA_CUSTOM);

        

        // Testing the block graphics registration
        // This will get called automatically when blocks are registered
        // testRegister();

        /* THIS IS DEBUG */

        debugCreateBlockGraphics();


        /* END DEBUG */


        // Generating a grass block debug

        // Texture testingTexture = LoadTexture("textures/debug.png");
        
        // testingModel.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture = testingTexture;



        // Client loop
        while(!WindowShouldClose()) {

            // These two functions literally build the environent
            processTerrainGenerationStack();
            processChunkMeshUpdateStack();

            // Delta calculation must come first
            calculateDelta();

            // Automatically plops the FPS and delta time onto the window title
            SetWindowTitle((getVersionTitle() ~ " | FPS: " ~ to!string(GetFPS()) ~ " | Delta: " ~ to!string(getDelta())).ptr);

            UpdateCamera(&camera);

            BeginDrawing();

            ClearBackground(Colors.SKYBLUE);

            BeginMode3D(camera);

            

            DrawCube(Vector3(0,0,-1),1,1,1,Colors.BLACK);

            renderWorld();
            // DrawModel(testingModel,Vector3(0,0,1),1,Colors.WHITE);
            // DrawCube(Vector3(1.5,0.5,1.5),1,1,1,Colors.RED);


            EndMode3D();

            EndDrawing();
        }

        CloseWindow();
    }
}