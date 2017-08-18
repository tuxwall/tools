#!/bin/bash
#
# Copyright (c) 2017 Igor Pecovnik, igor.pecovnik@gma**.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.

# check for root
#
if [[ $EUID != 0 ]]; then
	echo "Warning. This script requires root privileges. Exiting ..."
	sleep 2
	exit
fi


# search for wlan interfaces and provide a selection menu if there are more than one
#

function description
{
	case $1 in
		*header*)
			echo "Big board logo and kernel info"
		;;
		*sysinfo*)
			echo "Sysinfo - load, ip, memory, uptime, ..."
		;;
		*tips*)
			echo "Shows tip of the day"
		;;
		*updates*)
			echo "Display number of avaliable updates"
		;;
		*armbian-config*)
			echo "Show command for system configuration"
		;;
		*autoreboot-warn*)
			echo "Show warning when reboot is needed"
		;;
		*)
		echo ""
		;;
	esac
}

function select_interface ()
{
	IFS=$'\r\n'
	GLOBIGNORE='*'
	WLAN_INTERFACES=($(nmcli dev status | grep "^[ewrl]" | grep -v lo | sort |awk '{print $1}'))
	local LIST=()
	for i in "${WLAN_INTERFACES[@]}"
	do
			LIST+=( "${i[0]//[[:blank:]]/}" "" )
	done
	LIST_LENGHT=$((${#LIST[@]}/2));
	if [ "$LIST_LENGHT" -eq 1 ]; then
			WIRELESS_ADAPTER=${WLAN_INTERFACES[0]}
	else
			exec 3>&1
			WIRELESS_ADAPTER=$(dialog --nocancel --backtitle "$BACKTITLE" --no-collapse \
			--title "Select $1 interface" --clear --menu "" $((6+${LIST_LENGHT})) 30 15 "${LIST[@]}" 2>&1 1>&3)
			exec 3>&-
	fi
}

function bridge_interfaces ()
{
	IFS=$''
	GLOBIGNORE=''
	local home="/tmp/bridge/"
	mkdir -p $home
	#
	nmcli dev status | grep "^[ewrl]" | grep -v lo | grep -v $1 | sort |awk '{print $1}' |  awk -v var=$home '{print var $0}' | xargs touch

	while true; do
		MOTD=()
		LINES=()
		LIST_CONST=6
		j=0
		DIALOG_CANCEL=1
		DIALOG_ESC=255

		while read line
		do
			STATUS=$([[ -x ${home}${line} ]] && echo "on")
			DESC=$(description "$line")
			MOTD+=( "$line" "$DESC" "$STATUS")
			LINES[ $j ]=$line
			(( j++ ))
		done < <(ls -1 $home)

				LISTLENGHT="$(($LIST_CONST+${#MOTD[@]}/2))"

				exec 3>&1
				selection=$(dialog --backtitle "$BACKTITLE" --title "Toggle motd executing scripts" --clear --cancel-label \
				"Exit" --ok-label "Save" --checklist "\nChoose what you want to enable or disable:\n " \
				$LISTLENGHT 70 15 "${MOTD[@]}" 2>&1 1>&3)
				exit_status=$?
				exec 3>&-
				case $exit_status in
				$DIALOG_CANCEL | $DIALOG_ESC)
						break
						;;
				0)
						chmod -x ${home}*
						chmod +x $(echo "$selection" | sed "s|[^ ]* *|${home}&|g")
						ls /tmp/bridge/
						echo "chmod -x ${home}*"
						exit
				;;
				esac
		done
}

# select WLAN interface
select_interface "wan"

bridge_interfaces "$WIRELESS_ADAPTER"
exit 0