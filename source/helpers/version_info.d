module helpers.version_info;

import std.stdio;
import std.range;
import std.string;


private char[] VERSION_TITLE;
private bool LOCK;

void initVersionTitle() {
    if (LOCK) {
        return;
    }
    File readme = File("README.md");
    string tempString = readme.readln;
    char[] tempCharArray;
    ulong length = tempString.length;
    length -= 1;
    foreach (char letter; tempString[2..length]) {
        tempCharArray ~= letter;
    }
    VERSION_TITLE = tempCharArray;
    readme.close();
}

char[] getVersionTitle() {
    return VERSION_TITLE;
}
