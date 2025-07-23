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

/// Timezone-free date. Each fields' size is same to ones of `std.time.epoch`,
/// in case integration will be added.
pub const CalendarDate = packed struct {
    const format = "YYYY-MM-DD";

    year: u16,
    month: u4,
    day: u5,

    pub const ParseError = error{
        InvalidFormat,
        MonthOutOfRange,
        DayOfMonthOutOfRange,
    };

    pub fn fromString(str: []const u8) ParseError!@This() {
        if (str.len != format.len) {
            return ParseError.InvalidFormat;
        }

        if (str[4] != format[4] or str[7] != format[7]) {
            return ParseError.InvalidFormat;
        }

        const month = std.fmt.parseUnsigned(u4, str[5..7], 10) catch |err| {
            return switch (err) {
                error.InvalidCharacter => ParseError.InvalidFormat,
                error.Overflow => ParseError.MonthOutOfRange,
            };
        };

        if (month == 0 or month > 12) {
            return ParseError.MonthOutOfRange;
        }

        const day = std.fmt.parseUnsigned(u5, str[8..], 10) catch |err| {
            return switch (err) {
                error.InvalidCharacter => ParseError.InvalidFormat,
                error.Overflow => ParseError.DayOfMonthOutOfRange,
            };
        };

        if (day == 0 or day > 31) {
            return ParseError.DayOfMonthOutOfRange;
        }

        // "std.fmt.parseInt/parseUnsigned" ignores underscore between digits.
        // hours, minutes, seconds, month and days won't be affected by this because
        // all of those are 2 characters, so there is no possibility "parseUnsigned"
        // skips underscore. However, year is 4 character thus it's possible to
        // insert underscore. For example, "1__0", "20_4", "2_25".
        if (std.mem.indexOfScalar(u8, str[0..4], '_')) |_| {
            return ParseError.InvalidFormat;
        }

        return .{
            .year = std.fmt.parseUnsigned(u16, str[0..4], 10) catch {
                return ParseError.InvalidFormat;
            },
            .month = month,
            .day = day,
        };
    }

    test fromString {
        {
            const d = try fromString("2000-01-01");
            try std.testing.expectEqual(2000, d.year);
            try std.testing.expectEqual(1, d.month);
            try std.testing.expectEqual(1, d.day);
        }

        {
            const d = try fromString("1901-12-31");
            try std.testing.expectEqual(1901, d.year);
            try std.testing.expectEqual(12, d.month);
            try std.testing.expectEqual(31, d.day);
        }

        {
            const d = try fromString("2025-07-22");
            try std.testing.expectEqual(2025, d.year);
            try std.testing.expectEqual(7, d.month);
            try std.testing.expectEqual(22, d.day);
        }

        {
            const d = try fromString("9999-12-31");
            try std.testing.expectEqual(9999, d.year);
            try std.testing.expectEqual(12, d.month);
            try std.testing.expectEqual(31, d.day);
        }

        try std.testing.expectError(ParseError.InvalidFormat, fromString("1970-1-1"));
        try std.testing.expectError(ParseError.InvalidFormat, fromString("1970-01-1"));
        try std.testing.expectError(ParseError.InvalidFormat, fromString("1970-1-01"));
        try std.testing.expectError(ParseError.InvalidFormat, fromString("70-01-01"));
        try std.testing.expectError(ParseError.InvalidFormat, fromString("1970-_1-_1"));
        try std.testing.expectError(ParseError.InvalidFormat, fromString("1970-1_-1_"));
        try std.testing.expectError(ParseError.InvalidFormat, fromString("1970001001"));
        try std.testing.expectError(ParseError.InvalidFormat, fromString("1970 01 01"));
        try std.testing.expectError(ParseError.InvalidFormat, fromString("1970.01.01"));
        try std.testing.expectError(ParseError.InvalidFormat, fromString("1970/01/01"));
        try std.testing.expectError(ParseError.InvalidFormat, fromString("1970- 1- 1"));
        try std.testing.expectError(ParseError.InvalidFormat, fromString("1__0-01-01"));
        try std.testing.expectError(ParseError.InvalidFormat, fromString("19_0-01-01"));
        try std.testing.expectError(ParseError.MonthOutOfRange, fromString("1970-00-01"));
        try std.testing.expectError(ParseError.MonthOutOfRange, fromString("1970-13-01"));
        try std.testing.expectError(ParseError.DayOfMonthOutOfRange, fromString("1970-08-00"));
        try std.testing.expectError(ParseError.DayOfMonthOutOfRange, fromString("1970-08-32"));
    }
};

