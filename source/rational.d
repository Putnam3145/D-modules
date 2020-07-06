module rational;

import std.traits : isIntegral;
struct Rational(T)
	if(isIntegral!T)
{
	T numerator = 0;
	T denominator = 1;
	real f()
	{
		return cast(real)numerator/cast(real)denominator;
	}
	real f(U)(U n)
		if(is(U : real))
	{
		this = fromFloat(n);
		return f();
	}
	static Rational!T fromFloat(U)(U n)
		if(is(U : real))
	{
		import std.math : modf, approxEqual, pow, quantize;
		Rational!T ret;
		import std.stdio : writeln;
		real integerPart;
		auto frac = n.modf(integerPart);
		int exponent = 0;
		while(frac.quantize(1) != frac)
		{
			exponent++;
			frac*=10;
		}
		auto den = cast(int)(pow(10,exponent));
		ret.numerator = cast(int)(frac + integerPart*den);
		ret.denominator = cast(int)(den);
		ret.simplify();
		return ret;
	}
	void opAssign(U)(U n)
	{
		static if(is(U : T))
		{
			this.numerator = n;
			this.denominator = 1;
		}
		else static if(is(U : real))
		{
			this.f(n);
		}
		else static if(is(U : Rational!T))
		{
			this.numerator = n.numerator;
			this.denominator = n.denominator;
		}
	}
	private void simplify()
	{
		import std.numeric : gcd;
		immutable auto ourGcd = gcd(numerator,denominator);
		numerator /= ourGcd;
		denominator /= ourGcd;
	}
	Rational!T opUnary(string op)()
	{
		final switch(op)
		{
			case "-":
				return Rational!T(-numerator,denominator);
			case "+":
				return this;
			case "++":
				numerator += denominator;
				return this;
			case "--":
				numerator -= denominator;
				return this;
		}
	}
	Rational!T opBinary(string op,U)(U other)
	{
		import std.traits : TemplateOf,isNumeric;
		static if(is(U : Rational!T))
		{
			final switch(op)
			{
				case "+":
					import std.algorithm.comparison : min;
					auto n = Rational!T();
					n.denominator = denominator*other.denominator;
					n.numerator = (numerator*other.denominator)+(other.numerator*denominator);
					n.simplify();
					return n;
				case "-":
					return this + (-other);
				case "*":
					return Rational!T(numerator*other.numerator,denominator*other.denominator);
				case "/":
					return this*(1/other);
			}
		}
		else static if(is(U : T))
		{
			final switch(op)
			{
				case "-":
					other = -other;
					goto case;
				case "+":
					return Rational!T(numerator+(other*denominator),denominator);
				case "*":
					return Rational!T(numerator*other,denominator);
				case "/":
					return Rational!T(numerator,denominator * other);
			}
		}
		else static if(is(U : real))
		{
			return mixin("this"~op~"fromFloat(other)");
		}
	}
	import std.traits : isNumeric;
	Rational!T opBinaryRight(string op,U)(U value)
		if(isNumeric!U && op == "/")
	{
		auto n = Rational!T();
		n.denominator = numerator;
		n.numerator = denominator;
		return n*value;
	}
	bool opEquals(Rational!T b)
	{
		simplify();
		b.simplify();
		return numerator == b.numerator && denominator == b.denominator;
	}
	void opOpAssign(string op,U)(U rhs)
	{
		import std.stdio : writeln;
		mixin("this = this"~op~"rhs;");
	}
}

unittest
{
	import std.stdio : writeln;
	import std.math : approxEqual;
	writeln("Starting rational test.");
	auto r = Rational!int();
	r = 3;
	r /= 2;
	assert (r == Rational!int(3,2));
	r = r.fromFloat(1.8582);
	writeln(r.f);
	writeln(r);
	assert(r.f.approxEqual(1.8582));
	writeln("Finished.");
}