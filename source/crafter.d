module crafter;

import std.stdio;
import std.conv;

import delta_time;

import engine.helpers.version_info;
import game.entity.mob.mob;
import game.entity.mob.mob_definitions.zombie;
import game.entity.mob.mob_factory;
import game.entity.player.player;
import game.entity.player.player_factory;
import game.chunk.chunk;
import game.chunk.chunk_factory;
import game.chunk.world_generation;
import game.graphics.chunk_mesh_generation;
import game.graphics.chunk_mesh_factory;

import Math = math;
import Window = engine.window.window;

void main(string[] args) {

    initVersionTitle();    

    /*
    if (args.length > 1 && args[1] == "--server") {
        // Server loop
        bool serverShouldClose = false;

        while (!serverShouldClose) {
            calculateDelta();
            writeln("wow this is a server! ", getDelta());
        }
    } else {
        //WorldGenerator.generate(128,0);

        
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

        Window.initializeWindow(getVersionTitle());

        // Uncomment this to get a cleaner terminal - Disables raylib logging
        // Maybe make a version of this somehow
        // SetTraceLogLevel(10_000);

        // Need to make a version of this internal to engine
        //SetWindowIcon(LoadImage("textures/icon.png"));

        newTexture("textures/world_texture_map.png");

        int debugSize = 10;

        for (int x = -debugSize; x <= debugSize; x++) {
            for (int z = -debugSize; z <= debugSize; z++) {
                generateChunk(Vector2I(x,z));
            }
        }


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
            SetWindowTitle((
                getVersionTitle() ~ " | FPS: " ~ to!string(GetFPS()) ~ " | Delta: " ~ to!string(getDelta())).ptr
            );

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
    // }
}