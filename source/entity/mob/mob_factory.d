module entity.mob.mob_factory;

import std.stdio;
import std.uuid;
import entity.mob.mob;
import entity.mob.zombie;

public static class MobFactory {
    private static Mob[UUID] container;

    public static void spawnMob(Mob newMob) {
        container[newMob.getUUID()] = newMob;
        writeln("MOB HAS BEEN ADDED TO FACTORY: ", newMob.getUUID());
    }
}