module shader.shader;

import std.stdio;
import std.file;
import std.string;
import std.conv;

import bindbc.opengl;

import OpenGlLogger = tools.opengl_error_logger;

/// These work as a synced list
private GLuint[string] vertexShaders;
private GLuint[string] fragmentShaders;
private GLuint[string] shaderPrograms;
// Indexed as uniform["shaderName"]["uniformName"]
private GLint[string] uniforms;

void create(string shaderName,
    string vertexShaderCodeLocation,
    string fragmentShaderCodeLocation,
    string[] uniformList = []) {
    

    // The game cannot run without shaders, bail out
    if (!exists(vertexShaderCodeLocation)) {
        throw new Exception("Vertex shader code does not exist!");
    }
    if (!exists(fragmentShaderCodeLocation)) {
        throw new Exception("Fragment shader code does not exist!");
    }

    string vertexShaderCode = cast(string)read(vertexShaderCodeLocation);
    string fragmentShaderCode = cast(string)read(fragmentShaderCodeLocation);

    GLuint vertexShader = compileShader(shaderName, vertexShaderCode, GL_VERTEX_SHADER);
    GLuint fragmentShader = compileShader(shaderName, fragmentShaderCode, GL_FRAGMENT_SHADER);

    GLuint shaderProgram = glCreateProgram();

    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);

    glLinkProgram(shaderProgram);

    int success;
    // Default value is SPACE instead of garbage
    char[512] infoLog = (' ');
    glGetProgramiv(shaderProgram, GL_LINK_STATUS, &success);

    if (!success) {
        glGetProgramInfoLog(shaderProgram, 512, null, infoLog.ptr);
        writeln(infoLog);

        throw new Exception("Error creating shader program!");
    }

    writeln("GL Shader Program with ID ", shaderProgram, " successfully linked!");

    // Now dump them into the container
    vertexShaders[shaderName] = vertexShader;
    fragmentShaders[shaderName] = fragmentShader;
    shaderPrograms[shaderName] = shaderProgram;

    foreach (string uniformName; uniformList) {
        createUniform(shaderName, uniformName);
    }
}

void createUniform(string shaderName, string uniformName) {

    GLint location = glGetUniformLocation(shaderPrograms[shaderName], uniformName.toStringz);

    writeln("Shader ",shaderName, ": uniform ", uniformName, " is at id ", location);
    // Do not allow out of bounds
    if (location < 0) {
        throw new Exception("OpenGL uniform is out of bounds!");
    }

    OpenGlLogger.execute("This error comes from the createUniform() method of Shader.\n" ~ "ERROR CREATING UNIFORM!");

    uniforms[genUniformName(shaderName, uniformName)] = location;
}

// Set the uniform's int value in GPU memory (integer)
void setUniformInt(string shaderName, string uniformName, GLuint value) {
    glUniform1i(getUniform(shaderName, uniformName), value);

    OpenGlLogger.execute("This error comes from the setUniformInt() method of Shader.\n" ~ "Error setting shader uniform: " ~ uniformName);
}


void setUniformDouble(string shaderName, string uniformName, GLdouble value) {
    glUniform1d(getUniform(shaderName, uniformName), value);
    
    OpenGlLogger.execute("This error comes from the setUniformDouble() method of Shader.\n" ~ "Error setting shader uniform: " ~ uniformName);
}

void setUniformMatrix4(string shaderName, string uniformName, double[] matrix, GLint count = 1) {   

    glUniformMatrix4fv(
        getUniform(shaderName, uniformName), // Location
        count, // Count
        GL_FALSE,// Transpose
        to!(float[])(matrix).ptr// Pointer
    );

    OpenGlLogger.execute("This error comes from the setUniformMatrix4() method of Shader.\n" ~ "Error setting shader uniform: " ~ uniformName);
}

uint getUniform(string shaderName, string uniformName) {
    return uniforms[genUniformName(shaderName, uniformName)];
}

/// A helper shortcut to initialize this shader
void startProgram(string shaderName) {
    glUseProgram(shaderPrograms[shaderName]);
}

// Automates shader compilation
private uint compileShader(string shaderName, string sourceCode, GLuint shaderType) { 

    GLuint shader;
    shader = glCreateShader(shaderType);

    char* shaderCodePointer = sourceCode.dup.ptr;
    const(char*)* shaderCodeConstantPointer = &shaderCodePointer;
    glShaderSource(shader, 1, shaderCodeConstantPointer, null);
    glCompileShader(shader);

    int success;
    // Default value is SPACE instead of garbage
    char[512] infoLog = (' ');
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);

    // Log info in terminal, freeze the program to prevent erroneous behavior
    if (!success) {
        string infoName = "?Other Shader?";
        if (shaderType == GL_VERTEX_SHADER) {
            infoName = "GL Vertex Shader";
        } else if (shaderType == GL_FRAGMENT_SHADER) {
            infoName = "GL Fragment Shader";
        }

        writeln("ERROR IN SHADER ", shaderName, " ", infoName);

        glGetShaderInfoLog(shader, 512, null, infoLog.ptr);
        writeln(infoLog);

        throw new Exception("Shader compile error");
    }

    // Match the correct debug info name
    string infoName = "?Other Shader?";
    if (shaderType == GL_VERTEX_SHADER) {
        infoName = "GL Vertex Shader";
    } else if (shaderType == GL_FRAGMENT_SHADER) {
        infoName = "GL Fragment Shader";
    }

    writeln("Successfully compiled ", infoName, " with ID: ", shader);

    return shader;
}

void deleteShader(string shaderName) {

    // Stop it if it's running
    glUseProgram(0);

    // Detach shaders from program
    glDetachShader(shaderPrograms[shaderName], vertexShaders[shaderName]);
    glDetachShader(shaderPrograms[shaderName], fragmentShaders[shaderName]);

    // Delete shaders
    glDeleteShader(vertexShaders[shaderName]);
    glDeleteShader(fragmentShaders[shaderName]);

    // Delete the program
    glDeleteProgram(shaderPrograms[shaderName]);

    // Delete the program memory
    vertexShaders.remove(shaderName);
    fragmentShaders.remove(shaderName);
    shaderPrograms.remove(shaderName);

    writeln("Deleted shader: ", shaderName);
}

string genUniformName(string shaderName, string uniformName) {
    return shaderName ~ "_" ~ uniformName;
}