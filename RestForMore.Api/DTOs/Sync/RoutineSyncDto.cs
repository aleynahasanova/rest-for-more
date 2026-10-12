namespace RestForMore.Api.DTOs.Sync;

public class RoutineSyncDto
{
    public Guid RoutineId { get; set; }
    public Guid UserId { get; set; }

    public string Name { get; set; } = string.Empty;
    public string RoutineType { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DateTime? DeletedAt { get; set; }
}