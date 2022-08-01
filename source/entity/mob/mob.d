module entity.mob.mob;

import entity.entity;

// The base class for all mobs
abstract class Mob : Entity {
    float health;
    abstract void onSpawn();
    abstract void onTick(double delta);
    abstract void onHurt();
    abstract void onDeath();
    abstract void onDeathPoof();
}