using FluentAssertions;
using MediatR;
using Microsoft.Extensions.DependencyInjection;

namespace di_resolve_covariant_type;

public class UnitTest1
{
    // Let's say we have a request that has variations with different properties
    public record FooOptions(int Foo1, int Foo2);
    public record BarOptions(int Bar1, int Bar2);

    // We can either have a base request and extend it to add different options
    public interface IBaseRequest : IRequest
    {
        public string Name { get; }
    }
    public record FooRequest(string Name, FooOptions Options) : IBaseRequest;
    public record BarRequest(string Name, BarOptions Options) : IBaseRequest;

    // Or use composition and have base request with type parameter
    public interface IComposedRequest : IRequest
    {
        string Name { get; }
    }
    public class ComposedRequest<TOptions> : IComposedRequest
    {
        public string Name { get; }
        public TOptions Options { get; set; }
    }

    // A handler for base request would look like this
    public class BaseRequestHandler : IRequestHandler<IBaseRequest, Unit>
    {
        public Task<Unit> Handle(IBaseRequest request, CancellationToken cancellationToken)
        {
            Console.WriteLine($"Got a request to base handler of type: {request.GetType()}");
            return Task.FromResult(Unit.Value);
        }
    }

    // A handler for composed request would look like this
    public class ComposedRequestHandler : IRequestHandler<IComposedRequest, Unit>
    {
        public Task<Unit> Handle(IComposedRequest request, CancellationToken cancellationToken)
        {
            Console.WriteLine($"Got a request to composed handler of type: {request.GetType()}");
            return Task.FromResult(Unit.Value);
        }
    }

    // There might be a problem with composed handler as it can only handle a request with single type of TOptions.
    // But if a base interface would be introduces, then it wouldn't be a problem?

    [Fact]
    public void Microsoft_di_container_cannot_resolve_covariant_services()
    {
        var serviceProvider = new ServiceCollection()
            .AddSingleton<IRequestHandler<IBaseRequest, Unit>, BaseRequestHandler>()
            .BuildServiceProvider();

        var handler = serviceProvider.GetService<IRequestHandler<FooRequest, Unit>>();

        handler.Should().BeNull();
        // Except the handler is not covariant, but contravariant -> interface IRequestHandler<in TRequest, TResponse>
        // So this approach doesn't work, we need a base interface for a request, which would hold different options.
    }

    [Fact]
    public void Resolving_composed_request_handler_and_calling_it_with_different_compositions()
    {
        var serviceProvider = new ServiceCollection()
            .AddSingleton<IRequestHandler<IComposedRequest, Unit>, ComposedRequestHandler>()
            .BuildServiceProvider();

        var handler = serviceProvider.GetService<IRequestHandler<IComposedRequest, Unit>>();

        handler.Should().NotBeNull();

        handler.Invoking(x => x.Handle(new ComposedRequest<FooOptions>(), default)).Should().NotThrowAsync();
        handler.Invoking(x => x.Handle(new ComposedRequest<BarOptions>(), default)).Should().NotThrowAsync();
    }
}
