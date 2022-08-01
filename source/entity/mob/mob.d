module entity.mob.mob;

import std.stdio;
import entity.entity;
import raylib;

// The base class for all mobs
abstract class Mob : Entity {

    private float health;

    abstract void onSpawn();
    abstract void onTick(double delta);
    abstract void onHurt();
    abstract void onDeath();
    abstract void onDeathPoof();

    this() {
        super();
        writeln("I am constructing a mob object");
    }

    // Boilerplate
    float getHealth() {
        return this.health;
    }
    void setHealth(float newHealth) {
        this.health = newHealth;
    }
}