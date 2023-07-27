namespace pause_token;
public class PauseTokenSource
{
    private volatile TaskCompletionSource<bool>? _taskCompletionSource;
    public static readonly Task COMPLETED_TASK = Task.FromResult(true);

    public PauseToken Token => new(this);
    public bool IsPaused => _taskCompletionSource != null;

    public void Pause()
    {
        Interlocked.CompareExchange(
            ref _taskCompletionSource,
            value: new TaskCompletionSource<bool>(),
            comparand: null);
    }

    public void Resume()
    {
        while (true)
        {
            var currentTaskCompletionSource = _taskCompletionSource;
            if (currentTaskCompletionSource == null)
            {
                return;
            }

            if (Interlocked.CompareExchange(
                ref _taskCompletionSource,
                value: null,
                comparand: currentTaskCompletionSource) == currentTaskCompletionSource)
            {
                currentTaskCompletionSource.SetResult(true);
                break;
            }
        }
    }

    public Task WaitWhilePausedAsync()
    {
        return _taskCompletionSource?.Task ?? COMPLETED_TASK;
    }
}
