#!/bin/sh


MOCS=$1
FCID=$2

# get path of the current file
	file_path="${BASH_SOURCE[0]}"
# if the file path is relative, convert it to absolute path
	if [[ $file_path != /* ]]; then
	  file_path="$PWD/${BASH_SOURCE[0]}"
	fi

scripts_dir="$(dirname $file_path)"

# source idi/moc_ec/MOC/scripts/bash_header
	source "$scripts_dir/bash_header"


### source all functions 
# source "idi/moc_ec/MOC/scripts/MOC_functions.sh"
source "$scripts_dir/MOC_functions.sh"
### determining paths and headers 
	paths_and_headers $ID $@

### set paths to directories, files, and scripts from config file
### default config file is /idi/moc_ec/MOC/config_files/PC_config.yaml
	PROJECT_ROOT_DIR="$(dirname $(dirname $(dirname $(dirname $(dirname $file_path)))))"

	DEFAULT_CONFIG_PATH="$(dirname $(dirname $file_path))"/config_files/PC_config.yaml
	CONFIG_FILE=`extract_option -conf $DEFAULT_CONFIG_PATH 1 $@`
	METRICS=`extract_option -metrics Y 1 $@`
	SEQ_LANE=`extract_option -lane "B" 1 $@`
	RAW_SYM_PATH=`extract_option -symlink $RAWSYM_PATH 1 $@`

	if [[ $CONFIG_FILE != /* ]]; then
		CONFIG_FILE="$PROJECT_ROOT_DIR/$CONFIG_FILE"
	fi

	OW=`extract_option -ow N 1 $@`

	MOCSID=`echo $MOCS | sed 's/-//g'`

	# Set directory paths
	WU_DIR="/idi/moc_ec/RawSeq_data/Walkup/"
	FC_DIR=`ls -lrt $WU_DIR* | grep $FCID | sed 's/:/\//g'`
	TEMP_PATH=`config_read $CONFIG_FILE Temp_path`
	GLOCAL_PATH=`config_read $CONFIG_FILE gdrivelocal_path`
	GDRIVE_SCRIPT=`config_read $CONFIG_FILE gdrive_script`
	if [[ $GDRIVE_SCRIPT != /* ]]; then
		GDRIVE_SCRIPT="$PROJECT_ROOT_DIR/$GDRIVE_SCRIPT"
	fi

	RAWDATA_PATH=`config_read $CONFIG_FILE Seq_base`
	TEMP_DIR=$TEMP_PATH"/MOCS_move/"
	mkdir -p $TEMP_DIR

	FASTQ_FILE=$TEMP_PATH"/MOCS_COMBOS_fastqs.txt"

	mkdir -p $POOL_SYMDIR


########### pull desktop files for all/recently changed MOCS submission wbs from $GWB_DIR

	GMOCPM_PATH=`config_read $CONFIG_FILE gdrivepm_path`
	GWB_DIR=$GMOCPM_PATH"/MOCS_WBs/"
	LOCAL_DIR=$GLOCAL_PATH"/"$GWB_DIR
	mkdir -p $LOCAL_DIR

	### pull MOCS desktop files from $GWB_DIR
	echo " pull MOCS desktop files from $GWB_DIR"
	echo "cd $GLOCAL_PATH"
	cd $GLOCAL_PATH
	pwd 

	echo "Pulling all files from "$GWB_DIR
	ls -lrt $LOCAL_DIR > $TEMP_DIR"/before.txt"
	echo "$GDRIVE_SCRIPT pull -no-prompt -files $GWB_DIR"
	$GDRIVE_SCRIPT pull -no-prompt -files $GWB_DIR
	ls -lrt $LOCAL_DIR > $TEMP_DIR"/after.txt"
	
	### change permissions for GWB_DIR and $LOCAL_DIR 
	change_perms $MOCSDB_DIR $LOCAL_DIR


	### Pull GIDs from desktop files 
	cd $LOCAL_DIR
	pwd 

	if [ $OW == "Y" ];then
		ALL_FILES=`ls -lrt $LOCAL_DIR* | grep desk | awk '{print $NF}'`
	fi
	
	if [ $OW != "N" ] && [ $OW != "Y" ];then	
		ALL_FILES=`ls -lrt $LOCAL_DIR* | grep desk | grep $OW | awk '{print $NF}'`
	fi	
	
	if [ $OW == "N" ];then		
		# Identify and limit to newly changed files plus target MOCS
		
		NEW_MOCS_WBS=`diff $TEMP_DIR"/before.txt" $TEMP_DIR"/after.txt" | awk '{split($10, ar, "_");if(ar[1]!="MOCS")print ar[1]}' | sort | uniq `
		NEW_MOCS_WBS=$NEW_MOCS_WBS" "$MOCS
		ALL_FILES=""
		
		for MOCS in $NEW_MOCS_WBS
		do
			FILE=`ls -lrt $LOCAL_DIR* | grep desk | grep $MOCS | awk '{print $NF}'`
			ALL_FILES=$ALL_FILES" "$FILE
		done
	fi
	### Use GIDs to download WBs from $GWB_DIR into $LOCAL_DIR 

	for FILE in $ALL_FILES
	do
		GID=`cat $FILE | grep "URL" | cut -d"/" -f6`
		NAME=`cat $FILE | grep "Name=" | cut -d"=" -f2 | sed 's/_Pool_Sub_WB//g'`

		echo "$SCRIPTS_DIR"/GS_import.py" -s $GID -t "Pooling" -p $NAME --Key_dir $MOCSDB_DIR -S "_Pool_Sub_WB.txt""
		$SCRIPTS_DIR"/GS_import.py" -s $GID -t "Pooling" -p $NAME --Key_dir $MOCSDB_DIR -S "_Pool_Sub_WB.txt" 

	done


	### change permissions for MOCSDB_DIR
	change_perms $MOCSDB_DIR
	
	PROC=`ls -lrt $MOCSDB_DIR* | grep $MOCS | awk '{y=split($9,ar,"/");split(ar[y],pr,"_");print pr[2]}'`

	echo $MOCS_WB
	echo $PROC
	
	
	if [ $PROC == "SCR" ];then
	
		RAW_SYM_PATH=`echo $RAW_SYM_PATH | sed s/RtS/SCR/g`
		
	fi

	echo "RAW_SYM_PATH:" $RAW_SYM_PATH
	
	
	# Make $MOCS_DB
	echo "" | sed 1d > $MOCS_DB
	cat $MOCSDB_DIR*RtS* | grep -v "MOCS-ID" | grep -v "MOCS_ID" | grep MOCS | awk '{print $1";"$2";"$4";"$5";"$2}' > $MOCS_DB
	cat $MOCSDB_DIR*SCR* | grep -v "MOCS_ID" | grep -v "MOCS_ID" | grep MOCS | awk -F"\t" '{print $1";"$2";"$9";"$9";"$4}' >> $MOCS_DB
	ls -lrt $MOCS_DB

###### Make symlinks with pool IDs in MOCS and MOC dirs
### Make symlinks in MOCS dir

	#  making MOCS symlinks dir
	echo "	making MOCS symlinks dir"
	MOCS_SYMDIR=$RAWSYM_PATH"/"$MOCS"/"
	mkdir -p $MOCS_SYMDIR

	FASTQ_DIR_LEVEL=`ls -lrt $FC_DIR | grep -w fastq | awk '{print $NF}' | wc -l `
	
	echo $FASTQ_DIR_LEVEL
	if [ $FASTQ_DIR_LEVEL == "1" ];then
		FASTQ_DIR=$FC_DIR"/fastq/"
	else
		FASTQ_SUB=`ls -lrt $FC_DIR | grep -v total | tail -1 | awk '{print $NF}' `
		FASTQ_DIR=$FC_DIR"/"$FASTQ_SUB"/fastq/"
	fi
	echo $FASTQ_DIR
	echo $FASTQ_DIR_LEVEL

	ALL_FILES=`ls -lrt $FASTQ_DIR/ | grep fastq | grep -v $MOCS | grep -e "R2" -e "R1" | awk '{print $9}'`

	#  Using MOCS WB to link index IDs to pool IDs
	MOCS_COMBOS=`cat $MOCS_DB | grep $MOCS`

	#  Making symlinks with index IDs swapped for pool IDs
	echo "Making symlinks for fastqs to $MOCS_SYMDIR"
	
	echo $FASTQ_DIR
	echo $ALL_FILES
	
	echo "MOCS_COMBOS:" $MOCS_COMBOS
	
	ls -lrt $MOCS_DB
	cat $MOCS_DB | grep $MOCS
	
	cat $MOCS_DB 

	
	echo $MOCS_COMBOS
	
	
	for FILE in $ALL_FILES
	do
		echo $FILE
		INDEX=`echo $FILE | awk '{split($1, ar, "_");print ar[4]"_"ar[5]}'`
		SYM_INDEX=`echo $INDEX | sed 's/_/-/g'`
		SYM_FILE=`echo $FILE | sed 's*'$INDEX'*'$SYM_INDEX'*g'`
		LANE=`echo $FILE | awk '{split($1, ar, "_");print ar[2]}'`

		FASTQ=$FASTQ_DIR$FILE
		SYM=$MOCS_SYMDIR$SYM_FILE
		
		for COMBO in $MOCS_COMBOS
		do
			MOCS=`echo $COMBO | sed 's/;/ /g' | awk '{print $1}'`
			POOL=`echo $COMBO | sed 's/;/ /g' | awk '{print $2}'`
			INDEX=`echo $COMBO | sed 's/;/ /g' | awk '{print $3"-"$4}'`
			#INDEX=`echo $COMBO | sed 's/;/ /g' | awk '{print $3"_"$4}'`
			SYM_INDEX=`echo $INDEX | sed 's/_/-/g'`
			MATCH=`echo $FASTQ | grep $INDEX | wc -l`
#   		echo $FASTQ 
#  	  		echo $INDEX
			
			if [ $MATCH -gt "0" ];then
				SYM=`echo $SYM | sed 's*'$SYM_INDEX'*'$SYM_INDEX'-PM-'$POOL'*g'`
				break
			fi

		done
		if [ $SEQ_LANE == "B" ] || [ $LANE == $SEQ_LANE ];then
			echo $FILE 
			echo $LANE, $SEQ_LANE
			echo "ln -sf $FASTQ $SYM"
			ln -sf $FASTQ $SYM
		fi
	done
	### change permissions for MOCS_SYMDIR
	change_perms $MOCS_SYMDIR

	ls -lrt $MOCS_SYMDIR 
	
	echo $MOCS_SYMDIR

### Make symlinks for MOCS fastqs in MOC dirs
	echo "Make symlinks for MOCS fastqs in MOC dirs"
	ALL_FILES=`ls -lrt $MOCS_SYMDIR | awk '{print $9}' | grep "\-PM-"`

echo $ALL_FILES

	# Make symdirs for all MOCIDs
	
	echo "ALL_FILES:" $ALL_FILES
	echo "MOCS_SYMDIR:" $MOCS_SYMDIR


# Make symfile name and make symlink in project dir
	echo "Make symfile name and make symlink in project dir"
	
	for FILE in $ALL_FILES
	do
		 echo $FILE
		 
		 
		 FASTQ_FILE=$MOCS_SYMDIR"/"$FILE
	 
		 echo $FASTQ_FILE
 
		 INFO=` echo $FILE | awk '{

				y=split($1,ar,"_")
				FCID=ar[1]
				LANE=ar[2]
			
				if(y==7)
				{
					t=split(ar[4], qr, "-")
					INDEX1=qr[1]
					INDEX2=qr[2]
					if(t==5)
						POOL_ID=qr[4]"-"qr[5]
					if(t==6)
						POOL_ID=qr[4]"-"qr[5]

				}
				if(y==8)
				{
					t=split(ar[4], qr, "-")
					INDEX1=qr[1]
					INDEX2=qr[2]
					if(t==5)
						POOL_ID=qr[4]"-"qr[5]
					if(t==6)
						POOL_ID=qr[4]"-"qr[5]"-"qr[6]

				}
				
				
				if(y==9)
				{	
					
					POOL_ID=POOL_ID"."ar[5]
				}

				## get indexes
				
				READ=substr(ar[y-1],2,1)
					
				print POOL_ID" "READ" "LANE" "INDEX1"	"INDEX2

			}' `
				
		POOL_ID=`echo $INFO | awk '{print $1}'`
		MOC_ID=`cat $MOCS_DB | grep $MOCS | grep $POOL_ID | head -1 | awk '{y=split($1,ar,";");split(ar[y], pr, "p");split(pr[1], qr, "-");print qr[1]"-"qr[2]}' | sed 's/_//g'`
		INDEX1=`echo $INFO | awk '{print $4}'`
		INDEX2=`echo $INFO | awk '{print $5}'`
		echo $INFO
		echo $POOL_ID
		echo $MOC_ID
		echo "**********************"
		MOC_SYM_DIR=$RAW_SYM_PATH"/"$MOCID
		if [ ! -d  $MOC_SYM_DIR ];then
			echo "Making $RAW_SYM_PATH"/"$MOCID"
			mkdir -p $RAW_SYM_PATH"/"$MOCID
		fi

		READ=`echo $INFO | awk '{print $2}'`
		LANE=`echo $INFO | awk '{print $3}'`
		
		
		SYM_NAME=$FCID"-"$MOCSID"-"$INDEX1"-"$INDEX2"."$LANE"."$POOL_ID"_"$POOL_ID",.unmapped."$READ".fastq.gz"
						
		echo $FASTQ_FILE
		echo $SYM_NAME "----------"
		
		
		SYM_DIR=$RAW_SYM_PATH"/"$MOC_ID
		SYM_FILE=$SYM_DIR"/"$SYM_NAME
		mkdir -p $SYM_DIR
		
		
		if [ $SEQ_LANE == "B" ] || [ $LANE == $SEQ_LANE ];then
			echo "ln -sf $FASTQ_FILE $SYM_FILE"
			rm $SYM_FILE
			
			ln -sf $FASTQ_FILE $SYM_FILE
			
			### change permissions for SYM_DIR
			change_perms $SYM_DIR
		fi
		ls -lrt $SYM_DIR
	
	done
	
	

# List all symlinks in MOC symlink dirs
	for MOCID in $ALL_MOCIDS
	do
		echo $MOCID 
		echo $RAW_SYM_PATH"/"$MOCID
		ls -lrt $RAW_SYM_PATH"/"$MOCID 
	done 
 
	
	if [ $METRICS == "Y" ];then
		echo "sh $SCRIPTS_DIR"/MOC_walkup_metrics3.sh" $MOCS $MOCS_SYMDIR"
		sh $SCRIPTS_DIR"/MOC_walkup_metrics3.sh" $MOCS $MOCS_SYMDIR" -lane "$SEQ_LANE
	fi



