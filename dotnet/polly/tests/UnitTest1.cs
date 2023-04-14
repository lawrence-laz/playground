using FluentAssertions;
using Polly;
using Polly.CircuitBreaker;

namespace tests;

public class UnitTest1
{
    private static int _counter;

    [Fact]
    public void Circuit_breaker_with_exception()
    {
        var circuitBreaker = Policy
            // .HandleResult<Exception>(e => true)
            .HandleResult<int>(_ => true)
            .AdvancedCircuitBreaker(
                failureThreshold: 1,
                samplingDuration: TimeSpan.FromSeconds(1),
                minimumThroughput: 2,
                durationOfBreak: TimeSpan.FromSeconds(1));

        circuitBreaker.Execute(IncrementCounter);
        circuitBreaker.Execute(IncrementCounter);
        circuitBreaker.Invoking(x => x.Execute(IncrementCounter)).Should().Throw<BrokenCircuitException>();

        _counter.Should().Be(2);
    }

    [Fact]
    public void Circuit_breaker_without_exception()
    {
        var circuitBreaker = Policy
            // .HandleResult<Exception>(e => true)
            .HandleResult<int>(_ => true)
            .AdvancedCircuitBreaker(
                failureThreshold: 1,
                samplingDuration: TimeSpan.FromSeconds(1),
                minimumThroughput: 2,
                durationOfBreak: TimeSpan.FromSeconds(1));

        circuitBreaker.Execute(IncrementCounter);
        circuitBreaker.ExecuteAndCapture(IncrementCounter);
        circuitBreaker.ExecuteAndCapture(IncrementCounter);

        _counter.Should().Be(2);
    }

    private int IncrementCounter()
    {
        ++_counter;
        return _counter;
    }
}

