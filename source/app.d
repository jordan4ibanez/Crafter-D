import std.stdio;

import raylib;
import entity.mob.mob;
import entity.mob.mob_definitions.zombie;
import entity.mob.mob_factory;
import entity.player.player;
import entity.player.player_factory;
import world.chunk;
import world.chunk_factory;
import world.chunk;
import world.world_generation;

void main() {
    WorldGenerator.generate();

    /*
    // Debug mobs
	MobFactory.spawnMob(new Zombie());
    MobFactory.debugFactory();

    // Debug players
    PlayerFactory.spawnPlayer(new Player("singleplayer"));
    PlayerFactory.debugFactory();


    ChunkFactory.newChunkGeneration(0,0);
    ChunkFactory.processStack();
    ChunkFactory.debugFactoryContainer();

    //Chunk chunky = new Chunk("default", Position2I(0,0));
    for ( int i = 0; i < 32_768; i++ ) {
        chunky.runADebug(i);
    }
    */



}
