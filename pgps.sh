#!/bin/sh

. pgcommon.sh

BATCH=false
DELAY=1
ONETIME=false
FORMAT="u"

usage ()
{
    echo "$PROGNAME provides a dynamic real-time view of running postgres processes."
    echo ""
    echo "Usage:"
    echo "  $PROGNAME [OPTIONS]"
		echo ""
		echo "Description:"
    echo "  By default, screen is updated every 1 second."
    echo ""
    echo "Options:"
    echo "  -b          batch mode; reports running processes in a row"
    echo "  -d SECS     specifies the delay between screen updates or"
		echo "              reports in batch mode"
		echo "  -o FORMAT   uses user-defined format, e.g., -o pid"
		echo "  u           uses user-oriented format (default format)"
    echo "  -1          1-time mode; reports running processes only once"
		echo ""
		echo "Notes:"
		echo "  -1 is given priority over -b if both are specified."
}

while [ $# -gt 0 ]; do
	case "$1" in
		-b)
			BATCH=true;;
		-d)
			DELAY="$2"
			shift;;
		"-?"|--help)
			usage
			exit 0;;
		-o)
			FORMAT="-o $2"
			shift;;
		u)
			FORMAT="u";;
		-1)
			ONETIME=true;;
		*)
			elog "invalid option: $1";;
	esac
	shift
done

report_pgsql_processes ()
{
	date

	for processname in postgres postmaster; do
		PIDLIST=$(pgrep -d, -x $processname)
		if [ ! -z "$PIDLIST" ]; then
			ps $FORMAT -p $PIDLIST
			echo ""
			return
		fi
	done
}

if [ "$ONETIME" = "true" ]; then
	report_pgsql_processes
	exit 0
fi

if [ "$BATCH" = "true" ]; then
	while [ 1 ]; do
		report_pgsql_processes
		sleep $DELAY
	done
else
	watch -n$DELAY "$PROGNAME -1 $FORMAT"
fi
