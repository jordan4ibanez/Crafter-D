module game.entity.mob.mob;

import std.stdio;

import game.entity.entity;

// The base class for all mobs
abstract class Mob : Entity {

    // All Mobs must have health
    private float health;

    // All mobs must implement these methods 
    abstract void onSpawn();
    abstract void onTick(double delta);
    abstract void onHurt();
    abstract void onDeath();
    abstract void onDeathPoof();

    this() {
        // writeln("I am constructing a mob object");
    }

    // Boilerplate
    float getHealth() {
        return this.health;
    }
    void setHealth(float newHealth) {
        this.health = newHealth;
    }
}