module entity.mob.mob_definitions.zombie;

import entity.mob.mob;
import std.stdio;

public class Zombie : Mob {

    this() {
        // writeln("I am creating a zombie object");
        // writeln("My UUID is: ", this.getUUID());
    }

    override void onSpawn() {
        this.setHealth(10);
        writeln("I am at health: ", this.getHealth());
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

