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

const ParseArgsError = @import("./parser.zig").ParseArgsError;

const format = "YYYY-MM-DD";

/// Timezone-free date. Each fields' size is same to ones of `std.time.epoch`,
/// in case integration will be added.
pub const CalendarDate = packed struct {
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

        if (str[4] != '-' or str[7] != '-') {
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
        try std.testing.expectError(ParseError.MonthOutOfRange, fromString("1970-00-01"));
        try std.testing.expectError(ParseError.MonthOutOfRange, fromString("1970-13-01"));
        try std.testing.expectError(ParseError.DayOfMonthOutOfRange, fromString("1970-08-00"));
        try std.testing.expectError(ParseError.DayOfMonthOutOfRange, fromString("1970-08-32"));
    }
};

test {
    _ = CalendarDate;
}
