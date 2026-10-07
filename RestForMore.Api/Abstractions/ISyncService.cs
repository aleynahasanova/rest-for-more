using RestForMore.Api.DTOs.Sync;

namespace RestForMore.Api.Abstractions;

public interface ISyncService
{
    Task<SyncResponseDto> SyncAsync(SyncRequestDto request);
}