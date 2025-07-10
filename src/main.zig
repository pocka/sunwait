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

const ExitCode = enum(u8) {
    ok = 0,
    generic_error = 1,
    day = 2,
    night = 3,

    pub fn code(self: ExitCode) u8 {
        return @intFromEnum(self);
    }
};

const RunOptions = struct {
    latitude: f64 = c.DEFAULT_LATITUDE,
    longitude: f64 = c.DEFAULT_LONGITUDE,
    offset_hour: f64 = 0,
    twilight_angle: f64 = c.TWILIGHT_ANGLE_DAYLIGHT,
    now: c.time_t = 0,
    target_time: c.time_t = 0,
    now_delta: c_ulong = 0,
    target_delta: c_ulong = 0,
    function_version: c.OnOff = c.ONOFF_OFF,
    function_usage: c.OnOff = c.ONOFF_OFF,
    function_report: c.OnOff = c.ONOFF_OFF,
    function_list: c.OnOff = c.ONOFF_OFF,
    function_poll: c.OnOff = c.ONOFF_OFF,
    function_wait: c.OnOff = c.ONOFF_OFF,
    utc: c.OnOff = c.ONOFF_OFF,
    debug: c.OnOff = c.ONOFF_OFF,
    report_sunrise: c.OnOff = c.ONOFF_OFF,
    report_sunset: c.OnOff = c.ONOFF_OFF,
    list_days: c_uint = c.DEFAULT_LIST,
    utc_bias_hours: f64 = 0,

    pub fn init() @This() {
        var opts = RunOptions{};

        _ = c.time(&opts.now);
        opts.now_delta = c.daysSince2000(&opts.now);

        return opts;
    }

    pub fn toC(self: *const RunOptions) c.runStruct {
        return c.runStruct{
            .latitude = self.latitude,
            .longitude = self.longitude,
            .offsetHour = self.offset_hour,
            .twilightAngle = self.twilight_angle,
            .nowTimet = self.now,
            .targetTimet = self.target_time,
            .now2000 = self.now_delta,
            .target2000 = self.target_delta,
            .functionVersion = self.function_version,
            .functionUsage = self.function_usage,
            .functionReport = self.function_report,
            .functionList = self.function_list,
            .functionPoll = self.function_poll,
            .functionWait = self.function_wait,
            .utc = self.utc,
            .debug = self.debug,
            .reportSunrise = self.report_sunrise,
            .reportSunset = self.report_sunset,
            .listDays = self.list_days,
            .utcBiasHours = self.utc_bias_hours,
        };
    }
};

pub fn main() u8 {
    const opts = RunOptions.init();
    var c_opts = opts.toC();

    return switch (c.sunpoll(&c_opts)) {
        c.EXIT_DAY => ExitCode.day.code(),
        c.EXIT_NIGHT => ExitCode.night.code(),
        else => ExitCode.generic_error.code(),
    };
}
