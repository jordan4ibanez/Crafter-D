module dumpster.crafter;

module crafter;

// External normal libraries
import std.stdio;
import delta_time;
import vector_2i;
import std.conv: to;
import bindbc.opengl;
import vector_3d;
import vector_2d;

// External concurrency libraries
import std.concurrency;
import std.algorithm.mutation: copy;
import core.time: Duration;
import asdf;

// Internal engine libraries
import engine.helpers.version_info;
import engine.texture.texture;
import engine.opengl.gl_interface;
import engine.opengl.shaders;
import engine.openal.al_interface;
import engine.mesh.debug_collision_box;

// Internal game libraries
import game.entity.mob.mob;
import game.entity.mob.mob_definitions.zombie;
import game.entity.mob.mob_factory;
import game.entity.player.player;
import game.entity.player.player_container;
import game.chunk.chunk;
import game.chunk.chunk_data_container;
import game.chunk.world_generator;
import game.graphics.chunk_mesh_generator;
import game.graphics.chunk_mesh_data_container;

// Libraries imported as objects
import Math          = math;
import Window        = engine.window.window;
import Camera        = engine.camera.camera;
import SoundManager  = engine.openal.sound_manager;
import ThreadLibrary = engine.thread.thread_library;
import PlayerClient  = game.client.player_client;


void debugCreateBlockGraphics(){
    // Stone
    registerBlockGraphicsDefinition(
        1,
        [
            // [0,0,0,1,0.5,1],
            // [0,0,0,0.5,1,0.5]
        ],
        [
            Vector2i(0,0),
            Vector2i(0,0),
            Vector2i(0,0),
            Vector2i(0,0),
            Vector2i(0,0),
            Vector2i(0,0)
        ]
    );

    // Grass
    registerBlockGraphicsDefinition(
        2,
        [],
        [
            Vector2i(1,0),
            Vector2i(1,0),
            Vector2i(1,0),
            Vector2i(1,0),
            Vector2i(3,0),
            Vector2i(2,0)
        ]
    );

    // Dirt
    registerBlockGraphicsDefinition(
        3,
        [],
        [
            Vector2i(3,0),
            Vector2i(3,0),
            Vector2i(3,0),
            Vector2i(3,0),
            Vector2i(3,0),
            Vector2i(3,0)
        ]
    );

    /*
    // Water?
    registerBlockGraphicsDefinition(
        4,
        [],
        [
            Vector2i(9,0),
            Vector2i(9,0),
            Vector2i(9,0),
            Vector2i(9,0),
            Vector2i(9,0),
            Vector2i(9,0)
        ]
    );
    */
}


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

        // Dispatch needed threads for game prototyping, handle these when a player enters a world instead of this mess!
        // Scoped so NOTHING else here can touch them and they go off the stack
        {
            Tid worldGenThread = spawn(&startWorldGeneratorThread, thisTid);
            ThreadLibrary.setWorldGeneratorThread(worldGenThread);

            Tid chunkMeshGenThread = spawn(&startMeshGeneratorThread, thisTid);
            ThreadLibrary.setChunkMeshGeneratorThread(chunkMeshGenThread);
        }


        // Uncomment this to get a cleaner terminal - Disables raylib logging
        // Maybe make a version of this somehow
        // SetTraceLogLevel(10_000);

        // Need to make a version of this internal to engine
        //SetWindowIcon(LoadImage("textures/icon.png"));

        writeln("Loaded chunk texture atlas!");
        newTexture("textures/world_texture_map.png");

        int debugSize = 10;
        // This is the initial payload
        // Generates from the center outward
        for (int i = 0; i <= debugSize; i++){
            for (int x = -i; x <= i; x++) {
                for (int z = -i; z <= i; z++) {
                    if (Math.abs(z) == i || Math.abs(x) == i) {
                        generateChunk(Vector2i(x,z));
                    }
                }
            }
        }

        // How low can we go before people start going through the floor?
        // Limboooooo
        setMaxDeltaFPS(3);

        // Unlmited for now
        Window.setVsync(0);


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

        constructCollisionBoxMesh();

        double playerDebug = 0;
        bool up = true;

        // Client loop
        while(!Window.shouldClose()) {
            // Delta calculation must come first
            calculateDelta();

            if (up) {
                playerDebug += getDelta();
                if (playerDebug > 0.5) {
                    up = false;
                }
            } else {
                playerDebug -= getDelta();
                if (playerDebug < -0.5) {
                    up = true;
                }
            }

            // This is a lag test for the physics/weird bugs
            /*
            int w = 0;
            for (int i = 0; i < 100_000_000; i++) {
                w += 1 * i;
            }
            */

            

            // These two functions literally build the environent
            chunkData.receiveChunksFromWorldGenerator();
            chunkMeshData.receiveMeshesFromChunkMeshGenerator();

            PlayerClient.onTick();

            // Automatically plops the FPS and delta time onto the window title
            Window.setTitle((
                getVersionTitle() ~ " | FPS: " ~ to!string(Window.getFPS()) ~ " | Delta: " ~ to!string(getDelta()))
            );


            // BEGIN RENDERING 3D!

            glUseProgram(getShader("main").shaderProgram);

            // Sky blue translated into doubles
            Camera.setClearColor(0,0.709803,0.88627);
            Camera.clear();

            Camera.clearDepthBuffer();

            Camera.updateCameraMatrix();

            drawCollisionBoxMesh(PlayerClient.getPosition(), PlayerClient.getSize());


            chunkMeshData.renderWorld();
            // DrawModel(testingModel,Vector3(0,0,1),1,Colors.WHITE);
            // DrawCube(Vector3(1.5,0.5,1.5),1,1,1,Colors.RED);



            // BEGIN ORTHOLINEAR HUD 3D!


            Window.swapBuffers();

            Window.pollEvents();

        }
        
        cleanUpCollisionBoxMesh();
        ThreadLibrary.killAllThreads();
        cleanUpAllTextures();
        deleteShaders();
        cleanUpOpenAL();
        Window.destroy();
    // }
}