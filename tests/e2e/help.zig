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

test "should print to stdout" {
    const result = try std.process.Child.run(.{
        .allocator = std.testing.allocator,
        .argv = &.{ config.bin, "--help" },
    });
    defer std.testing.allocator.free(result.stderr);
    defer std.testing.allocator.free(result.stdout);

    try std.testing.expectEqual(0, result.term.Exited);
    try std.testing.expectEqual(0, result.stderr.len);
    try std.testing.expect(result.stdout.len > 0);
}
