module game.entity.player.player_factory;

import std.stdio;

import game.entity.player.player;

// A static factory/container class, allowing functional programming inside of OOP
private Player[string] container;

void spawnPlayer(Player player) {
    this.container[player.getName()] = player;
    writeln(player.classinfo.name , " HAS BEEN ADDED TO FACTORY: ", player.getUUID());
}

void debugFactory() {
    writeln(this.container);
}
