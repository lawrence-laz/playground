using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using MediatR;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace MediatRTests;

record RequestBase<TResponse>() : IRequest<TResponse>;
record RequestFoo() : RequestBase<Unit>;
record RequestBar() : RequestBase<Unit>;
record RequestBaz() : IRequest; // Not extending RequestBase!

class RequestBaseHandler<TResponse> : IRequestHandler<RequestBase<TResponse>, TResponse>
{
    public static List<RequestBase<TResponse>> ReceivedRequests = new();

    public Task<TResponse> Handle(RequestBase<TResponse> request, CancellationToken cancellationToken)
    {
        ReceivedRequests.Add(request);
        return Task.FromResult(default(TResponse))!;
    }
}

class GenericHandler<TRequest, TResponse> : IRequestHandler<TRequest, TResponse>
where TRequest : RequestBase<TResponse>
{
    public static List<TRequest> ReceivedRequests = new();

    public Task<TResponse> Handle(TRequest request, CancellationToken cancellationToken)
    {
        ReceivedRequests.Add(request);
        return Task.FromResult(default(TResponse))!;
    }
}

public class SendCommandTests
{
    [Fact]
    public void Send_extended_type_commands_to_constrained_generic_handler()
    {
        // Arrange
        var services = new ServiceCollection()
            .AddTransient(typeof(IRequestHandler<,>), typeof(GenericHandler<,>))
            .AddMediatR(typeof(RequestFoo))
            .BuildServiceProvider();
        var mediator = services.GetRequiredService<IMediator>();
        var foo = new RequestFoo();
        var bar = new RequestBar();
        var baz = new RequestBaz();

        // Act
        mediator.Send(foo);
        mediator.Send(bar);
        mediator.Send(baz); // Baz does not inherit from base request.

        // Assert
        GenericHandler<RequestFoo, Unit>.ReceivedRequests.Should().Contain(foo);
        GenericHandler<RequestBar, Unit>.ReceivedRequests.Should().Contain(bar);
        // GenericHandler<RequestBaz, Unit>.ReceivedRequests.Should().NotContain(baz); // Doesn't even compile.
    }

    [Fact]
    public void Send_extended_type_commands_to_request_base_handler()
    {
        // Arrange
        var services = new ServiceCollection()
            .AddMediatR(typeof(RequestFoo))
            .BuildServiceProvider();
        var mediator = services.GetRequiredService<IMediator>();
        var foo = new RequestFoo();
        var bar = new RequestBar();

        // Act
        mediator.Send(foo);
        mediator.Send(bar);

        // Assert
        RequestBaseHandler<Unit>.ReceivedRequests.Should().NotContain(foo);
        RequestBaseHandler<Unit>.ReceivedRequests.Should().NotContain(bar);
    }
}
