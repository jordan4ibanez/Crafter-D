module blockmodel.blockmodel;

import std.stdio;
import std.string;
import std.file;
import std.json;
import std.conv;
import std.algorithm.iteration;
import std.algorithm.sorting;
import std.conv;
import doml.vector_2d;
import doml.vector_3d;
import doml.vector_3i;
import doml.matrix_4d;
import doml.math;
import delta_time;

/// Container class for constructing the model
class Block {
    int id;
    Vector3d size;
    Vector3d staticPosition;
    Vector3d staticRotation;
    Vector3d[] translation;
    Vector3d[] rotation;
    Vector3d[] scale;
    Vector2d[] textureCoordinates;
}

class BlockModel {

    private static immutable double RADIANS = PI/180.0;
    
    private static immutable int[] indiceOrder = [
        // Front
        0,1,2,2,3,0,
        // Back
        4,5,6,6,7,4,
        // Left
        8,9,10,10,11,8,
        // Right
        12,13,14,14,15,12,
        // Top
        16,17,18,18,19,16,
        // Bottom
        20,21,22,22,23,20
    ];

    /// This is basically a worker array
    /// Indexed 0 - NO skipping
    Block[] blocks;

    string name;
    int FPS;
    int total_frames = 0;
    int total_blocks = 0;
    bool isStatic;
    
    double[] vertexPositions;
    int[] indices;
    int[] bones;
    double[] textureCoordinates;
    
    // Framerate is constant LINEAR interpolation
    const double frameTick;

    double frameTime = 0.0;
    int currentFrame = 0;

    this(string fileLocation) {
        this.loadBlocks(fileLocation);
        this.constructGLModel();

        frameTick = 1.0/cast(double)FPS;
    }

    //*========================= BEGIN OPENGL METHODS =====================================
    
    //! This is a debug container method for playing animation
    //! In the future create a frame range and automate

    // These comments are dumped from main()
    //! Begin first iteration of animation prototyping, this is doing the ENTIRE animation
    //! In future implementation: Containerization will allow LERP portions of the animation
    
    /// Speed is a multiplier on the base model FPS
    double[] playAnimation(double speed = 1.0) {

        double[] animationAccumulator;
        
        if (isStatic) {
            foreach (Block block; blocks) {
                Vector3d translation = block.staticPosition;
                Vector3d rotation = block.staticRotation;
                Vector3d scale = Vector3d(1,1,1);

                Matrix4d animationMatrix = Matrix4d()
                    .identity()
                    .setTranslation(translation)
                    .setRotationXYZ(rotation.x, rotation.y, rotation.z)
                    .scaleLocal(scale.x,scale.y,scale.z);
                    
                animationAccumulator ~= animationMatrix.getDoubleArray();
            }

        } else {

            frameTime += getDelta() * speed;

            // Tick up integral frame
            if (frameTime >= frameTick) {
                frameTime -= frameTick;
                currentFrame++;
                // Loop integral frame - Remember: 0 count
                if (currentFrame >= total_frames) {
                    currentFrame = 0;
                }
            }

            const double frameProgress = frameTime / frameTick;
            
            int startFrame;
            int endFrame;

            // LERP back to frame 0 - Remember 0 count
            if (currentFrame == total_frames - 1) {
                startFrame = currentFrame;
                endFrame   = 0;
            } 
            // LERP to next frame
            else {
                startFrame = currentFrame;
                endFrame   = currentFrame + 1;
            }

            foreach (Block block; blocks) {
                Vector3d[] t = block.translation;
                Vector3d[] r = block.rotation;
                Vector3d[] s = block.scale;

                Vector3d translation = Vector3d(t[startFrame]).lerp(t[endFrame], frameProgress);
                Vector3d rotation    = Vector3d(r[startFrame]).lerp(r[endFrame], frameProgress);
                Vector3d scale       = Vector3d(s[startFrame]).lerp(s[endFrame], frameProgress);
                Matrix4d animationMatrix = Matrix4d()
                    .identity()
                    .setTranslation(translation)
                    .setRotationXYZ(rotation.x, rotation.y, rotation.z)
                    .scaleLocal(scale.x,scale.y,scale.z);
                    
                animationAccumulator ~= animationMatrix.getDoubleArray();
            }
        }
        
        return animationAccumulator;
    }

