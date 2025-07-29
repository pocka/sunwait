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
    const legacy = b.option(bool, "legacy", "Build legacy C program") orelse false;
    const version = b.option([]const u8, "version", "Application version, without \"v\" prefix") orelse "dev";
    const update_snapshot = b.option(bool, "update-snapshot", "Update snapshot on snapshot tests") orelse false;

    const zsh_completion = b.option(bool, "zsh-completion", "Install Zsh completion file") orelse false;
    const fish_completion = b.option(bool, "fish-completion", "Install fish shell completion file") orelse false;

    const exe = addExe(b, .{
        .target = target,
        .optimize = optimize,
        .legacy = false,
        .version = version,
    });

    const legacy_exe = addExe(b, .{
        .target = target,
        .optimize = optimize,
        .legacy = true,
        .version = "0.91",
    });

    // "zig build run"
    {
        const step = b.step("run", "Build and run sunwait");

        const run = b.addRunArtifact(if (legacy) legacy_exe else exe);
        if (b.args) |args| {
            run.addArgs(args);
        }

        step.dependOn(&run.step);
    }

    // "zig build man"
    const man = man: {
        const step = b.step("man", "Build man pages");

        const ManPage = struct {
            source: std.Build.LazyPath,
            outname: []const u8,
        };

        for ([_]ManPage{
            .{ .source = b.path("docs/sunwait.adoc"), .outname = "sunwait.1" },
            .{ .source = b.path("docs/sunwait-poll.adoc"), .outname = "sunwait-poll.1" },
            .{ .source = b.path("docs/sunwait-wait.adoc"), .outname = "sunwait-wait.1" },
            .{ .source = b.path("docs/sunwait-list.adoc"), .outname = "sunwait-list.1" },
            .{ .source = b.path("docs/sunwait-report.adoc"), .outname = "sunwait-report.1" },
        }) |page| {
            const cmd = b.addSystemCommand(&.{"asciidoctor"});

            cmd.addArgs(&.{ "-b", "manpage" });
            cmd.addFileArg(page.source);
            cmd.addArg("--out-file");
            const out = cmd.addOutputFileArg(page.outname);

            const install = b.addInstallFile(out, b.fmt("share/man/man1/{s}", .{page.outname}));
            step.dependOn(&install.step);
        }

        break :man step;
    };

    // "zig build"
    {
        const root_step = b.getInstallStep();

        b.installArtifact(if (legacy) legacy_exe else exe);

        if (man_opt) {
            root_step.dependOn(man);
        }

        if (zsh_completion) {
            const install = b.addInstallFile(b.path("dist/completion.zsh"), "share/zsh/site-functions/_sunwait");
            root_step.dependOn(&install.step);
        }

        if (fish_completion) {
            const install = b.addInstallFile(
                b.path("dist/completion.fish"),
                "share/fish/vendor_completions.d/sunwait.fish",
            );
            root_step.dependOn(&install.step);
        }
    }

    // "zig build unit-test"
    const unit_tests = unit_tests: {
        const step = b.step("unit-test", "Run unit tests");

        const t = b.addTest(.{
            .name = "unit_test",
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path("src/main.zig"),
        });

        t.linkLibC();
        t.addCSourceFiles(.{
            .files = &.{
                "src/print.c",
                "src/sunriset.c",
                "src/sunwait.c",
            },
        });
        t.addIncludePath(b.path("src"));
        t.root_module.addCMacro("SUNWAIT_NOMAIN", "");

        const run = b.addRunArtifact(t);
        step.dependOn(&run.step);

        break :unit_tests step;
    };

    // "zig build behavior-test"
    const behavior_tests = behavior_tests: {
        const step = b.step("behavior-test", "Run behavior matching tests");

        const t = b.addTest(.{
            .name = "behavior_matching_test",
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path("tests/behavior_matching/main.zig"),
        });

        const config = b.addOptions();
        config.addOptionPath("legacy_bin", legacy_exe.getEmittedBin());
        config.addOptionPath("new_bin", exe.getEmittedBin());

        t.root_module.addOptions("config", config);

        const run = b.addRunArtifact(t);
        step.dependOn(&run.step);

        break :behavior_tests step;
    };

    // "zig build e2e-test"
    const e2e_tests = e2e_tests: {
        const step = b.step("e2e-test", "Run end-to-end tests");

        const t = b.addTest(.{
            .name = "e2e_test",
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path("tests/e2e/main.zig"),
        });

        const config = b.addOptions();
        config.addOptionPath("bin", exe.getEmittedBin());

        t.root_module.addOptions("config", config);

        const run = b.addRunArtifact(t);
        step.dependOn(&run.step);

        break :e2e_tests step;
    };

    // "zig build snapshot-test"
    const snapshot_tests = snapshot_test: {
        const step = b.step("snapshot-test", "Run snapshot tests");

        const t = b.addTest(.{
            .name = "snapshot_test",
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path("tests/snapshot/main.zig"),
        });

        const config = b.addOptions();
        config.addOptionPath("bin", exe.getEmittedBin());
        config.addOptionPath("test_src_root", b.path("tests/snapshot/"));
        config.addOption(bool, "update_snapshot", update_snapshot);

        t.root_module.addOptions("config", config);

        const run = b.addRunArtifact(t);
        step.dependOn(&run.step);

        break :snapshot_test step;
    };

    // "zig build test"
    {
        const step = b.step("test", "Run all tests");

        step.dependOn(unit_tests);
        step.dependOn(behavior_tests);
        step.dependOn(e2e_tests);
        step.dependOn(snapshot_tests);
    }
}

const AddExeOptions = struct {
    target: ?std.Build.ResolvedTarget = null,
    optimize: std.builtin.OptimizeMode,
    legacy: bool = false,
    version: []const u8,
};

fn addExe(b: *std.Build, opts: AddExeOptions) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = "sunwait",
        .target = opts.target,
        .optimize = opts.optimize,
    });

    if (!opts.legacy) {
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
