// See https://aka.ms/new-console-template for more information
using System.Diagnostics;
using Polly;

Console.WriteLine("Hello, World!");
Console.WriteLine("Hello, World!");

var breaker = Policy
    .Handle<MyException>()
    .CircuitBreaker(2, TimeSpan.FromSeconds(5));
var stopwatch = Stopwatch.StartNew();
for (var i = 0; i < 100; ++i)
{
    var executionStopwatch = Stopwatch.StartNew();
    try
    {
        breaker.Execute(() =>
        {
            Console.WriteLine("Real call");
            throw new MyException();
        });
    }
    catch (Exception e)
    {
        Console.WriteLine($"Exception '{e.GetType().Name}' at {stopwatch.Elapsed} (duration was {executionStopwatch.Elapsed})");
    }
    await Task.Delay(TimeSpan.FromMilliseconds(100));
}


public class MyException : Exception
{
    public MyException()
    {
        Console.WriteLine("New exception");
        Thread.Sleep(1000); // Exceptions are expensive
    }
}