    double[] getVertexPositions() {
        return this.vertexPositions;
    }

    int[] getIndices() {
        return this.indices;
    }

    double[] getTextureCoordinates() {
        return this.textureCoordinates;
    }

    int[] getBones() {
        return this.bones;
    }

private:

    void constructGLModel() {
        // Construct each cube
        foreach (block; blocks) {
            this.constructVertexPositions(block);
            this.constructIndices(block);
            this.constructBones(block);
            this.constructTextureCoordinates(block);
        }
    }

    void constructTextureCoordinates(Block block) {
        foreach (Vector2d point; block.textureCoordinates) {
            textureCoordinates ~= point.x;
            textureCoordinates ~= point.y;
        }
    }

    void constructBones(Block block) {
        const int boneCache = block.id;
        foreach (int i; 0..24) {
            bones ~= boneCache;
        }
    }

    void constructVertexPositions(Block block) {
        
        // 8 Vertex Positions

        // Wall 1 (FRONT)
        const auto v0 = Vector3d(block.size.x, block.size.y * 2, -block.size.z);
        const auto v1 = Vector3d(block.size.x, 0, -block.size.z);
        const auto v2 = Vector3d(-block.size.x, 0, -block.size.z);
        const auto v3 = Vector3d(-block.size.x, block.size.y * 2, -block.size.z);

        // Wall 2 (BACK)
        const auto v4 = Vector3d(-block.size.x, block.size.y * 2, block.size.z);
        const auto v5 = Vector3d(-block.size.x, 0, block.size.z);
        const auto v6 = Vector3d(block.size.x, 0, block.size.z);
        const auto v7 = Vector3d(block.size.x, block.size.y * 2, block.size.z);

        // Front face
        assembleQuad(v0,v1,v2,v3);
        //Back face
        assembleQuad(v4,v5,v6,v7);

        //Left face
        assembleQuad(v3,v2,v5,v4);
        //Right face
        assembleQuad(v7,v6,v1,v0);

        // Top face (up is -Z, points to front face)
        assembleQuad(v3,v4,v7,v0);
        // Bottom face (up is -Z, points to front face)
        assembleQuad(v1,v6,v5,v2);

    }

    // Builds a plane of 2 tris out of 4 vertex positions
    void assembleQuad(Vector3d pos1, Vector3d pos2, Vector3d pos3, Vector3d pos4) {
        foreach (thisVertexPos; [pos1, pos2, pos3, pos4]) {
            vertexPositions ~= thisVertexPos.x;
            vertexPositions ~= thisVertexPos.y;
            vertexPositions ~= thisVertexPos.z;
        }
    }

    // Assembles the indices of the block
    void constructIndices(Block block) {

        // There are 24 indices per block
        const int currentCount = block.id * 24;

        foreach (int key; indiceOrder) {
            indices ~= currentCount + key;
        }
    }
    //!====================== END OPENGL METHODS =================================

    //*====================== BEGIN JSON METHODS =================================

