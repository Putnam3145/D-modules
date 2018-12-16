module cayley_dickson;

import std.traits;

import std.complex;

bool isCayleyDickson(T)()
{
    return __traits(isSame,TemplateOf!T,TemplateOf!(CayleyDickson!(double,1))) || __traits(isSame,TemplateOf!T,Complex);
}

template CayleyDickson(T,uint depth=0)
if(isFloatingPoint!T && depth==0)
{
    alias CayleyDickson = Complex!(T);
}

struct CayleyDickson(T,uint depth)
if(isFloatingPoint!T && depth>=1)
{
    import std.format : FormatSpec;
    import std.range.primitives : isOutputRange;
    static immutable uint dim=depth;
    CayleyDickson!(T,depth-1) re;
    CayleyDickson!(T,depth-1) im;
    alias re this;
    /** Converts any generic cayley-dickson construction to a string representation.
    The second form of this function is usually not called directly;
    instead, it is used via $(REF format, std,string), as shown in the examples
    below.  Supported format characters are 'e', 'f', 'g', 'a', and 's'.
    See the $(MREF std, format) and $(REF format, std,string)
    documentation for more information.
    */
    string toString() const @safe /* TODO: pure nothrow */
    {
        import std.exception : assumeUnique;
        char[] buf;
        buf.reserve(100);
        auto fmt = FormatSpec!char("%s");
        toString((const(char)[] s) { buf ~= s; }, fmt);
        static trustedAssumeUnique(T)(T t) @trusted { return assumeUnique(t); }
        return trustedAssumeUnique(buf);
    }

    static if (is(T == double))
    ///
    @safe unittest
    {
        auto q = CayleyDickson!(double,1)(1.2, 3.4, 5.0, 4.04);

        // Vanilla toString formatting:
        assert(q.toString() == "1.2+3.4i+5j+4.04k");

        // Formatting with std.string.format specs: the precision and width
        // specifiers apply to both the real and imaginary parts of the
        // complex number.
        import std.format : format;
        assert(format("%.2f", q)  == "1.20+3.40i+5.00j+4.04k");
        assert(format("%4.1f", q) == " 1.2+ 3.4i+ 5.0j+ 4.0k");
    }

    /// ditto
    void toString(Writer, Char)(scope Writer w, const ref FormatSpec!Char formatSpec) const
        if (isOutputRange!(Writer, const(Char)[]))
    {
        import std.format : formatValue;
        import std.math : signbit;
        import std.range.primitives : put;
        import std.conv : to;
        static if(depth==1)
        {
            formatValue(w, this[0], formatSpec);
            if (signbit(this[0]) == 0)
                put(w, "+");
            formatValue(w, this[1], formatSpec);
            put(w, "i");
            if (signbit(this[1]) == 0)
                put(w, "+");
            formatValue(w, this[2], formatSpec);
            put(w, "j");
            if (signbit(this[2]) == 0)
                put(w, "+");
            formatValue(w, this[3], formatSpec);
            put(w, "k");
        }
        else
        {
            for(auto i=0;i<2^^(depth+1);i++)
            {
                formatValue(w,this[i],formatSpec);
                put(w,"e"~to!string(i));
                if(i+1<2^^(depth+1) && signbit(this[i+1]) == 0)
                    put(w,"+");
            }
        }
    }
@safe pure nothrow @nogc:
    this(R : T)(CayleyDickson!(R,depth) z)
    {
        re=z.re;
        im=z.im;
    }
    this(R : T)(CayleyDickson!(R,depth-1) z1, CayleyDickson!(R,depth-1) z2)
    {
        re=z1;
        im=z2;
    }
    this(R : T)(CayleyDickson!(R,depth-1) z)
    {
        re=z;
        im=0.0;
    }
    this(R : T)(ref CayleyDickson z)
    {
        this.re=0.0;
        this.im=0.0;
        CayleyDickson* me=&this;
        for(uint i = 0;i<(depth-z.dim);i++)
        {
            me=*this.re;
        }
        *me=z;
    }
    this(R : T)(Complex!R z1, Complex!R z2)
    {
        this[0]=z1.re;
        this[1]=z1.im;
        this[2]=z2.re;
        this[3]=z2.im;
    }
    this(R : T)(R scalar)
    {
        this.re=0.0;
        this.im=0.0;
        this[0]=scalar;
    }
    this(R : T)(R[] scalars ...)
    {
        const maxSize=2^^depth+1;
        foreach(uint idx,T scalar;scalars)
        {
            if(idx>maxSize) 
                break;
            this[idx]=scalar;
        }
    }
    void opAssign(R : T)(R z)
    {
        static if(isCayleyDickson!R)
        {
            auto realZ=CayleyDickson!(T,depth)(z);
            re=z.re;
            im=z.im;
        }
        else
        {
            re=z;
            im=0.0;
        }
    }

    bool opEquals(R)(R z)
    {
        static if(is(R==CayleyDickson!(T,depth)))
        {
            return re==z.re && im==z.im;
        }
        else
        {
            return this==CayleyDickson!(T,depth)(z);
        }
    }

	CayleyDickson opUnary(string op)()
	{
		static if(op == "+") { return this; }
		else static if(op == "-") 
        {
            this.re=-this.re;
            this.im=-this.im;
            return this;
        }
	}
    CayleyDickson opBinary(string op, R)(R z)
    {
        alias Q = typeof(return);
        auto w = Q(this.re,this.im);
        return w.opOpAssign!(op)(z);
    }
    CayleyDickson opBinaryRight(string op, R)(const R r)
    if(isNumeric!R)
    {
		static if (op == "+" || op == "*")
		{
			return opBinary!(op)(r);
		}
		else static if (op == "-")
		{
            alias Q = typeof(return);
			return(Q(r-this.re,-this.im));
		}
		else static if (op == "/")
		{
            assert(0,"cayley-dickson construction doesn't necessarily create a division algebra!"); //todo: make depths 2, 1 work
		}
    }
    ref CayleyDickson opOpAssign(string op, R)(const R z)
    if(isCayleyDickson!R)
    {
        static if(z.dim<depth)
        {
            auto realZ=CayleyDickson!(T,depth)(z);
        }
        else
        {
            auto realZ=z;
        }
        static if(op == "+" || op == "-")
        {
            mixin ("re "~op~"= realZ.re;");
            mixin ("im "~op~"= realZ.im;");
            return this;
        }
        else static if (op == "*")
        {
            auto copy=this;
            re=(copy.re*realZ.re)-(copy.im*realZ.im);
            im=(copy.re*realZ.im)+(copy.im*realZ.re);
            return this;
        }
        else static if (op == "/")
        {
            assert(0,"cayley-dickson construction doesn't necessarily create a division algebra!");
        }
    }
    ref CayleyDickson opOpAssign(string op, R : T)(const R i)
    if(isNumeric!R)
    {
        static if(op == "+" || op == "-" || op == "*" || op == "/")
        {
            mixin ("re "~op~"= i;");
            static if (!(op == "+" || op == "-"))
            {
                mixin ("im "~op~"= i;");
            }
            return this;
        }
        else static if(op == "^^")
        {
            static if(isIntegral!R)
            {
                switch(i)
                {
                    case 0:
                        re=1;
                        im=0;
                        break;
                    case 1:
                        break;
                    case 2:
                        this*=this;
                        break;
                    default:
                        alias Q = typeof(return);
                        int exp=i;
                        Q result = this;
                        while(i>=0)
                        {
                            if(i%2)
                            {
                                this*=result;
                            }
                            result*=result;
                            exp/=2;
                        }
                }
                return this;
            }
            else
            {
                return this=exp(i*log(this));
            }
        }
    }
    T opIndex(size_t idx) const
    {
        const size_t maxSize=(2^^(depth+1));
        static if(depth==1)
        {
            switch(idx)
            {
                case 0:
                    return this.re.re;
                case 1:
                    return this.re.im;
                case 2:
                    return this.im.re;
                case 3:
                    return this.im.im;
                default:
                    assert(0,"This algebra doesn't have that many parts!");
            }
        }
        else
        {
            assert(idx<maxSize,"This algebra doesn't have that many parts!");
            if(idx<maxSize/2)
            {
                return this.re[idx];
            }
            else
            {
                return this.im[idx/2];
            }
        }
    }
    T opIndexAssign(T n, size_t idx)
    {
        const size_t maxSize=(2^^(depth+1));
        static if(depth==1)
        {
            switch(idx)
            {
                case 0:
                    return this.re.re=n;
                case 1:
                    return this.re.im=n;
                case 2:
                    return this.im.re=n;
                case 3:
                    return this.im.im=n;
                default:
                    assert(0,"This algebra doesn't have that many parts!");
            }
        }
        else
        {
            assert(idx<maxSize,"This algebra doesn't have that many parts!");
            if(idx<maxSize/2)
            {
                return this.re[idx]=n;
            }
            else
            {
                return this.im[idx/2]=n;
            }
        }
    }
}
unittest
{
    auto im=CayleyDickson!(double)(0.0,1.0);
    assert(isCayleyDickson!(typeof(im)));
    alias ComplexC = CayleyDickson!(double);
    alias Quaternion = CayleyDickson!(double,1);
    alias Octonion = CayleyDickson!(double,2);
    alias Sedenion = CayleyDickson!(double,3);
    ComplexC c = 0.0;
    Quaternion q = 0.0;
    Octonion o = 0.0;
    Sedenion s = 0.0;
    import std.stdio,std.conv;
    s[1]=1;
    assert(s[1]==1);
    writeln("Complex: ",c);
    writeln("Quaternion: ",q);
    writeln("Octonion: ",o);
    writeln("Sedenion: ",s);
    writeln("Sedenion squared: ",s^^2);
    assert(s^^2==-1);
    assert(im^^2==-1,text(im,' ',im^^2));
}

pure nothrow CayleyDickson!(T,depth) exp(T,uint depth)(CayleyDickson!(T,depth) z,int precision=-1)
{
    import std.mathspecial;
    alias Q = typeof(return);
    auto result=Q(1)+z;
    if(precision<1)
    {
        precision=T.dig-2;
    }
    for(i=2;i<precision+2;i++)
    {
        result+=(z^^i)/(gamma(i-1));
    }
    return result;
}

pure nothrow CayleyDickson!(T,depth) log(T)(CayleyDickson!(T,depth) z, int precision=-1)
{
    import std.algorithm : max;
    if(precision<1)
    {
        precision=T.dig-1;
    }
    auto result=z;
    for(i=1;i<precision+1;i++)
    {
        auto resultExp=exp(result,max(precision/4,4));
        result+=2*((z-resultExp)/(z+resultExp));
    }
    return result;
}