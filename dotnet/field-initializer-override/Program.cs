var foo = new Foo()
{
    Number = 321 // Object initializer provides a value, but "DefaultNumber()" is still called.
};

Console.WriteLine(foo.Number);


class Foo
{
    public int Number = DefaultNumber();

    public static int DefaultNumber()
    {
        Console.WriteLine("DefaultNumber() is called!");
        return 123;
    }
}
