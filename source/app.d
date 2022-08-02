import std.stdio;

import raylib;
import entity.mob.mob;
import entity.mob.mob_definitions.zombie;
import entity.mob.mob_factory;
import entity.player.player;
import entity.player.player_factory;

void main() {
    // Debug mobs
	MobFactory.spawnMob(new Zombie());
    MobFactory.debugFactory();

    // Debug players
    PlayerFactory.spawnPlayer(new Player("singleplayer"));
    PlayerFactory.debugFactory();

}
