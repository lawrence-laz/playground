using Xunit;

namespace Tests;

public class UnitTest1
{
    [Fact]
    public void Test1()
    {
        var options = new DispatchingOptions { ShouldGoToFirst = true };
        var chain = new LoggingBehavior(new DispatchingBehavior<IFooBarHandler>(
           next: null,
           first: new FirstFooBarHandler(),
           second: new SecondFooBarHandler(),
           options: options));
        chain.Handle<FooRequest, string>(new("Hello"));
        chain.Handle<BarRequest, int>(new(111));
    }
}
