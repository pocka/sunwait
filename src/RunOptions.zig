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

const builtin = @import("builtin");
const std = @import("std");

const ArgIterator = @import("./RunOptions/ArgIterator.zig");
const TestArgIterator = @import("./RunOptions/TestArgIterator.zig");
const datetime = @import("./RunOptions/datetime.zig");
const EventType = @import("./RunOptions/event.zig").EventType;
const ParseArgsError = @import("./RunOptions/parser.zig").ParseArgsError;
const TwilightAngle = @import("./RunOptions/twilight.zig").TwilightAngle;

const RunOptions = @This();

pub const ProcessArgIterator = @import("./RunOptions/ProcessArgIterator.zig");

const c = @cImport({
    @cInclude("time.h");
    @cInclude("sunriset.h");
});

latitude: ?f64 = null,
longitude: ?f64 = null,
offset_mins: i32 = 0,
twilight_angle: ?TwilightAngle = null,
utc: bool = false,
debug: bool = false,
command: CommandOptions = .{ .poll = .{} },

const PollOptions = struct {
    at: ?datetime.Datetime = null,

    pub fn parseArg(self: *@This(), arg: []const u8, args: ArgIterator) ParseArgsError!void {
        if (std.mem.eql(u8, "--at", arg)) {
            const next = args.next() orelse {
                std.log.err("{s} option requires a value", .{arg});
                return ParseArgsError.MissingValue;
            };

            const at = datetime.Datetime.fromString(next) catch |err| {
                std.log.err("\"{s}\" is not a valid datetime string: {s}", .{ next, @errorName(err) });
                return ParseArgsError.InvalidDatetimeFormat;
            };

            self.at = at;
            return;
        }

        return ParseArgsError.UnknownArg;
    }
};

pub const ReportOptions = struct {
    /// Current time should not affect report generation. However, as C function prints
    /// the current time, this option is necessary for snapshot testing. Will be removed
    /// once the report generation was replaced with Zig impelementation.
    now: ?datetime.Datetime = null,

    day_of_month: ?u5 = null,
    month: ?u4 = null,
    year_since_2000: ?c_int = null,

    pub fn parseArg(self: *@This(), arg: []const u8, args: ArgIterator) ParseArgsError!void {
        if (std.mem.eql(u8, "--date", arg)) {
            const next = args.next() orelse {
                std.log.err("{s} option requires a value", .{arg});
                return ParseArgsError.MissingValue;
            };

            const date = datetime.CalendarDate.fromString(next) catch |err| {
                std.log.err("\"{s}\" is not a valid date string: {s}", .{ next, @errorName(err) });
                return ParseArgsError.InvalidDateFormat;
            };

            self.year_since_2000 = @as(c_int, date.year) - 2000;
            self.month = date.month;
            self.day_of_month = date.day;
            return;
        }

        if (datetime.CalendarDate.fromString(arg)) |date| {
            self.year_since_2000 = @as(c_int, date.year) - 2000;
            self.month = date.month;
            self.day_of_month = date.day;
            return;
        } else |_| {}

        if (std.mem.eql(u8, "d", arg)) {
            const next = args.next() orelse {
                std.log.err("{s} option requires a value", .{arg});
                return ParseArgsError.MissingValue;
            };

            const d = std.fmt.parseUnsigned(u5, next, 10) catch {
                std.log.err("Value of {s} option must be unsigned integer between 1 and 31", .{arg});
                return ParseArgsError.InvalidDayOfMonth;
            };

            if (d == 0 or d > 31) {
                std.log.err("Value of {s} option must be between 1 and 31", .{arg});
                return ParseArgsError.InvalidDayOfMonth;
            }

            self.day_of_month = d;
            return;
        }

        if (std.mem.eql(u8, "m", arg)) {
            const next = args.next() orelse {
                std.log.err("{s} option requires a value", .{arg});
                return ParseArgsError.MissingValue;
            };

            const m = std.fmt.parseUnsigned(u4, next, 10) catch {
                std.log.err("Value of {s} option must be unsigned integer between 1 and 12", .{arg});
                return ParseArgsError.InvalidMonth;
            };

            if (m == 0 or m > 12) {
                std.log.err("Value of {s} option must be between 1 and 12", .{arg});
                return ParseArgsError.InvalidMonth;
            }

            self.month = m;
            return;
        }

        if (std.mem.eql(u8, "y", arg)) {
            const next = args.next() orelse {
                std.log.err("{s} option requires a value", .{arg});
                return ParseArgsError.MissingValue;
            };

            const y = std.fmt.parseUnsigned(c_int, next, 10) catch {
                std.log.err("Value of {s} option must be integer", .{arg});
                return ParseArgsError.InvalidYearSince2000;
            };

            // Although the original program accepts 0 for year, it will crash because
            // some place produce NaN (division? idk) and attempt int cast (`(int) NaN`).
            if (y == 0) {
                std.log.err("Value of {s} option must be greater than 0", .{arg});
                return ParseArgsError.InvalidYearSince2000;
            }

            self.year_since_2000 = y;
            return;
        }

        if (std.mem.eql(u8, "--now", arg)) {
            const next = args.next() orelse {
                std.log.err("{s} option requires a value", .{arg});
                return ParseArgsError.MissingValue;
            };

            const now = datetime.Datetime.fromString(next) catch |err| {
                std.log.err("\"{s}\" is not a valid datetime string: {s}", .{ next, @errorName(err) });
                return ParseArgsError.InvalidDatetimeFormat;
            };

            self.now = now;
            return;
        }

        return ParseArgsError.UnknownArg;
    }
};

