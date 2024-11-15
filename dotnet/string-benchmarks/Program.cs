using System.Text;
using BenchmarkDotNet.Attributes;
using BenchmarkDotNet.Running;

// dotnet add package BenchmarkDotNet
// dotnet run -c Release

var summary = BenchmarkRunner.Run<SomeBenchmarks>();

[MemoryDiagnoser]
public class SomeBenchmarks
{
    private StringBuilder _sb;

    public SomeBenchmarks()
    {
        _sb = new();
    }

    [Benchmark]
    public void New_SB_Append()
    {
        var a = new StringBuilder();
        a.Append("Hello, ");
        a.Append("world");
        a.Append("!");
        var b = a.ToString();
    }

    [Benchmark]
    public void New_SB_AppendFormat()
    {
        var a = new StringBuilder();
        a.AppendFormat("Hello, {0}!", "world");
        var b = a.ToString();
    }

    [Benchmark]
    public void Reused_SB_Append()
    {
        _sb.Clear();
        _sb.Append("Hello, ");
        _sb.Append("world");
        _sb.Append("!");
        var b = _sb.ToString();
    }

    [Benchmark]
    public void String_Format()
    {
        var a = string.Format("Hello, {0}!", "world");
    }
}
