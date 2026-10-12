using Microsoft.AspNetCore.Mvc;
using RestForMore.Api.Abstractions;
using RestForMore.Api.DTOs.Sync;

namespace RestForMore.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SyncController : ControllerBase
{
    private readonly ISyncService _syncService;

    public SyncController(ISyncService syncService)
    {
        _syncService = syncService;
    }

    [HttpPost]
    public async Task<ActionResult<SyncResponseDto>> Sync(
        [FromBody] SyncRequestDto request)
    {
        if (request.UserId == Guid.Empty)
        {
            return BadRequest("UserId is required.");
        }

        var response = await _syncService.SyncAsync(request);

        return Ok(response);
    }
}