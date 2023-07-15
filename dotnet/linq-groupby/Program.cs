using BenchmarkDotNet.Attributes;
using BenchmarkDotNet.Jobs;
using BenchmarkDotNet.Running;

BenchmarkRunner.Run<LinqGroupBy>();

[SimpleJob(RuntimeMoniker.Net70)]
[MemoryDiagnoser]
public class LinqGroupBy
{
    private readonly List<string> _list = Enumerable
        .Range(1, 100)
        .Select(i => i.ToString())
        .Append("1")
        .Append("52")
        .Append("13")
        .ToList();

    [Benchmark]
    public void GroupBy()
    {
        _list.GroupBy(x => x)
            .Where(g => g.Count() > 1)
            .Select(y => y.Key)
            .ToList();
    }

    [Benchmark]
    public void Imperative()
    {
        Duplicates(_list);
    }

    static List<T> Duplicates<T>(IList<T> list)
    {
        var duplicates = new List<T>();
        var uniqueElements = new List<T>();

        foreach (var item in list)
        {
            if (uniqueElements.Contains(item))
            {
                duplicates.Add(item);
            }
            else
            {
                uniqueElements.Add(item);
            }
        }

        return duplicates;
    }
}
