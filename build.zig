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

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = exe: {
        const exe = b.addExecutable(.{
            .name = "sunwait",
            .target = target,
            .optimize = optimize,
        });

        exe.linkLibC();

        exe.addCSourceFiles(.{
            .files = &.{
                "src/print.c",
                "src/sunriset.c",
                "src/sunwait.c",
            },
        });

        exe.addIncludePath(b.path("src"));

        break :exe exe;
    };

    // Default step
    b.installArtifact(exe);

    // "zig build run"
    {
        const step = b.step("run", "Build and run sunwait");

        const run = b.addRunArtifact(exe);
        if (b.args) |args| {
            run.addArgs(args);
        }

        step.dependOn(&run.step);
    }
}
