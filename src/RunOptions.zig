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

const c = @cImport({
    @cInclude("time.h");
    @cInclude("sunriset.h");
});

latitude: f64 = c.DEFAULT_LATITUDE,
longitude: f64 = c.DEFAULT_LONGITUDE,
offset_hour: f64 = 0,
twilight_angle: f64 = c.TWILIGHT_ANGLE_DAYLIGHT,
now: c.time_t = 0,
target_time: c.time_t = 0,
now_delta: c_ulong = 0,
target_delta: c_ulong = 0,
utc: bool = false,
debug: bool = false,
report_sunrise: c.OnOff = c.ONOFF_OFF,
report_sunset: c.OnOff = c.ONOFF_OFF,
list_days: c_uint = c.DEFAULT_LIST,
utc_bias_hours: f64 = 0,
command: CommandOptions = .poll,

pub const ParseArgsError = error{
    UnknownArg,
};

pub const ListOptions = struct {
    days: c_uint = 1,

    pub fn parseArg(self: *@This(), arg: []const u8, args: *std.process.ArgIterator) ParseArgsError!void {
        _ = self;
        _ = arg;
        _ = args;

        return ParseArgsError.UnknownArg;
    }
};

pub const Command = enum {
    help,
    version,
    poll,
    report,
    wait,
    list,

    pub const ParseError = error{
        UnknownCommand,
    };

    pub fn parse(str: []const u8) ParseError!@This() {
        inline for (@typeInfo(@This()).@"enum".fields) |field| {
            if (std.mem.eql(u8, field.name, str)) {
                return @enumFromInt(field.value);
            }
        }

        return ParseError.UnknownCommand;
    }
};

pub const CommandOptions = union(Command) {
    help: void,
    version: void,
    poll: void,
    report: void,
    wait: void,
    list: ListOptions,

    pub fn parseArg(self: *@This(), arg: []const u8, args: *std.process.ArgIterator) ParseArgsError!void {
        switch (self.*) {
            .help => return ParseArgsError.UnknownArg,
            .version => return ParseArgsError.UnknownArg,
            .poll => return ParseArgsError.UnknownArg,
            .report => return ParseArgsError.UnknownArg,
            .wait => return ParseArgsError.UnknownArg,
            .list => try self.list.parseArg(arg, args),
        }
    }
};

pub fn init() @This() {
    var opts = @This(){};

    _ = c.time(&opts.now);
    opts.now_delta = c.daysSince2000(&opts.now);

    return opts;
}

const ParseState = enum {
    no_command,
    with_command,
};

pub fn parseArgs(self: *@This(), args: *std.process.ArgIterator) ParseArgsError!void {
    state: switch (ParseState.no_command) {
        .no_command => {
            while (args.next()) |arg| {
                if (Command.parse(arg)) |command| {
                    switch (command) {
                        .version => {
                            self.command = .version;
                            return;
                        },
                        .help => {
                            self.command = .help;
                            return;
                        },
                        .poll => {
                            self.command = .poll;
                        },
                        .report => {
                            self.command = .report;
                        },
                        .wait => {
                            self.command = .wait;
                        },
                        .list => {
                            self.command = .{ .list = .{} };
                        },
                    }

                    continue :state .with_command;
                } else |_| {}

                self.parseArg(arg, args) catch |err| {
                    std.log.err("Unknown argument: {s}", .{arg});
                    return err;
                };
            }
        },
        .with_command => {
            while (args.next()) |arg| {
                self.parseArg(arg, args) catch |err| {
                    std.log.err("Unknown argument: {s}", .{arg});
                    return err;
                };
            }
        },
    }
}

fn parseArg(self: *@This(), arg: []const u8, args: *std.process.ArgIterator) ParseArgsError!void {
    if (std.mem.eql(u8, "-v", arg) or std.mem.eql(u8, "--version", arg)) {
        self.command = .version;
        return;
    }

    if (std.mem.eql(u8, "-h", arg) or std.mem.eql(u8, "--help", arg)) {
        self.command = .help;
        return;
    }

    if (self.command.parseArg(arg, args)) |_| {
        return;
    } else |_| {}

    if (std.mem.eql(u8, "--debug", arg)) {
        self.debug = true;
        return;
    }

    if (std.mem.eql(u8, "--utc", arg)) {
        self.utc = true;
        return;
    }

    if (std.mem.eql(u8, "--gmt", arg)) {
        std.log.warn("--gmt is deprecated. Use --utc instead.", .{});
        self.utc = true;
        return;
    }

    return ParseArgsError.UnknownArg;
}

pub fn toC(self: *const @This()) c.runStruct {
    return c.runStruct{
        .latitude = self.latitude,
        .longitude = self.longitude,
        .offsetHour = self.offset_hour,
        .twilightAngle = self.twilight_angle,
        .nowTimet = self.now,
        .targetTimet = self.target_time,
        .now2000 = self.now_delta,
        .target2000 = self.target_delta,
        .functionVersion = c.ONOFF_OFF,
        .functionUsage = c.ONOFF_OFF,
        .functionReport = c.ONOFF_OFF,
        .functionList = c.ONOFF_OFF,
        .functionPoll = c.ONOFF_OFF,
        .functionWait = c.ONOFF_OFF,
        .utc = if (self.utc) c.ONOFF_ON else c.ONOFF_OFF,
        .debug = if (self.debug) c.ONOFF_ON else c.ONOFF_OFF,
        .reportSunrise = self.report_sunrise,
        .reportSunset = self.report_sunset,
        .listDays = self.list_days,
        .utcBiasHours = self.utc_bias_hours,
    };
}
