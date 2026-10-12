namespace RestForMore.Api.DTOs.Sync;

public class SyncRequestDto
{
    public Guid UserId { get; set; }

    public List<RoutineSyncDto> Routines { get; set; } = [];
}