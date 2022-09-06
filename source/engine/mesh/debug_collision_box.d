module engine.mesh.debug_collision_box;

import std.stdio;
import bindbc.opengl;
import vector_3d;


import engine.opengl.shaders;
import engine.opengl.gl_interface;
import engine.opengl.frustum_culling;

import Camera = engine.camera.camera;

private immutable bool debugNow = false;

struct CollisionBoxMesh {

    private bool exists = false;

    GLuint vao = 0; // Vertex array object - Main object
    GLuint pbo = 0; // Positions vertex buffer object

    GLuint indexCount = 0;

    this(float[] vertices) {

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

    void cleanUp() {

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

    void render(Vector3d offset) {

        // Don't bother the gpu with garbage data
        if (!this.exists) {
            if (debugNow) {
                writeln("sorry, I cannot render, I don't exist in gpu memory");
            }
            return;
        }

        getShader("main").setUniformF("light", 1.0);
        
        Camera.setObjectMatrix(offset, Vector3d(0,0,0), 1.0);

        glBindVertexArray(this.vao);
        // glDrawArrays(GL_TRIANGLES, 0, this.indexCount);
        // glDrawElements(GL_LINES, this.indexCount, GL_UNSIGNED_INT, cast(const(void)*)0);
        glDrawArrays(GL_LINES, 0, this.indexCount);
        
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