module entity.player.player_factory;

import std.stdio;
import entity.player.player;

// A static factory/container class, allowing functional programming inside of OOP
public static class PlayerFactory {

    private static Player[string] container;

    public static void spawnPlayer(Player player) {
        this.container[player.getName()] = player;
        writeln(player.classinfo.name , " HAS BEEN ADDED TO FACTORY: ", player.getUUID());
    }
    
    public static void debugFactory() {
        writeln(this.container);
    }
    

}