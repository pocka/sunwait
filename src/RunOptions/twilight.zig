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

const legacy_daylight_keywords: []const []const u8 = &.{
    "sun",
    "day",
    "light",
    "normal",
    "visible",
    "daylight",
};

const legacy_civil_keywords: []const []const u8 = &.{
    "civil",
    "civ",
};

const legacy_nautical_keywords: []const []const u8 = &.{
    "nautical",
    "nau",
    "naut",
};

const legacy_astronomical_keywords: []const []const u8 = &.{
    "astronomical",
    "ast",
    "astr",
    "astro",
};

const legacy_custom_angle_keywords: []const []const u8 = &.{
    "a",
    "angle",
    "twilightangle",
    "twilight",
};

pub const TwilightAngle = union(enum) {
    daylight: void,
    civil: void,
    nautical: void,
    astronomical: void,
    custom: f64,

    const valueless_variants: []const TwilightAngle = &.{ .daylight, .civil, .nautical, .astronomical };

    pub fn parseArg(arg: []const u8, args: *std.process.ArgIterator) ParseArgsError!@This() {
        inline for (legacy_daylight_keywords) |keyword| {
            if (std.mem.eql(u8, keyword, arg)) {
                return .daylight;
            }
        }

        inline for (legacy_civil_keywords) |keyword| {
            if (std.mem.eql(u8, keyword, arg)) {
                return .civil;
            }
        }

        inline for (legacy_nautical_keywords) |keyword| {
            if (std.mem.eql(u8, keyword, arg)) {
                return .nautical;
            }
        }

        inline for (legacy_astronomical_keywords) |keyword| {
            if (std.mem.eql(u8, keyword, arg)) {
                return .astronomical;
            }
        }

        inline for (legacy_custom_angle_keywords) |keyword| {
            if (std.mem.eql(u8, keyword, arg)) {
                const next = args.next() orelse {
                    std.log.err("{s} option requires a value", .{arg});
                    return ParseArgsError.MissingValue;
                };

                const angle = std.fmt.parseFloat(f64, next) catch {
                    std.log.err("Value of {s} must be valid floating point number", .{arg});
                    return ParseArgsError.InvalidAngle;
                };

                return .{ .custom = angle };
            }
        }

        if (std.mem.eql(u8, "--twilight", arg)) {
            const next = args.next() orelse {
                std.log.err("{s} option requires a value", .{arg});
                return ParseArgsError.MissingValue;
            };

            inline for (valueless_variants) |variant| {
                if (std.mem.eql(u8, @tagName(variant), next)) {
                    return variant;
                }
            }

            return .{
                .custom = std.fmt.parseFloat(f64, next) catch {
                    const variants = comptime variants: {
                        var buf_size: usize = 0;
                        for (valueless_variants) |variant| {
                            buf_size += @tagName(variant).len + 4;
                        }

                        var buf: [buf_size]u8 = undefined;
                        var i: usize = 0;

                        for (valueless_variants) |variant| {
                            const wrote = std.fmt.bufPrint(buf[i..], "\"{s}\", ", .{@tagName(variant)}) catch {
                                @compileError("Failed to write to comptime buffer");
                            };

                            i += wrote.len;
                        }

                        break :variants buf;
                    };
                    std.log.err("Value of {s} must be {s}or a floating point number", .{
                        arg,
                        variants,
                    });
                    return ParseArgsError.InvalidAngle;
                },
            };
        }

        return ParseArgsError.UnknownArg;
    }

    pub fn toFloat(self: @This()) f64 {
        return switch (self) {
            .daylight => -50.0 / 60.0,
            .civil => -6.0,
            .nautical => -12.0,
            .astronomical => -18.0,
            .custom => |v| v,
        };
    }
};
