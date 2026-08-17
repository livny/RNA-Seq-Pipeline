#!/bin/sh


DIR=$1

ALL_MOCS=`ls -lrt $DIR | awk '{print $9}' | grep MOCS0`

for MOCS in $ALL_MOCS
do
	printf "%s\t" $MOCS
  	ALL_FILES=` ls -lrt $DIR"/"$MOCS"/"* | awk '{print $NF}'`
	for FILE in $ALL_FILES
	do
		dirname $FILE
	done | sort | uniq -c | sort | tail -1
done

exit
ALL_MOCS=`ls -lrt $DIR | awk '{print $9}' | grep MOCS-`

for MOCS in $ALL_MOCS
do
	printf "%s\t" $MOCS
	ls -lrt $DIR"/"$MOCS | awk '{print $NF}' | rev | cut -d"/" -f1 | rev | cut -d"_" -f1 | sort | uniq -c | sort | tail -1 | awk '{print $2}'
done
