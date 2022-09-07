module engine.helpers.nothrow_writeln;

import std.stdio: writeln;

void nothrowWriteln(Exception input) nothrow {
    try {
        writeln(input);
    } catch(Exception){}
}