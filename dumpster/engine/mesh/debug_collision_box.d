module engine.mesh.debug_collision_box;

import std.stdio;
import bindbc.opengl;
import vector_3d;
import vector_2d;


import engine.opengl.shaders;
import engine.opengl.gl_interface;
import engine.opengl.frustum_culling;

import Camera = engine.camera.camera;

private immutable bool debugNow = false;
private CollisionBoxMesh theMesh;
private bool existenceLock = false;
void constructCollisionBoxMesh() {
    // 1 way lock
    if (!existenceLock) {
        theMesh = CollisionBoxMesh(Vector2d(1,1));
        existenceLock = true;
    }
}
void destroyCollisionBoxMesh() {
    theMesh.destroy();
}
void drawCollisionBoxMesh(Vector3d position, Vector2d size) {
    theMesh.render(position,size);
}

// Reuse this for block selection box?
private struct CollisionBoxMesh {

    private bool exists = false;

    GLuint vao = 0; // Vertex array object - Main object
    GLuint pbo = 0; // Positions vertex buffer object
    GLuint ibo = 0; // Indices vertex buffer object
    GLuint indexCount = 0;

    private float[] constructCollisionBox(Vector2d size) {
        Vector3d min = Vector3d(-size.x, 0,      -size.x);
        Vector3d max = Vector3d( size.x, size.y,  size.x);
        return [
            // Bottom square
            min.x, min.y, min.z, // 0
            min.x, min.y, max.z, // 1
            max.x, min.y, max.z, // 2
            max.x, min.y, min.z, // 3
            // Top square
            min.x, max.y, min.z, // 4
            min.x, max.y, max.z, // 5
            max.x, max.y, max.z, // 6
            max.x, max.y, min.z, // 7
        ];
        // Tada! You have a box! Wow!
    }

    this(Vector2d size) {

        float[] vertices = constructCollisionBox(size);
        GLuint[] indices = [
            // Bottom Square
            0,1, 1,2, 2,3, 3,0,
            // Top square
            4,5, 5,6, 6,7, 7,4,
            // Sides
            0,4, 1,5, 2,6, 3,7
        ];

        // Existence lock
        this.exists = true;

        this.indexCount = cast(GLuint)(vertices.length);

        // bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
        glGenVertexArrays(1, &this.vao);
        glBindVertexArray(this.vao);
    

        // Positions VBO

        glGenBuffers(1, &this.pbo);
        glBindBuffer(GL_ARRAY_BUFFER, this.pbo);

        glBufferData(
            GL_ARRAY_BUFFER,                // Target object
            vertices.length * float.sizeof, // How big the object is
            vertices.ptr,                   // The pointer to the data for the object
            GL_STATIC_DRAW                  // Which draw mode OpenGL will use
        );

        glVertexAttribPointer(
            0,           // Attribute 0 (matches the attribute in the glsl shader)
            3,           // Size (literal like 3 points)  
            GL_FLOAT,    // Type
            GL_FALSE,    // Normalized?
            0,           // Stride
            cast(void*)0 // Array buffer offset
        );
        glEnableVertexAttribArray(0);

        // Indices VBO

        glGenBuffers(1, &this.ibo);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, this.ibo);

        glBufferData(
            GL_ELEMENT_ARRAY_BUFFER,     // Target object
            indices.length * int.sizeof, // size (bytes)
            indices.ptr,                 // the pointer to the data for the object
            GL_STATIC_DRAW               // The draw mode OpenGL will use
        );


        glBindBuffer(GL_ARRAY_BUFFER, 0);   
        
        // Unbind vao just in case
        glBindVertexArray(0);

        GLenum glErrorInfo = getAndClearGLErrors();
        if (glErrorInfo != GL_NO_ERROR) {
            writeln("GL ERROR: ", glErrorInfo);
            writeln("ERROR IN A MESH CONSTRUCTOR");
        }

        if (debugNow) {
            writeln("Mesh ", this.vao, " has been successfully created");
        }
    }

    void destroy() {

        // Don't bother the gpu with garbage data
        if (!this.exists) {
            if (debugNow) {
                writeln("sorry, I cannot clear gpu memory, I don't exist in gpu memory");
            }
            return;
        }

        // This is done like this because it works around driver issues
        
        // When you bind to the array, the buffers are automatically unbound
        glBindVertexArray(this.vao);

        // Disable all attributes of this "object"
        glDisableVertexAttribArray(0);

        // Delete the positions vbo
        glDeleteBuffers(1, &this.pbo);
        assert (glIsBuffer(this.pbo) == GL_FALSE);

        // Delete the indices vbo
        glDeleteBuffers(1, &this.ibo);
        assert (glIsBuffer(this.ibo) == GL_FALSE);

        // Unbind the "object"
        glBindVertexArray(0);
        // Now we can delete it without any issues
        glDeleteVertexArrays(1, &this.vao);
        assert(glIsVertexArray(this.vao) == GL_FALSE);

        GLenum glErrorInfo = getAndClearGLErrors();
        if (glErrorInfo != GL_NO_ERROR) {
            writeln("GL ERROR: ", glErrorInfo);
            writeln("ERROR IN A MESH DESTRUCTOR");
        }

        if (debugNow) {
            writeln("Mesh ", this.vao, " has been successfully deleted from gpu memory");
        }
    }

    void render(Vector3d offset, Vector2d scale) {

        // Don't bother the gpu with garbage data
        if (!this.exists) {
            if (debugNow) {
                writeln("sorry, I cannot render, I don't exist in gpu memory");
            }
            return;
        }

        getShader("main").setUniformF("light", 1.0);
        
        Camera.setObjectMatrix(offset, Vector3d(0,0,0), Vector3d(scale.x, scale.y, scale.x));

        glBindVertexArray(this.vao);
        // glDrawArrays(GL_TRIANGLES, 0, this.indexCount);
        glDrawElements(GL_LINES, this.indexCount, GL_UNSIGNED_INT, cast(const(void)*)0);
        
        GLenum glErrorInfo = getAndClearGLErrors();
        if (glErrorInfo != GL_NO_ERROR) {
            writeln("GL ERROR: ", glErrorInfo);
            writeln("ERROR IN A MESH RENDER");
        }
        if (debugNow) {
            writeln("Mesh ", this.vao, " has rendered successfully ");
        }
    }
}