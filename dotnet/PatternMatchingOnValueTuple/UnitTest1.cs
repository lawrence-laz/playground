using Xunit;

namespace PatternMatchingOnValueTuple;

public class UnitTest1
{

    [Fact]
    public void Test1()
    {
        (bool Foo, bool Bar) aaa = (true, false);

        var a = aaa switch
        {
            { Foo: true } => 1,
            _ => 0
        };

        Assert.True(a == 1);
    }
}
