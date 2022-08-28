module engine.camera.camera;

import std.stdio;
import matrix_4d;
import vector_3d;
import bindbc.opengl;
import vector_3d;
import delta_time;

import engine.opengl.shaders;

import Keyboard = engine.input.keyboard;
import Window   = engine.window.window;
import Math     = math;

// There can only be one camera in the game, this is it

private double FOV = Math.toRadians(60.0);

// Never set this to 0 :P
// ALSO never set this too low!! You get float errors!
private immutable double Z_NEAR = 0.1;
// Never set this too high or less than Z_NEAR!!!
private immutable double Z_FAR = 600.0;

private Vector3d clearColor = Vector3d(0,0,0);

private Matrix4d cameraMatrix = Matrix4d();
private Matrix4d objectMatrix = Matrix4d();

// Set at x:0, y:0 z:1 so I can see the "center of the 4d world"
private Vector3d position = Vector3d(0,128,0);
private Vector3d rotation = Vector3d(0,0,0); 

private double aspectRatio = 0;

Matrix4d getCameraMatrix() {
    return cameraMatrix;
}

void testCameraHackRemoveThis() {

    double speed = 100;

    // This is an extreme hack for testing remove this garbage
    Vector3d modifier = Vector3d(0,0,0);

    if(Keyboard.getForward()){
        modifier.z -= getDelta() * speed;
    } else if (Keyboard.getBack()) {
        modifier.z += getDelta() * speed;
    }

    if(Keyboard.getLeft()){
        modifier.x += getDelta() * speed;
    } else if (Keyboard.getRight()) {
        modifier.x -= getDelta() * speed;
    }

    if (Keyboard.getUp()){
        modifier.y += getDelta() * speed;
    } else if (Keyboard.getDown()) {
        modifier.y -= getDelta() * speed;
    }

    movePosition(modifier);
}

/*
This is where the object get's it's render point

it does 3 things:

1. Calculates it's position in 4d space

2. Uploads the matrix to glsl

3. glsl will multiply this matrix by the camera's matrix, giving a usable position
*/
void setObjectMatrix(Vector3d offset, Vector3d rotation, float scale) {
    objectMatrix.identity()
        .translate(-position.x + offset.x, -position.y + offset.y, -position.z + offset.z)
        .rotateX(Math.toRadians(rotation.x))
        .rotateY(Math.toRadians(rotation.y))
        .rotateZ(Math.toRadians(rotation.z))
        .scale(scale);
    float[16] floatBuffer = objectMatrix.getFloatArray();
    glUniformMatrix4fv(getShader("main").getUniform("objectMatrix"),1, GL_FALSE, floatBuffer.ptr);
}

/*
This is where the camera gets it's viewpoint for the frame

it does 3 things:

1. Calculates and sets it's aspect ratio from the window

2. Calculates it's position in 4d space, and locks it in place

3. It updates GLSL so it can work with it
*/
void updateCameraMatrix() {
    aspectRatio = Window.getAspectRatio();
    GameShader mainShader = getShader("main");
    cameraMatrix.identity()
        .perspective(FOV, aspectRatio, Z_NEAR, Z_FAR)
        .rotateX(Math.toRadians(rotation.x))
        .rotateY(Math.toRadians(rotation.y));
    float[16] floatBuffer = cameraMatrix.getFloatArray();
    glUniformMatrix4fv(mainShader.getUniform("cameraMatrix"),1, GL_FALSE, floatBuffer.ptr);
}

void clear() {    
    glClear(GL_COLOR_BUFFER_BIT);
}

// It is extremely important to clear the buffer bit!
void clearDepthBuffer() {
    glClear(GL_DEPTH_BUFFER_BIT);
}

void setClearColor(double r, double g, double b) {
    clearColor = Vector3d(r,g,b);
    glClearColor(clearColor.x,clearColor.y,clearColor.z,1);
}

void setFOV(double newFOV) {
    FOV = newFOV;
}

double getFOV() {
    return FOV;
}

Vector3d getPosition() {
    return position;
}

void movePosition(Vector3d positionModification) {
    if ( positionModification.z != 0 ) {
        position.x += -Math.sin(Math.toRadians(rotation.y)) * positionModification.z;
        position.z += Math.cos(Math.toRadians(rotation.y)) * positionModification.z;
    }
    if ( positionModification.x != 0) {
        position.x += -Math.sin(Math.toRadians(rotation.y - 90)) * positionModification.x;
        position.z += Math.cos(Math.toRadians(rotation.y - 90)) * positionModification.x;
    }
    position.y += positionModification.y;
}

void setPosition(Vector3d newCameraPosition){
    position = newCameraPosition;
}


void rotationLimiter() {    
    
    // Pitch limiter
    if (rotation.x > 90) {
        rotation.x = 90;
    } else if (rotation.x < -90) {
        rotation.x = -90;
    }
    // Yaw overflower
    if (rotation.y > 180) {
        rotation.y -= 360.0;
    } else if (rotation.y < -180) {
        rotation.y += 360.0;
    }
}

void moveRotation(Vector3d rotationModification) {
    rotation.x += rotationModification.x;
    rotation.y += rotationModification.y;
    rotation.z += rotationModification.z;
    rotationLimiter();
}

void setRotation(Vector3d newRotation) {
    rotation = newRotation;
    rotationLimiter();
}

Vector3d getRotation() {
    return rotation;
}