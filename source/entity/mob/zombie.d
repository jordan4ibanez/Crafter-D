module entity.mob.zombie;

import entity.mob.mob;
import std.stdio;

public class Zombie : Mob {

    void scream() {
        writeln("I am at health: ", this.health);
    }


    override void onSpawn() {
        this.health = 10;

        this.scream();
    }

    override void onTick(double delta) {
        
    }

    override void onHurt() {
        
    }

    override void onDeath() {
        
    }

    override void onDeathPoof() {
        
    }
}

