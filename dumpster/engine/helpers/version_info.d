module engine.helpers.version_info;

import std.stdio;
import std.range;
import std.conv: to;


private string VERSION_TITLE;
private bool titleLock;

void initVersionTitle() {
    if (titleLock) {
        return;
    }
    File readme = File("README.md");
    string tempString = readme.readln;
    ulong length = tempString.length;
    length -= 1;

    string tempTitleHolder;
    foreach (char letter; tempString[2..length]) {
        tempTitleHolder ~= letter;
    }
    VERSION_TITLE = tempTitleHolder;
    readme.close();
}

string getVersionTitle() {
    return VERSION_TITLE;
}
