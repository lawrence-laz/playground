using Microsoft.Extensions.Logging;

public abstract class BaseIntegrationTest : IDisposable
{
    protected LoggerRepository LoggerRepository = new();

    public void Arrange(LoggerContextObject context)
    {
        // Some common integration arrangement here...
    }

    public string GetLogs(LoggerContextObject context)
    {
        return File.ReadAllText(LoggerRepository.GetMetadata(context).LogFileName);
    }

    public void AssertLogs(LoggerContextObject context, string expectedPath)
    {
        GetLogs(context).Should().Be(File.ReadAllText(expectedPath));
    }

    public void Dispose()
    {
        foreach (var loggerMetadata in LoggerRepository.GetAllMetadata())
        {
            File.Delete(loggerMetadata.LogFileName);
        }
    }
}

public class TestWithLoggerRepository : BaseIntegrationTest
{
    [Fact]
    // Short, standard, simple, provide config, run the command under test, assert what it did.
    public void ExampleTestUsingLoggerRepository()
    {
        // Arrange
        var context = new LoggerContextObject(
            "Thing under test",
            new() { IsEnabled = true }
        );
        Arrange(context);

        // Act
        // Execute some mediator command here
        LoggerRepository.GetLogger(context).LogInformation("I did this");
        LoggerRepository.GetLogger(context).LogInformation("And I did that");

        // Assert
        AssertLogs(context, "Expected.txt");
    }
}

