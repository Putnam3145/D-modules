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
    pure @safe @nogc void opAssign(T n)
    {
        import core.atomic : atomicStore;
        // we use curTask being null as a way to tell if a task is running.
        // it feels kinda like abuse, but it's allowed and (technically) safe, so this we do.
        curTask = null;
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
    @safe void lazySet(alias func,Args...)(Args args) // not pure because taskPool isn't; not nogc because task!func isn't
        if(is(ReturnType!func == T))
    {
        import std.parallelism : task,taskPool;
        auto t = task!func(args);
        taskPool.put(t);
        curTask = (() => t.workForce);
    }
    /// ditto
    @safe void lazySet(F,Args...)(F fpOrDelegate, ref Args args)
        if(is(ReturnType!F == T))
    {
        import std.parallelism : task,taskPool;
        auto t = task(fpOrDelegate,args);
        taskPool.put(t);
        curTask = (() => t.workForce);
    }

    private:
        T _val;
        T delegate() curTask;

        T val() // we can't guarantee ANY properties of curTask, so this gets none
        {
            import core.atomic : cas,atomicLoad;
            T prev = _val; // this can run in however many threads at once, which is why this is done cas-wise
            if(curTask && cas(&_val,prev,curTask())) curTask = null;
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
