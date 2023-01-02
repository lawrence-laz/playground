namespace Transactional.IO.Tests;

public class FileStreamTests
{
    [Theory, AutoData]
    public void FileStream_changes_file_contents_right_after_writing(
        string fileName,
        string contentBefore,
        string expectedContent)
    {
        {
            // Arrange
            File.WriteAllText(fileName, contentBefore);
            using var fileStream = new FileStream(fileName, FileMode.Open);
            using var writer = new StreamWriter(fileStream);

            // Act
            writer.Write(expectedContent);
            fileStream.Flush();
        }

        // Assert
        var contentAfter = File.ReadAllText(fileName);
        contentAfter.Should().Be(expectedContent);
    }
}

