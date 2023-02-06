using System;
using System.Collections.Generic;

public static class TreeEnumerator
{
    public static IEnumerable<T> IterateBreadthFirst<T>(
        T root,
        Func<T, IEnumerable<T>> getChildren)
    {
        var queue = new Queue<T>();
        queue.Enqueue(root);
        while (queue.TryDequeue(out var node))
        {
            foreach (var child in getChildren(node))
            {
                queue.Enqueue(child);
            }
            yield return node;
        }
    }

    public static IEnumerable<T> IterateDepthFirst<T>(
        T root,
        Func<T, IEnumerable<T>> getChildren)
    {
        var stack = new Stack<T>();
        stack.Push(root);
        while (stack.TryPop(out var node))
        {
            yield return node;
            foreach (var child in getChildren(node))
            {
                stack.Push(child);
            }
        }
    }
}

