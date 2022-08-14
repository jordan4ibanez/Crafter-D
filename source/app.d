import std.stdio;

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

immutable string GAME_VERSION = "0.0.0 - Prototype";

void main(string[] args) {

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



        InitWindow(1280,720, ("Crafter " ~ GAME_VERSION).ptr);
        SetTargetFPS(60);

        SetWindowIcon(LoadImage("textures/icon.png"));

        loadTextureAtlas();

        // Debug camera
        Camera camera = Camera(
            Vector3(0,66,-1),
            Vector3(1,0,-2),
            Vector3(0,1,0),
            73,
            CameraProjection.CAMERA_PERSPECTIVE
        );

        SetCameraMode(camera, CameraMode.CAMERA_FIRST_PERSON);

        // Testing the block graphics registration
        // This will get called automatically when blocks are registered
        // testRegister();

        /* THIS IS DEBUG */

        debugCreateBlockGraphics();


        /* END DEBUG */



        Chunk thisChunk = Chunk("default", Vector2I(-1,-1));

        generateTerrain(thisChunk);

        for (ubyte i = 0; i < 8; i++) {
            generateChunkMesh(thisChunk, i);
        }

        // Generating a grass block debug

        // Texture testingTexture = LoadTexture("textures/debug.png");
        
        // testingModel.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture = testingTexture;



        // Client loop
        while(!WindowShouldClose()) {


            UpdateCamera(&camera);
            // Delta calculation must come first
            calculateDelta();

            BeginDrawing();

            ClearBackground(Colors.RAYWHITE);

            BeginMode3D(camera);

            

            DrawCube(Vector3(0,0,-1),1,1,1,Colors.BLACK);

            for (ubyte i = 0; i < 8; i++) {
                thisChunk.drawModel(i);
            }

            // DrawModel(testingModel,Vector3(0,0,1),1,Colors.WHITE);
            // DrawCube(Vector3(1.5,0.5,1.5),1,1,1,Colors.RED);


            EndMode3D();

            EndDrawing();
        }

        CloseWindow();
    }
}
