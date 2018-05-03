#!/usr/bin/env bash

# Variables
DEBUG=1 # 0 (false) or 1 (true)
VOCAL=1 # 0 (false) or 1 (true)
SENSOR_MONITOR="temp1"
SENSOR_MAX="110"
LOAD_MAX="85"
ALERT_SOUND="/usr/share/sounds/purple/alert.wav"
SENSOR_ALERT=0

# Functions
playsound(){
	aplay -q "$@"
		if [ "$DEBUG" != 0 ]; then
			printf "DEBUG:  Aplay location | `which aplay`\n"
			printf "DEBUG:  Sound location | ${@}\n"
			printf "DEBUG:  Sound exists   | "
				if [ -f "${@}" ]; then printf "TRUE\n" else printf "FALSE\n"; fi
		fi
}

say(){
	simple_google_tts en "$@"
}

systemp(){
	# Grab the sensor temperature
	SENSOR_TEMP=`sensors -f | grep ${SENSOR_MONITOR} | cut -d "+" -f2 | cut -d "." -f1`

	# Test if the temperature goes over threshold
		if [ "${SENSOR_TEMP}" -ge "${SENSOR_MAX}" ]; then SENSOR_ALERT=1; else SENSOR_ALERT=0; fi
	
		if [ "$DEBUG" != 0 ]; then
			printf "DEBUG:  Sensor temperature | ${SENSOR_TEMP}°F\n"
			printf "DEBUG:  Sensor threshold   | ${SENSOR_ALERT}\n"
		fi

		if [ "$VOCAL" != 0 ]; then
			if [ "${SENSOR_TEMP}" -ge "${SENSOR_MAX}" ]; then SENSOR_THRESHOLD=" which is over your maximum sensor parameters"; fi
			say "Your temperature sensor is reading at ${SENSOR_TEMP} degrees ${SENSOR_THRESHOLD}"
		fi
}

sysload(){
	NO_CPUS=`grep processor /proc/cpuinfo | wc -l`
	CPU_LOAD_1MIN=`cat /proc/loadavg | cut -d " " -f1`
	CPU_LOAD_5MIN=`cat /proc/loadavg | cut -d " " -f2`
	CPU_LOAD_15MIN=`cat /proc/loadavg | cut -d " " -f3`
	SYSTEM_LOAD_PERCENT=`echo "scale=2; ${CPU_LOAD_1MIN}/${NO_CPUS}*100" | bc`
		if [ "$DEBUG" != 0 ]; then
			printf "DEBUG:  Number of CPUs | ${NO_CPUS}\n"
			printf "DEBUG:  CPU LoadAvg 1 minute | ${CPU_LOAD_1MIN}\n"
			printf "DEBUG:  CPU LoadAvg 5 minute | ${CPU_LOAD_5MIN}\n"
			printf "DEBUG:  CPU LoadAvg 15 minute | ${CPU_LOAD_15MIN}\n"
			printf "DEBUG:  System LoadAvg Percentage | ${SYSTEM_LOAD_PERCENT}%%\n"
		fi
		if [ "$VOCAL" != 0 ]; then
			SYSTEM_LOAD_PERCENT=`echo ${SYSTEM_LOAD_PERCENT} | cut -d "." -f1`
			if [ "${SYSTEM_LOAD_PERCENT}" -ge "${LOAD_MAX}" ]; then LOAD_THRESHOLD=" which is over your maximum load parameters"; fi
			say "You have ${NO_CPUS} cores in your machine, your current system load is at ${SYSTEM_LOAD_PERCENT} percent of capacity ${LOAD_THRESHOLD}"
		fi
}

sysmem(){
	TOTAL_MEMORY=`free -h | grep "Mem:" | awk '{print $2}'`
	INUSE_MEMORY=`free -h | grep "Mem:" | awk '{print $3}'`
	FREE_MEMORY=`free -h | grep "Mem:" | awk '{print $4}'`
	FREE_SWAP=`free -h | grep "Swap:" | awk '{print $3}'`
	MEMORY_FREE_PERCENT=`free | grep Mem | awk '{print $3/$2 * 100.0}'`
		if [ "$DEBUG" != 0 ]; then
			printf "DEBUG:  Total memory | ${TOTAL_MEMORY}\n"
			printf "DEBUG:  Free memory | ${FREE_MEMORY}\n"
			printf "DEBUG:  In-use memory | ${INUSE_MEMORY}\n"
			printf "DEBUG:  In-use memory percentage | ${MEMORY_FREE_PERCENT}%%\n"
		fi
		if [ "$VOCAL" != 0 ]; then
			MEMORY_FREE_PERCENT=`echo ${MEMORY_FREE_PERCENT} | cut -d "." -f1`
			if [ "$FREE_SWAP" == "0B" ]; then FREE_SWAP="none"; fi
			say "Your system has ${TOTAL_MEMORY} of memory, your usage percentage is currently at ${MEMORY_FREE_PERCENT} percent, you are currently using ${FREE_SWAP} of swap"
		fi
}

sysspeedtest(){
	SPEEDTEST=`speedtest-cli --simple > /tmp/stcli.tmp`
	SPEEDTEST_PING=`cat /tmp/stcli.tmp | grep Ping: | cut -d ":" -f2`
	SPEEDTEST_DL=`cat /tmp/stcli.tmp | grep Download: | cut -d ":" -f2`
	SPEEDTEST_UL=`cat /tmp/stcli.tmp | grep Upload: | cut -d ":" -f2`	
		if [ "$DEBUG" != 0 ]; then
			printf "DEBUG:  Ping | ${SPEEDTEST_PING}\n"
			printf "DEBUG:  Download | ${SPEEDTEST_DL}\n"
			printf "DEBUG:  Upload | ${SPEEDTEST_UL}\n"
		fi
		if [ "$VOCAL" != 0 ]; then
			say "Your internet ping is averaging ${SPEEDTEST_PING}, your download speed is at ${SPEEDTEST_DL} with an upload speed of ${SPEEDTEST_UL}"
		fi
	rm -f /tmp/stcli.tmp
}

while test $# -gt 0; do
		case "$1" in
			-h|--help)
					version
					echo "options:"
					echo -e "-h, --help\tIts what youre looking at!"
					echo -e "-t, --temp\tQuery system temperature"
					echo -e "-l, --load\tQuery system load"
					echo -e "-m, --mem\tQuery system memory"
					echo -e "-s, --speed\tQuery system internet (WAN) speed"
					exit 0
					;;
			-t|--temp)
					systemp
					shift
					;;
			-l|--load)
					sysload
					shift
					;;
			-m|--mem)
					sysmem
					shift
					;;						
			-s|--speed)
					printf "Testing internet speed...please wait (this could take some time)\n"
					sysspeedtest
					;;
			*)
					break
					;;
					esac
done
printf "I'm much more useful if you give me a task.  Use -h for help!\n"
exit 1