pub const ClockTime = packed struct {
    const format = "hh:mm:ss";

    hour: u5 = 0,
    minute: u6 = 0,
    second: u6 = 0,

    pub const ParseError = error{
        InvalidFormat,
        HourOutOfRange,
        MinuteOutOfRange,
        SecondOutOfRange,
    };

    pub fn fromString(str: []const u8) ParseError!@This() {
        if (str.len != format.len) {
            return ParseError.InvalidFormat;
        }

        if (str[2] != format[2] or str[5] != format[5]) {
            return ParseError.InvalidFormat;
        }

        const hour = std.fmt.parseUnsigned(u5, str[0..2], 10) catch |err| {
            return switch (err) {
                error.InvalidCharacter => ParseError.InvalidFormat,
                error.Overflow => ParseError.HourOutOfRange,
            };
        };

        if (hour > 23) {
            return ParseError.HourOutOfRange;
        }

        const minute = std.fmt.parseUnsigned(u6, str[3..5], 10) catch |err| {
            return switch (err) {
                error.InvalidCharacter => ParseError.InvalidFormat,
                error.Overflow => ParseError.MinuteOutOfRange,
            };
        };

        if (minute > 59) {
            return ParseError.MinuteOutOfRange;
        }

        const second = std.fmt.parseUnsigned(u6, str[6..], 10) catch |err| {
            return switch (err) {
                error.InvalidCharacter => ParseError.InvalidFormat,
                error.Overflow => ParseError.SecondOutOfRange,
            };
        };

        // Leap second
        if (second > 60) {
            return ParseError.SecondOutOfRange;
        }

        return .{
            .hour = hour,
            .minute = minute,
            .second = second,
        };
    }

    test fromString {
        {
            const t = try fromString("00:00:00");
            try std.testing.expectEqual(0, t.hour);
            try std.testing.expectEqual(0, t.minute);
            try std.testing.expectEqual(0, t.second);
        }

        {
            const t = try fromString("23:59:60");
            try std.testing.expectEqual(23, t.hour);
            try std.testing.expectEqual(59, t.minute);
            try std.testing.expectEqual(60, t.second);
        }
    }
};

pub const TimezoneOffset = struct {
    positive: bool = true,
    hour: u5 = 0,
    minute: u6 = 0,

    pub const ParseError = error{
        InvalidFormat,
        HourOutOfRange,
        MinuteOutOfRange,
    };

    pub fn fromString(str: []const u8) ParseError!@This() {
        switch (str.len) {
            1 => return if (str[0] == 'Z') .{} else ParseError.InvalidFormat,
            3, 6 => {
                const hour = std.fmt.parseUnsigned(u5, str[1..3], 10) catch |err| {
                    return switch (err) {
                        error.InvalidCharacter => ParseError.InvalidFormat,
                        error.Overflow => ParseError.HourOutOfRange,
                    };
                };

                if (hour > 23) {
                    return ParseError.HourOutOfRange;
                }

                return .{
                    .positive = switch (str[0]) {
                        '-' => false,
                        '+' => true,
                        else => return ParseError.InvalidFormat,
                    },
                    .hour = hour,
                    .minute = if (str.len == 6) minute: {
                        if (str[3] != ':') {
                            return ParseError.InvalidFormat;
                        }

                        const min = std.fmt.parseUnsigned(u6, str[4..6], 10) catch |err| {
                            return switch (err) {
                                error.InvalidCharacter => ParseError.InvalidFormat,
                                error.Overflow => ParseError.MinuteOutOfRange,
                            };
                        };

                        if (min > 59) {
                            return ParseError.MinuteOutOfRange;
                        }

                        break :minute min;
                    } else 0,
                };
            },
            else => return ParseError.InvalidFormat,
        }
    }

    test fromString {
        {
            const o = try fromString("Z");
            try std.testing.expectEqual(0, o.hour);
            try std.testing.expectEqual(0, o.minute);
        }

        {
            const o = try fromString("+09:30");
            try std.testing.expectEqual(true, o.positive);
            try std.testing.expectEqual(9, o.hour);
            try std.testing.expectEqual(30, o.minute);
        }

        {
            const o = try fromString("-00:15");
            try std.testing.expectEqual(false, o.positive);
            try std.testing.expectEqual(0, o.hour);
            try std.testing.expectEqual(15, o.minute);
        }
    }
};

