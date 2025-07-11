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
    const man_opt = b.option(bool, "man", "Builds and installs man pages") orelse false;
    const zig_main = b.option(bool, "zigmain", "Use Zig rewrite") orelse false;
    const version = b.option([]const u8, "version", "Application version, without \"v\" prefix") orelse "dev";

    const exe = addExe(b, .{
        .target = target,
        .optimize = optimize,
        .zig_main = zig_main,
        .version = version,
    });

    // "zig build run"
    {
        const step = b.step("run", "Build and run sunwait");

        const run = b.addRunArtifact(exe);
        if (b.args) |args| {
            run.addArgs(args);
        }

        step.dependOn(&run.step);
    }

    const man = man: {
        const cmd = b.addSystemCommand(&.{"asciidoctor"});

        cmd.addArgs(&.{ "-b", "manpage" });
        cmd.addFileArg(b.path("docs/sunwait.adoc"));
        cmd.addArg("--out-file");
        const out = cmd.addOutputFileArg("sunwait.1");

        break :man b.addInstallFile(out, "share/man/man1/sunwait.1");
    };

    // "zig build man"
    {
        const step = b.step("man", "Build man pages");
        step.dependOn(&man.step);
    }

    // "zig build"
    {
        b.installArtifact(exe);

        if (man_opt) {
            b.getInstallStep().dependOn(&man.step);
        }
    }

    // "zig build behavior_test"
    {
        const step = b.step("behavior_test", "Run behavior matching tests");

        const legacy_exe = addExe(b, .{
            .target = target,
            .optimize = optimize,
            .version = "0.91",
        });

        const new_exe = addExe(b, .{
            .target = target,
            .optimize = optimize,
            .zig_main = true,
            .version = version,
        });

        const t = b.addTest(.{
            .name = "behavior_matching_test",
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path("tests/main.zig"),
        });

        const config = b.addOptions();
        config.addOptionPath("legacy_bin", legacy_exe.getEmittedBin());
        config.addOptionPath("new_bin", new_exe.getEmittedBin());

        t.root_module.addOptions("config", config);

        const run = b.addRunArtifact(t);
        step.dependOn(&run.step);
    }
}

const AddExeOptions = struct {
    target: ?std.Build.ResolvedTarget = null,
    optimize: std.builtin.OptimizeMode,
    zig_main: bool = false,
    version: []const u8,
};

fn addExe(b: *std.Build, opts: AddExeOptions) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = "sunwait",
        .target = opts.target,
        .optimize = opts.optimize,
    });

    if (opts.zig_main) {
        exe.root_module.root_source_file = b.path("src/main.zig");
        exe.root_module.addCMacro("SUNWAIT_NOMAIN", "");

        const config = b.addOptions();
        config.addOption([]const u8, "version", opts.version);
        exe.root_module.addOptions("config", config);
    }

    exe.linkLibC();

    exe.addCSourceFiles(.{
        .files = &.{
            "src/print.c",
            "src/sunriset.c",
            "src/sunwait.c",
        },
    });

    exe.addIncludePath(b.path("src"));

    return exe;
}
