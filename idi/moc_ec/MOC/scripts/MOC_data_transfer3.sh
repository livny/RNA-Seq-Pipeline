#!/bin/sh


MOC_ID=$1

# get path of the current file
file_path="${BASH_SOURCE[0]}"
# if the file path is relative, convert it to absolute path
if [[ $file_path != /* ]]; then
  file_path="$PWD/${BASH_SOURCE[0]}"
fi

scripts_dir="$(dirname $file_path)"


# source idi/moc_ec/MOC/scripts/bash_header
source "$scripts_dir/bash_header"

# source "idi/moc_ec/MOC/scripts/MOC_functions.sh"
source "$scripts_dir/MOC_functions.sh"

### determining paths and headers 
### default config file is /broad/IDP-Dx_storage/MOC/config_files/PC_config.yaml
paths_and_headers $MOC_ID $@

# -fastq: include fastq files along with bams in Aspera (default N)
# -internal: internal collaborator (default N)

CONFIG_FILE=`extract_option -conf "/idi/moc_ec//MOC/config_files/PC_config.yaml" 1 $@`
INTERNAL=`extract_option -internal 0 1 $@`
MOVE_KEY=`extract_option -move_key N 1 $@`
RES_DIR_OPT=`extract_option -res_dir - 1 $@`
BAM_DIR_OPT=`extract_option -bam_dir - 1 $@`
MERGE_DIR_OPT=`extract_option -merge_dir - 1 $@`
COLLAB=`extract_option -collab Y 1 $@`

### run path_suff function to set RESPATH_SUFF.
##	If -moc_id N included in command line, do not moc_ID to RESPATH_SUFF.  
##	If -user_id included with Y or no string add USID to RESPATH_SUFF.  
##	If -user_id followed by userID, add userID to RESPATH_SUFF.

path_suff $@
 
### get paths etc. from config file
KEY_DIR=`config_read $CONFIG_FILE Key_base`
USER_GUIDE=`config_read $CONFIG_FILE user_guide`
ASPERA_MAKER=`config_read $CONFIG_FILE aspera_script`
RESULTS_PATH=`config_read $CONFIG_FILE Results_path`
TRANSFER_PATH=`config_read $CONFIG_FILE Transfer_path`
BAM_PATH=`config_read $CONFIG_FILE Bam_path`
TEMP_PATH=`config_read $CONFIG_FILE Temp_path`
DB_SCRIPT=`config_read $CONFIG_FILE DB_script`
MAN_DIR=`config_read $CONFIG_FILE manifest_dir`
GLOCAL_PATH=`config_read $CONFIG_FILE gdrivelocal_path`
GDRIVE_SCRIPT=`config_read $CONFIG_FILE gdrive_script`
FILES_PATH=`config_read $CONFIG_FILE file_path`

#### determining project type based on MOC_ID prefix and lists of prefixes in config

USID=`USID`

PROJ_TYPE=`project_type $MOC_ID`

echo "Proj_type: "$PROJ_TYPE


### set paths to directories, files, and scripts from config file
if [ $PROJ_TYPE == "P" ];then
	GMOC_PATH=`config_read $CONFIG_FILE gdrivemoc_path`
	GMOC_DIR=$GMOC_PATH"/"$MOC_ID
	GREF_DIR=$GMOC_DIR"/Reference_files/"
fi
if [ $PROJ_TYPE == "D" ];then
	GMOC_PATH=`config_read $CONFIG_FILE gdriveDEV_path`
	TYPE=`echo $MOC_ID | cut -d"-" -f1`
	PROJ_ID=`echo $MOC_ID | cut -d"." -f1`
	GMOC_DIR=$GMOC_PATH"/"$TYPE"/Experiments/"$MOC_ID"/"
	GREF_DIR=$GMOC_DIR"/Reference_files/"
fi
if [ $PROJ_TYPE == "TC" ];then
	GMOC_PATH=`config_read $CONFIG_FILE gdriveGCIDTC_path`
	TYPE=`echo $MOC_ID | cut -d"-" -f1`
	GMOC_DIR=$GMOC_PATH"/"$TYPE"/Experiments/"$MOC_ID"/"
	GREF_DIR=$GMOC_DIR"/Reference_files/"
fi

IMPORT_GS=`extract_option -import_gs Y 1 $@`
MOVE_KEY=`extract_option -move_key Y 1 $@`

### set paths to files
KEY_FILE=$KEY_DIR$MOC_ID"_key.txt"
TEMP_FILE=$TEMP_PATH/"temp_"$MOC_ID"_transfer_.txt"

### get GID from Gdrive or use GID included as command line option
# if -GID_OPT not included in command line, get it from Gdrive 

if [ $GID_OPT == "0" ];then
	echo "Getting GID from Gdrive using the path in $CONFIG_FILE"
	G_ID=`gdrive_gid $MOC_ID -conf $CONFIG_FILE -proj_type $PROJ_TYPE | tail -1`
else
	G_ID=$GID_OPT
fi

if [ -z $G_ID ];then

	echo "G_ID not found in gdrive or entered in command line with -gid option"
	exit
fi

echo $G_ID 

############## moving key file to server ###############
############################ MOVE KEY FILE TO SERVER ###################################
	
############### moving key file to server #############################
if [ $MOVE_KEY == "Y" ];then 
	echo "Running move_key..."
	move_key		
	### if key file not found or empty, stop pipeline
	if [ ! -s $KEY_FILE ];then
		ls -lrt $KEY_FILE
		exit
	fi
fi
########################################################

ALL_SMOC_INDEX1=`sh $DB_SCRIPT SMOC_ID,$SMOC_ID Index1_Seq | sed 1d | awk '{print $2}'  | sed 's/,/ /g'`

SAMP_ID_FIELD=`FIELD_HEADER $KEY_FILE Sample_ID`
PID_FIELD=`FIELD_HEADER $KEY_FILE Project_ID`
ALL_PROJ_ID=`FIND_FIELD $KEY_FILE $PID_FIELD | sort -T $TEMP_PATH | uniq` 

if [ $PROJ_TYPE == "P" ];then

	############## Import google sheet databases to server ###############=
	if [ $IMPORT_GS == "Y" ];then
		echo "Running $scripts_dir"/"GS_import.sh to import google sheet databases to server"
		sh $scripts_dir"/GS_import.sh"
	fi
	########################################################
	DB_FILE=`ls -lrt $PCDB_DIR/*$PCDB_SUFF | tail -1 | awk '{print $9}'`

	if [ $INTERNAL == 0 ];then
		INTERNAL=`FIND_HEADER_AND_FIELD $MOC_ID "MOCP_ID" "Funding" $DB_FILE | awk '{if($1 ~ /xternal/) print "N"; else print "Y"}'`
	fi

	DATA_EMAIL=`FIND_HEADER_AND_FIELD $MOC_ID "MOCP_ID" "Email_for_data_receipt" $DB_FILE | awk '{print $1}'`
	COL_EMAIL=`FIND_HEADER_AND_FIELD $MOC_ID "MOCP_ID" "Collaborator_email" $DB_FILE | awk '{print $1}'`

	echo $DATA_EMAIL


	if [ -z $COL_EMAIL ] && [ $COLLAB == "Y" ];then
	
		echo "FAILURE: Entry missing for 'Collaborator_email' in $DB_FILE for $MOC_ID"
		exit

	fi

	if [ -z $DATA_EMAIL ];then
	
		DATA_EMAIL=$COL_EMAIL

	fi

	if [ -z $INTERNAL ] && [ $COLLAB == "Y" ];then

		echo "FAILURE: Entry missing for 'Funding' in $DB_FILE for $MOC_ID"
		exit
	fi
else
	
	COL_EMAIL=$USID"@broadinstitute.org"
fi

echo "COL_EMAIL:" $COL_EMAIL

### update data transfer DB ####
# 
# date=`date "+%D"`
# edate=`date +%s`
# ID=`id -un`
# echo $MOC_ID 	$date	$edate	$COL_EMAIL	$DATA_EMAIL	$INTERNAL	$ID >> $DATA_DB
# 
# ls -lrt $DATA_DB
# cat $DATA_DB

### move files to Gdrive ########

echo $ALL_PROJ_ID

for PROJ_ID in $ALL_PROJ_ID
do
	
	GDRIVE_ADDRESS="https://drive.google.com/drive/folders/"
	TRANS_DIR=$TRANSFER_PATH$RESPATH_SUFF$PROJ_ID"_Results/"
	TAR_DIR=$TRANSFER_PATH$MOC_ID"_"$PROJ_ID"_Results.tar.gz"

	if [ $RES_DIR_OPT == "-" ];then
		RES_DIR=$RESULTS_PATH$RESPATH_SUFF$PROJ_ID"/"
	else
		RES_DIR=$RES_DIR_OPT
	fi
	if [ $BAM_DIR_OPT == "-" ];then
		BAM_DIR=$BAM_PATH$RESPATH_SUFF$PROJ_ID"/"
	else
		BAM_DIR=$BAM_DIR_OPT
	fi
	
	NUM_MERGED_DIR=`ls $TEMP_PATH$RESPATH_SUFF/*/* | grep merge | grep ":" | wc -l`
	
	if [ $MERGE_DIR_OPT == "-" ];then
		if [ $NUM_MERGED_DIR == 1 ];then
			MERGE_DIR=`echo $TEMP_PATH$RESPATH_SUFF"/"*"/mergedir/" | grep $PROJ_ID`
		else
			MERGE_DIR=`echo $TEMP_PATH$RESPATH_SUFF"/"$PROJ_ID"/mergedir/" | grep $PROJ_ID`
		fi
	else
		MERGE_DIR=$MERGE_DIR_OPT
	fi
	
	echo "BAM_DIR: "$BAM_DIR 
	echo "RES_DIR: "$RES_DIR 
	echo "MERGE_DIR: "$MERGE_DIR 
	echo "NUM_MERGED_DIR: "$NUM_MERGED_DIR
	echo "PROJ_ID: "$PROJ_ID
		
	
	GDRIVE_DIR=$GMOC_DIR
	GRES_DIR=$GMOC_PATH$MOC_ID"/"$PROJ_ID"_results/"

	GTRANS_DIR=$GLOCAL_PATH"/"$PROJ_ID"_results/"
	EDG_TAR=$GTRANS_DIR$"EdgeR_"$PROJ_ID".tar.gz"
	DES_TAR=$GTRANS_DIR$"DESeq2_"$PROJ_ID".tar.gz"

	GV_TAR=$GTRANS_DIR$"GV_"$PROJ_ID".tar.gz"

	cd $GLOCAL_PATH

	if [ ! -s $RESULTS_PATH ];then
		echo $RESULTS_PATH" not found!"
		exit
	fi
	
	
 	GID_RES=`$GDRIVE_SCRIPT id $GMOC_PATH$MOC_ID | tail -1 | sed 's/\"//g' | awk '{print $1}'`
 	G_DIR_ADDRESS=$GDRIVE_ADDRESS$GID_RES
	
	#### remove TRANS_DIR and GRES_DIR	
	rm -rf $TRANS_DIR
	echo $GLOCAL_PATH
	echo "yes Y | $GDRIVE_SCRIPT delete $GRES_DIR"
	yes Y | $GDRIVE_SCRIPT delete $GRES_DIR
	echo ""
	
	
	#### make TRANS_DIR and GRES_DIR
	mkdir -p $TRANS_DIR
	mkdir -p $GTRANS_DIR
	echo $GLOCAL_PATH
# 	echo "$GDRIVE_SCRIPT new -folder $GRES_DIR"
# 	$GDRIVE_SCRIPT new -folder $GRES_DIR
	yes Y | $GDRIVE_SCRIPT share -with-link $GRES_DIR 

	echo "Copying results files to "$GTRANS_DIR
	cp $RES_DIR/*".tsv" $GTRANS_DIR
	cp $RES_DIR/*"corr.txt" $GTRANS_DIR
	cp $RES_DIR/*"AlignmentSummaryMetrics.txt" $GTRANS_DIR
	cp $RES_DIR/*"etrics.txt" $GTRANS_DIR
	cp $RES_DIR/*"etrics.txt" $GTRANS_DIR
	cp $RES_DIR/*"_abs.txt" $GTRANS_DIR
	cp $RES_DIR/*"_gv.txt" $GTRANS_DIR
	cp $RES_DIR/*"session_info.txt" $GTRANS_DIR
	
	echo "Copying user guide to "$GTRANS_DIR
	cp $USER_GUIDE $GTRANS_DIR
	
	if [ -s $RES_DIR/"DE/" ];then

		echo "Compressing $RES_DIR/"DE/EdgeR/" files and copying them to "$EDG_TAR
		cd $RES_DIR/"DE/EdgeR/"
		tar -zczf $EDG_TAR *
		echo "Compressing $RES_DIR/"DE/DESeq2/" files and copying them to "$DES_TAR
		cd $RES_DIR/"DE/DESeq2/"
		tar -zczf $DES_TAR *
	fi

	cd $GTRANS_DIR
	echo "$GDRIVE_SCRIPT push -no-prompt -destination $GRES_DIR -files $GTRANS_DIR"
	$GDRIVE_SCRIPT push -no-prompt -destination $GDRIVE_DIR -files $GTRANS_DIR
	
	echo "Copying $GTRANS_DIR and $BAM_DIR files to $TRANS_DIR"
	cp $GTRANS_DIR* $TRANS_DIR
	cp $BAM_DIR $TRANS_DIR
	echo "Compressing "$TRANS_DIR
	echo "-zczf $TAR_DIR $RES_DIR"
	cd $TRANSFER_PATH
	tar -zczf $TAR_DIR $RES_DIR

#################

### Write out IN_MESSAGE into OUT_MESSAGE to create email, attachment to send to collab
	IN_MESSAGE=$FILES_PATH"/Data_delivery_message.txt"
	OUT_MESSAGE=$TEMP_PATH"/"$MOC_ID"_OUT_MESSAGE.txt"
 

	cat $IN_MESSAGE | sed 's/DATA_EMAIL/'$DATA_EMAIL'/g' | sed 's/MOC_ID/'$MOC_ID'/g' | sed 's/PROJ_ID/'$PROJ_ID'/g' | sed 's*MERGE_DIR*'$MERGE_DIR'*g' | sed 's*BAM_DIR*'$BAM_DIR'*g' | sed 's*RES_DIR*'$RES_DIR'*g' | sed 's*G_DIR_ADDRESS*'$G_DIR_ADDRESS'*g' |  sed 's*TAR_DIR*'$TAR_DIR'*g' > $OUT_MESSAGE
	
	ls -lrt $OUT_MESSAGE

	export TMPDIR=$TEMP_PATH

	cat $OUT_MESSAGE |  mailx -s "Analysis for $MOC_ID $PROJ_ID complete" $USID"@broadinstitute.org"

	
	echo "sh $ASPERA_MAKER $MOC_ID $BAM_DIR $TAR_DIR $MERGE_DIR bam,tdf $@"
	sh $ASPERA_MAKER $MOC_ID $BAM_DIR $TAR_DIR $MERGE_DIR bam,tdf $@

	### change permissions on gdrive files
	
	cd $GLOCAL_PATH
	SHARE_NOTIFY=`echo $COL_EMAIL $DATA_EMAIL | awk '{if($0 ~ /gmail.com/) print "-notify=false"; else; print "-notify=true"}'`
	echo $SHARE_NOTIFY
		
	echo "Giving permissions for anyone with a link to view $GRES_DIR"
	echo "yes Y | $GDRIVE_SCRIPT share -with-link $GRES_DIR"
	yes Y | $GDRIVE_SCRIPT share -with-link $GRES_DIR 

	### change permissions on local files
	change_perms $TRANS_DIR $GTRANS_DIR	$TAR_DIR

	
done


