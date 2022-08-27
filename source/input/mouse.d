module input.mouse;

import std.stdio;
import vector_2d;
import vector_3d;

private immutable bool debugNow = false;

import Window = window.window;
import Camera = camera.camera;

private Vector2d oldPosition = Vector2d(0,0);
private Vector2d position    = Vector2d(0,0);
private Vector2d vector      = Vector2d(0,0);

private double sensitivity   = 0.1;

private bool locked = false;

void mouseCallback(Vector2d newPosition) {
    if (debugNow) {
        writeln("mouse was at: ", position);
        writeln("mouse is at: ", newPosition);
        writeln("the mouse vector is: ", vector);
    }

    if (locked) {
        vector = Vector2d(
            newPosition.x - oldPosition.x,
            newPosition.y - oldPosition.y
        );
        Camera.moveRotation(Vector3d(
            // These are inverted because y is the yaw and x is the pitch
            vector.y * sensitivity,
            vector.x * sensitivity,
            0
        ));

        newPosition = Window.centerMouse();
    }

    position = newPosition;
    oldPosition = newPosition;
}

void lockMouse(bool newLockMode) {
    if (newLockMode) {
        if (!locked) {
            Window.lockMouse();
            locked = true;
        } // Don't send out another callback to C
    } else {
        if (locked) {
            Window.unlockMouse();
            locked = false;
        } // Don't send out another callback to C
    }
}

// this is debug, remove this
void debugLockMouse() {
    bool newLockMode = !locked;
    if (newLockMode) {
        if (!locked) {
            Window.lockMouse();
            locked = true;
        } // Don't send out another callback to C
    } else {
        if (locked) {
            Window.unlockMouse();
            locked = false;
        } // Don't send out another callback to C
    }
}

// This allows me to stop the jolt when the mouse moves after being locked
void setOldPosition(Vector2d newOldPosition) {
    oldPosition = newOldPosition;
}
void setNewPosition(Vector2d newPosition) {
    position = newPosition;
}