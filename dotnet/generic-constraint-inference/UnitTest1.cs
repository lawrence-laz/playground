namespace GenericConstraintInference;

public static class Foo
{
    public TItem DoSomething<TCollection, TItem>(TCollection collection)
        where TCollection : ICollection<TItem>
    {
        return collection.
    }
}

public class UnitTest1
{
    [Fact]
    public void Test1()
    {

    }
}
