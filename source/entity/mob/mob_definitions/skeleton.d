module entity.mob.mob_definitions.skeleton;

import entity.mob.mob;
import std.stdio;

public class Skeleton : Mob {

    this() {
        super();

        // writeln("I am creating a zombie object");
        // writeln("My UUID is: ", this.getUUID());
    }

    override void onSpawn() {
        
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