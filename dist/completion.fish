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

set -l commands poll wait report list
set -l events sunrise sunset

complete -c sunwait --no-files

# sunwait [OPTIONS]

complete -c sunwait --short h --long help -d "Prints usage to stdout and exits"
complete -c sunwait --short v --long version -d "Prints version to stdout and exits"
complete -c sunwait --long debug -d "Prints debug log and shortens wait duration to 1 min"
complete -c sunwait --long utc -d "Parses timezone-less dates and times as UTC"

complete -c sunwait \
	--long latitude --require-parameter --no-files \
	--description "Latitude in degree, signed float or positive float with N/S suffix"

complete -c sunwait \
	--long longitude --require-parameter --no-files \
	--description "Longitude in degree, signed float or positive float with E/W suffix"

complete -c sunwait \
	--long twilight --require-parameter --no-files \
	--argument "daylight civil nautical astronomical" \
	--description "Twilight type or angle"

complete -c sunwait \
	--short o --long offset --require-parameter --no-files \
	--description "Time offset in minutes"

complete -c sunwait \
	--condition "not __fish_seen_subcommand_from $commands" \
	-a "$commands"

# sunwait poll [OPTIONS]

complete -c sunwait \
	--condition "__fish_seen_subcommand_from poll" \
	--long at --require-parameter --no-files \
	--description "YYYY-MM-DDThh:mm:ssZ"

# sunwait wait [OPTIONS]

complete -c sunwait \
	--condition "__fish_seen_subcommand_from wait" \
	--short e --long event --require-parameter --no-files \
	--argument "$events" \
	--description "Events to wait for"

# sunwait report [OPTIONS]

complete -c sunwait \
	--condition "__fish_seen_subcommand_from report" \
	--long date --require-parameter --no-files \
	--description "Date to generate report of, in YYYY-MM-DD"

# sunwait list [OPTIONS]

complete -c sunwait \
	--condition "__fish_seen_subcommand_from list" \
	--long from --require-parameter --no-files \
	--description "Start date, in YYYY-MM-DD"

complete -c sunwait \
	--condition "__fish_seen_subcommand_from list" \
	--short e --long event --require-parameter --no-files \
	--argument "$events" \
	--description "Events to print"
