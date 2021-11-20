using SQLite;

[Table("Accounts")]
public class Account
{
    [PrimaryKey, AutoIncrement]
    public int Id { get; set; }
    [Indexed]
    public decimal Balance { get; set; }
    [Indexed]
    public string Currency { get; set; }
}
