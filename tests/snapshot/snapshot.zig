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

pub const SnapshotError = error{
    ProcessNotExited,
};

const test_name_prefix = "test.";

pub fn expectMatchSnapshot(
    location: std.builtin.SourceLocation,
    run: *const std.process.Child.RunResult,
) !void {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    switch (run.term) {
        .Exited => {},
        else => {
            std.debug.print("Program did not exit: {s}\n", .{@tagName(run.term)});
            return SnapshotError.ProcessNotExited;
        },
    }

    const filename = if (std.mem.startsWith(u8, location.fn_name, test_name_prefix))
        location.fn_name[test_name_prefix.len..]
    else
        location.fn_name;

    var src_dir = try std.fs.openDirAbsolute(config.test_src_root, .{ .no_follow = true });
    defer src_dir.close();

    const current = src_dir.readFileAlloc(allocator, filename, std.math.maxInt(usize)) catch |err| {
        if (config.update_snapshot) {
            std.debug.print("Writing snapshot to {s}\n", .{filename});
            try src_dir.writeFile(.{
                .data = run.stdout,
                .sub_path = filename,
            });
            return;
        }

        std.debug.print(
            "Unable to open snapshot file {s}. Create using -Dupdate-snapshot option\n",
            .{filename},
        );
        return err;
    };

    const current_normalized = try std.mem.replaceOwned(u8, allocator, current, "\r\n", "\n");
    allocator.free(current);

    const actual_normalized = try std.mem.replaceOwned(u8, allocator, run.stdout, "\r\n", "\n");

    if (!std.mem.eql(u8, current_normalized, actual_normalized) and config.update_snapshot) {
        std.debug.print("Writing snapshot to {s}\n", .{filename});
        try src_dir.writeFile(.{
            .data = actual_normalized,
            .sub_path = filename,
        });
        return;
    }

    // Let std.testing print diffs
    try std.testing.expectEqualStrings(current_normalized, actual_normalized);
}
