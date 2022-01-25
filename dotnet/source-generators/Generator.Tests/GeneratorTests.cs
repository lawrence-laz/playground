using System;
using FluentAssertions;
using Xunit;

namespace Generator.Tests;

public class GeneratorTests
{
    [Fact]
    public void Generator_creates_Foo_class_with_static_Bar_property()
    {
        typeof(GeneratorTests).Assembly.GetTypes().Should().Contain(type => type.Name == "Foo");
        Foo.Bar.Should().Be("BAR");
    }
}
