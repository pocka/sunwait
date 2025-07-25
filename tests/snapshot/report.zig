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

const snapshot = @import("./snapshot.zig");

test "snapshots/report_basic.txt" {
    var env = std.process.EnvMap.init(std.testing.allocator);
    defer env.deinit();

    try env.put("TZ", "Asia/Tokyo");

    const result = try std.process.Child.run(.{
        .allocator = std.testing.allocator,
        .argv = &.{ config.bin, "report", "--now", "2025-07-07", "31.132484E", "29.977435N" },
        .env_map = &env,
    });
    defer std.testing.allocator.free(result.stderr);
    defer std.testing.allocator.free(result.stdout);

    try snapshot.expectMatchSnapshot(@src(), &result);
}

test "snapshots/report_utc.txt" {
    var env = std.process.EnvMap.init(std.testing.allocator);
    defer env.deinit();

    try env.put("TZ", "Asia/Tokyo");

    const result = try std.process.Child.run(.{
        .allocator = std.testing.allocator,
        .argv = &.{ config.bin, "report", "--utc", "--now", "2025-07-07", "31.132484E", "29.977435N" },
        .env_map = &env,
    });
    defer std.testing.allocator.free(result.stderr);
    defer std.testing.allocator.free(result.stdout);

    try snapshot.expectMatchSnapshot(@src(), &result);
}

test "snapshots/report_2010_02_01.txt" {
    var env = std.process.EnvMap.init(std.testing.allocator);
    defer env.deinit();

    try env.put("TZ", "Asia/Tokyo");

    const result = try std.process.Child.run(.{
        .allocator = std.testing.allocator,
        .argv = &.{
            config.bin,
            "report",
            "--now",
            "2025-07-07",
            "d",
            "1",
            "m",
            "2",
            "y",
            "10",
            "31.132484E",
            "29.977435N",
        },
        .env_map = &env,
    });
    defer std.testing.allocator.free(result.stderr);
    defer std.testing.allocator.free(result.stdout);

    try snapshot.expectMatchSnapshot(@src(), &result);
}

test "snapshots/report_christmas_island_2022_03_15.txt" {
    // From original USAGE.txt
    // > Produce a report of the different sunrises and sunsets on an arbitrary day (2022/03/15) for an arbitrary location (Christmas Island)
    var env = std.process.EnvMap.init(std.testing.allocator);
    defer env.deinit();

    try env.put("TZ", "Asia/Taipei");

    const result = try std.process.Child.run(.{
        .allocator = std.testing.allocator,
        .argv = &.{
            config.bin,
            "report",
            "--now",
            "2025-07-07",
            "d",
            "15",
            "m",
            "3",
            "y",
            "20",
            "10.49S",
            "105.55E",
        },
        .env_map = &env,
    });
    defer std.testing.allocator.free(result.stderr);
    defer std.testing.allocator.free(result.stdout);

    try snapshot.expectMatchSnapshot(@src(), &result);
}
