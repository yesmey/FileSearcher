module main;

import FileSearcher;
import std.array;
import std.stdio;
import std.string;
import std.conv;
import std.datetime;
import core.stdc.string;
import core.sys.windows.windows;

inout(string) stringzToString(inout(char*) cString)
{
    size_t len = strlen(cString);
    return to!string(cString[0 .. len]);
}

int main(string[] argv)
{
    string path = "C:\\";
    string search = "game.cfg";

    WIN32_FIND_DATA[] result;

    //string[] directories;
    int i = 0;
    auto directories = new DirectorySearcher(path, "*", true);
    foreach (dir; directories)
    {
        writeln("Searching: ", stringzToString(cast(char*)(dir.cFileName)));
        string filepath = CommonSearcher.Combine(path, stringzToString(cast(char*)(dir.cFileName)));
        auto files = new FileSearcher(filepath, "*", true);
        foreach (file; files)
        {
            if (indexOf(stringzToString(cast(char*)(file.cFileName)), search, CaseSensitive.no) == 0)
            {
                writeln("Found: ", stringzToString(cast(char*)(file.cFileName)));
                if (i == result.length)
                    result.length += 10;
                result[i++] = file;
            }
        }
    }
    result.length = i;

    if (i == 0)
        writeln("Found nothing");

    string buf;
    stdin.readln(buf);
    return 0;
}
