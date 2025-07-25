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

const ArgIterator = @import("./ArgIterator.zig");

const TestArgIterator = @This();

args: []const []const u8 = &.{""},
index: usize = 0,

pub fn init(args: []const []const u8) TestArgIterator {
    return .{ .args = args };
}

pub fn iterator(self: *TestArgIterator) ArgIterator {
    return .{
        .ptr = self,
        .vtable = &.{
            .next = &next,
        },
    };
}

fn next(ctx: *anyopaque) ?[]const u8 {
    const self: *TestArgIterator = @ptrCast(@alignCast(ctx));

    if (self.index >= self.args.len) {
        return null;
    }

    defer self.index += 1;
    return self.args[self.index];
}

test {
    var test_args = TestArgIterator.init(&.{ "foo", "bar", "baz" });
    const iter = test_args.iterator();

    try std.testing.expectEqualStrings("foo", iter.next().?);
    try std.testing.expectEqualStrings("bar", iter.next().?);
    try std.testing.expectEqualStrings("baz", iter.next().?);
    try std.testing.expectEqual(null, iter.next());
}
