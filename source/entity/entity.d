module entity.entity;

import raylib;

// A raw abstract class which all entity sub-types will inherit
abstract class Entity {
    // Entities must have spatial fields
    Vector3 position = Vector3(0,0,0);
    Vector3 inertia  = Vector3(0,0,0);
    Vector3 rotation = Vector3(0,0,0);
}