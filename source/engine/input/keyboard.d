module input.keyboard;

import std.stdio;
import bindbc.glfw;
import std.conv: to;

import Mouse = input.mouse;
import Window = window.window;

// Automate keyboard input across the entire board
// Do this when not half awake
//bool[int] keyboardInput;

private bool left    = false;
private bool right   = false;
private bool forward = false;
private bool back    = false;
private bool up      = false;
private bool down    = false;

private bool quickSwitch(int input) {
    return input > 0;
}

void keyCallback(int key, int scancode, int action, int mods){
    //keyboardInput[key] = action > 0;
    switch(key) {
        case GLFW_KEY_D:{
            left = quickSwitch(action);
            break;
        }
        case GLFW_KEY_A:{
            right = quickSwitch(action);
            break;
        }
        case GLFW_KEY_W:{
            forward = quickSwitch(action);
            break;
        }
        case GLFW_KEY_S: {
            back = quickSwitch(action);
            break;
        }
        case GLFW_KEY_LEFT_SHIFT: {
            down = quickSwitch(action);
            break;
        }
        case GLFW_KEY_SPACE: {
            up = quickSwitch(action);
            break;
        }

        case GLFW_KEY_ESCAPE: {
            Window.close();
            break;
        }
        case GLFW_KEY_LEFT_CONTROL: {
            if (action == GLFW_PRESS) {
                Mouse.debugLockMouse();
            }
            break;
        }

        // Special handler for fullscreening
        case GLFW_KEY_F11: {
            if (action == GLFW_PRESS) {
                Window.toggleFullScreen();                
            }
            break;
        }

        default:{
            writeln("YOU HIT THE WRONG BUTTON");
        }
    }
}

bool getLeft() {
    return left;
}
bool getRight() {
    return right;
}
bool getForward() {
    return forward;
}
bool getBack() {
    return back;
}
bool getUp() {
    return up;
}
bool getDown() {
    return down;
}