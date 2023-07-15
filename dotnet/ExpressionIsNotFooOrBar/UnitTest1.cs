using System;
using Xunit;

namespace ExpressionIsNotFooOrBar;

public class Foo { }
public class Bar { }

public class UnitTest1
{
    [Fact]
    public void Test1()
    {
        object o = new Bar();
        // if (o is not Foo or Bar) // This doesn't work
        // if (o is not Foo and Bar) // This doesn't work either
        // if (o is not Foo && o is not Bar) // This works, but doesnt fully use pattern matching
        if (o is not Foo and not Bar) // ok, so suggestion to use pattern matching showed where my thinking was incorrect, had to use two "not"
        {
            // good
        }
        else
        {
            throw new Exception();
        }
    }
}
