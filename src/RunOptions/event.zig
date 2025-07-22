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

const sunrise_keywords: []const []const u8 = &.{
    "sunrise",
    "rise",
    "dawn",
    "sunup",
    "up",
};

const sunset_keywords: []const []const u8 = &.{
    "sunset",
    "set",
    "dusk",
    "sundown",
    "down",
};

pub const EventType = enum {
    sunset,
    sunrise,

    // sunset and sunrise
    both,

    pub fn parseArg(current: ?@This(), arg: []const u8, args: *std.process.ArgIterator) ParseArgsError!@This() {
        // Compatibility
        inline for (sunrise_keywords) |keyword| {
            if (std.mem.eql(u8, keyword, arg)) {
                return .sunrise;
            }
        }

        // Compatibility
        inline for (sunset_keywords) |keyword| {
            if (std.mem.eql(u8, keyword, arg)) {
                return .sunset;
            }
        }

        if (std.mem.eql(u8, "--event", arg) or std.mem.eql(u8, "-e", arg)) {
            const next = args.next() orelse {
                std.log.err("{s} option requires a value", .{arg});
                return ParseArgsError.MissingValue;
            };

            if (std.mem.eql(u8, "sunrise", next)) {
                return if (current) |e| switch (e) {
                    .sunset => .both,
                    else => e,
                } else .sunrise;
            }

            if (std.mem.eql(u8, "sunset", next)) {
                return if (current) |e| switch (e) {
                    .sunrise => .both,
                    else => e,
                } else .sunset;
            }

            std.log.err("Value of {s} must be either `sunrise` or `sunset`: got {s}", .{ arg, next });
            return ParseArgsError.InvalidEventType;
        }

        return ParseArgsError.UnknownArg;
    }
};
