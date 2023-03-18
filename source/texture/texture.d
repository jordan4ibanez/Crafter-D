module texture.texture;

import std.stdio;
import bindbc.opengl;
import color;
import png;

import OpenGlLogger = tools.opengl_error_logger;

/**
    Texture works as a singleton container.
    If you add all textures in at the beginning
    of the program, this becomes a cache.
*/

private immutable GLuint invalid = GLuint.max;

// Stores all textures as simple GLuint pointers. Accessed by file location.
private GLuint[string] storage;

/// Add a texture into the container.
GLuint addTexture(string fileLocation, bool debugEnabled = false) {

    if (fileLocation in storage) {
        throw new Exception("Attempted to create a texture twice! Must be deleted first!");
    }

    // Use ADR's awesome framework library to convert the png into a raw data stream.
    TrueColorImage tempImageObject = readPng(fileLocation).getAsTrueColorImage();

    const int width = tempImageObject.width();
    const int height = tempImageObject.height();

    ubyte[] tempData = tempImageObject.imageData.bytes;

    // Now use the OpenGL framework to upload it.
    GLuint id;

    glGenTextures(1, &id);
    glBindTexture(GL_TEXTURE_2D, id);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, tempData.ptr);

    // Enable texture clamping to edge
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);

    // Border color is nothing - This is a GL REQUIRED float
    float[4] borderColor = [0,0,0,0];
    glTexParameterfv(GL_TEXTURE_2D, GL_TEXTURE_BORDER_COLOR, borderColor.ptr);

    // Add in nearest neighbor texture filtering
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST/*_MIPMAP_NEAREST*/);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    // glGenerateMipmap(GL_TEXTURE_2D);

    OpenGlLogger.execute("This error is from the Texture constructor.\n" ~ "Failed to load texture!");

    if (debugEnabled) {
        writeln(fileLocation, " is stored as ID: ", id);
    }

    // Finally cache the GL pointer ID as a GLuint
    storage[fileLocation] = id;
    
    // Then return ID to make this even more flexible
    return id;
}

GLuint getTexture(string fileLocation) {
    if (fileLocation !in storage) {
        return invalid;
    }
    return storage[fileLocation];
}

void cleanUp() {
    foreach (string key, GLuint value; storage) {
        glDeleteTextures(1, &value);

        writeln("TEXTURE ", value, " (" ~ key ~ ") HAS BEEN DELETED");
    }
}