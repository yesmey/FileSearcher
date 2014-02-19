module main;

import FileSearcher;
import std.array;
import std.conv;
import std.datetime;
import std.stdio;
import std.string;
import std.parallelism;
import core.stdc.string;
import core.sys.windows.windows;

inout(string) stringzToString(inout(char*) cString)
{
    size_t len = strlen(cString);
    return to!string(cString[0 .. len]);
}

private immutable string path = "C:\\";
private immutable string search = "gdrv.sys";

int main(string[] argv)
{
    WIN32_FIND_DATA[] result;
    //string[] directories;
    int i = 0;

    auto directories = new DirectorySearcher(path, "*", SearchOptions.SkipFirst);
    foreach (dir; parallel(directories, 3)) // parallel three top level directories per thread
    {
        writeln("Searching: ", stringzToString(cast(char*)(dir.cFileName)));
        string filepath = CommonSearcher.Combine(path, stringzToString(cast(char*)(dir.cFileName)));
        auto files = new FileSearcher(filepath, "*", SearchOptions.SkipFirst | SearchOptions.LargeFetch);
        foreach (file; files)
        {
            if (indexOf(stringzToString(cast(char*)(file.cFileName)), search, CaseSensitive.no) == 0)
            {
                writeln("Found: ", CommonSearcher.Combine(filepath, stringzToString(cast(char*)(file.cFileName))));
                if (i == result.length)
                    result.length += 10;
                result[i++] = file;
            }
        }
    }

    result.length = i;

    if (i == 0)
        writeln("Found nothing");

    string line;
    line = stdin.readln();
    return 0;
}