    void loadBlocks(string fileLocation) {
        if (!exists(fileLocation)) {
            throw new Exception(fileLocation ~ " does not exist!");
        }

        void[] rawData;
        string jsonString;
        rawData = read(fileLocation);
        jsonString = cast(string)rawData;
        JSONValue jsonData = parseJSON(jsonString);

        // Get REQUIRED baseline info
        foreach (string key,JSONValue value; jsonData.objectNoRef) {
            switch (key) {
                case "name": {
                    assert(value.type == JSONType.string);
                    this.name = value.str;
                    break;
                }
                case "FPS": {
                    assert(value.type == JSONType.integer);
                    this.FPS = cast(int)value.integer;
                    break;
                }
                case "total_frames": {
                    assert(value.type == JSONType.integer);
                    this.total_frames = cast(int)value.integer;
                    break;
                }
                case "total_blocks": {
                    assert(value.type == JSONType.integer);
                    this.total_blocks = cast(int)value.integer;
                    break;
                }
                default:
            }
        }

        // Now store if it's a static model
        if (total_frames <= 1 || FPS == 0) {
            //! Re-enable this for export testing
            isStatic = true;
        }

        // Now get the blocks and animation
        foreach (i; 0..total_blocks) {

            Block block = new Block();

            block.id = i;

            JSONValue blockData = jsonData.objectNoRef["block" ~ to!string(i)];

            foreach (string key, JSONValue value; blockData.objectNoRef) {
                switch (key) {
                    case "size": {
                        assert(value.type == JSONType.array);

                        JSONValue[3] temp = value.array;
                        
                        block.size = Vector3d(
                            getDouble(temp[0]),
                            getDouble(temp[1]),
                            getDouble(temp[2])
                        );
                        break;
                    }
                    case "static_position": {
                        assert(value.type == JSONType.array);

                        JSONValue[3] temp = value.array;
                        
                        block.staticPosition = Vector3d(
                            getDouble(temp[0]),
                            getDouble(temp[1]),
                            getDouble(temp[2])
                        );
                        break;
                    }
                    case "static_rotation": {
                        assert(value.type == JSONType.array);

                        JSONValue[3] temp = value.array;
                        
                        block.staticRotation = Vector3d(
                            getDouble(temp[0]) * RADIANS,
                            getDouble(temp[1]) * RADIANS,
                            getDouble(temp[2]) * RADIANS
                        );
                        break;
                    }
                    case "animation": {
                        assert(value.type == JSONType.object);
                        if (isStatic) {
                            throw new Exception("A static model cannot have animation!");
                        }
                        extractAnimation(block, value);
                        break;
                    }
                    case "texture_coordinates": {
                        assert(value.type == JSONType.array);
                        // Stride is 2
                        // 48 texture points (vertex positions)
                        // 48 / 2 is 24 because the stride is 2
                        foreach (i; 0..24) {
                            const int currentStride = i * 2;
                            block.textureCoordinates ~= Vector2d(
                                getDouble(value[currentStride]),
                                getDouble(value[currentStride + 1])
                            );
                        }
                        break;
                    }
                    default:
                }
            }

            blocks ~= block;
        }
    }

    void extractAnimation(ref Block block, JSONValue animationData) {
        foreach (string key, JSONValue value; animationData.objectNoRef) {

            // Stride is 3
            switch (key) {
                case "T": {
                    assert(value.type == JSONType.array);
                    foreach (i; 0..total_frames){
                        const int baseIndex = i * 3;
                        block.translation ~= Vector3d(
                            getDouble(value[baseIndex]),
                            getDouble(value[baseIndex + 1]),
                            getDouble(value[baseIndex + 2]),
                        );
                    }
                    break;
                }
                case "R": {
                    assert(value.type == JSONType.array);
                    foreach (i; 0..total_frames){
                        const int baseIndex = i * 3;
                        block.rotation ~= Vector3d(
                            getDouble(value[baseIndex])     * RADIANS,
                            getDouble(value[baseIndex + 1]) * RADIANS,
                            getDouble(value[baseIndex + 2]) * RADIANS,
                        );
                    }
                    break;
                }
                case "S": {
                    assert(value.type == JSONType.array);
                    foreach (i; 0..total_frames){
                        const int baseIndex = i * 3;
                        block.scale ~= Vector3d(
                            getDouble(value[baseIndex]),
                            getDouble(value[baseIndex + 1]),
                            getDouble(value[baseIndex + 2]),
                        );
                    }
                    break;
                }
                default:
            }
        }
    }

    double getDouble(JSONValue input) {
        if (input.type == JSONType.integer) {
            return cast(double)input.integer;
        } else {
            return input.floating;
        }
    }


    //!====================== END JSON METHODS ===============================
    
}
