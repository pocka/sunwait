#compdef sunwait

# Copyright (C) 2025 Shota FUJI
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: GPL-3.0-only

function _sunwait {
	local line state

	_arguments -C \
		{-h,--help}"[Prints usage to stdout and exits]" \
		{-v,--version}"[Prints version to stdout and exits]" \
		"--debug[Prints debug log and shortens wait duration to 1 min]" \
		"--utc[Parses timezone-less dates and times as UTC]" \
		{--lat,--latitude}"[Latitude in degree, signed float or positive float with N/S suffix]:degree:" \
		{--lon,--longitude}"[Longitude in degree, signed float or positive float with E/W suffix]:degree:" \
		"--twilight[Twilight type or angle]:type:->twilight" \
		{-o,--offset}"[Time offset in minutes]:minutes:" \
		"1: :->command" \
		"*::arg:->args"

	case "$state" in
		(command)
			_values "command" \
				"poll[Prints DAY or NIGHT]" \
				"wait[Wait until next sunrise or sunset]" \
				"report[Prints detailed report for sunrise and sunset]" \
				"list[List sunrise and/or sunset for next N days]"
		;;
		(twilight)
			_values "twilight" \
				"daylight" \
				"civil" \
				"nautical" \
				"astronomical"
		;;
		(args)
			case $line[1] in
				(poll)
					_sunwait_poll
				;;
				(wait)
					_sunwait_wait
				;;
				(report)
					_sunwait_report
				;;
				(list)
					_sunwait_list
				;;
			esac
		;;
	esac
}

function _sunwait_poll {
	_arguments "--at[YYYY-MM-DDThh:mm:ssZ]:datetime:"
}

function _sunwait_wait {
	local state

	_arguments -C \
		\*{-e,--event}"[Events to wait]:type:->event"

	case "$state" in
		(event)
			_values "event" \
				"sunrise[Waits for sunrise]" \
				"sunset[Waits for sunset]"
		;;
	esac
}

function _sunwait_report {
	local state

	_arguments -C \
		"--date[Date to generate report for, in YYYY-MM-DD]:date:->date"

	case "$state" in
		(date)
			_values "date" "$(date -Idate)[Current date]"
		;;
	esac
}

function _sunwait_list {
	local state

	_arguments -C \
		"--from[Start date in YYYY-MM-DD]:date:->date" \
		\*{-e,--event}"[Events to print]:type:->event" \
		"1:days:"

	case "$state" in
		(event)
			_values "event" \
				"sunrise[List sunrise times]" \
				"sunset[List sunset times]"
		;;
		(date)
			_values "date" "$(date -Idate)[Current date]"
		;;
	esac
}

if [ "$funcstack[1]" = "_sunwait" ]; then
	_sunwait "$@"
else
	compdef _sunwait sunwait
fi
