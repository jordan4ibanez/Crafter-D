module engine.opengl.gl_interface;

import std.stdio;
import bindbc.glfw;
import bindbc.opengl;
import helper.log;
import std.conv: to;
import vector_2i;

import loader = bindbc.loader.sharedlib;
import Window = engine.window.window;

bool initializeOpenGL() {
    /*
     Compare the return value of loadGL with the global `glSupport` constant to determine if the version of GLFW
     configured at compile time is the version that was loaded.
    */
    GLSupport ret = loadOpenGL();

    writeln("The current supported context is: ", translateGLVersionName(ret));

    // Minimum version is GL 4.1 (July 26, 2010)
    if(ret < GLSupport.gl41) {
        writeln("ERROR IN gl_interface.d");
        // Log the error info
        foreach(info; loader.errors) {
            /*
             A hypothetical logging function. Note that `info.error` and `info.message` are `const(char)*`, not
             `string`.
            */
            logCError(info.error, info.message);
        }

        // Optionally construct a user-friendly error message for the user
        string msg;
        if(ret == GLSupport.noLibrary) {
            msg = "This application requires the GLFW library.";
        }
        else if(ret == GLSupport.badLibrary) {
            msg = "The version of the GLFW library on your system is too low. Please upgrade.";
        }
        // GLSupport.noContext
        else {
            msg = "Your GPU cannot support the minimum OpenGL Version: 4.1! Released: July 26, 2010.\n" ~
                  "Are your graphics drivers updated?";
        }
        // A hypothetical message box function
        writeln(msg);
        writeln("ABORTING");
        return true;
    }

    if (!isOpenGLLoaded()) {
        writeln("GL FAILED TO LOAD!!");
        return true;
    }

    Vector2i windowSize = Window.getSize();

    glViewport(0, 0, windowSize.x, windowSize.y);

    // Enable backface culling
    glEnable(GL_CULL_FACE);

    // Alpha color blending
    glEnable(GL_BLEND);

    // Enable depth testing
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);


    GLenum glErrorInfo = glGetError();


    if (glErrorInfo != 0) {
        writeln("GL ERROR: ", glErrorInfo);
        writeln("ERROR IN GL INIT");
        writeln("FREEZING PROGRAM TO ALLOW DIAGNOSTICS!");

        while(true) {
            
        }
    }
    return false;
}

string getInitialOpenGLVersion() {
    string raw = to!string(loadedOpenGLVersion());
    char[] charArray = raw.dup[2..raw.length];
    return "OpenGL " ~ charArray[0] ~ "." ~ charArray[1];
}

string translateGLVersionName(GLSupport name) {
    string raw = to!string(name);
    char[] charArray = raw.dup[2..raw.length];
    return "OpenGL " ~ charArray[0] ~ "." ~ charArray[1];
}