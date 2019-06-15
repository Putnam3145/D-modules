/** This module contains the $(LREF Quaternion) type, which is used to represent
    quaternions, along with related mathematical operations and functions.
    License:    $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/

//Much of the code in this was cribbed from phobos's std.complex, thus the boost license.

module quaternions;

import std.traits,std.complex,std.math;

/** Helper function that returns a quaternion with the specified
    parts.
    Params:
        R = (template parameter) type of real part of quaternion
        I = (template parameter) type of i part of quaternion
        J = (template parameter) type of j part of quaternion
        K = (template parameter) type of k part of quaternion
        re = real part of quaternion to be constructed
        i = (optional) i part of quaternion, 0 if omitted.
        j = (optional) j part of quaternion, 0 if omitted.
        k = (optional) k part of quaternion, 0 if omitted.
    Returns:
        `Quaternion` instance with all parts set the the values
        provided as input.  If neither `re`, `i`, `j` or `k`
        are floating-point numbers, the return type will be
        `Complex!double`.  Otherwise, the return type is
        deduced using $(D std.traits.CommonType!(R, I, J, K)).
*/
auto quaternion(R)(const R re)  @safe pure nothrow @nogc
if (is(R : double))
{
    static if (isFloatingPoint!R)
        return Quaternion!R(re, 0, 0, 0);
    else
        return Quaternion!double(re, 0, 0, 0);
}

/// ditto
auto quaternion(R, I, J, K)(const R re, const I i, const J j, const K k)  @safe pure nothrow @nogc
if (is(R : double) && is(I : double) && is(J : double) && is(K : double))
{
    static if (isFloatingPoint!R || isFloatingPoint!I || isFloatingPoint!J || isFloatingPoint!K)
        return Quaternion!(CommonType!(R, I, J, K))(re, i, j, k);
    else
        return Quaternion!double(re, i, j, k);
}

//straight up copied this unit test from std.complex
///
@safe pure nothrow unittest
{
    auto a = quaternion(1.0);
    static assert(is(typeof(a) == Quaternion!double));
    assert(a.re == 1.0);
    assert(a.i == 0.0);
    assert(a.j == 0.0);
    assert(a.k == 0.0);

    auto b = quaternion(2.0L);
    static assert(is(typeof(b) == Quaternion!real));
    assert(b.re == 2.0L);
    assert(b.i == 0.0);
    assert(b.j == 0.0);
    assert(b.k == 0.0);

    auto c = quaternion(1.0, 2.0, 1.5, 3.0);
    static assert(is(typeof(c) == Quaternion!double));
    assert(c.re == 1.0);
    assert(c.i == 2.0);
    assert(c.j == 1.5);
    assert(c.k == 3.0);

    auto d = quaternion(3.0, 4.0L,2.0,5.0L);
    static assert(is(typeof(d) == Quaternion!real));
    assert(d.re == 3.0);
    assert(d.i == 4.0);
    assert(d.j == 2.0);
    assert(d.k == 5.0);

    auto e = quaternion(1);
    static assert(is(typeof(e) == Quaternion!double));
    assert(e.re == 1);
    assert(e.i == 0.0);
    assert(e.j == 0.0);
    assert(e.k == 0.0);

    auto f = quaternion(1L, 2, 3, 4);
    static assert(is(typeof(f) == Quaternion!double));
    assert(f.re == 1L);
    assert(f.i == 2);
    assert(f.j == 3);
    assert(f.k == 4);

    auto g = quaternion(3, 4.0L, 5, 6);
    static assert(is(typeof(g) == Quaternion!real));
    assert(g.re == 3);
    assert(g.i == 4.0);
    assert(g.j == 5);
    assert(g.k == 6);
}


