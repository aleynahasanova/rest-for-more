namespace RestForMore.Api.Models;

public class RoutineItem
{
    public Guid RoutineItemId { get; set; }

    public Guid RoutineId { get; set; }

    public string Title { get; set; } = string.Empty;

    public string? Description { get; set; }

    public TimeOnly? StartTime { get; set; }

    public int? DurationMinutes { get; set; }

    public int SortOrder { get; set; } = 0;

    public bool IsDefault { get; set; } = false;

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public DateTime? DeletedAt { get; set; }

    public Routine Routine { get; set; } = null!;
}