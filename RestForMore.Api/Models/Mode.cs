namespace RestForMore.Api.Models;

public class Mode
{
    public Guid ModeId { get; set; }

    public Guid UserId { get; set; }

    public string Name { get; set; } = string.Empty;

    public string ModeType { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public DateTime? DeletedAt { get; set; }

    public User User { get; set; } = null!;

    public ICollection<ModeBlockedApp> BlockedApps { get; set; }
        = new List<ModeBlockedApp>();

    public ICollection<Session> Sessions { get; set; }
        = new List<Session>();
}