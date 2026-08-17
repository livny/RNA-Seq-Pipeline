#!/bin/sh


DIR=$1


ALL_MOC_IDS_1=`ls -lrt $DIR/* | awk '{print $9}' | sort | uniq -c | sort | awk '{print $2}' | grep "MOC" | sort`
ALL_MOC_IDS_2=`ls -lrt $DIR/ | awk '{print $9}' | sort | uniq -c | sort | awk '{print $2}' | grep "MOC" | sort `

ALL_MOC_IDS=`echo $ALL_MOC_IDS_1 $ALL_MOC_IDS_2 `


for ID in $ALL_MOC_IDS
do
	{
	  du -s /idi/moc_ec/idpweb/data/MOC/*/$ID/
	  du -s /idi/moc_ec/idpweb/data/MOC/$ID/
	} 2>/dev/null | sort -n | awk '{if($1>1000000) print $2}' | tail -1
done