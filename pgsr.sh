#!/bin/bash

. pgcommon.sh

ACTDATA=$CURDIR/act
ACTCONF=$ACTDATA/postgresql.conf
ACTPORT=5432
ACTHBA=$ACTDATA/pg_hba.conf
ACTPREFIX=act
ACTARCH=$CURDIR/act.arh

SBYDATA=$CURDIR/sby
SBYCONF=$SBYDATA/postgresql.conf
SBYPORT=5433
SBYPREFIX=sby
SBYNUM=1
SBYMAX=16

PGBKP=$ACTDATA.bkp
TRIGGER=$CURDIR/trigger
RECCONF=$SBYDATA/recovery.conf

usage ()
{
	echo "$PROGNAME sets up streaming replication."
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS]"
	echo ""
	echo "Default:"
	echo "  This utility sets up primary and standby servers"
	echo "  without the archive."
	echo ""
	echo "Options:"
	echo "  -a, --archive    uses the archive"
	echo "  -C, --conflict   creates standby query conflict"
	echo "  -n  NUMBER       specifys number of standbys"
	echo "  -p, --primary    sets up only primary server"
	echo "  -q, --quit       shuts down servers with fast mode"
	echo "  -s, --standby    sets up only standby server"
	echo "  -S, --sync       sets up synchronous replication"
}

ONLYACT="FALSE"
ONLYSBY="FALSE"
USEARCH="FALSE"
SYNCREP="FALSE"
QUITMODE="FALSE"
MKCONFLICT="FALSE"
while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-a|--archive)
			USEARCH="TRUE";;
		-C|--conflict)
			MKCONFLICT="TRUE";;
		-n)
			SBYNUM=$2
			shift;;
		-p|--primary)
			ONLYACT="TRUE";;
		-q|--quit)
			QUITMODE="TRUE";;
		-s|--standby)
			ONLYSBY="TRUE";;
		-S|--sync)
			SYNCREP="TRUE";;
		*)
			elog "invalid option: $1";;
	esac
	shift
done

here_is_installation

if [ $PGMAJOR -lt 90 ]; then
	elog "streaming replication is NOT supported in $($PGBIN/pg_config --version)"
fi

setup_primary ()
{
	pgsql_is_dead $ACTDATA

	pginitdb.sh $ACTDATA

	if [ "$USEARCH" = "TRUE" ]; then
		pgarch.sh $ACTDATA
	fi

	set_guc port $ACTPORT $ACTCONF
	set_guc log_line_prefix "'$ACTPREFIX '" $ACTCONF
	set_guc max_wal_senders $(expr $SBYNUM + 4) $ACTCONF
	set_guc wal_level hot_standby $ACTCONF
	set_guc wal_keep_segments 32 $ACTCONF

	if [ "$SYNCREP" = "TRUE" ]; then
		set_guc synchronous_standby_names "'*'" $ACTCONF
	fi

	echo "host replication all 0.0.0.0/0 trust" >> $ACTHBA
	echo "host replication all ::1/128   trust" >> $ACTHBA

	pgstart.sh -w $ACTDATA
}

prepare_standbys ()
{
	NEXTID=0
	for i in $(seq 1 $SBYNUM); do
		for j in $(seq $NEXTID $SBYMAX); do
			$PGBIN/pg_ctl -D $SBYDATA$j status > /dev/null
			if [ $? -ne 0 ]; then
				SBYID[$i]=$j
				SBYDATA[$i]=$SBYDATA$j
				SBYCONF[$i]=$SBYDATA$j/postgresql.conf
				SBYPORT[$i]=$(expr $SBYPORT + $j)
				SBYPREFIX[$i]=$SBYPREFIX$j
				TRIGGER[$i]=$TRIGGER$j
				RECCONF[$i]=$SBYDATA$j/recovery.conf

				NEXTID=$(expr $j + 1)
				if [ $NEXTID -gt $SBYMAX ]; then
					elog "could not set up the specified number of standbys"
				fi
				break
			fi
		done
	done
}

setup_standby ()
{
	prepare_standbys

	for i in $(seq 1 $SBYNUM); do
		pgsql_is_dead ${SBYDATA[$i]}
		rm -rf ${TRIGGER[$i]} ${SBYDATA[$i]}
	done

	pgbackup.sh $ACTDATA

	for i in $(seq 1 $SBYNUM); do
		cp -r $PGBKP ${SBYDATA[$i]}

		set_guc port ${SBYPORT[$i]} ${SBYCONF[$i]}
		set_guc log_line_prefix "'${SBYPREFIX[$i]} '" ${SBYCONF[$i]}
		set_guc hot_standby on ${SBYCONF[$i]}

		echo "standby_mode = 'on'" >> ${RECCONF[$i]}
		echo "primary_conninfo = 'host=localhost port=$ACTPORT application_name=${SBYPREFIX[$i]}'" >> ${RECCONF[$i]}
		echo "trigger_file = '${TRIGGER[$i]}'" >> ${RECCONF[$i]}

		if [ "$USEARCH" = "TRUE" ]; then
			echo "restore_command = 'cp $ACTARCH/%f %p'" >> ${RECCONF[$i]}
		fi

		pgstart.sh ${SBYDATA[$i]}
	done
}

if [ "$QUITMODE" = "TRUE" ]; then
	pgshutdown.sh -f $ACTDATA
	for i in $(seq 0 $SBYMAX); do
		$PGBIN/pg_ctl -D $SBYDATA$i status > /dev/null
		if [ $? -eq 0 ]; then
			pgshutdown.sh -f $SBYDATA$i
		fi
	done
	exit 0
fi

if [ "$MKCONFLICT" = "TRUE" ]; then
	pgsql_is_alive $ACTDATA
	pgsql_is_alive ${SBYDATA[1]}

	TMPTBL=tmptable_$(date +%Y%m%d%H%M%S)

	$PGBIN/psql -p $ACTPORT -c "CREATE TABLE $TMPTBL (id int)"
	$PGBIN/psql -p $ACTPORT -c "INSERT INTO  $TMPTBL VALUES (1)"
	sleep 1

	$PGBIN/psql -p ${SBYPORT[1]} -c "SELECT pg_sleep(60) FROM $TMPTBL" &
	PSQLPID=$!
	sleep 1

	$PGBIN/psql -p $ACTPORT -c "DELETE FROM $TMPTBL"
	$PGBIN/psql -p $ACTPORT -c "VACUUM $TMPTBL"

	exit 0
fi

if [ "$ONLYACT" = "TRUE" ]; then
	setup_primary
fi

if [ "$ONLYSBY" = "TRUE" ]; then
	setup_standby
fi

if [ "$ONLYACT" = "FALSE" -a "$ONLYSBY" = "FALSE" ]; then
	setup_primary
	setup_standby
fi
