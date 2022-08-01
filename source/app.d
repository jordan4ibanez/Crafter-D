import std.stdio;

import raylib;

void main()
{
	Mob[] debugBoi;

    debugBoi ~= new Zombie();
}


class Zombie : Mob {

    this() {
        this.health = 10;
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