struct Quaternion(T)
if (isFloatingPoint!T)
{
    import std.format : FormatSpec;
    import std.range.primitives : isOutputRange;
	/// The real (scalar) part of the number.
	T re;
	/// The i part of the number.
	T i;
	/// The j part of the number.
	T j;
	/// The k part of the number.
	T k;

    /** Converts the quaternion to a string representation.
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
        auto q = quaternion(1.2, 3.4, 5.0, 4.04);

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
        formatValue(w, re, formatSpec);
        if (signbit(i) == 0)
           put(w, "+");
        formatValue(w, i, formatSpec);
        put(w, "i");
        if (signbit(j) == 0)
           put(w, "+");
        formatValue(w, j, formatSpec);
        put(w, "j");
        if (signbit(k) == 0)
           put(w, "+");
        formatValue(w, k, formatSpec);
        put(w, "k");
    }

@safe pure nothrow @nogc:
	/** Construct a quaternion with all the specified
	parts. A real argument will fill only the real part,
	a complex argument will fill only real and i parts.
	*/
	this(R : T)(Quaternion!R q)
	{
		re=q.re;
		i=q.i;
		j=q.j;
		k=q.k;
	}
	///ditto
	this(Ra : T, Rb : T, Rc : T, Rd : T)(const Ra a, const Rb b, const Rc c, const Rd d)
	{
		re=a;
		i=b;
		j=c;
		k=d;
	}
	///ditto
	this(R : T)(Complex!R z)
	{
		re=z.re;
		i=z.im;
		j=0;
		k=0;
	}
	///ditto
	this(R : T)(const R r)
	{
		re=r;
		i=0;
		j=0;
		k=0;
	}
    this(R : T)(const R z,const Quaternion!R n,const R theta) // polar form
    {
        this = z*exp(n.vector.norm*theta);
    }

	// ASSIGNMENT

	ref Quaternion opAssign(R : T)(Quaternion!R q)
	{
		re=q.re;
		i=q.i;
		j=q.j;
		k=q.k;
		return this;
	}
	ref Quaternion opAssign(R : T)(Complex!R z)
	{
		re=z.re;
		i=z.im;
		j=0;
		k=0;
		return this;
	}
    ref Quaternion opAssign(R : T)(const R r)
    {
		re=r;
		i=0;
		j=0;
		k=0;
        return this;
    }

	//COMPARISON

    bool opEquals(R : T)(Quaternion!R q) const
    {
        const auto EPS=CommonType!(T,R).epsilon;
        return re.approxEqual(q.re,EPS) && i.approxEqual(q.i,EPS) && j.approxEqual(q.j,EPS) && k.approxEqual(q.k,EPS);
    }

    bool opEquals(R : T)(Complex!R z) const
    {
        const auto EPS=CommonType!(T,R).epsilon;
        return re.approxEqual(z.re,EPS) && i.approxEqual(z.im,EPS) && j == 0 && k == 0;
    }

    // this == numeric
    bool opEquals(R : T)(const R r) const
    {
        return re.approxEqual(r,CommonType!(T,R).epsilon) && i == 0 && j == 0 && k == 0;
    }

	//OPERATORS

	Quaternion opUnary(string op)() const
	{
		static if(op == "+") { return this; }
		else static if(op == "-") { return Quaternion(-re,-i,-j,-k); }
	}

    Quaternion!(CommonType!(T,R)) opBinary(string op, R)(Quaternion!R q) const
    {
        alias Q = typeof(return);
        auto w = Q(this.re, this.i, this.j, this.k);
        return w.opOpAssign!(op)(q);
    }
    Quaternion!(CommonType!(T,R)) opBinary(string op, R)(const R r) const
    if (isNumeric!R)
	{
        alias Q = typeof(return);
        auto w = Q(this.re, this.i, this.j, this.k);
        return w.opOpAssign!(op)(r);
	}
	Quaternion!(CommonType!(T, R)) opBinaryRight(string op, R)(const R r) const //all the stuff with real numbers
	if (isNumeric!R)
	{
		static if (op == "+" || op == "*") //since we're multiplying with a real there's no rotation, so we can treat multiplication as commutative
		{
			return opBinary!(op)(r);
		}
		else static if (op == "-")
		{
            alias Q = typeof(return);
			return(Q(r-re,-i,-j,-k));
		}
		else static if (op == "/")
		{
            alias Q = typeof(return);
			//now i can finally stop plagiarizing phobos
            auto denominator = (re*re+i*i+j*j+k*k);
            return(Q((re*r)/denominator,(-i*r)/denominator,(-j*r)/denominator,(-k*r)/denominator));
		}
        else static if (op == "^^")
        {
            const auto adjustedNorm = this.vector.norm*std.math.log(r);
            return std.math.pow(r,re)*(cos(adjustedNorm)+q.vector.unit*sin(adjustedNorm));
        }
	}
    //OP-ASSIGN
    ref Quaternion opOpAssign(string op, Q)(const Q q)
    if(is(Q R == Quaternion!R))
    {
        static if (op == "+" || op == "-")
        {
            mixin ("re "~op~"= q.re;");
            mixin ("i "~op~"= q.i;");
            mixin ("j "~op~"= q.j;");
            mixin ("k "~op~"= q.k;");
            return this;
        }
        else static if (op == "*")
        {
            auto p=this;
            re=(q.re*p.re)-(q.i*p.i)-(q.j*p.j)-(q.k*p.k);
            i=(q.re*p.i)+(q.i*p.re)-(q.j*p.k)+(q.k*p.j);
            j=(q.re*p.j)+(q.i*p.k)+(q.j*p.re)-(q.k*p.i);
            k=(q.re*p.k)-(q.i*p.j)+(q.j*p.i)+(q.k*p.re);
            return this;
        }
        else static if (op == "/")
        {
            auto denominator = (q.re*q.re+q.i*q.i+q.j*q.j+q.k*q.k);
            auto p=this;
            re=((q.re*p.re)+(q.i*p.i)+(q.j*p.j)+(q.k*p.k))/denominator;
            i=((q.re*p.i)-(q.i*p.re)-(q.j*p.k)+(q.k*p.j))/denominator;
            j=((q.re*p.j)+(q.i*p.k)-(q.j*p.re)-(q.k*p.i))/denominator;
            k=((q.re*p.k)-(q.i*p.j)+(q.j*p.i)-(q.k*p.re))/denominator;
            return this;
        }
    }
    ref Quaternion opOpAssign(string op, U : T)(const U a)
        if (isNumeric!U)
    {
        static if (op == "+" || op == "-")
        {
            mixin ("re "~op~"= a;");
            return this;
        }
        else static if (op == "*" || op == "/")
        {
            mixin ("re "~op~"= a;");
            mixin ("i "~op~"= a;");
            mixin ("j "~op~"= a;");
            mixin ("k "~op~"= a;");
            return this;
        }
        else static if (op == "^^")
        {
            static if(isIntegral!U)
            {
                switch(a)
                {
                case 0:
                    re = 1.0;
                    i = 0.0;
                    j = 0.0;
                    k = 0.0;
                    break;
                case 1:
                    //1 is the identity here
                    break;
                case 2:
                    this *= this;
                    break;
                case 3:
                    auto q = this;
                    this *= q;
                    this *= q;
                    break;
                default:
                    this ^^= cast(T) a;
                }
                return this;
            }
            else
            {
                return this=exp(a*log(this));
            }
        }
    }
    ///Makes the quaternion its unit counterpart.
    ref Quaternion setToNorm()
    {
        return this/=this.norm;
    }
}

