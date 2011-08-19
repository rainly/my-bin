#!/bin/sh

. pgcommon

usage ()
{
	echo "$PROGNAME creates \"etags\" files"
	echo ""
	echo "Usage:"
	echo "  $PROGNAME"
}

while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help|"-\?")
			usage
			exit 0;;
		*)
			elog "invalid option: $1";;
	esac
	shift
done

here_is_source

$CURDIR/src/tools/make_etags
