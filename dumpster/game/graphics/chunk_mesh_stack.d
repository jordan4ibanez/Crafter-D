module game.graphics.chunk_mesh_stack;

import engine.mesh.mesh;
import game.chunk.chunk;
import vector_2i;
import vector_3d;

struct ChunkMeshStack {
    private bool thisExists = false;
    private Mesh[] chunkMeshStack;

    private string biome;
    private Vector2i chunkPosition;
    private bool positionLock = false;

    this(string biomeName, Vector2i position) {
        this.biome = biomeName;
        this.chunkPosition = *new Vector2i(position.x, position.y);
        this.positionLock = true;
        this.thisExists = true;
        this.chunkMeshStack = new Mesh[8];
    }

    // Mesh manipulation
    void setMesh(int yStack, Mesh newMesh) {
        // This will check if the mesh was ever initialized automatically
        this.chunkMeshStack[yStack].destroy();
        this.chunkMeshStack[yStack] = newMesh;
    }

    void removeMesh(int yStack) {
        // It's nothing, clean it up
        this.chunkMeshStack[yStack].destroy();
        // Remove it's old values!
        this.chunkMeshStack[yStack] = Mesh();
    }

    /*
     // This is disabled because it should just be called not manipulated
    Model getModel(int yStack) {
        return this.chunkMeshStack[yStack];
    }
    */
    // DO NOT USE THIS - needs to sort by distance
    void drawMesh(int yStack) {

        immutable Vector3d min = Vector3d(
            0,
            0,
            0
        );
        immutable Vector3d max = Vector3d(
            cast(float)chunkSizeX,
            cast(float)chunkStackSizeY,
            cast(float)chunkSizeZ
        );

        this.chunkMeshStack[yStack].batchRender(
            Vector3d(
                this.chunkPosition.x * chunkSizeX,
                cast(float)yStack * chunkStackSizeY,
                this.chunkPosition.y * chunkSizeZ
            ),
            Vector3d(0,0,0),
            Vector3d(1,1,1),
            true,
            min,
            max
        );
    }
}