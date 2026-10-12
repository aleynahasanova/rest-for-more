namespace RestForMore.Api.DTOs.Sync;

public class SyncResponseDto
{
    public bool Success { get; set; }

    public List<Guid> SyncedRoutineIds { get; set; } = [];

    public string? Message { get; set; }
}