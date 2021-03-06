#!/bin/sh

. pgcommon.sh

usage ()
{
	echo "$PROGNAME removes the deletable PostgreSQL directories."
	echo ""
	echo "Usage:"
	echo "  $PROGNAME"
	echo ""
	echo "Description:"
	echo "  All obsolete database cluster, archive and backup directories"
	echo "  are removed from current directory."
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		*)
			elog "invalid option: $1";;
	esac
	shift
done

here_is_installation

for pgdata in $(find_all_pgdata); do
	update_pgdata "$pgdata"

	$PGBIN/pg_ctl -D $PGDATA status > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "could not delete \"$PGDATA\": PostgreSQL is still running"
		continue
	fi

	TARGETS="$PGDATA $PGDATABKP $PGARCH $PGARCHBKP"
	for target in $TARGETS; do
		if [ ! -d $target ]; then
			continue
		fi

		echo "rm -rf $target"
		rm -rf "$target"
	done
done
