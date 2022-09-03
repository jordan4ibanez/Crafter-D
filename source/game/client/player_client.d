module game.client.player_client;

import vector_3d;
import vector_2d;
import vector_2i;

import Math = math;
import Camera = engine.camera.camera;
import Keyboard = engine.input.keyboard;
import Mouse = engine.input.mouse;

/*
This is the best name I could come up with, the next choice was:
the_current_player_of_the_client_that_is_playing_the_game_right_now.d

This is the player that is playing the game.
*/

private Vector3d position = *new Vector3d(0,0,0);
private Vector3d rotation = *new Vector3d(0,0,0);
private Vector2d size = *new Vector2d(0.35, 1.8);
private double height = 1.5;
private bool inGame = true;