/*  Makes Quaternion!(Quaternion!T) fold to Quaternion!T.
    The rationale for this is that just like the complex plane is a
    subspace of quaternion space, quaternion space is a
    subspace of itself. Example of usage:
    ---
    Quaternion!T addI(T)(T x)
    {
        return x + Quaternion!T(0.0, 1.0, 0, 0);
    }
    ---
    The above will work if T is both real and quaternion.
*/
template Quaternion(T)
if (is(T R == Quaternion!R))
{
    alias Quaternion = T;
}

@safe pure nothrow unittest
{
    static assert(is(Quaternion!(Quaternion!real) == Quaternion!real));

    Quaternion!T addI(T)(T x)
    {
        return x + Quaternion!T(0.0, 1.0, 2, 3);
    }

    auto z1 = addI(1.0);
    assert(z1.re == 1.0 && z1.i == 1.0 && z1.j == 2 && z1.k == 3);

    enum one = Quaternion!double(1.0, 0.0, 0.0, 0.0);
    auto z2 = addI(one);
    assert(z1 == z2);
}

///The quaternion with its scalar part stripped out.
pure nothrow Quaternion!T vector(T)(const Quaternion!T q)
{
    return Quaternion!(T)(0,q.i,q.j,q.k);
}

///
@safe pure nothrow unittest
{
    assert(quaternion(1,5,5,5).vector == quaternion(0,5,5,5));
}

///The scalar part of the quaternion.
@safe pure nothrow T scalar(T)(const Quaternion!T q)
{
    return q.re;
}

///
@safe pure nothrow unittest
{
    assert(quaternion(2,4,2,2).scalar==2);
}

/**
    Params: q = A quaternion.
    Returns: the norm of `q`.
*/
T norm(T)(const Quaternion!T q)
{
    return sqrt(sqNorm(q));
}
///
@safe unittest
{
    auto q = quaternion(0.5,2,2,0.5);
    assert(q.norm==sqrt(8.5));
    //should be exactly 1, but floating point errors tend to build up--use functions like isUnitQuaternion where possible!
    assert(approxEqual(q.norm,(q*quaternion(0,1,0,0)).norm,double.epsilon)); 
}

/**
    Params: q = A quaternion.
    Returns: The squared norm of `q`.
*/
T sqNorm(T)(const Quaternion!T q)
{
    return (q*q.conjugate).re;
}
///
@safe pure nothrow unittest
{
    auto q = quaternion(0.5,2,2,0.5);
    assert(q.sqNorm==8.5);
    assert(q.sqNorm==(q*quaternion(0,1,0,0)).sqNorm);
}
/**
    Params: q = A quaternion.
    Returns: whether `q` is a unit quaternion.
*/
bool isUnitQuaternion(T)(const Quaternion!T q)
{
    return approxEqual(q.sqNorm,1,T.epsilon);
}
///
@safe pure nothrow unittest
{
    assert(quaternion(1,0,0,0).isUnitQuaternion);
    assert(quaternion(0,1,0,0).isUnitQuaternion);
    assert(quaternion(0,0,1,0).isUnitQuaternion);
    assert(quaternion(0,0,0,1).isUnitQuaternion);
    assert(quaternion(0.5,0.5,0.5,0.5).isUnitQuaternion);
    assert(quaternion(0,SQRT1_2,0,SQRT1_2).isUnitQuaternion);
}
/**
    Params: 
     p = A quaternion.
     q = A unit quaternion.
    Returns: p conjugated with q.
    If only one quaternion is given, it will simply return that quaternion's conjugate.
*/
Quaternion!T conjugate(T)(const Quaternion!T p)
{
    return Quaternion!T(p.re,-p.i,-p.j,-p.k);
}

