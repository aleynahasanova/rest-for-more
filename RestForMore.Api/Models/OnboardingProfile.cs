namespace RestForMore.Api.Models;

public class OnboardingProfile
{
    public Guid OnboardingProfileId { get; set; }

    public Guid UserId { get; set; }

    public string? AgeGroup { get; set; }

    public string? MainGoal { get; set; }

    public string? BiggestChallenge { get; set; }

    public string? PhoneUseInBed { get; set; }

    public int? PhoneFreeTargetMinutes { get; set; }

    public TimeOnly? ReminderTime { get; set; }

    public string? Rhythm { get; set; }

    public string? RestMoments { get; set; }

    public string? FeasibleStep { get; set; }

    public string? PreferredActivity { get; set; }

    public string? CustomActivity { get; set; }

    public string? ProductOwnership { get; set; }

    public int? OnboardingStep { get; set; }

    public string ProductExpectation { get; set; } = "UNKNOWN";

    public string? ProductIssue { get; set; }

    public bool WantsSupport { get; set; } = false;

    public DateTime? CompletedAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public User User { get; set; } = null!;
}