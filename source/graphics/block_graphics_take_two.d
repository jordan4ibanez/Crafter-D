module graphics.block_graphics_take_two;

import std.stdio;
import raylib;
import helpers.structs;
import std.math: abs;


// Defines how many textures are in the texture map
const double textureMapTiles = 32;
// Defines the width/height of each texture
const double textureTileSize = 16;
// Defines the total width/height of the texture map in pixels
const double textureMapSize = textureTileSize * textureMapTiles;