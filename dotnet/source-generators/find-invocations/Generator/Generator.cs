using System;

using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp.Syntax;

// TODO: hello
// HACK: fff
// FIX: fff

namespace SourceGenerator
{
    public interface IFooInterface
    {
        double X { get; }
        double Y { get; }
    }

    public class MyBuilder
    {
        public static void TargetType<T>()
        {
            Console.WriteLine($"MyBuilder.TargetType<{typeof(T).Name}>");
        }
    }



    public class MySyntaxReceiver : ISyntaxReceiver
    {
        public ClassDeclarationSyntax ClassToAugment { get; private set; }

        public void OnVisitSyntaxNode(SyntaxNode syntaxNode)
        {
            // Business logic to decide what we're interested in g
            if (syntaxNode is InvocationExpressionSyntax syntax)
            {
                // ClassToAugment = cds;
            }
        }
    }

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
                "public class Foo { public static string Prop => \"FOO\"; } " +
                "public class Bar { public static string Prop => \"BAR\"; } " +
                "public class Baa { public static string Prop => \"BAZ\"; } "
                );
        }
    }
}
