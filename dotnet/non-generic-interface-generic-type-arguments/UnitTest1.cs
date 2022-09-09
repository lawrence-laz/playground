namespace non_generic_interface_generic_type_arguments;

public interface IFoo<T>
{
}

public interface IBar
{
}

public class Foo : IFoo<int>
{
}

public class Bar : IBar
{
}

public class UnitTest1
{
    [Fact]
    public void Test1()
    {
        // Accessing GenericTypeArguments on interface with type parameters should be ok
        new Foo().GetType().GetInterfaces().First().GenericTypeArguments.Contains(typeof(int)).Should().BeTrue();

        // But what happens if you access GenericTypeArguments on interface without type params?
        new Bar().GetType().GetInterfaces().First().GenericTypeArguments.Contains(typeof(int)).Should().BeFalse();
        // Conveniently the list is just empty, but it's still there and can be used.
    }
}
