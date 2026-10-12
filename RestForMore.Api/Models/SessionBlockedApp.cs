namespace RestForMore.Api.Models;

public class SessionBlockedApp
{
    public Guid SessionBlockedAppId { get; set; }

    public Guid SessionId { get; set; }

    public string AppIdentifier { get; set; } = string.Empty;

    public string AppName { get; set; } = string.Empty;

    public Session Session { get; set; } = null!;
}