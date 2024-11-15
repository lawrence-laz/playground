using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Serialization;
using FluentAssertions;

public class MyBaseJsonConverter : JsonConverter<MyBase>
{
    private readonly Dictionary<string, Type> TypeMap = new()
    {
        ["Foo"] = typeof(MyBase.Foo),
        ["Bar"] = typeof(MyBase.Bar),
    };

    public override MyBase Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        if (reader.TokenType == JsonTokenType.Null)
        {
            return null;
        }

        var readerAtStart = reader;

        using var jsonDocument = JsonDocument.ParseValue(ref reader);
        var jsonObject = jsonDocument.RootElement;

        var className = jsonObject.GetProperty("type").GetString();

        // See if that class can be deserialized or not
        if (!string.IsNullOrEmpty(className) && TypeMap.TryGetValue(className, out var targetType))
        {
            // Deserialize it
            return JsonSerializer.Deserialize(ref readerAtStart, targetType, options) as MyBase;
        }

        throw new NotSupportedException($"{className ?? "<unknown>"} can not be deserialized");
    }

    public override void Write(Utf8JsonWriter writer, MyBase value, JsonSerializerOptions options)
    {
        var node = JsonSerializer.SerializeToNode(value, value.GetType(), options);
        node["type"] = TypeMap.Single(pair => pair.Value == value.GetType()).Key;
        writer.WriteRawValue(node.ToJsonString());
    }
}

[JsonConverter(typeof(MyBaseJsonConverter))]
public abstract record MyBase
{
    public record Foo(string Name) : MyBase;
    public record Bar(string Title, int Age) : MyBase;
}

public class PolymorphicJsonSerialization
{
    [Fact]
    public void Deserialize()
    {
        var actualFoo = JsonSerializer.Deserialize<MyBase>("{\"type\":\"Foo\",\"Name\":\"Henlo\"}");
        actualFoo.Should().Be(new MyBase.Foo("Henlo"));
        var actualBar = JsonSerializer.Deserialize<MyBase>("{\"type\":\"Bar\",\"Title\":\"Goodbye\",\"Age\":123}");
        actualBar.Should().Be(new MyBase.Bar("Goodbye", 123));
    }

    [Fact]
    public void Serialize()
    {
        var actualFoo = JsonSerializer.Serialize<MyBase>(new MyBase.Foo("Henlo"));
        actualFoo.Should().Be("{\"Name\":\"Henlo\",\"type\":\"Foo\"}");
        var actualBar = JsonSerializer.Serialize<MyBase>(new MyBase.Bar("Goodbye", 123));
        actualBar.Should().Be("{\"Title\":\"Goodbye\",\"Age\":123,\"type\":\"Bar\"}");
    }
}

