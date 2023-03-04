using System.Reflection;
using BenchmarkDotNet.Attributes;
using BenchmarkDotNet.Jobs;
using BenchmarkDotNet.Running;
using MediatR;
using Microsoft.Extensions.DependencyInjection;

// var options = new DispatchingOptions { ShouldGoToFirst = true };
// var chain = new LoggingBehavior(new DispatchingBehavior<IFooBarHandler>(
//     next: null,
//     first: new FirstFooBarHandler(),
//     second: new SecondFooBarHandler(),
//     options: options));
//
// chain.Handle<FooRequest, string>(new FooRequest("Hello"));
// chain.Handle<BarRequest, int>(new BarRequest(111));

// var options = new DispatchingOptions { ShouldGoToFirst = true };
// var chain = new LoggingBehavior(new DispatchingBehavior<IFooBarHandler>(
//     next: null,
//     first: new FirstFooBarHandler(),
//     second: new SecondFooBarHandler(),
//     options: options));
// chain.Send(new FooRequest("Hello"));
// chain.Send(new BarRequest(111));
var summary = BenchmarkRunner.Run<BenchmarkTest>();

public static class BaseBehaviorExtensions
{
    public static TResponse? Send<TResponse>(this BaseBehavior behavior, IRequest<TResponse> request)
    {
        var method = behavior
            .GetType()
            .GetMethod(nameof(BaseBehavior.Handle), BindingFlags.Public | BindingFlags.Instance)
            ?.MakeGenericMethod(request.GetType(), typeof(TResponse))
            ?? throw new NotSupportedException();

        var response = method.Invoke(behavior, new[] { request });

        return response is null
            ? default
            : (TResponse)response;
    }
}

[SimpleJob(RuntimeMoniker.Net60)]
[RPlotExporter]
[MemoryDiagnoser]
public class BenchmarkTest
{
    BaseBehavior chain;

    BaseBehavior logging;
    IFooBarHandler first;
    IFooBarHandler second;
    IServiceProvider services;
    IMediator mediator;

    [GlobalSetup]
    public void Setup()
    {
        var options = new DispatchingOptions { ShouldGoToFirst = true };
        chain = new LoggingBehavior(new DispatchingBehavior<IFooBarHandler>(
            next: null,
            first: new FirstFooBarHandler(),
            second: new SecondFooBarHandler(),
            options: options));

        logging = new LoggingBehavior(null);
        first = new FirstFooBarHandler();
        second = new SecondFooBarHandler();
        services = new ServiceCollection()
            .AddMediatR(options =>
            {
                options.RegisterServicesFromAssembly(typeof(Program).Assembly);
                options.AddOpenBehavior(typeof(LoggingBehaviorMediatR<,>));
            })
            .BuildServiceProvider();
        mediator = services.GetRequiredService<IMediator>();
    }

    [Benchmark]
    public void ChainOfResponsibilityExplicit()
    {
        chain.Handle<FooRequest, string>(new("Hello"));
        chain.Handle<BarRequest, int>(new(111));
    }

    [Benchmark]
    public void ChainOfResponsibilityInferred()
    {
        chain.Send(new FooRequest("Hello"));
        chain.Send(new BarRequest(111));
    }

    [Benchmark]
    public void UsingMediatR()
    {
        mediator.Send(new FooRequestMediatR("Hello"));
        mediator.Send(new BarRequestMediatR(111));
    }


    [Benchmark(Baseline = true)]
    public void PlainCode()
    {
        // int x = 0;
        // for (int i = 0; i < 50; ++i)
        //     x += i;
        // x = 0;
        // for (int i = 0; i < 50; ++i)
        //     x += i;
        // x = 0;
        // for (int i = 0; i < 50; ++i)
        //     x += i;
        // x = 0;
        // for (int i = 0; i < 50; ++i)
        //     x += i;
        Foo();
        Bar();
    }

    public void Foo()
    {
        int x = 0;
        for (int i = 0; i < 50; ++i)
            x += i;
        x = 0;
        for (int i = 0; i < 50; ++i)
            x += i;
    }

    public void Bar()
    {
        int x = 0;
        for (int i = 0; i < 50; ++i)
            x += i;
        x = 0;
        for (int i = 0; i < 50; ++i)
            x += i;
    }
}

// -------------- MediatR stuff ------------------

public class LoggingBehaviorMediatR<TRequest, TResponse>
    : MediatR.IPipelineBehavior<TRequest, TResponse>
{
    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken cancellationToken)
    {
        var result = await next();

        int x = 0;
        for (int i = 0; i < 50; ++i)
            x += i;

        return result;
    }
}

public record struct FooRequestMediatR(string Foo) : MediatR.IRequest<string>;
public record struct BarRequestMediatR(int Bar) : MediatR.IRequest<int>;

public class DispatchingBehaviorMediatR :
    MediatR.IRequestHandler<FooRequestMediatR, string>,
    MediatR.IRequestHandler<BarRequestMediatR, int>
{
    // Ahh, I don't want to rewrite handlers to match MediatR interfaces for now, so I'll just inline calls, 
    // this will only improve MediatR times.
    // private readonly THandler first;
    // private readonly THandler second;
    private readonly DispatchingOptions options;

    public DispatchingBehaviorMediatR(
        // THandler first,
        // THandler second,
        DispatchingOptions options)
    {
        // this.first = first;
        // this.second = second;
        this.options = options;
    }

    public Task<string> Handle(FooRequestMediatR request, CancellationToken cancellationToken)
    {
        if (options.ShouldGoToFirst)
        {
            int x = 0;
            for (int i = 0; i < 50; ++i)
                x += i;
            x = 0;
            for (int i = 0; i < 50; ++i)
                x += i;
        }
        else if (!options.ShouldGoToFirst)
        {
            int x = 0;
            for (int i = 0; i < 50; ++i)
                x += i;
            x = 0;
            for (int i = 0; i < 50; ++i)
                x += i;
        }
        else
        {
            throw new NotSupportedException();
        }

        return Task.FromResult("Hello");
    }

    public Task<int> Handle(BarRequestMediatR request, CancellationToken cancellationToken)
    {
        if (options.ShouldGoToFirst)
        {
            int x = 0;
            for (int i = 0; i < 50; ++i)
                x += i;
            x = 0;
            for (int i = 0; i < 50; ++i)
                x += i;
        }
        else if (!options.ShouldGoToFirst)
        {
            int x = 0;
            for (int i = 0; i < 50; ++i)
                x += i;
            x = 0;
            for (int i = 0; i < 50; ++i)
                x += i;
        }
        else
        {
            throw new NotSupportedException();
        }

        return Task.FromResult(123);
    }
}


