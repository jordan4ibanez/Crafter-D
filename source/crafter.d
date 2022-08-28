module crafter;

import std.stdio;

import delta_time;
import vector_2i;
import std.conv: to;
import bindbc.opengl;


import engine.helpers.version_info;
import engine.texture.texture;
import engine.opengl.gl_interface;
import engine.opengl.shaders;
import engine.openal.al_interface;
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

import Math         = math;
import Window       = engine.window.window;
import Camera       = engine.camera.camera;
import SoundManager = engine.openal.sound_manager;


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

        // Window acts as a static class handler for GLFW & game window    
        if (Window.initializeWindow(getVersionTitle(), false)) {
            writeln("GLFW init failed!");
            return;
        }    

        // GL init is purely functional
        if(initializeOpenGL()) {
            writeln("OpenGL init failed!");
            return;
        }

        // OpenAL acts like a static class handler for all of OpenAL Soft
        if (initializeOpenAL()){
            writeln("OpenAL init failed!");
            return;
        }

        createShaderProgram(
            "main",
            "shaders/vertex.vs",
            "shaders/fragment.fs",
            [
                "cameraMatrix",
                "objectMatrix",
                "textureSampler",
                "light"
            ]
        );   

        writeln("INITIAL LOADED GL VERSION: ", getInitialOpenGLVersion());
        writeln("FORWARD COMPATIBILITY VERSION: ", to!string(glGetString(GL_VERSION)));
    

        // Uncomment this to get a cleaner terminal - Disables raylib logging
        // Maybe make a version of this somehow
        // SetTraceLogLevel(10_000);

        // Need to make a version of this internal to engine
        //SetWindowIcon(LoadImage("textures/icon.png"));

        writeln("Loaded chunk texture atlas!");
        newTexture("textures/world_texture_map.png");

        int debugSize = 2;

        for (int x = -debugSize; x <= debugSize; x++) {
            for (int z = -debugSize; z <= debugSize; z++) {
                generateChunk(Vector2i(x,z));
            }
        }

        // How low can we go before people start going through the floor?
        // Limboooooo
        setMaxDeltaFPS(3);


        // Testing the block graphics registration
        // This will get called automatically when blocks are registered
        // testRegister();

        /* THIS IS DEBUG */

        debugCreateBlockGraphics();


        /* END DEBUG */


        // Generating a grass block debug

        // Texture testingTexture = LoadTexture("textures/debug.png");
        
        // testingModel.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture = testingTexture;

        // Click! The game opened right, wow!
        SoundManager.playSound("sounds/button.ogg");
        

        // Client loop
        while(!Window.shouldClose()) {

            // Delta calculation must come first
            calculateDelta();

            // These two functions literally build the environent
            processTerrainGenerationStack();
            processChunkMeshUpdateStack();

            Camera.testCameraHackRemoveThis();

            // Automatically plops the FPS and delta time onto the window title
            Window.setTitle((
                getVersionTitle() ~ " | FPS: " ~ to!string(Window.getFPS()) ~ " | Delta: " ~ to!string(getDelta()))
            );


            // BEGIN RENDERING 3D!

            glUseProgram(getShader("main").shaderProgram);

            Camera.setClearColor(1,1,1);
            Camera.clear();

            Camera.clearDepthBuffer();

            Camera.updateCameraMatrix();


            renderWorld();
            // DrawModel(testingModel,Vector3(0,0,1),1,Colors.WHITE);
            // DrawCube(Vector3(1.5,0.5,1.5),1,1,1,Colors.RED);



            // BEGIN ORTHOLINEAR HUD 3D!


            Window.swapBuffers();

            Window.pollEvents();

        }

        cleanUpAllTextures();
        deleteShaders();
        cleanUpOpenAL();
        Window.destroy();
    // }
}