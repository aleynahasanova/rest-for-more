namespace RestForMore.Api.Models;

public class ProgramDay
{
    public Guid ProgramDayId { get; set; }

    public Guid ProgramId { get; set; }

    public int DayNumber { get; set; }

    public string? Title { get; set; }

    public string Content { get; set; } = string.Empty;

    public DateOnly ScheduledDate { get; set; }

    public string Timezone { get; set; } = string.Empty;

    public DateTime? OfferedAt { get; set; }

    public DateTime? OpenedAt { get; set; }

    public DateTime? CompletedAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public Program Program { get; set; } = null!;
}