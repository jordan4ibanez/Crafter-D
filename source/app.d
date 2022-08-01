import std.stdio;

import raylib;
import entity.mob.mob;
import entity.mob.zombie;

void main()
{
	Mob[] debugBoi;

    debugBoi ~= new Zombie();

    debugBoi[0].onSpawn();
}
