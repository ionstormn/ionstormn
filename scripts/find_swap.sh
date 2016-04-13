#!/bin/bash
# Find Processes Using Swap Space
#################################
# Version: 1.1
# TODO: Add MB parsing as an option.

######################
# Initialize Variables
######################
swap_pid=""
swap_name=""
swap_size=""
swap_color="false"
swap_filename=""

###########
# Functions
###########

usage() {
	echo "Usage: $(basename $0) [-hcf [Filename]]"
	echo "  -f 		Write to a specified file."
	echo "  -c 		Color Mode Enabled."
	echo "  -h 		Display this help message."
}

err() {
	echo "[$(basename $0)]-[$(date +'%Y-%m-%dT%H:%M:%S%z')]-[ERROR]: $@" >&2
}


############
# Parse Args
############

while getopts "hcf:" opt; do
	case "$opt" in
		h)
			usage
			exit 0
			;;
		c)
			swap_color="true"
			;;
		f)
			if [[ -d `dirname "${OPTARG}"` ]]; then 
				swap_filename="${OPTARG}"
			else
				err "`dirname ${OPTARG}` Cannot be found."
				err "Make sure the directory exists."
				exit 1
			fi
			;;
		*)
			err "Invalid Arg ${opt}"
			usage
			exit 1
			;;
	esac
done
shift "$(( OPTIND-1 ))"

if [[ $# -gt 0 ]]; then
	err "Unrecognized argument"
	usage
	exit 0
fi

######################################
# Capture Output of Loop into Variable
######################################

swap_output=$(for file in /proc/*/status 
do 
	if [[ -e $file ]]; then
		swap_name=`grep --color "Name" $file | cut -f 2`
		swap_pid=`grep --color "^Pid:" $file | cut -f 2`
		swap_size=`grep --color "VmSwap:" $file | cut -f 2`
	fi

	if [[ ! $( cut -d" " -f 1 <<< ${swap_size} ) -eq 0 ]]; then
		printf "Name: %10s\tPID: %05s\t Swap: %s\n" \
				"${swap_name}" "${swap_pid}" "${swap_size}"
	fi
done | sort -k 6 -n -r)

######################################
# Process Output Using While Read loop
######################################

if [[ -n "$swap_filename" ]]; then
	while IFS= read -r line; do
		printf "${line}\n"
	done <<< "${swap_output}" > "${swap_filename}"
	swap_filename_status="$?"
	if [[ "${swap_filename_status}" -eq 0 ]]; then
		echo "Written to ${swap_filename}"
		exit 0
	else
		err "Failed to write to ${swap_filename}"
		exit 1
	fi
fi

while IFS= read -r line; do
	if [[ "${swap_color}" == "true" ]]; then
		sed -e 's/Name:/'$(printf "\e[m%s\e[1;32m" "Name:")'/g' \
			-e 's/PID:/'$(printf "\e[m%s\e[1;33m" "PID:")'/g' \
			-e 's/Swap:/'$(printf "\e[m%s\e[1;31m" "Swap:")'/g' <<< "${line}"
		else
			printf "${line}\n"
	fi
done <<< "$swap_output"


### Tests
##	awk '/VmSwap|Name/ {printf $2 " " $3} END { print ""}' $file
# done | sort -k 6 -n -r | \
		# if [[ $swap_color == "true" ]]; then
		# 	sed -e 's/Name:/'$(printf "\e[m%s\e[1;32m" "Name:")'/g' \
		# 		-e 's/PID:/'$(printf "\e[m%s\e[1;33m" "PID:")'/g' \
		# 		-e 's/Swap:/'$(printf "\e[m%s\e[1;31m" "Swap:")'/g'
# 			exit 0
# 		else
# 			cat
# 			exit 0
# 		fi
## "Name: \e[1;32m%10s\e[m\tPID: \e[1;33m%05s\e[m\t Swap: \e[1;31m%s\e[m\n"