pub const Datetime = struct {
    const format = std.fmt.comptimePrint("{s}T{s}", .{ CalendarDate.format, ClockTime.format });

    date: CalendarDate,
    time: ClockTime = .{},
    offset: ?TimezoneOffset = null,

    pub const ParseError = error{
        InvalidFormat,
    } || CalendarDate.ParseError || ClockTime.ParseError || TimezoneOffset.ParseError;

    pub fn fromString(str: []const u8) ParseError!@This() {
        if (str.len == CalendarDate.format.len) {
            return .{
                .date = try CalendarDate.fromString(str),
            };
        }

        if (str.len < format.len or str[CalendarDate.format.len] != format[CalendarDate.format.len]) {
            return ParseError.InvalidFormat;
        }

        return .{
            .date = try CalendarDate.fromString(str[0..CalendarDate.format.len]),
            .time = try ClockTime.fromString(str[CalendarDate.format.len + 1 .. format.len]),
            .offset = if (str.len > format.len) try TimezoneOffset.fromString(str[format.len..]) else null,
        };
    }

    test fromString {
        {
            const x = try fromString("2020-08-09");
            try std.testing.expectEqual(2020, x.date.year);
            try std.testing.expectEqual(8, x.date.month);
            try std.testing.expectEqual(9, x.date.day);
            try std.testing.expectEqual(0, x.time.hour);
            try std.testing.expectEqual(0, x.time.minute);
            try std.testing.expectEqual(0, x.time.second);
            try std.testing.expectEqual(null, x.offset);
        }

        {
            const x = try fromString("2020-08-09T12:03:48");
            try std.testing.expectEqual(2020, x.date.year);
            try std.testing.expectEqual(8, x.date.month);
            try std.testing.expectEqual(9, x.date.day);
            try std.testing.expectEqual(12, x.time.hour);
            try std.testing.expectEqual(3, x.time.minute);
            try std.testing.expectEqual(48, x.time.second);
            try std.testing.expectEqual(null, x.offset);
        }

        {
            const x = try fromString("2020-08-09T12:03:48Z");
            try std.testing.expectEqual(2020, x.date.year);
            try std.testing.expectEqual(8, x.date.month);
            try std.testing.expectEqual(9, x.date.day);
            try std.testing.expectEqual(12, x.time.hour);
            try std.testing.expectEqual(3, x.time.minute);
            try std.testing.expectEqual(48, x.time.second);
            try std.testing.expectEqual(true, x.offset.?.positive);
            try std.testing.expectEqual(0, x.offset.?.hour);
            try std.testing.expectEqual(0, x.offset.?.minute);
        }

        {
            const x = try fromString("2121-12-21T12:21:12+03:45");
            try std.testing.expectEqual(2121, x.date.year);
            try std.testing.expectEqual(12, x.date.month);
            try std.testing.expectEqual(21, x.date.day);
            try std.testing.expectEqual(12, x.time.hour);
            try std.testing.expectEqual(21, x.time.minute);
            try std.testing.expectEqual(12, x.time.second);
            try std.testing.expectEqual(true, x.offset.?.positive);
            try std.testing.expectEqual(3, x.offset.?.hour);
            try std.testing.expectEqual(45, x.offset.?.minute);
        }

        {
            const x = try fromString("2005-11-20T00:59:30-01:15");
            try std.testing.expectEqual(2005, x.date.year);
            try std.testing.expectEqual(11, x.date.month);
            try std.testing.expectEqual(20, x.date.day);
            try std.testing.expectEqual(0, x.time.hour);
            try std.testing.expectEqual(59, x.time.minute);
            try std.testing.expectEqual(30, x.time.second);
            try std.testing.expectEqual(false, x.offset.?.positive);
            try std.testing.expectEqual(1, x.offset.?.hour);
            try std.testing.expectEqual(15, x.offset.?.minute);
        }

        try std.testing.expectError(ParseError.InvalidFormat, fromString("2020-02-02 22:22:22"));
        try std.testing.expectError(ParseError.InvalidFormat, fromString("2020-02-02T22:22"));
        try std.testing.expectError(ParseError.InvalidFormat, fromString("2020-02-02T22:22Z"));
    }
};

test {
    _ = CalendarDate;
    _ = ClockTime;
    _ = Datetime;
    _ = TimezoneOffset;
}
