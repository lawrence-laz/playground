using FluentAssertions;

namespace flip_array;

public class UnitTest1
{
    public void FlipX(int[] buffer, int bytesPerPixel, int widthInPixels)
    {
        var heightInPixels = buffer.Length / bytesPerPixel / widthInPixels;
        var bytesPerRow = bytesPerPixel * widthInPixels;
        for (var y = 0; y < heightInPixels; y++)
        {
            for (var x = 0; x < widthInPixels / 2; x++)
            {
                for (var byteOffset = 0; byteOffset < bytesPerPixel; byteOffset++)
                {
                    var leftIndex = y * bytesPerRow + x * bytesPerPixel + byteOffset;
                    var rightIndex = y * bytesPerRow + (widthInPixels - x - 1) * bytesPerPixel + byteOffset;
                    (buffer[leftIndex], buffer[rightIndex]) = (buffer[rightIndex], buffer[leftIndex]);
                }
            }
        }
    }

    [Fact]
    public void FlipArray_When2BytesPerPixel()
    {
        var actual = new int[]
        {
            1,  2,  3,  4,  5,  6,  7,  8,
            9, 10, 11, 12, 13, 14, 15, 16,
        };

        var expected = new int[]
        {
            7,  8,  5,  6,  3,  4,  1,  2,
            15, 16, 13, 14, 11, 12, 9, 10,
        };

        FlipX(actual, 2, 4);

        actual.Should().BeEquivalentTo(expected, options => options.WithStrictOrdering());
    }

    [Fact]
    public void FlipArray_When1BytePerPixel()
    {
        var actual = new int[]
        {
            1,  2,  3,  4,  5,  6,  7,  8,
            9, 10, 11, 12, 13, 14, 15, 16,
        };

        var expected = new int[]
        {
            8,  7,  6,  5,  4,  3,  2,  1,
            16, 15, 14, 13, 12, 11, 10, 9,
        };

        FlipX(actual, 1, 8);

        actual.Should().BeEquivalentTo(expected, options => options.WithStrictOrdering());
    }
}
