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

private Vector3d position = *new Vector3d(0,0,0);
private Vector3d velocity = *new Vector3d(0,0,0);
// This rotation is for the player's body
private Vector3d rotation = *new Vector3d(0,0,0);
private Vector2d size = *new Vector2d(0.35, 1.8);
private double eyeHeight = 1.5;
private bool inGame = true;

private static immutable double[string] speed;
shared static this() {
    speed = [
        "run"      : 5.0,
        "walk"     : 2.5,
        "sneak"    : 1.0,
        "friction" : 10.0
    ];
}

private void playerClientIntakeKeyInputs() {

    double deltaMultiplier = 100;

    // This is an extreme hack for testing remove this garbage
    Vector3d modifier = Vector3d(0,0,0);

    if(Keyboard.getForward()){
        modifier.z -= getDelta() * deltaMultiplier;
    } else if (Keyboard.getBack()) {
        modifier.z += getDelta() * deltaMultiplier;
    }

    if(Keyboard.getLeft()){
        modifier.x += getDelta() * deltaMultiplier;
    } else if (Keyboard.getRight()) {
        modifier.x -= getDelta() * deltaMultiplier;
    }

    // Reserve this for jump and sneak
    /*
    if (Keyboard.getUp()){
        modifier.y += getDelta() * deltaMultiplier;
    } else if (Keyboard.getDown()) {
        modifier.y -= getDelta() * deltaMultiplier;
    }
    */

    addVelocity(modifier);
}

private void addVelocity(Vector3d moreVelocity) {

    if ( moreVelocity.z != 0 ) {
        moreVelocity.x = -Math.sin(Math.toRadians(rotation.y)) * moreVelocity.z;
        moreVelocity.z = Math.cos(Math.toRadians(rotation.y)) * moreVelocity.z;
    }
    if ( moreVelocity.x != 0) {
        moreVelocity.x = -Math.sin(Math.toRadians(rotation.y - 90)) * moreVelocity.x;
        moreVelocity.z = Math.cos(Math.toRadians(rotation.y - 90)) * moreVelocity.x;
    }

    velocity.x += moreVelocity.x;
    velocity.y += moreVelocity.y;
    velocity.z += moreVelocity.z;

    if (velocity.length() > speed["walk"]) {
        velocity.normalize().mul(speed["walk"]);
    }

    // writeln(velocity);
}

private void applyVelocity() {
    position.x += velocity.x;
    position.y += velocity.y;
    position.z += velocity.z;
}

private void applyCameraRotation() {
    rotation.y = Camera.getRotation().y;
}

private void applyFriction() {
    Vector3d frictionSpeed = Vector3d(velocity).mul(speed["friction"] * getDelta());
    velocity.sub(frictionSpeed);
    // Avoid infinite float calculations
    if (velocity.length() <= 0.000000001) {
        velocity.zero();
    }
}

void onTick() {
    applyCameraRotation();
    playerClientIntakeKeyInputs();
    applyFriction();

    // applyVelocity();

    Camera.setPosition(Vector3d(
        position.x,
        position.y + eyeHeight,
        position.z
    ));
}