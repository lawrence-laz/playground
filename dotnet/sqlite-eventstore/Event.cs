using SQLite;

public enum EventAction
{
    None = 0,
    Start,
    Stop
}

public enum EventType
{
    None = 0,
}

[Table("Events")]
public class Event
{
    [PrimaryKey, AutoIncrement]
    public int Id { get; set; }
    [Indexed]
    public EventAction Type { get; set; }
    public string 
}
