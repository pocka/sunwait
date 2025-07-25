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

const ProcessArgIterator = @This();

args: std.process.ArgIterator,

pub fn init(allocator: std.mem.Allocator) std.mem.Allocator.Error!ProcessArgIterator {
    return .{
        .args = try std.process.ArgIterator.initWithAllocator(allocator),
    };
}

pub fn deinit(self: *ProcessArgIterator) void {
    self.args.deinit();
}

pub fn iterator(self: *ProcessArgIterator) ArgIterator {
    return .{
        .ptr = self,
        .vtable = &.{
            .next = &next,
        },
    };
}

fn next(ctx: *anyopaque) ?[]const u8 {
    const self: *ProcessArgIterator = @ptrCast(@alignCast(ctx));

    return self.args.next();
}
