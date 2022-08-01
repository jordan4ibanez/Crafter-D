import std.stdio;

import raylib;
import entity.mob.mob;
import entity.mob.zombie;
import entity.mob.mob_factory;

void main() {
	MobFactory.spawnMob(new Zombie());
}
