using System.Net.Http;
using System.Threading.Tasks;
using FluentAssertions;
using SQLite;
using Xunit;

namespace sqlite;

public class BinaryTest : BaseTest
{
    [Table("Entities")]
    public class Entity
    {
        [PrimaryKey, AutoIncrement]
        public int Id { get; set; }
        public byte[] Data { get; set; }
    }

    [Fact]
    public async Task Insert_row_with_binary_values()
    {
        // Arrange
        Database.CreateTable<Entity>();
        var image = await new HttpClient().GetByteArrayAsync("https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Cat03.jpg/481px-Cat03.jpg");
        Database.Insert(new Entity { Data = image });
        Database.Insert(new Entity { Data = new byte[] { 3, 4, 5 } });

        // Act
        var actual = Database.Table<Entity>().ToList();

        // Assert
        actual.Should().BeEquivalentTo(new[]
        {
            new Entity { Id = 1, Data = image },
            new Entity { Id = 2, Data = new byte[] { 3, 4, 5 } },
        });
    }
}
