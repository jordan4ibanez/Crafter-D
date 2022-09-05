module game.client.player_client;

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
private Vector3d rotation = *new Vector3d(0,0,0);
private Vector2d size = *new Vector2d(0.35, 1.8);
private double height = 1.5;
private bool inGame = true;

private static immutable double[string] speed;
shared static this() {
    speed = [
        "run"   : 5.0,
        "walk"  : 2.5,
        "sneak" : 1.0
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

    //movePosition(modifier);
}

private void addVelocity(Vector3d moreVelocity) {
    velocity.x += moreVelocity.x;
    velocity.y += moreVelocity.y;
    velocity.z += moreVelocity.z;

    if (velocity.length() > speed["walk"]) {
        velocity.normalize().mul(speed["walk"]);
    }
}

void onTick() {
    playerClientIntakeKeyInputs();
}