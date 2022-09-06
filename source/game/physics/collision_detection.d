module game.physics.collision_detection;

import vector_2d;
import vector_3d;

// Basic AABB and magnetic cylinder, nothing fancy

// I dunno where to even begin with this so here we go

void collideWithTerrain(ref Vector3d velocity, ){

}

private void applyVelocity() {
    double delta = getDelta();
    position.x += velocity.x * delta;
    position.y += velocity.y * delta;
    position.z += velocity.z * delta;
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