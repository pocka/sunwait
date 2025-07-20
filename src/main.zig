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

const RunOptions = @import("./RunOptions.zig");

const c = @cImport({
    @cInclude("time.h");
    @cInclude("sunriset.h");
});

const ExitCode = enum(u8) {
    ok = 0,
    generic_error = 1,
    day = 2,
    night = 3,
    out_of_memory = 10,
    stdout_write_error = 11,
    stderr_write_error = 12,
    incorrect_usage = 15,

    pub fn code(self: ExitCode) u8 {
        return @intFromEnum(self);
    }
};

fn writeHelp(writer: anytype, bin: []const u8) !void {
    try std.fmt.format(writer,
        \\[Usage]
        \\{s} [options...] <command> [parameters...]
        \\
        \\[Options]
        \\-v, --version   Prints version to stdout and exits.
        \\-h, --help      Prints this message to stdout and exits.
        \\--debug         Prints debug log, and shortens "wait" duration
        \\                to one minute.
        \\--utc           Dates and times will use UTC rather than local time.
        \\
        \\--lat <DEGREE>, --latitude <DEGREE>
        \\                Latitude of the point to calculate sunrise and sunset.
        \\                <DEGREE> must be a floating point number or a positive
        \\                floating point number with N or S suffix.
        \\
        \\--lon <DEGREE>, --longitude <DEGREE>
        \\                Longitude of the point to calculate sunrise and sunset.
        \\                <DEGREE> must be a floating point number or a positive
        \\                floating point number with E or W suffix.
        \\
        \\--twilight <TYPE OR ANGLE>
        \\                Specify twilight angle to determine day (twilight) or night.
        \\                Value must be a floating point number or one of:
        \\                * daylight
        \\                * civil
        \\                * nautical
        \\                * astronomical
        \\-o <DURATION>, --offset <DURATION>
        \\                Time offset for sunrise and sunset time, towards noon.
        \\                <DURATION> must be "MM" (minutes) or "HH:MM", and either
        \\                can be negative.
        \\
        \\[Commands]
        \\poll     Prints whether it's DAY or NIGHT.
        \\wait     Sleep until sunrise and/or sunset, then exits.
        \\report   Prints sunrise and sunset times.
        \\list     List sunrise and sunset times for next <DAYS>.
        \\
        \\[Options for "list" and "wait"]
        \\-e <TYPE>, --event <TYPE>
        \\                Events to print or wait. Valid values are:
        \\                * sunrise
        \\                * sunset
        \\                When this option is not set, sunwait targets both.
        \\                You can specify this option multiple times to explicitly
        \\                tell sunwait to target both.
        \\
        \\See man page for "sunwait(1)" for more.
        \\
    , .{bin});
}

pub fn main() u8 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var opts = RunOptions{};

    var args = std.process.ArgIterator.initWithAllocator(allocator) catch {
        return ExitCode.out_of_memory.code();
    };
    defer args.deinit();

    const bin_name = args.next() orelse {
        std.log.err("Got no arguments, exiting.", .{});
        return ExitCode.generic_error.code();
    };

    opts.parseArgs(&args) catch {
        writeHelp(std.io.getStdErr().writer(), bin_name) catch |err| {
            std.log.err("Unable to write help message to stderr: {s}", .{@errorName(err)});
            return ExitCode.stdout_write_error.code();
        };

        return ExitCode.incorrect_usage.code();
    };

    switch (opts.command) {
        .help => {
            writeHelp(std.io.getStdOut().writer(), bin_name) catch |err| {
                std.log.err("Unable to write help message to stdout: {s}", .{@errorName(err)});
                return ExitCode.stdout_write_error.code();
            };

            return ExitCode.ok.code();
        },
        .version => {
            std.fmt.format(std.io.getStdOut().writer(), "{s}\n", .{config.version}) catch |err| {
                std.log.err("Unable to write to stdout: {s}", .{@errorName(err)});
                return ExitCode.stdout_write_error.code();
            };

            return ExitCode.ok.code();
        },
        .poll => {
            var c_opts = opts.toC();

            switch (c.sunpoll(&c_opts)) {
                c.EXIT_DAY => {
                    std.io.getStdOut().writeAll("DAY\n") catch |err| {
                        std.log.err("Unable to write \"DAY\" to stdout: {s}", .{@errorName(err)});
                        return ExitCode.stdout_write_error.code();
                    };
                    return ExitCode.day.code();
                },
                c.EXIT_NIGHT => {
                    std.io.getStdOut().writeAll("NIGHT\n") catch |err| {
                        std.log.err("Unable to write \"NIGHT\" to stdout: {s}", .{@errorName(err)});
                        return ExitCode.stdout_write_error.code();
                    };
                    return ExitCode.night.code();
                },
                else => {
                    // TODO: Print to stderr after CLI rewrite
                    std.io.getStdOut().writeAll("ERROR\n") catch |err| {
                        std.log.err("Unable to write \"ERROR\" to stdout: {s}", .{@errorName(err)});
                        return ExitCode.stdout_write_error.code();
                    };
                    return ExitCode.generic_error.code();
                },
            }
        },
        .list => |_| {
            var c_opts = opts.toC();

            c.print_list(&c_opts);
            return ExitCode.ok.code();
        },
        .report => {
            var c_opts = opts.toC();

            c.generate_report(&c_opts);
            return ExitCode.ok.code();
        },
        .wait => {
            var c_opts = opts.toC();

            const code = c.sunwait(&c_opts);

            switch (code) {
                c.EXIT_OK => return ExitCode.ok.code(),
                c.EXIT_ERROR => return ExitCode.generic_error.code(),
                else => {
                    std.log.err("Unexpected exit code from sunwait(): {d}", .{code});
                    return ExitCode.generic_error.code();
                },
            }
        },
    }
}

test {
    _ = @import("./RunOptions.zig");
}
