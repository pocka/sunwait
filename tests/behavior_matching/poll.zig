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

const PollOptions = struct {
    bin: []const u8,
    tz: []const u8 = "UTC",
    twilight_angle: ?[]const u8 = null,
    longitude: []const u8 = "31.132484E",
    latitude: []const u8 = "29.977435N",
};

fn poll(allocator: std.mem.Allocator, opts: PollOptions) !std.process.Child.RunResult {
    var env = std.process.EnvMap.init(allocator);
    defer env.deinit();

    try env.put("TZ", opts.tz);

    var args = std.ArrayList([]const u8).init(allocator);
    defer args.deinit();

    try args.append(opts.bin);
    try args.append("poll");

    if (opts.twilight_angle) |angle| {
        try args.append("angle");
        try args.append(angle);
    }

    try args.append(opts.latitude);
    try args.append(opts.longitude);

    return try std.process.Child.run(.{
        .allocator = allocator,
        .argv = args.items,
        .env_map = &env,
    });
}

test {
    const legacy = try poll(std.testing.allocator, .{
        .bin = config.legacy_bin,
    });
    defer std.testing.allocator.free(legacy.stderr);
    defer std.testing.allocator.free(legacy.stdout);

    const new = try poll(std.testing.allocator, .{
        .bin = config.new_bin,
    });
    defer std.testing.allocator.free(new.stderr);
    defer std.testing.allocator.free(new.stdout);

    try std.testing.expectEqual(legacy.term.Exited, new.term.Exited);
    try std.testing.expectEqualStrings(legacy.stderr, new.stderr);
    try std.testing.expectEqualStrings(legacy.stdout, new.stdout);
}

test {
    const regular = try poll(std.testing.allocator, .{
        .bin = config.new_bin,
    });
    defer std.testing.allocator.free(regular.stderr);
    defer std.testing.allocator.free(regular.stdout);

    var env = std.process.EnvMap.init(std.testing.allocator);
    defer env.deinit();

    try env.put("TZ", "UTC");

    const debug = try std.process.Child.run(.{
        .allocator = std.testing.allocator,
        .argv = &.{ config.new_bin, "--debug", "poll", "29.977435N", "31.132484E" },
        .env_map = &env,
    });
    defer std.testing.allocator.free(debug.stderr);
    defer std.testing.allocator.free(debug.stdout);

    // Original sunwait prints debug log to stdout.
    // TODO: Print to stderr
    try std.testing.expect(debug.stdout.len > regular.stdout.len);
}

test "From original USAGE.txt: Example 3" {
    // Indicate by program exit-code if is Day or Night using a custom twilight angle of
    // 10 degrees above horizon. Washington, UK.
    const legacy = try poll(std.testing.allocator, .{
        .bin = config.legacy_bin,
        .twilight_angle = "10",
        .latitude = "54.897786N",
        // Original example uses -1.517536E but it does not make sense.
        .longitude = "1.517536W",
    });
    defer std.testing.allocator.free(legacy.stderr);
    defer std.testing.allocator.free(legacy.stdout);

    const new = try poll(std.testing.allocator, .{
        .bin = config.new_bin,
        .twilight_angle = "10",
        .latitude = "54.897786N",
        .longitude = "1.517536W",
    });
    defer std.testing.allocator.free(new.stderr);
    defer std.testing.allocator.free(new.stdout);

    try std.testing.expectEqual(legacy.term.Exited, new.term.Exited);
    try std.testing.expectEqualStrings(legacy.stderr, new.stderr);
    try std.testing.expectEqualStrings(legacy.stdout, new.stdout);
}
