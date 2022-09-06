using System.Text.Json;
using FluentAssertions;
using FluentAssertions.Extensions;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Configuration.Json;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;

namespace reload_config_when_changes;

public class MyOptions
{
    public string MyProperty { get; set; } = string.Empty;
}

public class UnitTest1
{
    [Fact(Skip = "failed attempt")]
    public async Task Load_json_configuration_and_get_modifications_on_file_to_represent_on_binded_options()
    {
        // Given two json files
        await File.WriteAllTextAsync("foo.json", @"{""MyProperty"":""foo""}");
        await File.WriteAllTextAsync("bar.json", @"{""MyProperty"":""bar""}");

        // We can set up host environment to use configuration from one of them
        var host = new HostBuilder()
            .ConfigureAppConfiguration((context, config) =>
                    config.AddJsonFile("foo.json", optional: false, reloadOnChange: true))
            .ConfigureServices((context, services) =>
                    services.Configure<MyOptions>(context.Configuration))
            .Build();

        // Then we can resolve strongly typed options to retreive values from the files
        var options = host.Services.GetRequiredService<IOptionsMonitor<MyOptions>>();
        options.CurrentValue.MyProperty.Should().Be("foo");

        // If json files changes, the value in strongly typed object changes as well
        await File.WriteAllTextAsync("foo.json", @"{""MyProperty"":""foofoo""}");
        await Task.Delay(TimeSpan.FromSeconds(1)); // Need to wait a bit because of FileConfigurationSource.ReloadDelay
        options.CurrentValue.MyProperty.Should().Be("foofoo");

        // But can we change config from foo.json to bar.json without rebuilding host?
        // Not really, because JsonConfigurationSource is a readonly property.
        // We need to have a mutable configuration source and provider implementation.
        // Or maybe we can change .Path in Source object, and Provider uses an instance of it?
        // Let's try it...
    }

    [Fact]
    public async Task Loading_config_from_one_json_file_then_the_other_using_same_provider()
    {
        // Given two json files
        await File.WriteAllTextAsync("foo.json", @"{""MyProperty"":""foo""}");
        await File.WriteAllTextAsync("bar.json", @"{""MyProperty"":""bar""}");

        // We can set up host environment to use configuration from one of them
        // Creating configuration source ourselves this time, so we could modify it later
        var source = new JsonConfigurationSource
        {
            Path = "foo.json",
            ReloadOnChange = true,
            Optional = false
        };

        var host = new HostBuilder()
            .ConfigureAppConfiguration((context, config) =>
                    config.Add(source))
            .ConfigureServices((context, services) =>
                    services.Configure<MyOptions>(context.Configuration))
            .Build();

        // Then we can resolve strongly typed options to retreive values from the files
        var options = host.Services.GetRequiredService<IOptionsMonitor<MyOptions>>();
        options.CurrentValue.MyProperty.Should().Be("foo");

        // If json files changes, the value in strongly typed object changes as well
        await File.WriteAllTextAsync("foo.json", @"{""MyProperty"":""foofoo""}");
        await Task.Delay(TimeSpan.FromSeconds(1)); // Need to wait a bit because of FileConfigurationSource.ReloadDelay
        options.CurrentValue.MyProperty.Should().Be("foofoo");

        // Now need to set new path on source and reload configuration.
        source.Path = "bar.json";
        var configuration = host.Services.GetRequiredService<IConfiguration>() as IConfigurationRoot;
        configuration.Reload();

        // Value is updated without reconfiguring host or recreating options.
        options.CurrentValue.MyProperty.Should().Be("bar");

        // Now if I modify the options and persist them back to file, I would expect that to trigger a reload
        // creating a fully functional persisted user configuration.
        options.CurrentValue.MyProperty = "baz";

        // Modifying one options should not change other right away
        var otherOptions = host.Services.GetRequiredService<IOptions<MyOptions>>();
        otherOptions.Value.MyProperty.Should().NotBe("baz");

        // But if I save first options to file, it should reload all options
        var newString = JsonSerializer.Serialize(options.CurrentValue);
        await File.WriteAllTextAsync("bar.json", newString);
        configuration.Reload();
        await Task.Delay(TimeSpan.FromSeconds(1)); // Waiting for a bit once again, because of FileConfigurationSource.ReloadDelay
        configuration.GetValue<string>("MyProperty").Should().Be("baz");
        var optionsAfterChanges = host.Services.GetRequiredService<IOptionsSnapshot<MyOptions>>();
        optionsAfterChanges.Value.MyProperty.Should().Be("baz");

        // There is a small catch though, notice that otherOptions is IOptions<>
        // while optionsAfterChanges is IOptionsSnapshot<>.
        // They have single instance lifecycle (singleton/scoped).
        // So saving changes to file doesn't really require reloading 
        // in this case, as changing instance is the only instance that is being changed.
        // But it is required cases with multiple scopes.
        optionsAfterChanges.Value.Should().NotBe(otherOptions.Value);
        optionsAfterChanges.Value.Should().Be(host.Services.GetRequiredService<IOptionsSnapshot<MyOptions>>().Value);
    }
}

