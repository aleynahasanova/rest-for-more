using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace RestForMore.Api.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "users",
                columns: table => new
                {
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    email = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    password_hash = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    first_name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    username = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    marketing_consent = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_users", x => x.user_id);
                });

            migrationBuilder.CreateTable(
                name: "modes",
                columns: table => new
                {
                    mode_id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    mode_type = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_modes", x => x.mode_id);
                    table.ForeignKey(
                        name: "FK_modes_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "onboarding_profiles",
                columns: table => new
                {
                    onboarding_profile_id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    age_group = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    main_goal = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    biggest_challenge = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    phone_use_in_bed = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: true),
                    phone_free_target_minutes = table.Column<int>(type: "integer", nullable: true),
                    reminder_time = table.Column<TimeOnly>(type: "time without time zone", nullable: true),
                    rhythm = table.Column<string>(type: "text", nullable: true),
                    rest_moments = table.Column<string>(type: "text", nullable: true),
                    feasible_step = table.Column<string>(type: "text", nullable: true),
                    preferred_activity = table.Column<string>(type: "text", nullable: true),
                    custom_activity = table.Column<string>(type: "text", nullable: true),
                    product_ownership = table.Column<string>(type: "text", nullable: true),
                    onboarding_step = table.Column<int>(type: "integer", nullable: true),
                    product_expectation = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false, defaultValue: "UNKNOWN"),
                    product_issue = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    wants_support = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    completed_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_onboarding_profiles", x => x.onboarding_profile_id);
                    table.ForeignKey(
                        name: "FK_onboarding_profiles_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "programs",
                columns: table => new
                {
                    program_id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    start_date = table.Column<DateOnly>(type: "date", nullable: false),
                    current_day = table.Column<int>(type: "integer", nullable: false, defaultValue: 1),
                    status = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_programs", x => x.program_id);
                    table.ForeignKey(
                        name: "FK_programs_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "routines",
                columns: table => new
                {
                    routine_id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    routine_type = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_routines", x => x.routine_id);
                    table.ForeignKey(
                        name: "FK_routines_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "mode_blocked_apps",
                columns: table => new
                {
                    mode_blocked_app_id = table.Column<Guid>(type: "uuid", nullable: false),
                    mode_id = table.Column<Guid>(type: "uuid", nullable: false),
                    app_identifier = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    app_name = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_mode_blocked_apps", x => x.mode_blocked_app_id);
                    table.ForeignKey(
                        name: "FK_mode_blocked_apps_modes_mode_id",
                        column: x => x.mode_id,
                        principalTable: "modes",
                        principalColumn: "mode_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "sessions",
                columns: table => new
                {
                    session_id = table.Column<Guid>(type: "uuid", nullable: false),
                    mode_id = table.Column<Guid>(type: "uuid", nullable: false),
                    status = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    planned_duration_seconds = table.Column<int>(type: "integer", nullable: false),
                    remaining_duration_seconds = table.Column<int>(type: "integer", nullable: true),
                    started_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    paused_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ended_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_sessions", x => x.session_id);
                    table.ForeignKey(
                        name: "FK_sessions_modes_mode_id",
                        column: x => x.mode_id,
                        principalTable: "modes",
                        principalColumn: "mode_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "program_days",
                columns: table => new
                {
                    program_day_id = table.Column<Guid>(type: "uuid", nullable: false),
                    program_id = table.Column<Guid>(type: "uuid", nullable: false),
                    day_number = table.Column<int>(type: "integer", nullable: false),
                    title = table.Column<string>(type: "text", nullable: true),
                    content = table.Column<string>(type: "text", nullable: false),
                    scheduled_date = table.Column<DateOnly>(type: "date", nullable: false),
                    timezone = table.Column<string>(type: "text", nullable: false),
                    offered_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    opened_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    completed_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_program_days", x => x.program_day_id);
                    table.ForeignKey(
                        name: "FK_program_days_programs_program_id",
                        column: x => x.program_id,
                        principalTable: "programs",
                        principalColumn: "program_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "routine_items",
                columns: table => new
                {
                    routine_item_id = table.Column<Guid>(type: "uuid", nullable: false),
                    routine_id = table.Column<Guid>(type: "uuid", nullable: false),
                    title = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    description = table.Column<string>(type: "text", nullable: true),
                    start_time = table.Column<TimeOnly>(type: "time without time zone", nullable: true),
                    duration_minutes = table.Column<int>(type: "integer", nullable: true),
                    sort_order = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    is_default = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_routine_items", x => x.routine_item_id);
                    table.ForeignKey(
                        name: "FK_routine_items_routines_routine_id",
                        column: x => x.routine_id,
                        principalTable: "routines",
                        principalColumn: "routine_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "session_blocked_apps",
                columns: table => new
                {
                    session_blocked_app_id = table.Column<Guid>(type: "uuid", nullable: false),
                    session_id = table.Column<Guid>(type: "uuid", nullable: false),
                    app_identifier = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    app_name = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_session_blocked_apps", x => x.session_blocked_app_id);
                    table.ForeignKey(
                        name: "FK_session_blocked_apps_sessions_session_id",
                        column: x => x.session_id,
                        principalTable: "sessions",
                        principalColumn: "session_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_mode_blocked_apps_mode_id_app_identifier",
                table: "mode_blocked_apps",
                columns: new[] { "mode_id", "app_identifier" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_modes_user_id",
                table: "modes",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "IX_onboarding_profiles_user_id",
                table: "onboarding_profiles",
                column: "user_id",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_program_days_program_id_day_number",
                table: "program_days",
                columns: new[] { "program_id", "day_number" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_programs_user_id",
                table: "programs",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "IX_routine_items_routine_id",
                table: "routine_items",
                column: "routine_id");

            migrationBuilder.CreateIndex(
                name: "IX_routines_user_id",
                table: "routines",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "IX_session_blocked_apps_session_id_app_identifier",
                table: "session_blocked_apps",
                columns: new[] { "session_id", "app_identifier" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_sessions_mode_id",
                table: "sessions",
                column: "mode_id");

            migrationBuilder.CreateIndex(
                name: "IX_users_email",
                table: "users",
                column: "email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_users_username",
                table: "users",
                column: "username",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "mode_blocked_apps");

            migrationBuilder.DropTable(
                name: "onboarding_profiles");

            migrationBuilder.DropTable(
                name: "program_days");

            migrationBuilder.DropTable(
                name: "routine_items");

            migrationBuilder.DropTable(
                name: "session_blocked_apps");

            migrationBuilder.DropTable(
                name: "programs");

            migrationBuilder.DropTable(
                name: "routines");

            migrationBuilder.DropTable(
                name: "sessions");

            migrationBuilder.DropTable(
                name: "modes");

            migrationBuilder.DropTable(
                name: "users");
        }
    }
}
