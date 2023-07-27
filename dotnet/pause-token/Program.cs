using System.Diagnostics;
using pause_token;

var tokenSource = new PauseTokenSource();

await Task.WhenAny(
    HandleInput(),
    Task.Run(() => LongRunningFunction(tokenSource.Token))
);

async Task LongRunningFunction(PauseToken token)
{
    var _stopwatch = Stopwatch.StartNew();

    while (true)
    {
        await token.WaitWhilePausedAsync();
        await Task.Delay(TimeSpan.FromSeconds(0.01));
        Console.Clear();
        Console.WriteLine("Press <Spacebar> to pause/resume.");
        Console.WriteLine("Press <Escape> to exit the program.");
        Console.WriteLine(_stopwatch.Elapsed);
    }
}

async Task HandleInput()
{
    while (true)
    {
        if (!Console.KeyAvailable)
        {
            await Task.Delay(TimeSpan.FromSeconds(0.01));
            continue;
        }

        var input = Console.ReadKey(true);
        if (input.Key == ConsoleKey.Spacebar)
        {
            if (tokenSource.IsPaused)
            {
                tokenSource.Resume();
            }
            else
            {
                tokenSource.Pause();
            }
        }
        else if (input.Key == ConsoleKey.Escape)
        {
            break;
        }
    }
}
