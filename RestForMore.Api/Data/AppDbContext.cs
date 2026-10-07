using Microsoft.EntityFrameworkCore;
using RestForMore.Api.Models;
using ProgramEntity = RestForMore.Api.Models.Program;

namespace RestForMore.Api.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users { get; set; }

    public DbSet<OnboardingProfile> OnboardingProfiles { get; set; }

    public DbSet<Routine> Routines { get; set; }

    public DbSet<RoutineItem> RoutineItems { get; set; }

    public DbSet<Mode> Modes { get; set; }

    public DbSet<ModeBlockedApp> ModeBlockedApps { get; set; }

    public DbSet<Session> Sessions { get; set; }

    public DbSet<SessionBlockedApp> SessionBlockedApps { get; set; }

    public DbSet<ProgramEntity> Programs { get; set; }

    public DbSet<ProgramDay> ProgramDays { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<User>(entity =>
        {
            entity.ToTable("users");

            entity.HasKey(user => user.UserId);

            entity.Property(user => user.UserId)
                .HasColumnName("user_id");

            entity.Property(user => user.Email)
                .HasColumnName("email")
                .HasMaxLength(255)
                .IsRequired();

            entity.HasIndex(user => user.Email)
                .IsUnique();

            entity.Property(user => user.PasswordHash)
                .HasColumnName("password_hash")
                .HasMaxLength(255)
                .IsRequired();

            entity.Property(user => user.FirstName)
                .HasColumnName("first_name")
                .HasMaxLength(100)
                .IsRequired();

            entity.Property(user => user.Username)
                .HasColumnName("username")
                .HasMaxLength(50)
                .IsRequired();

            entity.HasIndex(user => user.Username)
                .IsUnique();

            entity.Property(user => user.MarketingConsent)
                .HasColumnName("marketing_consent")
                .HasDefaultValue(false)
                .IsRequired();

            entity.Property(user => user.CreatedAt)
                .HasColumnName("created_at")
                .IsRequired();

            entity.Property(user => user.UpdatedAt)
                .HasColumnName("updated_at");
        });

        modelBuilder.Entity<OnboardingProfile>(entity =>
    {
        entity.ToTable("onboarding_profiles");

        entity.HasKey(profile => profile.OnboardingProfileId);

        entity.Property(profile => profile.OnboardingProfileId)
            .HasColumnName("onboarding_profile_id");

        entity.Property(profile => profile.UserId)
            .HasColumnName("user_id")
            .IsRequired();

        entity.Property(profile => profile.AgeGroup)
            .HasColumnName("age_group")
            .HasMaxLength(20);

        entity.Property(profile => profile.MainGoal)
            .HasColumnName("main_goal")
            .HasMaxLength(100);

        entity.Property(profile => profile.BiggestChallenge)
            .HasColumnName("biggest_challenge")
            .HasMaxLength(100);

        entity.Property(profile => profile.PhoneUseInBed)
            .HasColumnName("phone_use_in_bed")
            .HasMaxLength(30);

        entity.Property(profile => profile.PhoneFreeTargetMinutes)
            .HasColumnName("phone_free_target_minutes");

        entity.Property(profile => profile.ReminderTime)
            .HasColumnName("reminder_time");

        entity.Property(profile => profile.Rhythm)
            .HasColumnName("rhythm");

        entity.Property(profile => profile.RestMoments)
            .HasColumnName("rest_moments");

        entity.Property(profile => profile.FeasibleStep)
            .HasColumnName("feasible_step");

        entity.Property(profile => profile.PreferredActivity)
            .HasColumnName("preferred_activity");

        entity.Property(profile => profile.CustomActivity)
            .HasColumnName("custom_activity");

        entity.Property(profile => profile.ProductOwnership)
            .HasColumnName("product_ownership");

        entity.Property(profile => profile.OnboardingStep)
            .HasColumnName("onboarding_step");

        entity.Property(profile => profile.ProductExpectation)
            .HasColumnName("product_expectation")
            .HasMaxLength(30)
            .HasDefaultValue("UNKNOWN")
            .IsRequired();

        entity.Property(profile => profile.ProductIssue)
            .HasColumnName("product_issue")
            .HasMaxLength(255);

        entity.Property(profile => profile.WantsSupport)
            .HasColumnName("wants_support")
            .HasDefaultValue(false)
            .IsRequired();

        entity.Property(profile => profile.CompletedAt)
            .HasColumnName("completed_at");

        entity.Property(profile => profile.CreatedAt)
            .HasColumnName("created_at")
            .IsRequired();

        entity.Property(profile => profile.UpdatedAt)
            .HasColumnName("updated_at");

        entity.HasOne(profile => profile.User)
            .WithOne(user => user.OnboardingProfile)
            .HasForeignKey<OnboardingProfile>(profile => profile.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    });

    modelBuilder.Entity<Routine>(entity =>
    {
        entity.ToTable("routines");

        entity.HasKey(routine => routine.RoutineId);

        entity.Property(routine => routine.RoutineId)
            .HasColumnName("routine_id");

        entity.Property(routine => routine.UserId)
            .HasColumnName("user_id")
            .IsRequired();

        entity.Property(routine => routine.Name)
            .HasColumnName("name")
            .HasMaxLength(100)
            .IsRequired();

        entity.Property(routine => routine.RoutineType)
            .HasColumnName("routine_type")
            .HasMaxLength(20)
            .IsRequired();

        entity.Property(routine => routine.CreatedAt)
            .HasColumnName("created_at")
            .IsRequired();

        entity.Property(routine => routine.UpdatedAt)
            .HasColumnName("updated_at");

        entity.Property(e => e.DeletedAt)
            .HasColumnName("deleted_at");

        entity.HasOne(routine => routine.User)
            .WithMany(user => user.Routines)
            .HasForeignKey(routine => routine.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    });
    // ------------------------------------------
    // ROUTINE ITEMS
    // ------------------------------------------

    modelBuilder.Entity<RoutineItem>(entity =>
    {
        entity.ToTable("routine_items");

        entity.HasKey(item => item.RoutineItemId);

        entity.Property(item => item.RoutineItemId)
            .HasColumnName("routine_item_id");

        entity.Property(item => item.RoutineId)
            .HasColumnName("routine_id")
            .IsRequired();

        entity.Property(item => item.Title)
            .HasColumnName("title")
            .HasMaxLength(150)
            .IsRequired();

        entity.Property(item => item.Description)
            .HasColumnName("description");

        entity.Property(item => item.StartTime)
            .HasColumnName("start_time");

        entity.Property(item => item.DurationMinutes)
            .HasColumnName("duration_minutes");

        entity.Property(item => item.SortOrder)
            .HasColumnName("sort_order")
            .HasDefaultValue(0)
            .IsRequired();

        entity.Property(item => item.IsDefault)
            .HasColumnName("is_default")
            .HasDefaultValue(false)
            .IsRequired();

        entity.Property(item => item.CreatedAt)
            .HasColumnName("created_at")
            .IsRequired();

        entity.Property(item => item.UpdatedAt)
            .HasColumnName("updated_at");

        entity.Property(e => e.DeletedAt)
            .HasColumnName("deleted_at");    

        entity.HasOne(item => item.Routine)
            .WithMany(routine => routine.RoutineItems)
            .HasForeignKey(item => item.RoutineId)
            .OnDelete(DeleteBehavior.Cascade);
    });


    // ------------------------------------------
    // MODES
    // ------------------------------------------

    modelBuilder.Entity<Mode>(entity =>
    {
        entity.ToTable("modes");

        entity.HasKey(mode => mode.ModeId);

        entity.Property(mode => mode.ModeId)
            .HasColumnName("mode_id");

        entity.Property(mode => mode.UserId)
            .HasColumnName("user_id")
            .IsRequired();

        entity.Property(mode => mode.Name)
            .HasColumnName("name")
            .HasMaxLength(100)
            .IsRequired();

        entity.Property(mode => mode.ModeType)
            .HasColumnName("mode_type")
            .HasMaxLength(20)
            .IsRequired();

        entity.Property(mode => mode.CreatedAt)
            .HasColumnName("created_at")
            .IsRequired();

        entity.Property(mode => mode.UpdatedAt)
            .HasColumnName("updated_at");

        entity.Property(e => e.DeletedAt)
            .HasColumnName("deleted_at");

        entity.HasOne(mode => mode.User)
            .WithMany(user => user.Modes)
            .HasForeignKey(mode => mode.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    });


    // ------------------------------------------
    // MODE BLOCKED APPS
    // ------------------------------------------

    modelBuilder.Entity<ModeBlockedApp>(entity =>
    {
        entity.ToTable("mode_blocked_apps");

        entity.HasKey(blockedApp => blockedApp.ModeBlockedAppId);

        entity.Property(blockedApp => blockedApp.ModeBlockedAppId)
            .HasColumnName("mode_blocked_app_id");

        entity.Property(blockedApp => blockedApp.ModeId)
            .HasColumnName("mode_id")
            .IsRequired();

        entity.Property(blockedApp => blockedApp.AppIdentifier)
            .HasColumnName("app_identifier")
            .HasMaxLength(255)
            .IsRequired();

        entity.Property(blockedApp => blockedApp.AppName)
            .HasColumnName("app_name")
            .HasMaxLength(150)
            .IsRequired();

        entity.Property(blockedApp => blockedApp.CreatedAt)
            .HasColumnName("created_at")
            .IsRequired();

        entity.Property(e => e.DeletedAt)
            .HasColumnName("deleted_at");

        entity.HasIndex(blockedApp => new
        {
            blockedApp.ModeId,
            blockedApp.AppIdentifier
        })
        .IsUnique();

        entity.HasOne(blockedApp => blockedApp.Mode)
            .WithMany(mode => mode.BlockedApps)
            .HasForeignKey(blockedApp => blockedApp.ModeId)
            .OnDelete(DeleteBehavior.Cascade);
    });


    // ------------------------------------------
    // SESSIONS
    // ------------------------------------------

    modelBuilder.Entity<Session>(entity =>
    {
        entity.ToTable("sessions");

        entity.HasKey(session => session.SessionId);

        entity.Property(session => session.SessionId)
            .HasColumnName("session_id");

        entity.Property(session => session.ModeId)
            .HasColumnName("mode_id")
            .IsRequired();

        entity.Property(session => session.Status)
            .HasColumnName("status")
            .HasMaxLength(30)
            .IsRequired();

        entity.Property(session => session.PlannedDurationSeconds)
            .HasColumnName("planned_duration_seconds")
            .IsRequired();

        entity.Property(session => session.RemainingDurationSeconds)
            .HasColumnName("remaining_duration_seconds");

        entity.Property(session => session.StartedAt)
            .HasColumnName("started_at");

        entity.Property(session => session.PausedAt)
            .HasColumnName("paused_at");

        entity.Property(session => session.EndedAt)
            .HasColumnName("ended_at");

        entity.Property(session => session.CreatedAt)
            .HasColumnName("created_at")
            .IsRequired();

        entity.Property(session => session.UpdatedAt)
            .HasColumnName("updated_at");

        entity.Property(e => e.DeletedAt)
            .HasColumnName("deleted_at");

        entity.HasOne(session => session.Mode)
            .WithMany(mode => mode.Sessions)
            .HasForeignKey(session => session.ModeId)
            .OnDelete(DeleteBehavior.Cascade);
    });


    // ------------------------------------------
    // SESSION BLOCKED APPS
    // ------------------------------------------

    modelBuilder.Entity<SessionBlockedApp>(entity =>
    {
        entity.ToTable("session_blocked_apps");

        entity.HasKey(blockedApp => blockedApp.SessionBlockedAppId);

        entity.Property(blockedApp => blockedApp.SessionBlockedAppId)
            .HasColumnName("session_blocked_app_id");

        entity.Property(blockedApp => blockedApp.SessionId)
            .HasColumnName("session_id")
            .IsRequired();

        entity.Property(blockedApp => blockedApp.AppIdentifier)
            .HasColumnName("app_identifier")
            .HasMaxLength(255)
            .IsRequired();

        entity.Property(blockedApp => blockedApp.AppName)
            .HasColumnName("app_name")
            .HasMaxLength(150)
            .IsRequired();

        entity.HasIndex(blockedApp => new
        {
            blockedApp.SessionId,
            blockedApp.AppIdentifier
        })
        .IsUnique();

        entity.HasOne(blockedApp => blockedApp.Session)
            .WithMany(session => session.BlockedApps)
            .HasForeignKey(blockedApp => blockedApp.SessionId)
            .OnDelete(DeleteBehavior.Cascade);
    });


    // ------------------------------------------
    // PROGRAMS
    // ------------------------------------------

    modelBuilder.Entity<ProgramEntity>(entity =>
    {
        entity.ToTable("programs");

        entity.HasKey(program => program.ProgramId);

        entity.Property(program => program.ProgramId)
            .HasColumnName("program_id");

        entity.Property(program => program.UserId)
            .HasColumnName("user_id")
            .IsRequired();

        entity.Property(program => program.StartDate)
            .HasColumnName("start_date")
            .IsRequired();

        entity.Property(program => program.CurrentDay)
            .HasColumnName("current_day")
            .HasDefaultValue(1)
            .IsRequired();

        entity.Property(program => program.Status)
            .HasColumnName("status")
            .HasMaxLength(30)
            .IsRequired();

        entity.Property(program => program.CreatedAt)
            .HasColumnName("created_at")
            .IsRequired();

        entity.Property(program => program.UpdatedAt)
            .HasColumnName("updated_at");

        entity.HasOne(program => program.User)
            .WithMany(user => user.Programs)
            .HasForeignKey(program => program.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    });


    // ------------------------------------------
    // PROGRAM DAYS
    // ------------------------------------------

    modelBuilder.Entity<ProgramDay>(entity =>
    {
        entity.ToTable("program_days");

        entity.HasKey(day => day.ProgramDayId);

        entity.Property(day => day.ProgramDayId)
            .HasColumnName("program_day_id");

        entity.Property(day => day.ProgramId)
            .HasColumnName("program_id")
            .IsRequired();

        entity.Property(day => day.DayNumber)
            .HasColumnName("day_number")
            .IsRequired();

        entity.Property(day => day.Title)
            .HasColumnName("title");

        entity.Property(day => day.Content)
            .HasColumnName("content")
            .IsRequired();

        entity.Property(day => day.ScheduledDate)
            .HasColumnName("scheduled_date")
            .IsRequired();

        entity.Property(day => day.Timezone)
            .HasColumnName("timezone")
            .IsRequired();

        entity.Property(day => day.OfferedAt)
            .HasColumnName("offered_at");

        entity.Property(day => day.OpenedAt)
            .HasColumnName("opened_at");

        entity.Property(day => day.CompletedAt)
            .HasColumnName("completed_at");

        entity.Property(day => day.CreatedAt)
            .HasColumnName("created_at")
            .IsRequired();

        entity.Property(day => day.UpdatedAt)
            .HasColumnName("updated_at");

        entity.HasIndex(day => new
        {
            day.ProgramId,
            day.DayNumber
        })
        .IsUnique();

        entity.HasOne(day => day.Program)
            .WithMany(program => program.ProgramDays)
            .HasForeignKey(day => day.ProgramId)
            .OnDelete(DeleteBehavior.Cascade);
    });
    }
} 