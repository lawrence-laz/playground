public interface IRequest<TResponse>
{
}

public interface IRequestHandler<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
{
    TResponse Handle(TRequest request);
}

public abstract class BaseBehavior
{
    private readonly BaseBehavior next;

    public BaseBehavior(BaseBehavior next)
    {
        this.next = next;
    }

    public abstract TResponse Handle<TRequest, TResponse>(
            TRequest request)
        where TRequest : IRequest<TResponse>;

    protected TResponse HandleNext<TRequest, TResponse>(TRequest request) where TRequest : IRequest<TResponse>
    {
        if (next is not null)
        {
            return next.Handle<TRequest, TResponse>(request);
        }
        else
        {
            return default;
        }
    }
}

