using System.Linq;
using System;
using System.IO;
using Xunit;
using FluentAssertions;

namespace files;

public class UnitTest1
{
    [Fact]
    public void Getting_files_from_non_existing_directory_without_throwing()
    {
        var directoryPath = Path.Combine(Path.GetDirectoryName(typeof(UnitTest1).Assembly.Location), "foo");
        Action sut = () =>
        {
            var a = new DirectoryInfo(directoryPath);
            if (a.Exists)
            {
                a.GetFiles();
            }
        };

        sut.Should().NotThrow<Exception>();
    }

    [Fact]
    public void Getting_files_from_non_existing_directory_throws()
    {
        var directoryPath = Path.GetDirectoryName(typeof(UnitTest1).Assembly.Location);
        Action sut1 = () =>
        {
            var files = Directory.GetFiles(Path.Combine(directoryPath, "foo"));
        };
        Action sut2 = () =>
        {
            var files = new DirectoryInfo(Path.Combine(directoryPath, "foo")).GetFiles();
        };

        sut1.Should().Throw<Exception>();
        sut2.Should().Throw<Exception>();
    }
}
