public record struct FooRequest(string Foo) : IRequest<string>;
public record struct BarRequest(int Bar) : IRequest<int>;

public interface IFooBarHandler :
    IRequestHandler<FooRequest, string>,
    IRequestHandler<BarRequest, int>
{
}

public class FirstFooBarHandler : IFooBarHandler
{
    public string Handle(FooRequest request)
    {
        // Console.WriteLine("FIRST FOO METHOD");
        int x = 0;
        for (int i = 0; i < 50; ++i)
            x += i;
        return "";
    }

    public int Handle(BarRequest request)
    {
        // Console.WriteLine("FIRST BAR METHOD");
        int x = 0;
        for (int i = 0; i < 50; ++i)
            x += i;
        return 321;
    }
}

public class SecondFooBarHandler : IFooBarHandler
{
    public string Handle(FooRequest request)
    {
        // Console.WriteLine("SECOND FOO METHOD");
        int x = 0;
        for (int i = 0; i < 50; ++i)
            x += i;
        return "";
    }

    public int Handle(BarRequest request)
    {
        // Console.WriteLine("SECOND BAR METHOD");
        int x = 0;
        for (int i = 0; i < 50; ++i)
            x += i;
        return 123;
    }
}


public class LoggingBehavior : BaseBehavior
{
    public LoggingBehavior(BaseBehavior next) : base(next)
    {
    }

    public override TResponse Handle<TRequest, TResponse>(TRequest request)
    {
        // if (next is null)
        // {
        //     return default;
        // }

        var result = HandleNext<TRequest, TResponse>(request);
        // Console.WriteLine("LOGGING: " + request.ToString());
        int x = 0;
        for (int i = 0; i < 50; ++i)
            x += i;
        return result;
    }
}

public class DispatchingOptions
{
    public bool ShouldGoToFirst = true;
}

public class DispatchingBehavior<THandler> : BaseBehavior
{
    private readonly THandler first;
    private readonly THandler second;
    private readonly DispatchingOptions options;

    public DispatchingBehavior(
        BaseBehavior next,
        THandler first,
        THandler second,
        DispatchingOptions options) : base(next)
    {
        this.first = first;
        this.second = second;
        this.options = options;
    }

    public override TResponse Handle<TRequest, TResponse>(TRequest request)
    {
        if (options.ShouldGoToFirst && first is IRequestHandler<TRequest, TResponse> firstHandler)
        {
            return firstHandler.Handle(request);
        }
        else if (!options.ShouldGoToFirst && second is IRequestHandler<TRequest, TResponse> secondHandler)
        {
            return secondHandler.Handle(request);
        }
        else
        {
            throw new NotSupportedException();
        }
    }
}

