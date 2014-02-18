module FileSearcher;

import core.sys.windows.windows;
import std.array;
import std.string;
import typecons;

private immutable char AltDirectorySeparatorChar = '/';
private immutable char DirectorySeparatorChar = '\\';
private immutable char PathSeparator = ';';
private immutable char VolumeSeparatorChar = ':';
private immutable string DirectorySeparatorStr = "\\";
private immutable bool dirEqualsVolume = DirectorySeparatorChar == VolumeSeparatorChar;

public enum FileAttributes : uint
{
    Archive = 0x00020,
	Compressed = 0x00800, 
	Device = 0x00040,
	Directory = 0x00010,
	Encrypted = 0x04000,
	Hidden = 0x00002,
	Normal = 0x00080,
	NotContentIndexed = 0x02000,
	Offline = 0x01000,
	ReadOnly = 0x00001,
	ReparsePoint = 0x00400,
	SparseFile = 0x00200,
	System = 0x00004,
	Temporary = 0x00100,
}

abstract class CommonSearcher
{
    private WIN32_FIND_DATA _winFindData;
    private HANDLE _findHandle;
    private bool _empty;
    private string _path;

    this(string path)
    {
        this(path, "*");
    }

    this(string path, string pattern, bool skipFirst = false)
    {
        _path = strip(path);
        _findHandle = FindFirstFileA(cast(char*)Combine(path, pattern), &_winFindData);
        _empty = (_findHandle == INVALID_HANDLE_VALUE);
        if (skipFirst && !_empty)
            popFront();
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
        super(path, "*");
    }

    this(string path, string pattern, bool skipFirst = false)
    {
        super(path, pattern, skipFirst);
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
        super(path, "*");
    }

    this(string path, string pattern, bool skipFirst = false)
    {
        super(path, pattern, skipFirst);
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
