module entity.player.player;

import std.stdio;
import entity.mob.mob;

// A player. This is not a static object because: Multiplayer
// Inherits from mob to allow full compatibility between them
public class Player : Mob {

    // Players have a UUID (uninitialized), but their name is how they're identified
    private string name;

    this() {
        // Player's do not call down the super chain
        this.setHealth(20);
    }
    
    override void onSpawn() {
        writeln("I'm alive! I'm born!");
    }

    override void onTick(double delta) {
        
    }

    override void onHurt() {
        
    }

    override void onDeath() {
        writeln("Mama mia!");
    }

    override void onDeathPoof() {
        
    }
}