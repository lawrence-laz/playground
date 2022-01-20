using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace di;

public interface IFoo { }

public class Foo<T> : IFoo { }

public class ResolveTests
{
    [Fact]
    public void Cannot_resolve_multiple_open_generic_services()
    {
        var services = new ServiceCollection()
            .AddSingleton(typeof(Foo<>))
            .BuildServiceProvider();

        var fooInt = services.GetRequiredService<Foo<int>>();
        var fooString = services.GetRequiredService<Foo<string>>();

        // Does not compile
        // var fooAll = services.GetRequiredService(typeof(IEnumerable<Foo<>>));
    }
}
