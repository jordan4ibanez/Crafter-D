module game.client.player_client;

import std.stdio;
import vector_3d;
import vector_2d;
import vector_2i;
import delta_time;

import Math = math;
import Camera = engine.camera.camera;
import Keyboard = engine.input.keyboard;
import Mouse = engine.input.mouse;

/*
This is the best name I could come up with, the next choice was:
the_current_player_of_the_client_that_is_playing_the_game_right_now.d

This is the player that is playing the game.
*/

private Vector3d position = *new Vector3d(0,60,0);
private Vector3d velocity = *new Vector3d(0,0,0);
// This rotation is for the player's body
private Vector3d rotation = *new Vector3d(0,0,0);
private Vector2d size = *new Vector2d(0.35, 1.8);
private double eyeHeight = 1.5;
private bool inGame = true;

private static immutable double[string] speed;
shared static this() {
    speed = [
        "run"      : 9.0,
        "walk"     : 6.5,
        "sneak"    : 2.0,
        // Less inertia, faster things accelerate
        "inertia"  : 0.1,
        // More friction, faster things slow down
        "friction" : 1.0
    ];
}

private void playerClientIntakeKeyInputs() {

    double delta = getDelta();

    Vector3d modifier = Vector3d(0,0,0);

    immutable double inertia = speed["inertia"];
    immutable double walkSpeed = speed["walk"];

    if(Keyboard.getForward()){
        modifier.z -= (delta * walkSpeed) / inertia;
    } else if (Keyboard.getBack()) {
        modifier.z += (delta * walkSpeed) / inertia;
    }

    if(Keyboard.getLeft()){
        modifier.x += (delta * walkSpeed) / inertia;
    } else if (Keyboard.getRight()) {
        modifier.x -= (delta * walkSpeed) / inertia;
    }

    // Reserve this for jump and sneak
    if (Keyboard.getUp()){
        modifier.y += (delta * walkSpeed) / inertia;
    } else if (Keyboard.getDown()) {
        modifier.y -= (delta * walkSpeed) / inertia;
    }

    addVelocity(modifier);
}

// Intakes a speed that already has delta adjustment
private void addVelocity(Vector3d moreVelocity) {

    Vector3d rotatedVelocity = Vector3d();

    if ( moreVelocity.z != 0 ) {
        rotatedVelocity.x = -Math.sin(Math.toRadians(rotation.y)) * moreVelocity.z;
        rotatedVelocity.z = Math.cos(Math.toRadians(rotation.y)) * moreVelocity.z;
    }
    if ( moreVelocity.x != 0) {
        rotatedVelocity.x = -Math.sin(Math.toRadians(rotation.y - 90)) * moreVelocity.x;
        rotatedVelocity.z = Math.cos(Math.toRadians(rotation.y - 90)) * moreVelocity.x;
    }

    velocity.x += rotatedVelocity.x;
    velocity.y += rotatedVelocity.y;
    velocity.z += rotatedVelocity.z;

    // Limit to the current speed state, will be modifiable in the future
    if (velocity.length() > speed["walk"]) {
        velocity.normalize().mul(speed["walk"]);
    }
}

private void applyVelocity() {
    double delta = getDelta();
    position.x += velocity.x * delta;
    position.y += velocity.y * delta;
    position.z += velocity.z * delta;
}

private void applyCameraRotation() {
    rotation.y = Camera.getRotation().y;
}

// Uhh move this to collision detection?? Wtf
private void applyFriction() {
    Vector3d frictionSpeed = Vector3d(velocity).mul(speed["friction"] * getDelta()).div(speed["inertia"]);
    velocity.sub(frictionSpeed);
    // Avoid infinite float calculations
    if (velocity.length() <= 0.000000001) {
        velocity.zero();
    }
}

void onTick() {
    applyCameraRotation();
    playerClientIntakeKeyInputs();
    applyVelocity();
    applyFriction();

    writeln(velocity);

    Camera.setPosition(Vector3d(
        position.x,
        position.y + eyeHeight,
        position.z
    ));
}