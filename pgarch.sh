#!/bin/sh

. pgcommon.sh

usage ()
{
	echo "$PROGNAME enables WAL archiving"
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [PGDATA]"
	echo ""
	echo "Description:"
	echo "  This utility sets up the configuration parameters related to WAL archiving"
	echo "  and creates the archival directory."
}

while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help|"-\?")
			usage
			exit 0;;
		-*)
			echo "$PROGNAME: invalid option: $1" 1>&2
			exit 1;;
		*)
			update_pgdata "$1";;
	esac
	shift
done

here_is_installation
archiving_is_supported
check_directory_exists $PGDATA "database cluster"

rm -rf $PGARCH
mkdir $PGARCH

if [ $PGMAJOR -ge 90 ]; then
	set_guc wal_level archive $PGCONF
fi

if [ $PGMAJOR -ge 83 ]; then
	set_guc archive_mode on $PGCONF
fi

set_guc archive_command "'cp %p ../$(basename $PGARCH)/%f'" $PGCONF
