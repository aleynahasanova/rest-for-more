namespace RestForMore.Api.Models;

public class Program
{
    public Guid ProgramId { get; set; }

    public Guid UserId { get; set; }

    public DateOnly StartDate { get; set; }

    public int CurrentDay { get; set; } = 1;

    public string Status { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public User User { get; set; } = null!;

    public ICollection<ProgramDay> ProgramDays { get; set; }
        = new List<ProgramDay>();
}