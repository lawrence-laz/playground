using System.Xml;
using System.Threading;
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
        Foo.Prop.Should().Be("FOO");
        Bar.Prop.Should().Be("BAR");
        Baz.Prop.Should().Be("BAZ");
    }
}
