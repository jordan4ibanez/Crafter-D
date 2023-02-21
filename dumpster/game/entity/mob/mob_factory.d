module game.entity.mob.mob_factory;

import std.stdio;
import std.uuid;

import game.entity.mob.mob;


// A static factory/container class, allowing functional programming inside of OOP
public static final class MobFactory {
    
    private static Mob[UUID] container;

    public static void spawnMob(Mob newMob) {
        container[newMob.getUUID()] = newMob;
        writeln(newMob.classinfo.name , " HAS BEEN ADDED TO FACTORY: ", newMob.getUUID());
    }

    public static void debugFactory() {
        writeln("this is the factory:\n", this.container);
    }
}