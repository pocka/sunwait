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

test "snapshots/poll_basic.txt" {
    const result = try std.process.Child.run(.{
        .allocator = std.testing.allocator,
        .argv = &.{
            config.bin,
            "poll",
            "--at",
            "2025-07-07T12:30:00Z",
        },
    });
    defer std.testing.allocator.free(result.stderr);
    defer std.testing.allocator.free(result.stdout);

    try snapshot.expectMatchSnapshot(@src(), &result);
}

test "snapshots/poll_washington_twilight_10.txt" {
    // From original USAGE.txt
    // > Indicate by program exit-code if is Day or Night using a custom twilight angle of
    // > 10 degrees above horizon. Washington, UK.
    const result = try std.process.Child.run(.{
        .allocator = std.testing.allocator,
        .argv = &.{
            config.bin,
            "poll",
            "--twilight",
            "10",
            "--at",
            "2025-12-01T17:00:00Z",
            "54.897786N",
            // Original example uses -1.517536E but it does not make sense.
            "1.517536W",
        },
    });
    defer std.testing.allocator.free(result.stderr);
    defer std.testing.allocator.free(result.stdout);

    try snapshot.expectMatchSnapshot(@src(), &result);
}
