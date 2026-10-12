using Microsoft.EntityFrameworkCore;
using RestForMore.Api.Abstractions;
using RestForMore.Api.Data;
using RestForMore.Api.DTOs.Sync;
using RestForMore.Api.Models;

namespace RestForMore.Api.Services;

public class SyncService : ISyncService
{
    private readonly AppDbContext _dbContext;

    public SyncService(AppDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<SyncResponseDto> SyncAsync(SyncRequestDto request)
    {
        var response = new SyncResponseDto();

        foreach (var routineDto in request.Routines)
        {
            // Safety check:
            // A routine in this request must belong to the same user.
            if (routineDto.UserId != request.UserId)
            {
                continue;
            }

            var existingRoutine = await _dbContext.Routines
                .FirstOrDefaultAsync(
                    r => r.RoutineId == routineDto.RoutineId
                );

            // Routine does not exist remotely yet -> INSERT.
            if (existingRoutine == null)
            {
                var routine = new Routine
                {
                    RoutineId = routineDto.RoutineId,
                    UserId = routineDto.UserId,
                    Name = routineDto.Name,
                    RoutineType = routineDto.RoutineType,
                    CreatedAt = routineDto.CreatedAt,
                    UpdatedAt = routineDto.UpdatedAt,
                    DeletedAt = routineDto.DeletedAt
                };

                _dbContext.Routines.Add(routine);

                response.SyncedRoutineIds.Add(routineDto.RoutineId);
                continue;
            }

            // Make sure an existing routine cannot be changed
            // through another user's sync request.
            if (existingRoutine.UserId != request.UserId)
            {
                continue;
            }

            // Determine the latest modification time.
            var incomingTimestamp =
                routineDto.DeletedAt ??
                routineDto.UpdatedAt ??
                routineDto.CreatedAt;

            var existingTimestamp =
                existingRoutine.DeletedAt ??
                existingRoutine.UpdatedAt ??
                existingRoutine.CreatedAt;

            // Update PostgreSQL only when the incoming local
            // version is at least as recent as the remote version.
            if (incomingTimestamp >= existingTimestamp)
            {
                existingRoutine.Name = routineDto.Name;
                existingRoutine.RoutineType = routineDto.RoutineType;
                existingRoutine.UpdatedAt = routineDto.UpdatedAt;
                existingRoutine.DeletedAt = routineDto.DeletedAt;
            }

            response.SyncedRoutineIds.Add(routineDto.RoutineId);
        }

        await _dbContext.SaveChangesAsync();

        response.Success = true;
        response.Message = "Sync completed successfully.";

        return response;
    }
}