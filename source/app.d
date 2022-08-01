import std.stdio;

void main()
{
	Mob[] debugBoi;

    debugBoi ~= new Zombie();
}


abstract class Mob {
    float health;
    abstract void onSpawn();
    abstract void onTick(double delta);
    abstract void onHurt();
    abstract void onDeath();
    abstract void onDeathPoof();
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