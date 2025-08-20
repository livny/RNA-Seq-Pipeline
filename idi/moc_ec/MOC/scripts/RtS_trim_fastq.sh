#!/bin/sh

FASTQ=$1
TRIM_LEN=$2
MOC_SYM_DIR=$3
MOC_SYM_TRIM_DIR=$4

READ1_START=`echo $TRIM_LEN | cut -d"," -f1 | cut -d"-" -f1 `
READ1_END=`echo $TRIM_LEN | cut -d"," -f1 | cut -d"-" -f2 `
READ2_START=`echo $TRIM_LEN | cut -d"," -f2 | cut -d"-" -f1 `
READ2_END=`echo $TRIM_LEN | cut -d"," -f2 | cut -d"-" -f2 `
echo $READ1_START
echo $READ1_END
echo $READ2_START
echo $READ2_END

echo "Making fastq with R1 trimmed from $READ1_START to $READ1_END and R2 trimmed from $READ2_START to $READ2_END for $FASTQ..."
echo $FASTQ
ROOT=`basename $FASTQ`
OUT_FILE=$MOC_SYM_TRIM_DIR"/"$ROOT


READ=`echo $ROOT | awk '{y=split($1, ar, "."); g=split(ar[y-2],pr,"_"); print pr[g]}'`
echo $READ


if [ $READ == "R1" ];then
	TRIM_START=$READ1_START
	TRIM_END=$READ1_END
fi
if [ $READ == "R2" ];then
	TRIM_START=$READ2_START
	TRIM_END=$READ2_END
fi



zcat $FASTQ | awk -v TRIM_START=$TRIM_START -v TRIM_END=$TRIM_END '{	

												TRIM_LEN=TRIM_END-TRIM_START
												
												if($1 ~ /@/ || $1 ~ /+/) 
													print $0
												else
												{
													if(length($1)>TRIM_LEN+TRIM_START+2)
														print substr($1,TRIM_START+1,TRIM_LEN)
													else 
														print $1
												}
											}' | gzip > $OUT_FILE

echo $OUT_FILE