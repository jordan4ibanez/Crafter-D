module game.physics.collision_detection;

import vector_2d;
import vector_3d;
import delta_time;

import Math = math;

// Basic AABB and magnetic cylinder, nothing fancy
// If you would like to see how the AABB works with a visualization:
// https://raw.githubusercontent.com/jordan4ibanez/Crafter/main/github/AABB_explanation.png

// I dunno where to even begin with this so here we go

void collideWithTerrain(ref Vector3d position, ref Vector3d velocity, Vector2d size, double inertia){

    double delta = getDelta();

    applyFriction(velocity);
        
    // velocity and position are a constant, delta is the frame interpolator

    // This goes as move axis -> check axis, next axis, etc, y,x,z

    // Y first for half slabs and steps, also the check if player is on ground

    // Friction will be checked by doing a dry run collide with the floor then a real collide for situations like ice

    position.y += velocity.y * delta;

    // check goes here

    position.x += velocity.x * delta;

    // check goes here

    position.z += velocity.z * delta;

    // check goes here
}

/*
private void applyVelocity() {
    double delta = getDelta();
    position.x += velocity.x * delta;
    position.y += velocity.y * delta;
    position.z += velocity.z * delta;
}
*/

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

private void applyFriction(ref Vector3d velocity) {
    Vector3d frictionSpeed = Vector3d(velocity).mul(speed["friction"] * getDelta()).div(speed["inertia"]);
    velocity.sub(frictionSpeed);
    // Avoid infinite float calculations
    if (velocity.length() <= 0.000000001) {
        velocity.zero();
    }
}