pub const WaitOptions = struct {
    event_type: ?EventType = null,

    pub fn parseArg(self: *@This(), arg: []const u8, args: ArgIterator) ParseArgsError!void {
        self.event_type = try EventType.parseArg(self.event_type, arg, args);
    }
};

pub const ListOptions = struct {
    event_type: ?EventType = null,
    days: c_uint = c.DEFAULT_LIST,
    from: ?datetime.CalendarDate = null,

    pub fn parseArg(self: *@This(), arg: []const u8, args: ArgIterator) ParseArgsError!void {
        if (EventType.parseArg(self.event_type, arg, args)) |e| {
            self.event_type = e;
            return;
        } else |err| switch (err) {
            ParseArgsError.UnknownArg => {},
            else => return err,
        }

        if (std.mem.eql(u8, "--from", arg)) {
            const next = args.next() orelse {
                std.log.err("{s} option requires a value", .{arg});
                return ParseArgsError.MissingValue;
            };

            self.from = datetime.CalendarDate.fromString(next) catch |err| {
                std.log.err("\"{s}\" is not a valid date string: {s}", .{ next, @errorName(err) });
                return ParseArgsError.InvalidDateFormat;
            };
            return;
        }

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
    poll: PollOptions,
    report: ReportOptions,
    wait: WaitOptions,
    list: ListOptions,

    pub fn parseArg(self: *@This(), arg: []const u8, args: ArgIterator) ParseArgsError!void {
        switch (self.*) {
            .help => return ParseArgsError.UnknownArg,
            .version => return ParseArgsError.UnknownArg,
            .poll => try self.poll.parseArg(arg, args),
            .report => try self.report.parseArg(arg, args),
            .wait => try self.wait.parseArg(arg, args),
            .list => try self.list.parseArg(arg, args),
        }
    }
};

const ParseState = enum {
    no_command,
    with_command,
};

pub fn parseArgs(self: *@This(), args: ArgIterator) ParseArgsError!void {
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
                            self.command = .{ .poll = .{} };
                        },
                        .report => {
                            self.command = .{ .report = .{} };
                        },
                        .wait => {
                            self.command = .{ .wait = .{} };
                        },
                        .list => {
                            self.command = .{ .list = .{} };
                        },
                    }

                    continue :state .with_command;
                } else |_| {}

                self.parseArg(arg, args) catch |err| switch (err) {
                    ParseArgsError.UnknownArg => {
                        std.log.err("Unknown argument: {s}", .{arg});
                        return err;
                    },
                    else => return err,
                };
            }
        },
        .with_command => {
            while (args.next()) |arg| {
                self.parseArg(arg, args) catch |err| switch (err) {
                    ParseArgsError.UnknownArg => {
                        std.log.err("Unknown argument: {s}", .{arg});
                        return err;
                    },
                    else => return err,
                };
            }
        },
    }
}

test "help command aborts args parsing" {
    var opts = RunOptions{};

    var args = TestArgIterator.init(&.{ "--debug", "help", "--version", "--unknown-flag" });
    const iter = args.iterator();

    try opts.parseArgs(iter);

    try std.testing.expect(opts.command == .help);
}

test "version command aborts args parsing" {
    var opts = RunOptions{};

    var args = TestArgIterator.init(&.{ "--debug", "version", "--help", "--unknown-flag" });
    const iter = args.iterator();

    try opts.parseArgs(iter);

    try std.testing.expect(opts.command == .version);
}

