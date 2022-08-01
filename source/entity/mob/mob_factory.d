module entity.mob.mob_factory;

import std.stdio;
import std.uuid;
import entity.mob.mob;
import entity.mob.mob_definitions.zombie;

public static final class MobFactory {
    private static Mob[UUID] container;

    public static void spawnMob(Mob newMob) {
        container[newMob.getUUID()] = newMob;
        writeln("MOB HAS BEEN ADDED TO FACTORY: ", newMob.getUUID());
    }

    public static void debugFactory() {
        writeln("this is the factory:\n", this.container);
    }
}