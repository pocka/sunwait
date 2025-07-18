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

latitude: ?f64 = null,
longitude: ?f64 = null,
offset_hour: f64 = 0,
twilight_angle: f64 = c.TWILIGHT_ANGLE_DAYLIGHT,
target_time: ?c.time_t = null,
utc: bool = false,
debug: bool = false,
report_sunrise: c.OnOff = c.ONOFF_ON,
report_sunset: c.OnOff = c.ONOFF_ON,
utc_bias_hours: f64 = 0,
command: CommandOptions = .poll,

pub const ParseArgsError = error{
    UnknownArg,
    MissingValue,
    InvalidLatitudeFormat,
    InvalidLongitudeFormat,
};

pub const ListOptions = struct {
    days: c_uint = c.DEFAULT_LIST,

    pub fn parseArg(self: *@This(), arg: []const u8, _: *std.process.ArgIterator) ParseArgsError!void {
        if (std.fmt.parseUnsigned(c_uint, arg, 10)) |days| {
            self.days = days;
            return;
        } else |_| {}

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

    // For compatibility.
    // TODO: Delete this once migration is complete.
    if (std.mem.eql(u8, "utc", arg)) {
        self.utc = true;
        return;
    }

    if (std.mem.eql(u8, "--gmt", arg)) {
        std.log.warn("--gmt is deprecated. Use --utc instead.", .{});
        self.utc = true;
        return;
    }

    if (std.mem.eql(u8, "--lat", arg) or std.mem.eql(u8, "--latitude", arg)) {
        const next = args.next() orelse {
            std.log.err("{s} option requires a value", .{arg});
            return ParseArgsError.MissingValue;
        };

        const lat = parseSuffixedLatitude(next) orelse std.fmt.parseFloat(f64, next) catch {
            return ParseArgsError.InvalidLatitudeFormat;
        };

        if (self.latitude) |prev| {
            std.log.warn("Got more than one latitude, overwriting {d} with {d}", .{ prev, lat });
        }

        self.latitude = lat;
        return;
    }

    if (std.mem.eql(u8, "--lon", arg) or std.mem.eql(u8, "--longitude", arg)) {
        const next = args.next() orelse {
            std.log.err("{s} option requires a value", .{arg});
            return ParseArgsError.MissingValue;
        };

        const lon = parseSuffixedLongitude(next) orelse std.fmt.parseFloat(f64, next) catch {
            return ParseArgsError.InvalidLongitudeFormat;
        };

        if (self.longitude) |prev| {
            std.log.warn("Got more than one latitude, overwriting {d} with {d}", .{ prev, lon });
        }

        self.longitude = lon;
        return;
    }

    if (parseSuffixedLatitude(arg)) |lat| {
        if (self.latitude) |prev| {
            std.log.warn("Got more than one latitude, overwriting {d} with {d}", .{ prev, lat });
        }

        self.latitude = lat;
        return;
    }

    if (parseSuffixedLongitude(arg)) |lon| {
        if (self.longitude) |prev| {
            std.log.warn("Got more than one longitude, overwriting {d} with {d}", .{ prev, lon });
        }

        self.longitude = lon;
        return;
    }

    return ParseArgsError.UnknownArg;
}

fn parseSuffixedLatitude(x: []const u8) ?f64 {
    if (x.len <= 1) {
        return null;
    }

    const lastChar = x[x.len - 1];
    const value = std.fmt.parseFloat(f64, x[0 .. x.len - 1]) catch return null;

    if (value < 0) {
        return null;
    }

    return switch (lastChar) {
        'N' => value,
        'S' => -value,
        else => null,
    };
}

test parseSuffixedLatitude {
    try std.testing.expectEqual(29.977435, parseSuffixedLatitude("29.977435N"));
    try std.testing.expectEqual(-29.977435, parseSuffixedLatitude("29.977435S"));
    try std.testing.expectEqual(null, parseSuffixedLatitude("29.977435W"));
    try std.testing.expectEqual(null, parseSuffixedLatitude("-29.977435N"));
}

fn parseSuffixedLongitude(x: []const u8) ?f64 {
    if (x.len <= 1) {
        return null;
    }

    const lastChar = x[x.len - 1];
    const value = std.fmt.parseFloat(f64, x[0 .. x.len - 1]) catch return null;

    if (value < 0) {
        return null;
    }

    return switch (lastChar) {
        'E' => value,
        'W' => -value,
        else => null,
    };
}

test parseSuffixedLongitude {
    try std.testing.expectEqual(31.132484, parseSuffixedLongitude("31.132484E"));
    try std.testing.expectEqual(-31.132484, parseSuffixedLongitude("31.132484W"));
    try std.testing.expectEqual(null, parseSuffixedLongitude("31.132484N"));
    try std.testing.expectEqual(null, parseSuffixedLongitude("-31.132484E"));
}

fn startOfTheDay(time: c.time_t, is_utc: bool) c.time_t {
    var tm: c.tm = undefined;
    if (is_utc) {
        _ = c.gmtime_r(&time, &tm);
    } else {
        c.tzset();
        _ = c.localtime_r(&time, &tm);
    }

    tm.tm_hour = 0;
    tm.tm_min = 0;
    tm.tm_sec = 0;

    // Let `mktime` figure out whether DST or not.
    tm.tm_isdst = -1;

    return c.timegm(&tm);
}

pub fn toC(self: *const @This()) c.runStruct {
    var now: c.time_t = undefined;
    _ = c.time(&now);

    var target_time: c.time_t = self.target_time orelse startOfTheDay(now, self.utc);

    return c.runStruct{
        .latitude = self.latitude orelse c.DEFAULT_LATITUDE,
        .longitude = self.longitude orelse c.DEFAULT_LONGITUDE,
        .offsetHour = self.offset_hour,
        .twilightAngle = self.twilight_angle,
        .nowTimet = now,
        .targetTimet = target_time,
        .now2000 = c.daysSince2000(&now),
        .target2000 = c.daysSince2000(&target_time),
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
        .listDays = switch (self.command) {
            .list => |opts| opts.days,
            else => c.DEFAULT_LIST,
        },
        .utcBiasHours = self.utc_bias_hours,
    };
}
