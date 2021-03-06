#!/bin/sh

. bincommon.sh

GREP_PATTERN=
GREP_OPTIONS=
FIND_PATTERN="*"
SEARCH_DIR="."
EXCLUDE="-name .git -prune -or"

usage ()
{
	echo "$PROGNAME prints lines matching GREP_PATTERN from files matching FIND_PATTERN."
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS] GREP_PATTERN [FIND_PATTERN]"
	echo "Options:"
	echo "  -d DIR    where to search (default: .)"
	echo "  -i        ignore case distinctions in GREP_PATTERN"
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-d)
			SEARCH_DIR="$2"
			shift;;
		-i)
			GREP_OPTIONS="$GREP_OPTIONS -i";;
		-*)
			elog "invalid option: $1";;
		*)
			if [ -z "$GREP_PATTERN" ]; then
				GREP_PATTERN="$1"
			elif [ "$FIND_PATTERN" = "*" ]; then
				FIND_PATTERN="$1"
			else
				elog "too many arguments"
			fi
			;;
	esac
	shift
done

if [ -z "$GREP_PATTERN" ]; then
	elog "GREP_PATTERN must be supplied"
fi

find $SEARCH_DIR $EXCLUDE -name "$FIND_PATTERN" -exec grep -Hn $GREP_OPTIONS "$GREP_PATTERN" {} \;
