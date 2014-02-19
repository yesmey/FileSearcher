module FileSearcher;

import std.c.windows.windows;
import std.array;
import std.string;

private immutable char AltDirectorySeparatorChar = '/';
private immutable char DirectorySeparatorChar = '\\';
private immutable char PathSeparator = ';';
private immutable char VolumeSeparatorChar = ':';
private immutable string DirectorySeparatorStr = "\\";
private immutable bool dirEqualsVolume = DirectorySeparatorChar == VolumeSeparatorChar;
private immutable uint FIND_FIRST_EX_LARGE_FETCH = 2;

private enum FINDEX_INFO_LEVELS
{
    FindExInfoStandard,
    FindExInfoMaxInfoLevel
}

private enum FINDEX_SEARCH_OPS
{
    FindExSearchNameMatch,
    FindExSearchLimitToDirectories,
    FindExSearchLimitToDevices,
    FindExSearchMaxSearchOp
}

nothrow:
pragma(lib, "kernel32.lib");
extern(Windows)
{
    HANDLE FindFirstFileExA(LPCSTR, FINDEX_INFO_LEVELS, PVOID, FINDEX_SEARCH_OPS, PVOID, DWORD);
}

public enum FileAttributes : uint
{
    Archive             = 0x00020,
    Compressed          = 0x00800,
    Device              = 0x00040,
    Directory           = 0x00010,
    Encrypted           = 0x04000,
    Hidden              = 0x00002,
    Normal              = 0x00080,
    NotContentIndexed   = 0x02000,
    Offline             = 0x01000,
    ReadOnly            = 0x00001,
    ReparsePoint        = 0x00400,
    SparseFile          = 0x00200,
    System              = 0x00004,
    Temporary           = 0x00100,
}

public enum SearchOptions : uint
{
    None                = 0x00,
    SkipFirst           = 0x01,
    LargeFetch          = 0x02,
}

abstract class CommonSearcher
{
    private WIN32_FIND_DATA _winFindData;
    private HANDLE _findHandle;
    private bool _empty;
    private string _path;

    this(string path)
    {
        this(path, "*", SearchOptions.None);
    }

    this(string path, string pattern, SearchOptions options)
    {
        _path = strip(path);
    }

    ~this()
    {
        if (_findHandle != INVALID_HANDLE_VALUE)
            FindClose(_findHandle);
    }

    WIN32_FIND_DATA front() @property
    {
        return _winFindData;
    }

    bool empty() @property
    {
        return _empty;
    }

    typeof(this) save() @property { return this; }
    abstract void popFront() @property;

    public static string Combine(string path1, string path2)
    {
        if (IsPathRooted(path2))
            return path2;

        char endChar = path1[path1.length - 1];
        if (endChar != DirectorySeparatorChar && endChar != AltDirectorySeparatorChar && endChar != VolumeSeparatorChar)
            return path1 ~ DirectorySeparatorStr ~ path2;

        return path1 ~ path2;
    }

    public static bool IsPathRooted(string path)
    {
        if (path == null || path.length == 0)
            return false;

        char c = path[0];
        if (c == DirectorySeparatorChar || c == AltDirectorySeparatorChar)
            return true;

        static if (!dirEqualsVolume)
        {
            if (path.length > 1 && path [1] == VolumeSeparatorChar)
                return true;
        }

        return false;
    }
}

class DirectorySearcher : CommonSearcher
{
    this(string path)
    {
        super(path, "*", SearchOptions.None);
    }

    this(string path, string pattern, SearchOptions options)
    {
        super(path, pattern, options);
        if (options & SearchOptions.LargeFetch)
            _findHandle = FindFirstFileExA(cast(char*)Combine(path, pattern), FINDEX_INFO_LEVELS.FindExInfoStandard, &_winFindData, FINDEX_SEARCH_OPS.FindExSearchLimitToDirectories, null, FIND_FIRST_EX_LARGE_FETCH);
        else
            _findHandle = FindFirstFileExA(cast(char*)Combine(path, pattern), FINDEX_INFO_LEVELS.FindExInfoStandard, &_winFindData, FINDEX_SEARCH_OPS.FindExSearchLimitToDirectories, null, 0);

        _empty = (_findHandle == INVALID_HANDLE_VALUE);
        if ((options & SearchOptions.SkipFirst) && !_empty)
            popFront();
    }

    override void popFront() @property
    {
        // since front will always run once before popFront, we can always move to the next file
        while (FindNextFileA(_findHandle, &_winFindData))
        {
            if (_winFindData.cFileName[0] == '.')
                continue;

            if ((_winFindData.dwFileAttributes & FileAttributes.Directory) == FileAttributes.Directory)
                return; // found one - return and let next front provide it
        }

        // FindNextFileA returned false, meaning we are finished
        _empty = true;
    }
}

class FileSearcher : CommonSearcher
{
    this(string path)
    {
        super(path, "*", SearchOptions.None);
    }

    this(string path, string pattern, SearchOptions options)
    {
        super(path, pattern, options);
        if (options & SearchOptions.LargeFetch)
            _findHandle = FindFirstFileExA(cast(char*)Combine(path, pattern), FINDEX_INFO_LEVELS.FindExInfoStandard, &_winFindData, FINDEX_SEARCH_OPS.FindExSearchNameMatch, null, FIND_FIRST_EX_LARGE_FETCH);
        else
            _findHandle = FindFirstFileExA(cast(char*)Combine(path, pattern), FINDEX_INFO_LEVELS.FindExInfoStandard, &_winFindData, FINDEX_SEARCH_OPS.FindExSearchNameMatch, null, 0);

        _empty = (_findHandle == INVALID_HANDLE_VALUE);
        if ((options & SearchOptions.SkipFirst) && !_empty)
            popFront();
    }

    override void popFront() @property
    {
        // since front will always run once before popFront, we can always move to the next file
        while (FindNextFileA(_findHandle, &_winFindData))
        {
            if (_winFindData.cFileName[0] == '.')
                continue;

            if ((_winFindData.dwFileAttributes & FileAttributes.Directory) != FileAttributes.Directory)
                return; // found one - return and let next front provide it
        }

        // FindNextFileA returned false, meaning we are finished
        _empty = true;
    }
}
