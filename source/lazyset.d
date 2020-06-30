module lazyset;

/** 
    Provides a transparent wrapper that allows for lazy
    setting of variables. When lazySet!!func(args) is called
    on the value, the function will be called in a new thread;
    as soon as the value's access is attempted, it'll return the
    result of the task, blocking if it's not done calculating.

    Accessing the value is as simple as using it like the
    type it's templated for--see the unit test.
*/
shared struct LazySet(T)
{

    alias val this;

    /// You can set the value directly, as normal--this throws away the current task.
    void opAssign(T n)
    {
        import core.atomic : atomicStore;
        working = false;
        atomicStore(_val,n);
    }

    import std.traits : ReturnType;
/** 
    Called the same way as std.parallelism.task;
    after this is called, the next attempt to access
    the value will result in the value being set from
    the result of the given function before it's returned.
    If the task isn't done, it'll wait on the task to be done
    once accessed, using workForce.
*/
    void lazySet(alias func,Args...)(Args args)
        if(is(ReturnType!func == T))
    {
        import std.parallelism : task,taskPool;
        auto t = task!func(args);
        taskPool.put(t);
        curTask = (() => t.workForce);
        working = true;
    }
    /// ditto
    void lazySet(F,Args...)(F fpOrDelegate, ref Args args)
        if(is(ReturnType!F == T))
    {
        import std.parallelism : task,taskPool;
        auto t = task(fpOrDelegate,args);
        taskPool.put(t);
        curTask = (() => t.workForce);
        working = true;
    }

    private:
        T _val;
        T delegate() curTask;
        bool working = false;

        T val()
        {
            import core.atomic : atomicStore,atomicLoad;
            if(working)
            {
                atomicStore(_val,curTask());
                working = false;
            }
            return atomicLoad(_val);
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
    test.lazySet!({
        import std.random : uniform;
        int i;
        while(uniform(0,1000) != 0)
        {
            i = uniform(0,100);
        }
        return i;
    })();
    assert(test < 100,test.to!string);
    // you can also pass in a delegate argument
    test.lazySet(() => 40);
    assert(test == 40,test.to!string);
    writeln("Finished.");
}