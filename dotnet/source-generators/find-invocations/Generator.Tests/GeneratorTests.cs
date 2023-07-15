using System.Xml;
using System.Threading;
using System;
using FluentAssertions;
using Xunit;
using SourceGenerator;

namespace Generator.Tests;

// public class Foo
// {
// }

public class GeneratorTests
{
    [Fact]
    public void Generator_creates_Foo_class_with_static_Bar_property()
    {
        typeof(GeneratorTests).Assembly.GetTypes().Should().Contain(type => type.Name == "Foo");

        // SourceGenerator.MyBuilder.TargetType2<Foo>();
        var foo = Baa.Prop;
    }
}
