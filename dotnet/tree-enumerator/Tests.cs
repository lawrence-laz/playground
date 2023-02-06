using System.Collections.Generic;
using System.Linq;
using FluentAssertions;
using Xunit;

public class DepthFirstIteratorTests
{
    private record Node(string Value, IEnumerable<Node> Children);

    private Node GetTree()
    {
        return new Node("0", new Node[]
        {
            new ("1", new Node[]
            {
                new ("4", new Node[]
                {
                }),
                new ("5", new Node[]
                {
                }),
            }),
            new ("2", new Node[]
            {
            }),
            new ("3", new Node[]
            {
                new ("6", new Node[]
                {
                }),
                new ("7", new Node[]
                {
                    new ("8", new Node[]
                    {
                    }),
                    new ("9", new Node[]
                    {
                    }),
                }),
            }),
        });
    }

    [Fact]
    public void Iterating_depth_first_visits_deepest_nodes_first()
    {
        // Arrange
        var tree = GetTree();
        var expected = "0379862154";

        // Act
        var actual = string.Join(
            "",
            TreeEnumerator
                .IterateDepthFirst(tree, node => node.Children)
                .Select(node => node.Value));

        // Assert
        actual.Should().Be(expected);
    }

    [Fact]
    public void Iterating_breadth_first_visits_each_node_per_level_before_going_to_next()
    {
        // Arrange
        var tree = GetTree();
        var expected = "0123456789";

        // Act
        var actual = string.Join(
            "",
            TreeEnumerator
                .IterateBreadthFirst(tree, node => node.Children)
                .Select(node => node.Value));

        // Assert
        actual.Should().Be(expected);
    }
}

