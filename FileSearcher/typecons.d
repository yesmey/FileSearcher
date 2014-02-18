module typecons;

struct Flags(T) if (is (T == struct))
{
    private T base;
    this(T val)
    {
        base = val;
    }

    string toString()
    {
        import std.traits;
        import std.array;
        import std.conv;
        auto app = appender!string();
        bool bar = true;
        foreach(member; T)
        {
            if ((base & member) != 0)
            {
                if (!bar)
                    bar = true;
                else
                    app.put(" | ");
                app.put(member.to!string());
            }
        }
        if (!bar)
        {
            app.put("<empty>");
        }
        return app.data;
    }
}
