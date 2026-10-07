namespace RestForMore.Api.Models;

public class Session
{
    public Guid SessionId { get; set; }

    public Guid ModeId { get; set; }

    public string Status { get; set; } = string.Empty;

    public int PlannedDurationSeconds { get; set; }

    public int? RemainingDurationSeconds { get; set; }

    public DateTime? StartedAt { get; set; }

    public DateTime? PausedAt { get; set; }

    public DateTime? EndedAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public DateTime? DeletedAt { get; set; }

    public Mode Mode { get; set; } = null!;

    public ICollection<SessionBlockedApp> BlockedApps { get; set; }
        = new List<SessionBlockedApp>();
}