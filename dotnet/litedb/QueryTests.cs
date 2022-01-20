namespace litedb;

public record Foo(string Bar);

public class QueryTests
{
    [Fact]
    public void Queries_are_equal_by_value()
    {
        var db = new LiteDatabase("Filename=test.db;");
        var query1 = db.GetCollection<Foo>().Query().Where(x => x.Bar == "Bar").ToString();
        var query2 = (db.GetCollection<Foo>().Query().Where(x => x.Bar == "Bar")).ToString();

        query1.Should().Be(query2);
    }
}
