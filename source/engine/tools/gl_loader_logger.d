module engine.tools.gl_loader_logger;


import std.stdio;
import std.conv: to;

import bindbc.opengl;
import bindbc.opengl.gl;

import Loader = bindbc.loader.sharedlib;

//! This one is for the library loader

class OpenGLLoaderErrorLogger {
    
    // This is the actual Exception that will MAYBE be thrown 
    // Starts off as the output in the end of the line in terminal
    private string accumulator = "OpenGL Error!\n";

    private string helperTip;
    private string[] openGlErrorMessageTypes;
    private string[] openGlErrorMessages;

    
    this() {

    }

    /// Allows inserting helpful tips into the error message
    OpenGLLoaderErrorLogger attachTip(string helperTip) {
        this.helperTip = helperTip;
        return this;
    }

    /// Attaches the OpenGL error type
    private void attachType(const(char)* openGlErrorType) {
        this.openGlErrorMessageTypes ~= to!string(openGlErrorType);
    }

    /// Attaches the OpenGL error message
    private void attachMessage(const(char)* openGlErrorMessage) {
        this.openGlErrorMessages ~= to!string(openGlErrorMessage);
    }

    // Literally just inserts line seperators into the string accumulator
    private void line() {
        this.accumulator ~= "========================================\n";
    }

    // Automatically throws exception containing error output
    void execute() {

        // Iterate the errors into a more usable form
        foreach(info; Loader.errors) {
            attachType(info.error);
            attachMessage(info.message);
        }

        line();

        // Now print out how many errors
        accumulator ~= "Error count: " ~ to!string(openGlErrorMessages.length) ~ "\n";

        line();

        // Now dump the actual errors in with nice separators
        foreach (i; 0..openGlErrorMessages.length) {
            accumulator ~= openGlErrorMessageTypes[i] ~ ": " ~ openGlErrorMessages[i];
            line();
        }


        // Ends with helper tip
        if (this.helperTip !is null) {
            accumulator ~= helperTip ~ "\n";
        }

        line();

        // Prints it out as a nice helpful message
        throw new Exception(accumulator);
    }
}