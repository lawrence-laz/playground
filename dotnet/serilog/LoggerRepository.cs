using System.Collections.Concurrent;
using System.Collections.Generic;
using Microsoft.Extensions.Logging;
using ILogger = Microsoft.Extensions.Logging.ILogger;

public class LoggingOptions
{
    public bool IsEnabled = true;
}

public class LoggerContextObject
{
    public string UniqueId { get; set; }
    public LoggingOptions LoggingOptions { get; set; }

    public LoggerContextObject(string uniqueId, LoggingOptions loggingOptions)
    {
        UniqueId = uniqueId;
        LoggingOptions = loggingOptions;
    }
}

public record LoggingMetadata(string LogFileName);

public class LoggerRepository
{
    private ConcurrentDictionary<string, ILogger> _loggers = new();
    private ConcurrentDictionary<string, LoggingMetadata> _metadata = new();

    public ILogger GetLogger(LoggerContextObject context)
    {
        return _loggers.GetOrAdd(context.UniqueId, _ => CreateLogger(context));
    }

    public LoggingMetadata GetMetadata(LoggerContextObject context)
    {
        return _metadata.GetOrAdd(context.UniqueId, _ => CreateMetadata(context));
    }

    private ILogger CreateLogger(LoggerContextObject context)
    {
        var metadata = GetMetadata(context);
        var filePath = metadata.LogFileName;
        var loggerConfiguration = new LoggerConfiguration();
        if (context.LoggingOptions.IsEnabled)
        {
            loggerConfiguration.WriteTo.File(filePath, outputTemplate: "{Message}{NewLine}");
        }
        var serilogLogger = loggerConfiguration.CreateLogger();
        var microsoftLogger = new LoggerFactory()
            .AddSerilog(serilogLogger)
            .CreateLogger("MyLogger");
        return microsoftLogger;
    }

    private LoggingMetadata CreateMetadata(LoggerContextObject context)
    {
        return new LoggingMetadata($"{context.UniqueId}.txt");
    }

    public IEnumerable<LoggingMetadata> GetAllMetadata()
    {
        return _metadata.Values;
    }
}

public class LoggerRepositoryTests
{
    [Theory, AutoData]
    public void MultipleLoggersByContextObject(LoggerContextObject[] contexts)
    {
        try
        {
            var repository = new LoggerRepository();
            foreach (var context in contexts)
            {
                context.LoggingOptions.IsEnabled = true;
                var logger = repository.GetLogger(context);
                logger.LogInformation("Hello, " + context.UniqueId);
            }

            foreach (var context in contexts)
            {
                File.ReadAllText(context.UniqueId + ".txt").Should().Be("Hello, " + context.UniqueId);
            }
        }
        finally
        {
            foreach (var context in contexts)
            {
                File.Delete(context.UniqueId + ".txt");
            }
        }
    }
}
