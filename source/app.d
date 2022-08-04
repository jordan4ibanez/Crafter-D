import std.stdio;

import raylib;
import entity.mob.mob;
import entity.mob.mob_definitions.zombie;
import entity.mob.mob_factory;
import entity.player.player;
import entity.player.player_factory;
import world.chunk;
import world.chunk_factory;
import world.chunk;
import world.world_generation;

void main() {
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



    InitWindow(1280,720, "Voxel Thing");
    SetTargetFPS(60);

    // Debug camera
    Camera camera = Camera(Vector3(10,0,0), Vector3(0,0,0),Vector3(0,1,0),45, CameraProjection.CAMERA_PERSPECTIVE);

    SetCameraMode(camera, CameraMode.CAMERA_FIRST_PERSON);


    while(!WindowShouldClose()) {
        BeginDrawing();


        ClearBackground(Colors.RAYWHITE);


        UpdateCamera(&camera);

        BeginMode3D(camera);

        DrawSphere(Vector3(0,0,0),2, Colors.BLACK);

        EndMode3D();

        EndDrawing();
    }



}
