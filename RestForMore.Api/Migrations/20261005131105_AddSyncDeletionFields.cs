using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace RestForMore.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddSyncDeletionFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "deleted_at",
                table: "sessions",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "deleted_at",
                table: "routines",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "deleted_at",
                table: "routine_items",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "deleted_at",
                table: "modes",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "deleted_at",
                table: "mode_blocked_apps",
                type: "timestamp with time zone",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "deleted_at",
                table: "sessions");

            migrationBuilder.DropColumn(
                name: "deleted_at",
                table: "routines");

            migrationBuilder.DropColumn(
                name: "deleted_at",
                table: "routine_items");

            migrationBuilder.DropColumn(
                name: "deleted_at",
                table: "modes");

            migrationBuilder.DropColumn(
                name: "deleted_at",
                table: "mode_blocked_apps");
        }
    }
}
