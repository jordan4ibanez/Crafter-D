module game.graphics.chunk_mesh_generator;

// Normal external libraries
import std.algorithm;
import std.stdio;
import std.range: popFront;
import std.array: insertInPlace;
import vector_2i;
import vector_3i;

// Concurrency external libraries
import std.concurrency;
import std.algorithm.mutation: copy;
import core.time: Duration;
import asdf;

// Normal internal engine libraries
import Window = engine.window.window;

// Normal internal game libraries
import game.chunk.chunk_container;
import game.chunk.chunk;
import game.chunk.thread_chunk_package;
import game.graphics.mesh_generation;


// Mesh Generation Factory

/*
How this works:

The entry point is the chunk factory. It gets processed via internalGenerateChunk().

It then comes here and becomes part of the newStack!

A chunk mesh is created using the api in block graphics.

Next we need to update the neighbors if they exist. This gets sent into updatingStack.

Updating stack does not update the neighbors. This avoids a recursion crash.

That's about it really
*/

// Thread spawner starts here
void startMeshGeneratorThread(Tid parentThread) {

// Gotta tell the main thread what has been created
Tid mainThread = parentThread;

writeln("Starting thread mesh generator");

bool didGenLastLoop = false;

// New meshes call this update to fully update neighbors on heap
// This needs to be a package of current and neighbors
ThreadChunkPackage[] newStack = new ThreadChunkPackage[0];

// Preexisting meshes call this update to only update necessary neighbors on heap
// This needs to be a package of current and neighbors
ThreadChunkPackage[] updatingStack = new ThreadChunkPackage[0];

// This 
void newChunkMeshUpdate(ThreadChunkPackage thisPackage) {
    if (!newStack.canFind(thisPackage)) {
        // newStack.insertInPlace(0, thisPackage);
        newStack ~= thisPackage;
    }
}

void updateChunkMesh(ThreadChunkPackage thisPackage) {
    if (!updatingStack.canFind(thisPackage)) {
        updatingStack ~= thisPackage;
    }
}

void internalGenerateChunkMesh(ThreadChunkPackage thePackage) {

    Chunk thisChunk = *new Chunk(thePackage.thisChunk);

    Vector3i position = Vector3i(
        thisChunk.getPosition().x,
        thePackage.yStack,
        thisChunk.getPosition().y
    );

    // Get chunk neighbors
    // These do not exist by default
    Chunk neighborNegativeX = *new Chunk(thePackage.neighborNegativeX);
    Chunk neighborPositiveX = *new Chunk(thePackage.neighborPositiveX);
    Chunk neighborNegativeZ = *new Chunk(thePackage.neighborNegativeZ);
    Chunk neighborPositiveZ = *new Chunk(thePackage.neighborPositiveZ);

    writeln("go");
    generateChunkMesh(
        thisChunk,
        neighborNegativeX,
        neighborPositiveX,
        neighborNegativeZ,
        neighborPositiveZ,
        cast(ubyte)position.y
    );
    writeln("stop");

    // Update neighbors
    if (neighborNegativeX.exists()) {
        // updateChunkMesh(Vector3i(position.x - 1, position.y, position.z));
        writeln("send out request for update!");
    }
    if (neighborPositiveX.exists()) {
        // updateChunkMesh(Vector3i(position.x + 1, position.y, position.z));
        writeln("send out request for update!");
    }
    if (neighborNegativeZ.exists()) {
        // updateChunkMesh(Vector3i(position.x, position.y, position.z - 1));
        writeln("send out request for update!");
    }
    if (neighborPositiveZ.exists()) {
        // updateChunkMesh(Vector3i(position.x, position.y, position.z + 1));
        writeln("send out request for update!");
    }
}

void internalUpdateChunkMesh(ThreadChunkPackage thePackage) {

    Chunk thisChunk = *new Chunk(thePackage.thisChunk);

    Vector3i position = Vector3i(
        thisChunk.getPosition().x,
        thePackage.yStack,
        thisChunk.getPosition().y
    );

    // Get chunk neighbors
    // These do not exist by default
    Chunk neighborNegativeX = *new Chunk(thePackage.neighborNegativeX);
    Chunk neighborPositiveX = *new Chunk(thePackage.neighborPositiveX);
    Chunk neighborNegativeZ = *new Chunk(thePackage.neighborNegativeZ);
    Chunk neighborPositiveZ = *new Chunk(thePackage.neighborPositiveZ);

    generateChunkMesh(
        thisChunk,
        neighborNegativeX,
        neighborPositiveX,
        neighborNegativeZ,
        neighborPositiveZ,
        cast(ubyte)position.y
    );
    // As you can see as listed above, this is the same function but without the recursive update.
    // This could have intook a boolean, but it's easier to understand it as a separate function.
}

void processChunkMeshUpdateStack(){
    // See if there are any new chunk generations
    if (newStack.length > 0) {

        ThreadChunkPackage newPackage = newStack[0];
        newStack.popFront();
        // writeln("New Chunk Mesh: ", poppedValue);

        // Ship them to the chunk generator process
        internalGenerateChunkMesh(newPackage);
    }
    
    // See if there are any existing chunk mesh updates
    if (updatingStack.length > 0) {

        ThreadChunkPackage updatingPackage = updatingStack[0];
        updatingStack.popFront();
        // writeln("Updating Chunk Mesh: ", poppedValue);

        // Ship them to the chunk generator process
        internalUpdateChunkMesh(updatingPackage);
    }
}

while(!Window.externalShouldClose()) {

    // A cpu saver routine
    if (!didGenLastLoop) {

        didGenLastLoop = false;
        receive(
            (ThreadChunkPackage newPackage) {
                if (newPackage.updating) {
                    writeln("this is an update!");
                    updateChunkMesh(newPackage);
                    didGenLastLoop = true;
                } else {
                    writeln("this is a new generation!");
                    newChunkMeshUpdate(newPackage);
                    didGenLastLoop = true;
                }
            
            },
            // If you send this thread a bool, it continues, then breaks
            (bool kill) {}
        );
    } else {
        didGenLastLoop = false;
        receiveTimeout(
            Duration(),
            (ThreadChunkPackage newPackage) {
                if (newPackage.updating) {
                    writeln("this is an update!");
                    updateChunkMesh(newPackage);
                    didGenLastLoop = true;
                } else {
                    writeln("this is a new generation!");
                    newChunkMeshUpdate(newPackage);
                    didGenLastLoop = true;
                }
            
            },
            // If you send this thread a bool, it continues, then breaks
            (bool kill) {}
        );
    }

    if(updatingStack.length > 0 || newStack.length > 0) {
        didGenLastLoop = true;
        processChunkMeshUpdateStack();
    }
}

writeln("thread mesh generator closed!");


}// Thread spawner ends here