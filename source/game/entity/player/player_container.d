module game.entity.player.player_container;

import std.stdio;

import game.entity.player.player;

/*
A static factory/container class, allowing functional programming inside of OOP.
This is reserved for other players in multiplayer!
For single player and client access (your player in game) go to /game/client/client_player.d!
*/

private Player[string] container;

void spawnPlayer(Player player) {
    this.container[player.getName()] = player;
    writeln(player.classinfo.name , " HAS BEEN ADDED TO FACTORY: ", player.getUUID());
}

void debugFactory() {
    writeln(this.container);
}
