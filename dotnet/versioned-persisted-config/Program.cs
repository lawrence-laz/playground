using System.Text.Json;
using AutoMapper;
using Microsoft.Extensions.Configuration;

Console.WriteLine($"cwd: {Directory.GetCurrentDirectory()}");
var configuration = new ConfigurationBuilder()
    .SetBasePath(Directory.GetCurrentDirectory())
    .AddJsonFile("config-v1.json", optional: false)
    .Build();

/* var configurationObject = GetConfigurationObject<ConfigV2>(configuration); */
var configurationMigrators = new ConfigurationMigrators();
configurationMigrators.Add(new ConfigurationV1Migrator());
var binder = new VersionedConfigurationBinder(
    configurationMigrators,
    configuration => configuration.GetSection(nameof(BaseConfiguration.Version)).Get<string>() switch
    {
        "1" => typeof(ConfigV1),
        "2" => typeof(ConfigV2),
        _ => throw new NotSupportedException()
    });
var configurationObject = binder.Get<ConfigV2>(configuration);
Console.WriteLine($"Configuration value {configurationObject.Foo}");
SaveConfiguration(configurationObject);

void SaveConfiguration(object configurationObject)
{
    var configurationObjectJson = JsonSerializer.Serialize(configurationObject);
    File.WriteAllText("config-new.json", configurationObjectJson);
}

T GetConfigurationObjectOld<T>(IConfiguration configuration) where T : BaseConfiguration, new()
{
    var version = configuration.GetSection(nameof(BaseConfiguration.Version)).Get<string>();
    BaseConfiguration originalConfiguration = version switch
    {
    "1" => new ConfigV1(),
    "2" => new ConfigV2(),
    _ => throw new NotSupportedException()
    };
    if (version == "1")
    {
        Console.WriteLine($"config version: {version}");
    }
    configuration.Bind(originalConfiguration);

    var mapperConfiguration = new MapperConfiguration(cfg =>
    {
        cfg.CreateMap<ConfigV1, ConfigV2>().ForMember(d => d.Foo, opt => opt.MapFrom(src => src.Fo));
    });
    mapperConfiguration.AssertConfigurationIsValid();
    var mapper = mapperConfiguration.CreateMapper();
    var expectedConfiguration = mapper.Map<T>(originalConfiguration);

    return expectedConfiguration;
}

public class ConfigurationV1Migrator : IConfigurationMigrator<ConfigV1, ConfigV2>
{
    public ConfigV2 Migrate(ConfigV1 source)
    {
        var mapperConfiguration = new MapperConfiguration(cfg =>
                {
                cfg.CreateMap<ConfigV1, ConfigV2>().ForMember(d => d.Foo, opt => opt.MapFrom(src => src.Fo));
                });
        mapperConfiguration.AssertConfigurationIsValid();
        var mapper = mapperConfiguration.CreateMapper();
        return mapper.Map<ConfigV2>(source);
    }
}

public abstract class BaseConfiguration
{
    public abstract string Version { get; }
}

public class ConfigV1 : BaseConfiguration
{
    public string Fo { get; set; }

    public override string Version => "1";
}

public class ConfigV2 : BaseConfiguration
{
    public string Foo { get; set; }

    public override string Version => "2";
}


