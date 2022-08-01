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

    this() {
        writeln("I am creating an entity object");
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
}