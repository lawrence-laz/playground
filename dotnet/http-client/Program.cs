// See https://aka.ms/new-console-template for more information
using System.Text.Json;

var client = new HttpClient();
var response = await client.SendAsync(new HttpRequestMessage(HttpMethod.Get, "https://www.postman-echo.com/get"));
var content = await response.Content.ReadAsStringAsync();
var responseObject = JsonSerializer.Deserialize<PostmanResponse>(content);
System.Console.WriteLine(content);
System.Console.WriteLine($"URL: {responseObject.url}, host: {responseObject.headers.host}");

public record PostmanResponseHeaders(string host);
public record PostmanResponse(string url, PostmanResponseHeaders headers);
