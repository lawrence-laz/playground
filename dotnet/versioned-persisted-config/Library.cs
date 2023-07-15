
using Microsoft.Extensions.Configuration;

public delegate Type ConfigurationTypeMap(IConfiguration configuration);

public sealed class VersionedConfigurationBinder
{
    public ConfigurationMigrators ConfigurationMigrators { get; }
    public ConfigurationTypeMap ConfigurationTypeMap { get; }

    public VersionedConfigurationBinder(
        ConfigurationMigrators configurationMigrators,
        ConfigurationTypeMap configurationTypeMap)
    {
        ConfigurationMigrators = configurationMigrators;
        ConfigurationTypeMap = configurationTypeMap;
    }

    public T Get<T>(IConfiguration configuration)
    {
        var currentConfigurationType = ConfigurationTypeMap(configuration);
        var currentConfigurationObject = Activator.CreateInstance(currentConfigurationType);
        configuration.Bind(currentConfigurationObject);

        if (typeof(T) == currentConfigurationType)
            return (T)currentConfigurationObject;

        do
        {
            var migrator = ConfigurationMigrators.GetBySource(currentConfigurationType) as IConfigurationMigrator;
            if (migrator is null)
                throw new Exception("Uh-oh...");

            currentConfigurationObject = migrator.Migrate(currentConfigurationObject);
            currentConfigurationType = currentConfigurationObject.GetType();
        }
        while(typeof(T) != currentConfigurationType);

        return (T)currentConfigurationObject;
    }
}

public sealed class ConfigurationMigrators
{
    private Dictionary<(Type Source, Type Target), IConfigurationMigrator> _migrators = new();

    public void Add<TSource, TTarget>(IConfigurationMigrator<TSource, TTarget> migrator)
    {
        _migrators.Add((typeof(TSource), typeof(TTarget)), migrator);
    }

    public IConfigurationMigrator<TSource, TTarget> Get<TSource, TTarget>()
    {
        return (IConfigurationMigrator<TSource, TTarget>)_migrators[(typeof(TSource), typeof(TTarget))];
    }

    public IConfigurationMigrator GetBySource(Type sourceType)
    {
        return _migrators.FirstOrDefault(x => x.Key.Source == sourceType).Value;
    }
}

public interface IConfigurationMigrator
{
    object Migrate(object source)
    {
        /* if (source is not TSource) */
        /*     throw new ArgumentException( */
        /*             $"Configuration migrator '{GetType().FullName}' can migrate " + */
        /*             $"objects of type '{typeof(TSource).FullName}' but recieved " + */
        /*             $"an object of type '{source.GetType().FullName}'. Make sure " + */
        /*             $"you are providing the correct configuration object and/or " + */
        /*             $" using the correct IConfigurationMigrator"); */

        return Migrate(source);
        // TODO: Shouldn't call itself, but rather the inherited type, how to do this...?
    }
}

public interface IConfigurationMigrator<TSource, TTarget> : IConfigurationMigrator
{
    TTarget Migrate(TSource source);
}


