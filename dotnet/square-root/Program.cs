using BenchmarkDotNet.Attributes;
using BenchmarkDotNet.Running;

// dotnet add package BenchmarkDotNet
// dotnet run -c Release

var summary = BenchmarkRunner.Run<MyBenchmarks>();

[MemoryDiagnoser]
public class MyBenchmarks
{
    decimal _someNumber;
    public MyBenchmarks()
    {
        _someNumber = (decimal)new Random().NextDouble();
    }

    [Benchmark]
    public void MathSqrt()
    {
        var aa = (decimal)Math.Sqrt((double)_someNumber);
    }

    public static decimal NewtonSqrt(decimal x, decimal epsilon = 0.0M)
    {
        if (x < 0) throw new OverflowException("Cannot calculate square root from a negative number");

        decimal current = (decimal)Math.Sqrt((double)x), previous;
        do
        {
            previous = current;
            if (previous == 0.0M) return 0;
            current = (previous + x / previous) / 2;
        }
        while (Math.Abs(previous - current) > epsilon);
        return current;
    }

    [Benchmark]
    public void Newton()
    {
        NewtonSqrt(_someNumber, 0.000001m);
    }

    public static decimal BabylonSqrt(decimal x, decimal? guess = null)
    {
        var ourGuess = guess.GetValueOrDefault(x / 2m);
        var result = x / ourGuess;
        var average = (ourGuess + result) / 2m;

        if (average == ourGuess) // This checks for the maximum precision possible with a decimal.
            return average;
        else
            return BabylonSqrt(x, average);
    }
    [Benchmark]
    public void Babylonian()
    {
        BabylonSqrt(_someNumber);
    }
}
