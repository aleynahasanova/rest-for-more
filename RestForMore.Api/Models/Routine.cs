namespace RestForMore.Api.Models;

public class Routine
{
    public Guid RoutineId { get; set; }

    public Guid UserId { get; set; }

    public string Name { get; set; } = string.Empty;

    public string RoutineType { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }
    
    public DateTime? DeletedAt { get; set; }

    public User User { get; set; } = null!;

    public ICollection<RoutineItem> RoutineItems { get; set; }
     = new List<RoutineItem>();
}