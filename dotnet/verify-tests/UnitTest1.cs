using Microsoft.Extensions.Logging;
using Serilog;
using VerifyTests;
using VerifyTests.Serilog;
using Xunit;


namespace verify_tests;

[UsesVerify]
public class UnitTest1
{
    [Fact]
    public async Task Open_and_read_Serilog_file_sink()
    {
        Directory.Delete("Logs", true);
        var logFilePath = $"Logs/logfile_.log";
        var serilogLogger = new LoggerConfiguration().MinimumLevel.Debug()
            .WriteTo.File(logFilePath, shared: true, rollingInterval: RollingInterval.Hour, outputTemplate: "{Message}{NewLine}")
            .CreateLogger();

        var logger = new LoggerFactory()
            .AddSerilog(serilogLogger)
            .CreateLogger("test");

        logger.LogInformation("Testing stuff");
        logger.LogInformation("Testing stuff some more");
        logger.LogInformation("that's nice");

        var filePath = Directory.GetFiles("Logs", "logfile_*.log").First();
        var logs = File.ReadAllText(filePath);

        await Verify(logs);
    }

    [Fact]
    public async Task Test1()
    {
        VerifySerilog.Initialize();
        RecordingLogger.Start();

        var logFilePath = $"Logs/logfile_.log";
        var serilogLogger = new LoggerConfiguration().MinimumLevel.Debug()
            .WriteTo.File(logFilePath, shared: true, rollingInterval: RollingInterval.Hour, outputTemplate: "{Message}{NewLine}")
            .CreateLogger();

        var logger = new LoggerFactory()
            .AddSerilog(serilogLogger)
            .CreateLogger("test");

        logger.LogInformation("Testing stuff");

        var result = Method();

        await Verify(result);
    }

    static string Method()
    {
        Log.Error("The Messages");
        return "Result";
    }
}
