#!/bin/sh

MOC_ID=$1
 

source /idi/moc_ec/MOC/scripts/bash_header

### source all functions 
source "/idi/moc_ec/MOC/scripts/MOC_functions.sh"

### get options from command line
CONFIG_FILE=`extract_option -conf "/idi/moc_ec/MOC/config_files/PC_config.yaml" 1 $@`

# Get paths to dirs scripts from config file
read_config $CONFIG_FILE 

### run path_suff function to set RESPATH_SUFF.
##	If -moc_id N included in command line, do not moc_ID to RESPATH_SUFF.  
##	If -user_id included with Y or no string add USID to RESPATH_SUFF.  
##	If -user_id followed by userID, add userID to RESPATH_SUFF.

path_suff $@

FIRST=`extract_option -first Y 1 $@`
SPLIT=`extract_option -split Y 1 $@`
GUIDE=`extract_option -guide Y 1 $@`

RESULTS_DIR=$RESULTS_PATH"/"$RESPATH_SUFF"/UGER/"

echo "Results_dir: "$RESULTS_DIR

mkdir -p $RESULTS_DIR

TIME_STAMP=`date +%s` 

QSUB_ERR_FILE=$RESULTS_DIR"/"$MOC_ID"_"$TIME_STAMP"_qsub_err.txt"
QSUB_OUT_FILE=$RESULTS_DIR"/"$MOC_ID"_"$TIME_STAMP"_qsub_out.txt"

QSUB_FILE=~/$MOC_ID"_qsub.txt"

echo "source /idi/moc_ec/MOC/scripts/bash_header" > $QSUB_FILE

shift

if [ $FIRST == "Y" ];then
	echo "sh /home/unix/livny/RNA-Seq-Pipeline/idi/moc_ec/MOC/scripts/MOC_RtS_pipe_v2.sh $MOC_ID -user_id -trim_reads Y -bc_analysis N -cds_add5 0 -cds_add3 30 $@" >> $QSUB_FILE
fi


if [ $SPLIT == "Y" ];then
	echo "Running split..."
	ls -lrt $QSUB_FILE
	echo "cat /idi/moc_ec/MOC/Key_files//"$MOC_ID"_key.txt | sed 's/NC_000962_GCRISP_NoGuides/NC_000962_GCRISP_guides_split/g'  > temp.txt" >> $QSUB_FILE
	echo "cat temp.txt > /idi/moc_ec/MOC/Key_files//"$MOC_ID"_key.txt" >> $QSUB_FILE
	echo "sh /home/unix/livny/RNA-Seq-Pipeline/idi/moc_ec/MOC/scripts/MOC_RtS_pipe_v2.sh $MOC_ID -user_id -trim_reads Y -bc_analysis N -cds_add5 0 -cds_add3 30 -split N -merge N -move_ref N -move_key N $@" >> $QSUB_FILE
fi

if [ $GUIDE == "Y" ];then
	echo "sh /idi/moc_ec/MOC/scripts/sGRNA_counts.sh /broad/hptmp/RNASeq_proj/MOC/livny/$MOC_ID/GCRISP_Pilot/patho_result/GCRISP_Pilot /idi/moc_ec/RNASeq_results/MOC///livny//$MOC_ID/GCRISP_Pilot/sGRNA_counts.txt" >> $QSUB_FILE
fi

echo "qsub -e $QSUB_ERR_FILE -o $QSUB_OUT_FILE -l h_rt=24:00:00 -l h_vmem=8g -l os=RedHat7 $QSUB_FILE" 

qsub -e $QSUB_ERR_FILE -o $QSUB_OUT_FILE -l h_rt=24:00:00 -l h_vmem=8g -l os=RedHat7 $QSUB_FILE

echo "Outfile and errfile directory is:"
echo $RESULTS_DIR