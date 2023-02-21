module engine.helpers.log;

import std.stdio;
import std.conv: to;

void logCError(const(char)* error, const(char)* message) {
    writeln("(ERROR): ", to!string(error), "\n(MESSAGE): ", to!string(message));
}