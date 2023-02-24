
using Microsoft.Extensions.Logging;

namespace SerilogPlayground;

public class BasicLoggingToFile : IDisposable
{
    private string? _filePath;

    public void Dispose()
    {
        if (_filePath is not null)
        {
            File.Delete(_filePath);
        }
    }

    [Theory, AutoData]
    public void UsingSerilogInterface(string filePath)
    {
        _filePath = filePath;
        var expected = "Hello, world!";
        var log = new LoggerConfiguration()
            .WriteTo.File(filePath, outputTemplate: "{Message}")
            .CreateLogger();
        log.Write(LogEventLevel.Information, expected);
        File.ReadAllText(filePath).Should().Be(expected);
    }

    [Theory, AutoData]
    public void UsingMicrosoftInterface(string filePath)
    {
        _filePath = filePath;
        var expected = "Hello, world!";
        var serilogLogger = new LoggerConfiguration()
            .WriteTo.File(filePath, outputTemplate: "{Message}")
            .CreateLogger();
        var microsoftLogger = new LoggerFactory()
            .AddSerilog(serilogLogger)
            .CreateLogger("MyLogger");
        microsoftLogger.LogInformation(expected);
        File.ReadAllText(filePath).Should().Be(expected);
    }
}

