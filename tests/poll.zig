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

fn poll(allocator: std.mem.Allocator, bin: []const u8) !std.process.Child.RunResult {
    var env = std.process.EnvMap.init(allocator);
    defer env.deinit();

    try env.put("TZ", "UTC");

    return try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ bin, "poll", "29.977435N", "31.132484E" },
        .env_map = &env,
    });
}

test {
    const legacy = try poll(std.testing.allocator, config.legacy_bin);
    defer std.testing.allocator.free(legacy.stderr);
    defer std.testing.allocator.free(legacy.stdout);

    const new = try poll(std.testing.allocator, config.new_bin);
    defer std.testing.allocator.free(new.stderr);
    defer std.testing.allocator.free(new.stdout);

    try std.testing.expectEqual(legacy.term.Exited, new.term.Exited);
    try std.testing.expectEqualStrings(legacy.stderr, new.stderr);
    try std.testing.expectEqualStrings(legacy.stdout, new.stdout);
}
