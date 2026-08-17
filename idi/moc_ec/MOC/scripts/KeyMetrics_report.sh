#!/bin/sh



MOC_ID=$1

source /idi/moc_ec/MOC/scripts/bash_header

### source all functions 
source "/idi/moc_ec/MOC/scripts/MOC_functions.sh" 2> /dev/null

### determining paths and headers 
### default config file is /broad/IDP-Dx_storage/MOC/config_files/PC_config.yaml
paths_and_headers $MOC_ID $@
path_suff $@ "-moc_id "$MOC_ID_OPT" -user_id "$USER_ID

TOTAL=`extract_option -total 2 1 $@`
CDS=`extract_option -CDS 0.5 1 $@`

TOTAL_HEAD="Num_bc_reads"
CDS_HEAD="CDS_total_counts_for_replicon"

average ()
{

	HEADER=$1
	FILE=$2
	
	FIND_VALUES_FOR_HEADER $HEADER $FILE | sed '/^$/d'  | awk -v total=0 -v n=0 '{
																			if($1>0)
																			{
																				n++
																				total=total+$1
																			}
																			printf "%0.2f\n", total/n/1e6
																		}'  | tail -1
}

meet_target ()
{

	HEADER=$1
	TRAGET=$2
	FILE=$3
	
	FIND_VALUES_FOR_HEADER $HEADER $FILE | sed '/^$/d'  | awk -v total=0 -v n=0 -v target=$TRAGET '{

																			n++
																			if($1>(target*1e6))
																			{
																				total++1
																			}
																			printf "%0.1f(%s/%s)\n", total/n*100, total, n
																		}'  | tail -1

}

missing_target ()
{

	HEADER=$1
	TRAGET=$2
	FILE=$3
	AVG_TOTAL=$4
	
	ALL_MISSING=`FIND_VALUES_FOR_HEADER $HEADER $FILE | sed '/^$/d'  | awk -v total=0 -v n=0 -v target=$TRAGET '{

																			if($1<(target*1e6))
																				print $1
																		}' | sort -k1n`
	
	for MISSING in $ALL_MISSING
	do
		printf "%s" $MISSING
		echo $MISSING | awk '{print "|"('$TRAGET'*1e6-$1)/$1*'$AVG_TOTAL'"|"}'
	done
																	 
	echo ""
}

RESULTS_DIR=$RESULTS_PATH"/"$RESPATH_SUFF"/"

ALL_PROJ_DIR=`ls -lrtd $RESULTS_DIR* | grep -v UGER | awk '{print $9}'`
ALL_KM_FILES=`for PROJ_DIR in $ALL_PROJ_DIR
do
	ls -lrt $PROJ_DIR"/"* | grep KeyMetrics.txt | awk '{print $9}'
done`


for KM_FILE in $ALL_KM_FILES
do
	#echo $KM_FILE 

	TOTAL_AVG=`average $TOTAL_HEAD $KM_FILE`
	READ_TARGET_PCNT=`meet_target $TOTAL_HEAD $TOTAL $KM_FILE`
	CDS_TARGET_PCNT=`meet_target $CDS_HEAD $CDS $KM_FILE`

	echo "TOTAL_AVG:" $TOTAL_AVG
	echo "% meeting reads target of $TOTAL:" $READ_TARGET_PCNT
	echo "% meeting CDS target of $CDS:" $CDS_TARGET_PCNT


	ALL_POOLS=`FIND_VALUES_FOR_HEADER Pool_ID $KM_FILE | sort | uniq` 

	echo $ALL_POOLS


	for POOL in $ALL_POOLS
	do
		cat $KM_FILE | grep "Sample_ID" > temp_KM_report.txt
		cat $KM_FILE | grep -w $POOL >> temp_KM_report.txt
	
		READ_AVG=`average $TOTAL_HEAD temp_KM_report.txt`
		READ_TARGET_PCNT=`meet_target $TOTAL_HEAD $TOTAL temp_KM_report.txt`
		CDS_AVG=`average CDS_total_counts_for_replicon temp_KM_report.txt`
		MISSING_TOTAL=`missing_target $TOTAL_HEAD $TOTAL temp_KM_report.txt $READ_AVG`
		CDS_TARGET_PCNT=`meet_target $CDS_HEAD $CDS temp_KM_report.txt`
		MISSING_CDS=`missing_target $CDS_HEAD $CDS temp_KM_report.txt $READ_AVG`
		
		echo $POOL $READ_AVG $READ_TARGET_PCNT $CDS_AVG $CDS_TARGET_PCNT $MISSING_CDS 
	done
done


