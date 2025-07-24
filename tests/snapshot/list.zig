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

test "snapshots/list_basic.txt" {
    var env = std.process.EnvMap.init(std.testing.allocator);
    defer env.deinit();

    try env.put("TZ", "UTC");

    const result = try std.process.Child.run(.{
        .allocator = std.testing.allocator,
        .argv = &.{ config.bin, "list", "--from", "2025-07-07", "31.132484E", "29.977435N" },
        .env_map = &env,
    });
    defer std.testing.allocator.free(result.stderr);
    defer std.testing.allocator.free(result.stdout);

    try snapshot.expectMatchSnapshot(@src(), &result);
}

test "snapshots/list_asia_tokyo.txt" {
    var env = std.process.EnvMap.init(std.testing.allocator);
    defer env.deinit();

    try env.put("TZ", "Asia/Tokyo");

    const result = try std.process.Child.run(.{
        .allocator = std.testing.allocator,
        .argv = &.{ config.bin, "list", "3", "--from", "2025-01-01", "31.132484E", "29.977435N" },
        .env_map = &env,
    });
    defer std.testing.allocator.free(result.stderr);
    defer std.testing.allocator.free(result.stdout);

    try snapshot.expectMatchSnapshot(@src(), &result);
}

test "snapshots/list_utc_flag.txt" {
    var env = std.process.EnvMap.init(std.testing.allocator);
    defer env.deinit();

    try env.put("TZ", "Europe/Paris");

    const result = try std.process.Child.run(.{
        .allocator = std.testing.allocator,
        .argv = &.{ config.bin, "list", "3", "--utc", "--from", "2025-01-01", "31.132484E", "29.977435N" },
        .env_map = &env,
    });
    defer std.testing.allocator.free(result.stderr);
    defer std.testing.allocator.free(result.stdout);

    try snapshot.expectMatchSnapshot(@src(), &result);
}

test "snapshots/list_sunrise_only.txt" {
    var env = std.process.EnvMap.init(std.testing.allocator);
    defer env.deinit();

    try env.put("TZ", "Europe/Paris");

    const result = try std.process.Child.run(.{
        .allocator = std.testing.allocator,
        .argv = &.{
            config.bin,
            "list",
            "3",
            "--from",
            "2025-01-01",
            "31.132484E",
            "29.977435N",
            "-e",
            "sunrise",
        },
        .env_map = &env,
    });
    defer std.testing.allocator.free(result.stderr);
    defer std.testing.allocator.free(result.stdout);

    try snapshot.expectMatchSnapshot(@src(), &result);
}

test "snapshots/list_sunset_only.txt" {
    var env = std.process.EnvMap.init(std.testing.allocator);
    defer env.deinit();

    try env.put("TZ", "Europe/Paris");

    const result = try std.process.Child.run(.{
        .allocator = std.testing.allocator,
        .argv = &.{
            config.bin,
            "list",
            "3",
            "--from",
            "2025-01-01",
            "31.132484E",
            "29.977435N",
            "-e",
            "sunset",
        },
        .env_map = &env,
    });
    defer std.testing.allocator.free(result.stderr);
    defer std.testing.allocator.free(result.stdout);

    try snapshot.expectMatchSnapshot(@src(), &result);
}

test "snapshots/list_civil.txt" {
    var env = std.process.EnvMap.init(std.testing.allocator);
    defer env.deinit();

    try env.put("TZ", "Europe/Paris");

    const result = try std.process.Child.run(.{
        .allocator = std.testing.allocator,
        .argv = &.{
            config.bin,
            "list",
            "3",
            "--from",
            "2025-01-01",
            "31.132484E",
            "29.977435N",
            "--twilight",
            "civil",
        },
        .env_map = &env,
    });
    defer std.testing.allocator.free(result.stderr);
    defer std.testing.allocator.free(result.stdout);

    try snapshot.expectMatchSnapshot(@src(), &result);
}

test "snapshots/list_custom_twilight_angle.txt" {
    var env = std.process.EnvMap.init(std.testing.allocator);
    defer env.deinit();

    try env.put("TZ", "Europe/Paris");

    const result = try std.process.Child.run(.{
        .allocator = std.testing.allocator,
        .argv = &.{
            config.bin,
            "list",
            "3",
            "--from",
            "2025-01-01",
            "31.132484E",
            "29.977435N",
            "--twilight",
            "2.1",
        },
        .env_map = &env,
    });
    defer std.testing.allocator.free(result.stderr);
    defer std.testing.allocator.free(result.stdout);

    try snapshot.expectMatchSnapshot(@src(), &result);
}

test "snapshots/list_offset.txt" {
    var env = std.process.EnvMap.init(std.testing.allocator);
    defer env.deinit();

    try env.put("TZ", "Europe/Paris");

    const result = try std.process.Child.run(.{
        .allocator = std.testing.allocator,
        .argv = &.{
            config.bin,
            "list",
            "3",
            "--from",
            "2025-01-01",
            "31.132484E",
            "29.977435N",
            "--offset",
            "00:30",
        },
        .env_map = &env,
    });
    defer std.testing.allocator.free(result.stderr);
    defer std.testing.allocator.free(result.stdout);

    try snapshot.expectMatchSnapshot(@src(), &result);
}

test "snapshots/list_negative_offset.txt" {
    var env = std.process.EnvMap.init(std.testing.allocator);
    defer env.deinit();

    try env.put("TZ", "Europe/Paris");

    const result = try std.process.Child.run(.{
        .allocator = std.testing.allocator,
        .argv = &.{
            config.bin,
            "list",
            "3",
            "--from",
            "2025-01-01",
            "31.132484E",
            "29.977435N",
            "--offset",
            "-11:00",
        },
        .env_map = &env,
    });
    defer std.testing.allocator.free(result.stderr);
    defer std.testing.allocator.free(result.stdout);

    try snapshot.expectMatchSnapshot(@src(), &result);
}

test "snapshots/list_moscow_6days.txt" {
    // From original USAGE.txt
    // > List civil sunrise and sunset times for today and next 6 days. Moscow.
    var env = std.process.EnvMap.init(std.testing.allocator);
    defer env.deinit();

    try env.put("TZ", "Europe/Moscow");

    const result = try std.process.Child.run(.{
        .allocator = std.testing.allocator,
        .argv = &.{
            config.bin,
            "list",
            "7",
            "--from",
            "2025-01-01",
            "--twilight",
            "civil",
            "--lat",
            "55.752163N",
            "--lon",
            "37.617524E",
        },
        .env_map = &env,
    });
    defer std.testing.allocator.free(result.stderr);
    defer std.testing.allocator.free(result.stdout);

    try snapshot.expectMatchSnapshot(@src(), &result);
}

test "snapshots/list_default_location_7days.txt" {
    // From original USAGE.txt
    // > List next 7 days sunrise times, custom +3 degree twilight angle, default location.
    // > Uses GMT; as any change in daylight saving over the specified period is not considered.
    var env = std.process.EnvMap.init(std.testing.allocator);
    defer env.deinit();

    try env.put("TZ", "Asia/Tokyo");

    const result = try std.process.Child.run(.{
        .allocator = std.testing.allocator,
        .argv = &.{
            config.bin,
            "list",
            "7",
            "--from",
            "2025-01-01",
            "--utc",
            "-e",
            "sunrise",
            "--twilight",
            "3",
        },
        .env_map = &env,
    });
    defer std.testing.allocator.free(result.stderr);
    defer std.testing.allocator.free(result.stdout);

    try snapshot.expectMatchSnapshot(@src(), &result);
}
