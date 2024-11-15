// Need to make a synchronous request
#pragma warning disable SYSLIB0014

var request = System.Net.WebRequest.Create("https://postman-echo.com/get?message=hello-world");
var response = (System.Net.HttpWebResponse)request.GetResponse();
if (response.StatusCode == System.Net.HttpStatusCode.OK)
{
    using var responseStream = response.GetResponseStream();
    using var reader = new System.IO.StreamReader(responseStream);
    var responseFromServer = reader.ReadToEnd();
    Console.WriteLine(responseFromServer);
}
else
{
    Console.WriteLine("Error: " + response.StatusCode);
}
