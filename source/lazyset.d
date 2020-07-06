module lazyset;

/** 
    Provides a wrapper that allows for lazy, threaded
    setting of variables. When lazySet!func(args) is called
    on the value, the function will be called in a new thread;
    if the value is accessed before the thread is done, it'll block
    until the thread is finished.

    Accessing the value is as simple as using it like the
    type it's templated for--see the unit test.
*/
struct LazySet(T)
{

    alias val this;

    /// You can set the value directly, as normal--this will prevent the thread from modifying the value.
    pure @safe @nogc void opAssign(T n)
    {
        import core.atomic : atomicStore;
        thread = null; // this'll keep the thread going, technically, but the main thread will never stop to wait for it
        atomicStore(_val,n);
    }

    import std.traits : ReturnType;
/** 
    Called the same way as std.parallelism.task;
    after this is called, it'll set the value ASAP.
    If one attempts to access the value before
    the function is done, it'll wait until the function is done anyway.
*/
    void lazySet(alias func,Args...)(Args args)
        if(is(ReturnType!func == T))
    {
        import core.thread : Thread;
        import core.atomic : atomicLoad, cas;
        thread = new Thread({
            T prev = atomicLoad(_val);
            T newVal = func(args);
            cas(&_val,prev,newVal);
        }).start();
    }
    /// ditto
    void lazySet(F,Args...)(F fpOrDelegate, ref Args args)
        if(is(ReturnType!F == T))
    {
        import core.thread : Thread;
        import core.atomic : atomicLoad, cas;
        thread = new Thread({
            T prev = atomicLoad(_val);
            T newVal = fpOrDelegate(args);
            cas(&_val,prev,newVal);
        }).start();
    }

    private:
        import core.thread : Thread;
        shared T _val;
        Thread thread;

        T val()
        {
            if(thread) thread.join();
            return _val;
        }
}

///
unittest
{
    import std.stdio : writeln;
    writeln("Lazy set testing.");
    import std.conv : to;
    LazySet!int test;
    // can be set directly
    test = 500;
    assert(test == 500,test.to!string);
    // can be set using an anonymous function as the template argument, of course.
    import std.datetime.stopwatch;
    auto sw = StopWatch(AutoStart.yes);
    test.lazySet!({
        import std.random : uniform;
        int i = 0;
        while(i<100_000_000)
        {
            i++;
        }
        return i;
    })();
    writeln("Time taken to start the function: ",sw.peek);
    sw.reset();
    assert(test == 100_000_000,test.to!string);
    writeln("Time taken to access the variable: ",sw.peek);
    sw.reset();
    test.lazySet!({
        import std.random : uniform;
        int i = 0;
        while(i<100_000_000)
        {
            i++;
        }
        return i;
    })();
    sw.reset();
    test = 5;
    assert(test == 5,test.to!string);
    writeln("Time taken to access the variable when overridden during the function: ",sw.peek);
    // you can also pass in a delegate argument
    test.lazySet(() => 40);
    assert(test == 40,test.to!string);
    writeln("Finished.");
}