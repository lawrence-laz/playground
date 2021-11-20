using System;
using System.IO;
using SQLite;

public class BaseTest
{
    protected SQLiteConnection Database { get; init; }

    public BaseTest()
    {
        Database = new SQLiteConnection(Path.Combine(Directory.GetCurrentDirectory(), $"{Guid.NewGuid()}.db"));
    }

    ~BaseTest()
    {
        File.Delete(Database.DatabasePath);
    }
}
