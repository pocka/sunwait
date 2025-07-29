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

# Overall architecture is from Jujutsu's bash completion script.
# You can see it by `jj util completion bash`

_sunwait() {
	local i current cmd prev opts common_opts
	COMPREPLY=()
	current="${COMP_WORDS[COMP_CWORD]}"
	cmd=""
	prev="$3"
	opts=""
	common_opts="-h --help -v --version --debug --utc --latitude --longitude --twilight -o --offset "

	for i in "${COMP_WORDS[@]:0:COMP_CWORD}"
	do
		case "${cmd},${i}" in
			",$1")
				cmd="sunwait"
			;;
			sunwait,poll)
				cmd="sunwait__poll"
			;;
			sunwait,list)
				cmd="sunwait__list"
			;;
			sunwait,report)
				cmd="sunwait__report"
			;;
			sunwait,wait)
				cmd="sunwait__wait"
			;;
		esac
	done

	case "${cmd}" in
		# sunwait [OPTIONS]
		sunwait)
			opts="${common_opts} poll list report wait"
			if [[ ${current} == -* || ${COMP_CWORD} -eq 1 ]]; then
				COMPREPLY=($(compgen -W "${opts}" -- "${current}"))
				return 0
			fi
			case "${prev}" in
				--latitude)
					COMPREPLY=()
					return 0
				;;
				--longitude)
					COMPREPLY=()
					return 0
				;;
				-o)
					COMPREPLY=()
					return 0
				;;
				--offset)
					COMPREPLY=()
					return 0
				;;
				--twilight)
					COMPREPLY=($(compgen -W "daylight civil nautical astronomical" -- "${current}"))
					return 0
				;;
			esac
			COMPREPLY=($(compgen -W "${opts}" -- "${current}"))
			return 0
		;;
		# sunwait poll [OPTIONS]
		sunwait__poll)
			opts="${common_opts} --at"
			if [[ ${current} == -* || ${COMP_CWORD} -eq 2 ]]; then
				COMPREPLY=($(compgen -W "${opts}" -- "${current}"))
				return 0
			fi
			case "${prev}" in
				--latitude)
					COMPREPLY=()
					return 0
				;;
				--longitude)
					COMPREPLY=()
					return 0
				;;
				-o)
					COMPREPLY=()
					return 0
				;;
				--offset)
					COMPREPLY=()
					return 0
				;;
				--twilight)
					COMPREPLY=($(compgen -W "daylight civil nautical astronomical" -- "${current}"))
					return 0
				;;
				--at)
					COMPREPLY=()
					return 0
				;;
			esac
			COMPREPLY=($(compgen -W "${opts}" -- "${current}"))
			return 0
		;;
		# sunwait wait [OPTIONS]
		sunwait__wait)
			opts="${common_opts} -e --event"
			if [[ ${current} == -* || ${COMP_CWORD} -eq 2 ]]; then
				COMPREPLY=($(compgen -W "${opts}" -- "${current}"))
				return 0
			fi
			case "${prev}" in
				--latitude)
					COMPREPLY=()
					return 0
				;;
				--longitude)
					COMPREPLY=()
					return 0
				;;
				-o)
					COMPREPLY=()
					return 0
				;;
				--offset)
					COMPREPLY=()
					return 0
				;;
				--twilight)
					COMPREPLY=($(compgen -W "daylight civil nautical astronomical" -- "${current}"))
					return 0
				;;
				-e)
					COMPREPLY=($(compgen -W "sunrise sunset" -- "${current}"))
					return 0
				;;
				--event)
					COMPREPLY=($(compgen -W "sunrise sunset" -- "${current}"))
					return 0
				;;
			esac
			COMPREPLY=($(compgen -W "${opts}" -- "${current}"))
			return 0
		;;
		# sunwait report [OPTIONS]
		sunwait__report)
			opts="${common_opts} --date"
			if [[ ${current} == -* || ${COMP_CWORD} -eq 2 ]]; then
				COMPREPLY=($(compgen -W "${opts}" -- "${current}"))
				return 0
			fi
			case "${prev}" in
				--latitude)
					COMPREPLY=()
					return 0
				;;
				--longitude)
					COMPREPLY=()
					return 0
				;;
				-o)
					COMPREPLY=()
					return 0
				;;
				--offset)
					COMPREPLY=()
					return 0
				;;
				--twilight)
					COMPREPLY=($(compgen -W "daylight civil nautical astronomical" -- "${current}"))
					return 0
				;;
				--date)
					COMPREPLY=()
					return 0
				;;
			esac
			COMPREPLY=($(compgen -W "${opts}" -- "${current}"))
			return 0
		;;
		# sunwait list [OPTIONS]
		sunwait__list)
			opts="${common_opts} --from -e --event"
			if [[ ${current} == -* || ${COMP_CWORD} -eq 2 ]]; then
				COMPREPLY=($(compgen -W "${opts}" -- "${current}"))
				return 0
			fi
			case "${prev}" in
				--latitude)
					COMPREPLY=()
					return 0
				;;
				--longitude)
					COMPREPLY=()
					return 0
				;;
				-o)
					COMPREPLY=()
					return 0
				;;
				--offset)
					COMPREPLY=()
					return 0
				;;
				--twilight)
					COMPREPLY=($(compgen -W "daylight civil nautical astronomical" -- "${current}"))
					return 0
				;;
				--from)
					COMPREPLY=()
					return 0
				;;
				-e)
					COMPREPLY=($(compgen -W "sunrise sunset" -- "${current}"))
					return 0
				;;
				--event)
					COMPREPLY=($(compgen -W "sunrise sunset" -- "${current}"))
					return 0
				;;
			esac
			COMPREPLY=($(compgen -W "${opts}" -- "${current}"))
			return 0
		;;
	esac
}

complete -F _sunwait sunwait
