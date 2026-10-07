namespace RestForMore.Api.Models;

public class ModeBlockedApp
{
    public Guid ModeBlockedAppId { get; set; }

    public Guid ModeId { get; set; }

    public string AppIdentifier { get; set; } = string.Empty;

    public string AppName { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }

    public DateTime? DeletedAt { get; set; }

    public Mode Mode { get; set; } = null!;
}