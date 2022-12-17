var nativeWindowSettings = new NativeWindowSettings()
{
    Size = new Vector2i(800, 600),
    Title = "LearnOpenTK - Creating a Window",
    Flags = ContextFlags.ForwardCompatible, // For macOS compatability
};

// To create a new window, create a class that extends GameWindow, then call Run() on it.
using var window = new CreateWindow.Window(GameWindowSettings.Default, nativeWindowSettings);
window.Run();
