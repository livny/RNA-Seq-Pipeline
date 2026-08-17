#!/bin/sh


MOCS=$1
FCID=$2

# get path of the current file
	file_path="${BASH_SOURCE[0]}"
# if the file path is relative, convert it to absolute path
	if [[ $file_path != /* ]]; then
	  file_path="$PWD/${BASH_SOURCE[0]}"
	fi

scripts_dir="$(dirname $file_path)/"

# source idi/moc_ec/MOC/scripts/bash_header
	source "$scripts_dir/bash_header"


### source all functions 
# source "idi/moc_ec/MOC/scripts/MOC_functions.sh"
	source "$scripts_dir/MOC_functions.sh"


### determining paths and headers 
	paths_and_headers $ID $@

echo 
### set paths to directories, files, and scripts from config file
### default config file is /idi/moc_ec/MOC/config_files/PC_config.yaml
	PROJECT_ROOT_DIR="$(dirname $(dirname $(dirname $(dirname $(dirname $file_path)))))"

	DEFAULT_CONFIG_PATH="$(dirname $(dirname $file_path))"/config_files/PC_config.yaml
	CONFIG_FILE=`extract_option -conf $DEFAULT_CONFIG_PATH 1 $@`
	METRICS=`extract_option -metrics Y 1 $@`
	
	if [[ $CONFIG_FILE != /* ]]; then
		CONFIG_FILE="$PROJECT_ROOT_DIR/$CONFIG_FILE"
	fi
	
	RAW_SYM_PATH=`extract_option -symlink $RAWSYM_PATH 1 $@`
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
echo "pull desktop files for all/recently changed MOCS submission wbs from $GWB_DIR"

	GMOCPM_PATH=`config_read $CONFIG_FILE gdrivepm_path`
	GWB_DIR=$GMOCPM_PATH"/MOCS_WBs/"
	LOCAL_DIR=$GLOCAL_PATH"/"$GWB_DIR
	mkdir -p $LOCAL_DIR

	### pull MOCS desktop files from $GWB_DIR
	
	echo "cd $GLOCAL_PATH"
	cd $GLOCAL_PATH
	pwd 

	echo "Pulling all files from "$GWB_DIR
	ls -lrt $LOCAL_DIR | grep "_WB" > $TEMP_DIR"/before.txt"
	echo "$GDRIVE_SCRIPT pull -no-prompt -files $GWB_DIR"
	$GDRIVE_SCRIPT pull -no-prompt -files $GWB_DIR
	ls -lrt $LOCAL_DIR | grep "_WB" > $TEMP_DIR"/after.txt"
	
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
		
		ls -lrt $TEMP_DIR"/before.txt"
		ls -lrt $TEMP_DIR"/after.txt"
		
		NEW_MOCS_WBS=`diff $TEMP_DIR"/before.txt" $TEMP_DIR"/after.txt" | awk '{split($10, ar, "_");print ar[1]}' | sort | uniq`
		NEW_MOCS_WBS=$NEW_MOCS_WBS" "$MOCS
		
		echo $NEW_MOCS_WBS
		
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

		echo "$scripts_dir"GS_import.py" -s $GID -t "Pooling" -p $NAME --Key_dir $MOCSDB_DIR -S "_Pool_Sub_WB.txt""
		$scripts_dir"GS_import.py" -s $GID -t "Pooling" -p $NAME --Key_dir $MOCSDB_DIR -S "_Pool_Sub_WB.txt" 

	done
 
 	PROC=`ls -lrt $MOCSDB_DIR* | grep $MOCS | awk '{y=split($9,ar,"/");split(ar[y],pr,"_");print pr[2]}'`

	# Make $MOCS_DB and push to GDrive
	cat $MOCSDB_DIR*RtS* | grep -v "MOCS-ID" | grep -v "MOCS_ID" | grep MOCS | awk '{print $1","$2","$4","$5}' > $MOCS_DB
	
	ls -lrt $MOCS_DB

# 	mkdir "MOCS_DB"
# 	cp $MOCS_DB ./MOCS_DB
# 	
# 	cd ./MOCS_DB
# 	ls -lrt
# 	
# 	echo $GWB_DIR
# 	pwd
# 	echo "$GDRIVE_SCRIPT push -no-prompt -destination $GMOC_PATH -files ./"
# 	$GDRIVE_SCRIPT push -no-prompt -destination $GMOC_PATH ./


###### Make symlinks with pool IDs in MOCS and MOC dirs
### Make symlinks in MOCS dir
echo "Making symlinks in MOCS dir"

	#  making MOCS symlinks dir
	MOCS_SYMDIR=$MOCSDB_DIR"/SymLinks/"$MOCS"/"
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
	
	for FILE in $ALL_FILES
	do
	
		FASTQ=$FASTQ_DIR$FILE
		SYM=$MOCS_SYMDIR$FILE
		for COMBO in $MOCS_COMBOS
		do
			MOCS=`echo $COMBO | sed 's/,/ /g' | awk '{print $1}'`
			POOL=`echo $COMBO | sed 's/,/ /g' | awk '{print $2}'`
			INDEX=`echo $COMBO | sed 's/,/ /g' | awk '{print $3"_"$4}'`
			MATCH=`echo $FASTQ | grep $INDEX | wc -l`
			
			if [ $MATCH -gt "0" ];then
		
				SYM=`echo $SYM | sed 's*'$INDEX'*'$POOL'*g'`
			fi
		done
		
		echo "ln -sf $FASTQ $SYM"
		ln -sf $FASTQ $SYM
	done

	ls -lrt $MOCS_SYMDIR 
	
	echo $MOCS_SYMDIR	

	
### Make symlinks in MOC dirs
echo "Making symlinks in MOC dirs"

	# Pull out all MOCIDs
	ALL_FILES=`ls -lrt $MOCS_SYMDIR | grep -v Undeter | grep fastq | grep MOCP | awk '{print $9}'`

echo $MOCS_SYMDIR 
echo $ALL_FILES

	ALL_MOCIDS=`echo $ALL_FILES | awk '{

									for(i; i < NF+1; i++)
									{
										y=split($i,ar,"_")
										if(y==9)
											POOL_ID=ar[4]"."ar[5]
										if(y==8)
											POOL_ID=ar[4]

										split(POOL_ID, pr, "p")
										MOC_ID=pr[1]
										print MOC_ID
									}
								}' | sort | uniq`

	# Make symdirs for all MOCIDs
	
	echo "ALL_MOCIDS:" $ALL_MOCIDS
	
	for MOCID in $ALL_MOCIDS
	do
		echo "Making $RAW_SYM_PATH"/"$MOCID"
		mkdir -p $RAW_SYM_PATH"/"$MOCID

	done 


	# Make symfile name and make symlink in project dir
	for FILE in $ALL_FILES
	do

		 FASTQ_FILE=$FASTQ_DIR"/"$FILE
	 
		 echo $FASTQ_FILE
	 
		 INFO=` echo $FILE | awk '{

				y=split($1,ar,"_")
				FCID=ar[1]
				LANE=ar[2]
			
				if(y==9)
				{	
					POOL_ID=ar[4]"."ar[5]
					READ=substr(ar[8],2,1)
				}
				if(y==8)
				{
					POOL_ID=ar[4]
					READ=substr(ar[7],2,1)
				}
				split(POOL_ID, pr, "p")
				MOC_ID=pr[1]
				print MOC_ID" "POOL_ID" "READ" "LANE

			}' `
	
		MOC_ID=`echo $INFO | awk '{print $1}'`
		POOL_ID=`echo $INFO | awk '{print $2}'`
		READ=`echo $INFO | awk '{print $3}'`
		LANE=`echo $INFO | awk '{print $4}'`
		SYM_NAME=$FCID"-"$MOCSID"-XXXXXXXX-XXXXXXXX."$LANE"."$POOL_ID"_"$POOL_ID",.unmapped."$READ".fastq.gz"
		SYM_DIR=$RAW_SYM_PATH"/"$MOC_ID
		SYM_FILE=$SYM_DIR"/"$SYM_NAME
		mkdir -p $SYM_DIR
	
	
		echo "ln -s $FASTQ_FILE $SYM_FILE"
		rm $SYM_FILE
		
		ln -s $FASTQ_FILE $SYM_FILE

	done 

# List all symlinks in MOC symlink dirs
	for MOCID in $ALL_MOCIDS
	do
		echo $RAW_SYM_PATH"/"$MOCID
		ls -lrt $RAW_SYM_PATH"/"$MOCID | grep $MOCSID
	done 
	
	if [ $METRICS == "Y" ];then
		echo "Running metrics..."
		echo "sh $scripts_dir"/MOC_walkup_metrics3.sh" $MOCS"
		sh $scripts_dir"/MOC_walkup_metrics3.sh" $MOCS

	fi