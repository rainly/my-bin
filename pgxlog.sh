#!/bin/sh

. pgcommon.sh

SECS=

usage ()
{
    echo "$PROGNAME lists WAL files"
    echo ""
    echo "Usage:"
    echo "  $PROGNAME [OPTIONS] [PGDATA]"
    echo ""
    echo "Description:"
    echo "  By default, the WAL files in pg_xlog are listed once"
    echo ""
    echo "Options:"
    echo "  -n SECS   interval; lists every SECS"
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
	    usage
	    exit 0;;
		-n)
	    SECS=$2
			shift;;
		-*)
			elog "invalid option: $1";;
		*)
			update_pgdata "$1";;
	esac
	shift
done

here_is_installation
pgdata_exists

if [ -z "$SECS" ]; then
	ls $PGXLOG
else
	watch -n$SECS "pgxlog.sh $PGDATA"
fi
