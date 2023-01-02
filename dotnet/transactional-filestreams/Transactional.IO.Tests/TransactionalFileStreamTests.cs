namespace Transactional.IO.Tests;

public class TransactionalFileStreamTests
{
    [Theory, AutoData]
    public void TransactionalFileStream_does_not_modify_file_if_Commit_is_not_called(
        string fileName,
        string expected,
        string contentAfter)
    {
        {
            // Arrange
            File.WriteAllText(fileName, expected);
            using var fileStream = new TransactionalFileStream(fileName, FileMode.Truncate);
            using var writer = new StreamWriter(fileStream);

            // Act
            writer.Write(contentAfter);
        }

        // Assert
        var actual = File.ReadAllText(fileName);
        actual.Should().Be(expected);
    }

    [Theory, AutoData]
    public void TransactionalFileStream_does_modify_file_when_Commit_is_called(
        string fileName,
        string contentBefore,
        string expected)
    {
        {
            // Arrange
            File.WriteAllText(fileName, contentBefore);
            using var fileStream = new TransactionalFileStream(fileName, FileMode.Truncate);
            using var writer = new StreamWriter(fileStream);

            // Act
            writer.Write(expected);
            fileStream.Commit();
        }

        // Assert
        var actual = File.ReadAllText(fileName);
        actual.Should().Be(expected);
    }
}