///ditto
Quaternion!(CommonType!(R,T)) conjugate(R,T)(const Quaternion!R p, const Quaternion!T q)
in
{
    assert(q.norm==1,`q must be a unit quaternion!`);
}
do
{
    return q*p*q.conjugate;
}

///
@safe pure nothrow unittest
{
    auto q = quaternion(0.5,0.5,0.5,0.5);
    auto p = quaternion(0,1,1,1).unit;
    assert(q.conjugate==quaternion(0.5,-0.5,-0.5,-0.5));
    enum SQRT1_3 = std.math.sqrt(1.0/3);
    assert(conjugate(p,q)==quaternion(0,SQRT1_3,SQRT1_3,SQRT1_3));
}

pure nothrow T angle(T)(const Quaternion!T q)
{
    return acos(q.re/q.norm);
}

/**
    Params:
     q = A quaternion.
    Returns: The natural logarithm of q.
*/
pure nothrow Quaternion!T log(T)(const Quaternion!T q)
{
    /*   Gives me an error if I don't cast here. I don't actually recall the error, since I'm writing this comment after the fact,
      but I do remember that std.math.log returns a real and the error had to do with no implicit conversion between Quaternion!real
      and Quaternion!double. Either way, the cast is actually necessary.
    */
    return cast(T)std.math.log(q.norm)+q.vector.unit*q.angle; 
}

pure nothrow Quaternion!T vectorUnit(T)(const Quaternion!T q)
{
    return q.vector.unit;
}

/**
    Params: q = A quaternion.
    Returns: The exponential function of q.
*/
pure nothrow Quaternion!T exp(T)(const Quaternion!T q)
{
    const auto vectorNorm = q.vector.norm;
    return std.math.exp(q.re)*(cos(vectorNorm)+q.vectorUnit*sin(vectorNorm));
}
/**
    Params: q = A quaternion.
    Returns: A quaternion with the same argument but norm of one.
*/
Quaternion!T unit(T)(const Quaternion!T q)
{
    if(q==0)
    {
        return q;
    }
    return q/q.norm;
}

///
@safe pure nothrow unittest
{
    assert(quaternion(0,2,1,0).unit.norm.approxEqual(1.0));
}
unittest
{
    import quaternions;
    import std.math,std.complex;
    enum EPS = double.epsilon;
    const auto p = quaternion(0,1.0,1.0,1.0);
    const auto q = Quaternion!double(0.5,2.0,2.0,0.5);
    const auto i = quaternion(0,1,0,0);
    const auto j = quaternion(0,0,1,0);
    const auto k = quaternion(0,0,0,1);
    assert(p == +p);
    assert((-q).re == -(q.re));
    assert((-q).i == -(q.i));
    assert((-q).j == -(q.j));
    assert((-q).k == -(q.k));
    assert(q == -(-q));
    assert(i*i==-1);
    assert(j*j==-1);
    assert(k*k==-1);
    assert(i*j*k==-1);
    assert(k*k*k==-k);
    const auto ppq = p+q;
    assert(ppq.re==p.re+q.re);
    assert(ppq.i==p.i+q.i);
    assert(ppq.j==p.j+q.j);
    assert(ppq.k==p.k+q.k);
    const auto pmq = p-q;
    assert(pmq.re==p.re-q.re);
    assert(pmq.i==p.i-q.i);
    assert(pmq.j==p.j-q.j);
    assert(pmq.k==p.k-q.k);
    const auto ptq = p*q;
    const auto qtp = q*p;
    assert(qtp==quaternion(-4.5,2.0,-1.0,0.5));
    assert(ptq!=qtp);
    assert(q^^-1==1/q);
    assert(q^^1.0==q^^1);
    assert(q^^2.0==q^^2);
    assert(q^^3.0==q^^3);
    assert(q^^0.0==q^^0);
    assert(q^^2==q*q);
    assert(q^^5==q*q*q*q*q);
    assert(q.conjugate==quaternion(0.5,-2,-2,-0.5));
    assert(q.unit.conjugate==1/q.unit);
    assert(i^^0.5==complex(0,1)^^0.5);
}