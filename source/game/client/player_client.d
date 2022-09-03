module game.client.player_client;

import vector_3d;
import vector_2d;
import vector_2i;
import Math = math;

/*
This is the best name I could come up with, the next choice was:
the_current_player_of_the_client_that_is_playing_the_game_right_now.d

This is the player that is playing the game.
*/

Vector3d position = *new Vector3d(0,0,0);
Vector3d rotation = *new Vector3d(0,0,0);
Vector2d size = *new Vector2d(0.35, 1.8);
double height = 1.5;