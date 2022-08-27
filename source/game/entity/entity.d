module entity.entity;

import raylib;
import std.uuid;
import std.stdio;

// The base abstract class which all entity sub-types will inherit
abstract class Entity {

    // Entities must have spatial fields
    private Vector3 position = Vector3(0,0,0);
    private Vector3 inertia  = Vector3(0,0,0);
    private Vector3 rotation = Vector3(0,0,0);

    // Entities have a width/depth (x) and a height (y)
    private Vector2 dimensions = Vector2(0,0);

    /*
    Entities must have a physical state, collision detection with environment

    Up the inheritance chain:
        1. This affects players and mobs with magnetic collision detection.
           If an "alive" entity is physical, it will collide.
        2. This affects items to be able to phase through blocks when collecting.
    */
    private bool physical = true;

    // Entities must be unique
    private UUID uuid;

    this() {
        this.setUUID();
    }


    // Boilerplate
    Vector3 getPosition() {
        return this.position;
    }
    void setPosition(Vector3 newPosition) {
        this.position = newPosition;
    }
    Vector3 getIneritia() {
        return this.inertia;
    }
    void setInertia(Vector3 newInertia) {
        this.inertia = newInertia;
    }
    Vector3 getRotation() {
        return this.rotation;
    }
    void setRotation(Vector3 newRotation) {
        this.rotation = newRotation;
    }
    UUID getUUID() {
        return this.uuid;
    }
    void setUUID() {
        // This is special, it is a one way lock for the UUID
        if (this.uuid.empty()) {
            this.uuid = randomUUID();
        }
    }
    Vector2 getDimensions() {
        return this.dimensions;
    }
    void setDimensions(Vector2 newDimensions) {
        this.dimensions = newDimensions;
    }
    double getWidth() {
        return this.dimensions.x;
    }
    void setWidth(double newWidth) {
        this.dimensions.x = newWidth;
    }
    double getHeight() {
        return this.dimensions.y;
    }
    void setHeight(double newHeight) {
        this.dimensions.y = newHeight;
    }
    bool getPhysical() {
        return this.physical;
    }
    void setPhysical(bool newPhysical) {
        this.physical = newPhysical;
    }
}