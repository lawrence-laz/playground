public class DeviceOptions
{
    public bool IsVirtual { get; set; }
}

public interface IDeviceApi
{

}

public interface IFooDeviceApi
{
    public void DoSomething(int handle, int speed);
}

public class FooDeviceApi : IFooDeviceApi
{
    public void DoSomething(int handle, int speed)
    {
        // This actually calls some 3rd party .dll or something
    }
}

public class FooVirtualDeviceApi : IFooDeviceApi
{
    public void DoSomething(int handle, int speed)
    {
        // This is just a simple virtual emulation
    }
}

public class FooDeviceWrapperApi : IFooDeviceApi
{
    private readonly FooDeviceApi api;
    private readonly DeviceOptions deviceOptions;
    private readonly FooVirtualDeviceApi virtualApi;

    // LoggingOptions

    public FooDeviceWrapperApi(
        DeviceOptions deviceOptions,
        FooDeviceApi api,
        FooVirtualDeviceApi virtualApi)
    {
        this.api = api;
        this.deviceOptions = deviceOptions;
        this.virtualApi = virtualApi;
    }

    public void DoSomething(int handle, int speed)
    {
        if (deviceOptions.IsVirtual)
        {
            virtualApi.DoSomething(handle, speed);
        }
        else
        {
            api.DoSomething(handle, speed);
        }
        // Log that a call was made to DeviceLoggerRepository
    }
}

// This could be injected into IDeviceApi implementations
// This could be done after introducing standard api stuff?
public class SerialPortClient
{
    private readonly SerialPortOptions options;

    public SerialPortClient(SerialPortOptions options)
    {
        this.options = options;
    }

    // Like HttpClient Polly stuff and some other things, like clearing maybe etc.
}

public class SerialPortOptions
{

}


public class FooDriver<FooDriverData> : IEthernetDriver
{
    public void Initialize(DeviceOptions device)
    {
        var data = (FooDriverData)device.DriverData;
        data.Api = deviceApiFactory.Create<IFooDeviceApi>(device);
        data.Api.Connect(..);
    }
}

