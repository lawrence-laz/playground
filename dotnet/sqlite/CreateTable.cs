using FluentAssertions;
using Xunit;

namespace sqlite
{
    public class CreateTable : BaseTest
    {
        [Fact]
        public void Create_table_is_idempotent()
        {
            // Arrange
            Database.CreateTable<Account>();

            // Act & Assert
            Database.Invoking(x => x.CreateTable<Account>()).Should().NotThrow();
        }
    }
}