test "defaults to poll" {
    var opts = RunOptions{};

    var args = TestArgIterator.init(&.{ "--at", "2020-01-01" });
    const iter = args.iterator();

    try opts.parseArgs(iter);

    try std.testing.expect(opts.command.poll.at != null);
}

fn parseArg(self: *@This(), arg: []const u8, args: ArgIterator) ParseArgsError!void {
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
    } else |err| switch (err) {
        ParseArgsError.UnknownArg => {},
        else => return err,
    }

    if (TwilightAngle.parseArg(arg, args)) |angle| {
        if (self.twilight_angle) |prev| {
            std.log.warn("Overwriting twilight angle \"{s}\" with \"{s}\"", .{
                @tagName(prev),
                @tagName(angle),
            });
        }

        self.twilight_angle = angle;
        return;
    } else |err| switch (err) {
        ParseArgsError.UnknownArg => {},
        else => return err,
    }

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

    // Hyphen-less one is for compatibility.
    // TODO: Delete the hyphen-less one once migration is completed.
    if (std.mem.eql(u8, "-o", arg) or std.mem.eql(u8, "--offset", arg) or std.mem.eql(u8, "offset", arg)) {
        const next = args.next() orelse {
            std.log.err("{s} option requires a value", .{arg});
            return ParseArgsError.MissingValue;
        };

        const i: u1, const modifier: i2 = sign: {
            break :sign if (std.mem.startsWith(u8, next, "-")) .{
                1, -1,
            } else .{
                0, 1,
            };
        };

        if (std.mem.indexOfScalarPos(u8, next, i, ':')) |colon_pos| {
            // HH:MM
            const hrs = std.fmt.parseUnsigned(u7, next[i..colon_pos], 10) catch {
                std.log.err("Hour part of {s} option must be valid integer between 0 and 99", .{arg});
                return ParseArgsError.InvalidOffset;
            };

            if (hrs > 99) {
                std.log.err("Hour part of {s} option must be between 0 and 99", .{arg});
                return ParseArgsError.InvalidOffset;
            }

            if (next[i..].len == colon_pos + 1) {
                std.log.err("Value of {s} option cannot end with colon", .{arg});
                return ParseArgsError.InvalidOffset;
            }

            const mins = std.fmt.parseUnsigned(u6, next[colon_pos + 1 ..], 10) catch {
                std.log.err("Minute part of {s} option must be valid integer between 0 and 59", .{arg});
                return ParseArgsError.InvalidOffset;
            };

            if (mins > 59) {
                std.log.err("Minute part of {s} option must be between 0 and 59", .{arg});
                return ParseArgsError.InvalidOffset;
            }

            self.offset_mins = @as(i32, (@as(i32, hrs) * 60) + mins) * modifier;
            return;
        } else {
            // MM
            const parsed = std.fmt.parseUnsigned(u7, next[i..], 10) catch {
                std.log.err("Value of {s} option must be valid integer between -99 and 99", .{arg});
                return ParseArgsError.InvalidOffset;
            };

            if (parsed > 99) {
                std.log.err("Value of {s} option must be between -99 and 99", .{arg});
                return ParseArgsError.InvalidOffset;
            }

            self.offset_mins = @as(i32, parsed) * modifier;
            return;
        }
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

const GetTargetDayOptions = struct {
    is_utc: bool = false,
    day_of_month: ?c_int = null,
    month: ?c_int = null,
    year_since_2000: ?c_int = null,
};

fn getTargetDay(time: c.time_t, opts: GetTargetDayOptions) c.time_t {
    var tm: c.tm = undefined;
    if (opts.is_utc) {
        if (builtin.os.tag == .windows) {
            tm = c.gmtime(&time).*;
        } else {
            _ = c.gmtime_r(&time, &tm);
        }
    } else {
        if (builtin.os.tag == .windows) {
            tm = c.localtime(&time).*;
        } else {
            c.tzset();
            _ = c.localtime_r(&time, &tm);
        }
    }

    if (opts.year_since_2000) |y| {
        // tm_year ... Year since 1900.
        tm.tm_year = y + 100;
    }

    if (opts.month) |m| {
        // tm_mon ... An index of English month notation, not regular month. [0, 11]
        tm.tm_mon = m - 1;
    }

    if (opts.day_of_month) |d| {
        tm.tm_mday = d;
    }

    tm.tm_hour = 0;
    tm.tm_min = 0;
    tm.tm_sec = 0;

    return if (builtin.os.tag == .windows) c._mkgmtime(&tm) else c.timegm(&tm);
}

pub fn toC(self: *const @This()) c.runStruct {
    const timezone: c_long = timezone: switch (builtin.os.tag) {
        .windows => {
            // This header file is available from newer Windows (probably 10?)
            // and does not exist in old ones such as XP.
            const win32 = @cImport({
                @cInclude("timezoneapi.h");
            });

            var info: win32.DYNAMIC_TIME_ZONE_INFORMATION = undefined;
            _ = win32.GetDynamicTimeZoneInformation(&info);

            break :timezone info.Bias * -60;
        },
        else => {
            c.tzset();
            var now = c.time(null);
            var tm: c.tm = undefined;
            _ = c.localtime_r(&now, &tm);

            break :timezone tm.tm_gmtoff;
        },
    };

    const now: c.time_t = now: switch (self.command) {
        .poll => |opts| {
            if (opts.at) |at| {
                var tm: c.tm = .{
                    .tm_year = at.date.year - 1900,
                    .tm_mon = at.date.month - 1,
                    .tm_mday = at.date.day,
                    .tm_hour = at.time.hour,
                    .tm_min = at.time.minute,
                    .tm_sec = at.time.second,
                };

                var now = c.mktime(&tm);

                if (at.offset) |offset| {
                    now -= timezone;
                    now += @as(c_long, if (offset.positive) 1 else -1) *
                        (@as(c_long, offset.hour) * 60 + offset.minute) *
                        std.time.s_per_min;
                } else if (self.utc) {
                    now -= timezone;
                }

                break :now now;
            }

            break :now c.time(null);
        },
        // This block contains totally duplicated code of the above,
        // because `now` option will be removed soon.
        .report => |opts| {
            if (opts.now) |now| {
                var tm: c.tm = .{
                    .tm_year = now.date.year - 1900,
                    .tm_mon = now.date.month - 1,
                    .tm_mday = now.date.day,
                    .tm_hour = now.time.hour,
                    .tm_min = now.time.minute,
                    .tm_sec = now.time.second,
                };

                var t = c.mktime(&tm);

                if (now.offset) |offset| {
                    t -= timezone;
                    t += @as(c_long, if (offset.positive) 1 else -1) *
                        (@as(c_long, offset.hour) * 60 + offset.minute) *
                        std.time.s_per_min;
                } else if (self.utc) {
                    t -= timezone;
                }

                break :now t;
            }

            break :now c.time(null);
        },
        .list => |opts| {
            if (opts.from) |from| {
                var tm: c.tm = .{
                    .tm_year = from.year - 1900,
                    .tm_mon = from.month - 1,
                    .tm_mday = from.day,
                };

                if (!self.utc) {
                    break :now c.mktime(&tm);
                }

                break :now if (builtin.os.tag == .windows) c._mkgmtime(&tm) else c.timegm(&tm);
            }

            break :now c.time(null);
        },
        else => {
            break :now c.time(null);
        },
    };

    var target_time: c.time_t = switch (self.command) {
        .report => |opts| getTargetDay(now, .{
            .is_utc = self.utc,
            .year_since_2000 = opts.year_since_2000,
            .month = if (opts.month) |m| @intCast(m) else null,
            .day_of_month = if (opts.day_of_month) |d| @intCast(d) else null,
        }),
        else => getTargetDay(now, .{ .is_utc = self.utc }),
    };

    const event_type: EventType = switch (self.command) {
        .list => |opts| opts.event_type orelse .both,
        .wait => |opts| opts.event_type orelse .both,
        else => .both,
    };

    const twilight_angle = self.twilight_angle orelse .daylight;

    return c.runStruct{
        .latitude = self.latitude orelse c.DEFAULT_LATITUDE,
        .longitude = self.longitude orelse c.DEFAULT_LONGITUDE,
        .offsetHour = @as(f64, @floatFromInt(self.offset_mins)) / 60.0,
        .twilightAngle = twilight_angle.toFloat(),
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
        .reportSunrise = if (event_type == .sunset) c.ONOFF_OFF else c.ONOFF_ON,
        .reportSunset = if (event_type == .sunrise) c.ONOFF_OFF else c.ONOFF_ON,
        .listDays = switch (self.command) {
            .list => |opts| opts.days,
            else => c.DEFAULT_LIST,
        },
        .utcBiasHours = @as(f64, @floatFromInt(timezone)) / 60.0 / 60.0,
    };
}

test {
    _ = @import("RunOptions/datetime.zig");
    _ = @import("RunOptions/TestArgIterator.zig");
}
