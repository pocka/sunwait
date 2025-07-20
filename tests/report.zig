// Copyright (C) 2025 Shota FUJI
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: GPL-3.0-only

const std = @import("std");

const config = @import("config");

const ReportOptions = struct {
    bin: []const u8,
    utc: bool = false,
    longitude: []const u8 = "31.132484E",
    latitude: []const u8 = "29.977435N",
    tz: []const u8 = "UTC",
    dates: []const []const u8 = &.{},
};

fn report(allocator: std.mem.Allocator, opts: ReportOptions) !std.process.Child.RunResult {
    var env = std.process.EnvMap.init(allocator);
    defer env.deinit();

    try env.put("TZ", opts.tz);

    var args = std.ArrayList([]const u8).init(allocator);
    defer args.deinit();

    try args.append(opts.bin);
    if (opts.utc) {
        try args.append("utc");
    }
    try args.append("report");
    try args.appendSlice(opts.dates);
    try args.append(opts.latitude);
    try args.append(opts.longitude);

    return try std.process.Child.run(.{
        .allocator = allocator,
        .argv = args.items,
        .env_map = &env,
    });
}

test {
    const legacy = try report(std.testing.allocator, .{
        .bin = config.legacy_bin,
    });
    defer std.testing.allocator.free(legacy.stderr);
    defer std.testing.allocator.free(legacy.stdout);

    const new = try report(std.testing.allocator, .{
        .bin = config.new_bin,
    });
    defer std.testing.allocator.free(new.stderr);
    defer std.testing.allocator.free(new.stdout);

    try std.testing.expectEqual(legacy.term.Exited, new.term.Exited);
    try std.testing.expectEqualStrings(legacy.stderr, new.stderr);
    try std.testing.expectEqualStrings(legacy.stdout, new.stdout);
}

test "Should behave same with utc option" {
    const legacy = try report(std.testing.allocator, .{
        .bin = config.legacy_bin,
        .utc = true,
    });
    defer std.testing.allocator.free(legacy.stderr);
    defer std.testing.allocator.free(legacy.stdout);

    const new = try report(std.testing.allocator, .{
        .bin = config.new_bin,
        .utc = true,
    });
    defer std.testing.allocator.free(new.stderr);
    defer std.testing.allocator.free(new.stdout);

    try std.testing.expectEqual(legacy.term.Exited, new.term.Exited);
    try std.testing.expectEqualStrings(legacy.stderr, new.stderr);
    try std.testing.expectEqualStrings(legacy.stdout, new.stdout);
}

test "Should behave same in non-UTC timezone" {
    const legacy = try report(std.testing.allocator, .{
        .bin = config.legacy_bin,
        .tz = "Australia/Sydney",
    });
    defer std.testing.allocator.free(legacy.stderr);
    defer std.testing.allocator.free(legacy.stdout);

    const new = try report(std.testing.allocator, .{
        .bin = config.new_bin,
        .tz = "Australia/Sydney",
    });
    defer std.testing.allocator.free(new.stderr);
    defer std.testing.allocator.free(new.stdout);

    try std.testing.expectEqual(legacy.term.Exited, new.term.Exited);
    try std.testing.expectEqualStrings(legacy.stderr, new.stderr);
    try std.testing.expectEqualStrings(legacy.stdout, new.stdout);
}

test "Should behave same with date parameter" {
    const legacy = try report(std.testing.allocator, .{
        .bin = config.legacy_bin,
        .dates = &.{ "d", "1", "m", "2", "y", "10" },
    });
    defer std.testing.allocator.free(legacy.stderr);
    defer std.testing.allocator.free(legacy.stdout);

    const new = try report(std.testing.allocator, .{
        .bin = config.new_bin,
        .dates = &.{ "d", "1", "m", "2", "y", "10" },
    });
    defer std.testing.allocator.free(new.stderr);
    defer std.testing.allocator.free(new.stdout);

    try std.testing.expectEqual(legacy.term.Exited, new.term.Exited);
    try std.testing.expectEqualStrings(legacy.stderr, new.stderr);
    try std.testing.expectEqualStrings(legacy.stdout, new.stdout);
}

test "Should behave same with date parameter, in non-UTC timezone" {
    const legacy = try report(std.testing.allocator, .{
        .bin = config.legacy_bin,
        .dates = &.{ "d", "28", "m", "2", "y", "1" },
        .tz = "Asia/Tokyo",
    });
    defer std.testing.allocator.free(legacy.stderr);
    defer std.testing.allocator.free(legacy.stdout);

    const new = try report(std.testing.allocator, .{
        .bin = config.new_bin,
        .dates = &.{ "d", "28", "m", "2", "y", "1" },
        .tz = "Asia/Tokyo",
    });
    defer std.testing.allocator.free(new.stderr);
    defer std.testing.allocator.free(new.stdout);

    try std.testing.expectEqual(legacy.term.Exited, new.term.Exited);
    try std.testing.expectEqualStrings(legacy.stderr, new.stderr);
    try std.testing.expectEqualStrings(legacy.stdout, new.stdout);
}

test "From original USAGE.txt: Example 5" {
    const legacy = try report(std.testing.allocator, .{
        .bin = config.legacy_bin,
        .dates = &.{ "d", "15", "m", "3", "y", "20" },
        .tz = "Asia/Taipei",
        .latitude = "10.49S",
        .longitude = "105.55E",
    });
    defer std.testing.allocator.free(legacy.stderr);
    defer std.testing.allocator.free(legacy.stdout);

    const new = try report(std.testing.allocator, .{
        .bin = config.new_bin,
        .dates = &.{ "d", "15", "m", "3", "y", "20" },
        .tz = "Asia/Taipei",
        .latitude = "10.49S",
        .longitude = "105.55E",
    });
    defer std.testing.allocator.free(new.stderr);
    defer std.testing.allocator.free(new.stdout);

    try std.testing.expectEqual(legacy.term.Exited, new.term.Exited);
    try std.testing.expectEqualStrings(legacy.stderr, new.stderr);
    try std.testing.expectEqualStrings(legacy.stdout, new.stdout);
}
