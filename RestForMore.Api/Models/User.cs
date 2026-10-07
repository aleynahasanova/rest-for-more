namespace RestForMore.Api.Models;

public class User
{
    public Guid UserId { get; set; }

    public string Email { get; set; } = string.Empty;

    public string PasswordHash { get; set; } = string.Empty;

    public string FirstName { get; set; } = string.Empty;

    public string Username { get; set; } = string.Empty;

    public bool MarketingConsent { get; set; } = false;

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

     public OnboardingProfile? OnboardingProfile { get; set; }

    public ICollection<Routine> Routines { get; set; }
        = new List<Routine>();

    public ICollection<Mode> Modes { get; set; }
        = new List<Mode>();

    public ICollection<Program> Programs { get; set; }
        = new List<Program>();
}