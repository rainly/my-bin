#!/bin/sh

. pgcommon.sh

Usage ()
{
	echo "${PROGNAME} prints line matching PATTERN"
	echo ""
	echo "Usage:"
	echo "  ${PROGNAME} [-h] PATTERN [doc]"
}

here_is_source
while getopts "h" OPT; do
	case ${OPT} in
		h)
			Usage
			exit 0;;
		*)
			exit 1;;
	esac
done
shift $(expr ${OPTIND} - 1)

if [ ${#} -lt 1 ]; then
	echo "ERROR: PATTERN must be supplied"
	exit 1
fi
PATTERN="${1}"
OPERATION="${2}"

REGEXP=
SEARCHPATH=
case ${OPERATION} in
	"doc")
		REGEXP="*.sgml"
		SEARCHPATH=doc;;
	*)
		REGEXP="*.[chy]"
		SEARCHPATH=src;;
esac

find ${SEARCHPATH} -name "${REGEXP}" -exec grep -H "${PATTERN}" {} \;
