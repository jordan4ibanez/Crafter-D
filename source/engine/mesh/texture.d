module engine.mesh.texture;

import std.stdio;
import bindbc.opengl;
import image;

private immutable bool debugNow = false;

// Unlike meshes, textures never go out of scope until the program ends
// Automatically deletes when the program ends
private Texture[string] container;

void cleanUpAllTextures() {
    foreach (Texture thisTexture; container) {
        thisTexture.cleanUp();
    }
}

uint getTexture(string name) {
    return container[name].id;
}

void newTexture(string name) {    
    container[name] = Texture(name);
}

struct Texture {
    bool exists = false;
    GLuint id = 0;    
    GLuint width = 0;
    GLuint height = 0;

    this(string textureName) {
        this.exists = true;
        
        TrueColorImage tempImageObject = loadImageFromFile(textureName).getAsTrueColorImage();
        this.width = tempImageObject.width();
        this.height = tempImageObject.height();
        ubyte[] tempData = tempImageObject.imageData.bytes;

        glGenTextures(1, &this.id);
        glBindTexture(GL_TEXTURE_2D, this.id);
        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, this.width, this.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, tempData.ptr);

            // Enable texture clamping to edge
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
        // Border color is nothing
        float[4] borderColor = [0,0,0,0];
        glTexParameterfv(GL_TEXTURE_2D, GL_TEXTURE_BORDER_COLOR, borderColor.ptr);

        // Add in nearest neighbor texture filtering
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST/*_MIPMAP_NEAREST*/);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

        // glGenerateMipmap(GL_TEXTURE_2D);

        GLenum glErrorInfo = glGetError();

        if (glErrorInfo != 0) {
            writeln("GL ERROR: ", glErrorInfo);
            writeln("ERROR IN TEXTURE");
            writeln("FREEZING PROGRAM TO ALLOW DIAGNOSTICS!");

            while(true) {
                    
            }
        }
    }

    void cleanUp() {
        glDeleteTextures(1, &this.id);
        if (debugNow) {
            writeln("TEXTURE ", this.id, " HAS BEEN DELETED");
        }
    }
}