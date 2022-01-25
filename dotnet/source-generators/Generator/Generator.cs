using Microsoft.CodeAnalysis;

namespace SourceGenerator
{
    [Generator]
    public class Generator : ISourceGenerator
    {
        public void Initialize(GeneratorInitializationContext context)
        {
        }

        public void Execute(GeneratorExecutionContext context)
        {
            context.AddSource(
                "generated.cs",
                "public class Foo { public static string Bar => \"BAR\"; }");
        }
    }
}
