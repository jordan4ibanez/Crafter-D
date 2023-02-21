module game.entity.mob.mob_definitions.zombie;

import std.stdio;
import game.entity.mob.mob;

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

