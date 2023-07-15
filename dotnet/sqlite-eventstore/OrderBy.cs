using System.IO;
using FluentAssertions;
using SQLite;
using Xunit;

public class OrderBy : BaseTest
{
    [Fact]
    public void Ordering_by_two_columns()
    {
        // Arrange
        Database.CreateTable<Account>();
        Database.Insert(new Account { Id = 1, Balance = 100, Currency = "USD" });
        Database.Insert(new Account { Id = 2, Balance = 100, Currency = "EUR" });
        Database.Insert(new Account { Id = 3, Balance = 999, Currency = "USD" });
        Database.Insert(new Account { Id = 4, Balance = 999, Currency = "EUR" });

        // Act
        var actual = Database.Table<Account>()
            .OrderBy(x => x.Currency)
            .ThenByDescending(x => x.Balance)
            .ToList();

        // Assert
        actual.Should().BeEquivalentTo(new[]
        {
            new Account { Id = 4, Balance = 999, Currency = "EUR" },
            new Account { Id = 2, Balance = 100, Currency = "EUR" },
            new Account { Id = 3, Balance = 999, Currency = "USD" },
            new Account { Id = 1, Balance = 100, Currency = "USD" },
        });
    }

    [Fact]
    public void Ordering_should_go_first_before_take()
    {
        // Arrange
        Database.CreateTable<Account>();
        Database.Insert(new Account { Id = 1, Balance = 222, Currency = "USD" });
        Database.Insert(new Account { Id = 2, Balance = 111, Currency = "EUR" });
        Database.Insert(new Account { Id = 3, Balance = 444, Currency = "USD" });
        Database.Insert(new Account { Id = 4, Balance = 333, Currency = "EUR" });

        // Act
        var actual = Database.Table<Account>()
            .Where(x => x.Currency != "USD")
            .OrderBy(x => x.Balance)
            .Take(2)
            .ToList();

        // Assert
        actual.Should().BeEquivalentTo(new[]
        {
            new Account { Id = 2, Balance = 111, Currency = "EUR" },
            new Account { Id = 4, Balance = 333, Currency = "EUR" },
        });
    }

    [Fact]
    public void Ordering_foes_before_take_even_if_take_is_first()
    {
        // Arrange
        Database.CreateTable<Account>();
        Database.Insert(new Account { Id = 1, Balance = 222, Currency = "USD" });
        Database.Insert(new Account { Id = 2, Balance = 111, Currency = "EUR" });
        Database.Insert(new Account { Id = 3, Balance = 444, Currency = "USD" });
        Database.Insert(new Account { Id = 4, Balance = 333, Currency = "EUR" });

        // Act
        var actual = Database.Table<Account>()
            .Take(2)
            .Where(x => x.Currency != "USD")
            .OrderBy(x => x.Balance)
            .ToList();

        // Assert
        actual.Should().BeEquivalentTo(new[]
        {
            new Account { Id = 2, Balance = 111, Currency = "EUR" },
            new Account { Id = 4, Balance = 333, Currency = "EUR" },
        });
    }
}
