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

### source all functions 
# source "idi/moc_ec/MOC/scripts/MOC_functions.sh"
source "$scripts_dir/MOC_functions.sh"

ls -lrt $scripts_dir/MOC_functions.sh

Q_HEAD="MOC_ID"
USID=`USID`


# identify options to pass to this script (as opposed to the pipeline)
SCRIPT_OPTIONS=`echo $@ | cut -d":" -f1,3`

### set options
# -conf: sets path to config file (default /idi/moc_ec/MOC/config_files/PC_config.yaml)
# -q: sets name of header for Q_VAL (default MOC_ID)
# -move_key: setting to N skips moving google sheet to server (default Y)
# -use_p7: indicates fastq file is demultiplexed by P7 index (default Y)
# -use_p5: indicates fastq file is demultiplexed by P5 index (default N)
# -no_pipe: including or setting to Y skips running pipeline (default N)
# -qsub: run pipeline in UGER (default N)
# -gid: enter google ID if missing from DB (default 0 => get it from DB)
# -smocid: enter smocid if missing from DB (default 0 => get it from DB)
# -import_gs: updates DBs from google drive on server (default Y)
# -user_id: add userID to temp and results paths (default N.  If Y, add login name, if value added after option that userID will be added)
# -moc_id: add MOC_ID to temp and results paths (default Y)
# -PROJ_TYPE: project production (P) or development (D) (default P)

### determining paths and headers 
### default config file is /broad/IDP-Dx_storage/MOC/config_files/PC_config.yaml
paths_and_headers $MOC_ID $@

############################ MOVE KEY FILE TO SERVER ###################################
	
	############### moving key file to server #############################
	if [ $MOVE_KEY == "Y" ];then 
		echo "Running move_key..."
		move_key
	fi
##########################################################################

### Repeating to reset path with updated proj name(s) in key
### determining paths and headers 
### default config file is /broad/IDP-Dx_storage/MOC/config_files/PC_config.yaml
paths_and_headers $MOC_ID $@

echo $TEMP_DIR

### run path_suff function to set RESPATH_SUFF.
##	If -moc_id N included in command line, do not moc_ID to RESPATH_SUFF.  
##	If -user_id included with Y or no string add USID to RESPATH_SUFF.  
##	If -user_id followed by userID, add userID to RESPATH_SUFF.


mkdir -p $RESULTS_DIR
mkdir -p $TEMP_DIR
mkdir -p $BAM_DIR

echo "RESULTS_DIR: "$RESULTS_DIR
echo "TEMP_DIR: "$TEMP_DIR

RAW_SYM_PATH=`extract_option -symlink $RAWSYM_PATH 1 $@`
RAW_SEQ_PATH=`extract_option -raw_seq_path $RAWSYM_PATH 1 $@`

echo "RAW_SYM_PATH: "$RAW_SYM_PATH

############################ SET ANALYSIS PIPELINE OPTIONS ###################################

DEFAULT_PIPE_OPTIONS=" --ADD3 30 --ADD5 20 --use_p5 --gzip_merged --do_patho --MOC_id_ref $MOC_ID --trim_minlen $TRIM_MINLEN"
if [ $USER_ID == "N" ];then
	DEFAULT_PIPE_OPTIONS=$DEFAULT_PIPE_OPTIONS" --no_login_name"
else
	DEFAULT_PIPE_OPTIONS=$DEFAULT_PIPE_OPTIONS" --login_name $USER_ID"
fi
if [ $MOC_ID_OPT != "N" ];then
	DEFAULT_PIPE_OPTIONS=$DEFAULT_PIPE_OPTIONS" --MOC_id "$MOC_ID 
fi
if [ $DO_HOST != "N" ];then
	DEFAULT_PIPE_OPTIONS=`echo $DEFAULT_PIPE_OPTIONS | sed 's/do_patho/do_host/g'`
fi

# Assigns default pipeline options in case none are included in command line, replace default with 
# command line options, or add to default if --no_def_opt is not included
PIPE_COMMAND_OPTIONS=`echo $@ | cut -d':' -f2 | cut -d':' -f1`
PIPE_COMMAND_FLAG=`echo $@ | grep ":" | wc -w`
PIPE_COMMAND_DEF=`echo $@ | cut -d":" -f2 | cut -d":" -f1 | grep "\-no_def_opt" | wc -w`

if [ $PIPE_COMMAND_FLAG == "0" ];then
	PIPE_OPTIONS=$DEFAULT_PIPE_OPTIONS
else
	if [ $PIPE_COMMAND_DEF == "0" ];then
		MATCH="N"
		MOD_DEF_OPTIONS=`for DEF in $DEFAULT_PIPE_OPTIONS
						do
							if [[ "$DEF" == "--"* ]]; then
								printf "%s " $DEF
								PAR=$DEF
							else
								VAL=$DEF
								for MOD in $PIPE_COMMAND_OPTIONS
								do
									if [ $MATCH == "Y" ];then
										VAL=$MOD
										MATCH="N"
									fi
									if [ $MOD == $PAR ];then
										MATCH="Y"
									fi
								done	
								printf "%s " $VAL
							fi
						done`
		PIPE_OPTIONS=$MOD_DEF_OPTIONS" "$PIPE_COMMAND_OPTIONS
	else
		PIPE_OPTIONS=`echo $PIPE_COMMAND_OPTIONS" " | sed 's/\--no_def_opt//g'`
	fi
fi

echo "Pipe options:" 
echo $PIPE_OPTIONS
echo "Default options:" 
echo $DEFAULT_PIPE_OPTIONS


echo "Pipe options:" 
echo $PIPE_OPTIONS
echo "Pipeline options:" 
echo $DEFAULT_PIPE_OPTIONS

RUN_DATE=`date +"%m/%d/%Y %H:%M:%S"`
WRAPPER_OPTIONS=$@
$PIPE_OPTIONS

RUN_RECORD=$RESULTS_DIR"/Run_record.txt"

echo "Run date and time:" $RUN_DATE >> $RUN_RECORD
echo "WRAPPER_OPTIONS:" $WRAPPER_OPTIONS >> $RUN_RECORD
echo "PIPE_OPTIONS:" $PIPE_OPTIONS >> $RUN_RECORD
echo "-----------------" >> $RUN_RECORD

##########################################################################


############################ SET TEMP DIR PATHS ###################################

SAMP_KEY_ID="Sample_ID"
SID_F=`FIELD_HEADER $KEY_FILE $SAMP_KEY_ID`

echo "Results_dir: "$RESULTS_DIR
echo "Temp_dir: "$TEMP_DIR
echo "Data_dir: "$DATA_DIR
mkdir -p $RESULTS_DIR
mkdir -p $TEMP_DIR
rm -r $MOC_SYM_TEST_DIR
mkdir -p $MOC_SYM_TEST_DIR
rm -r $MOC_SYM_TEST_UMI_DIR
mkdir -p $MOC_SYM_TEST_UMI_DIR
echo $KEY_SHEET

echo "Printing merge directory before move and ref files: $MERGE_DIR"



############################ MOVE AND PARSE REF FILES ###################################

	############## Move references from Gdrive or ref dir and parse --> data dir ###############
	if [ $REFMOVE_OPT == "Y" ];then
		
		CHECK_DIR=$DATA_DIR
		ALL_SUFF="_ALL.gff,.fna" 

		echo "Moving references to appropriate directory"	
		echo "sh $REF_MOVE_SCRIPT $MOC_ID -data_dir $DATA_DIR -parse $PARSE_REF -move_key N -proj_type $PROJ_TYPE $@"
		sh $REF_MOVE_SCRIPT $MOC_ID -data_dir $DATA_DIR -parse $PARSE_REF -move_key N -proj_type $PROJ_TYPE $@


		############## Check if all gff files were parsed ##############
		echo "mod_check $MOC_ID $CHECK_DIR $ALL_SUFF -fail_exit Y -email Y -header "Bacterial_reference" -delimit none $@"
		mod_check $MOC_ID $CHECK_DIR $ALL_SUFF -fail_exit Y -email Y -header "Bacterial_reference" -delimit none $@
			
	fi
##########################################################################


######################  IF TEST_PIPE  #########################################

if [ $TEST_PIPE == "Y" ];then
	make_test_fastqs $NUM_TEST_READS
fi
if [ $TEST_PIPE == "Y" ] || [ $TEST_PIPE == "R" ];then
	MOC_SYM_DIR=$MOC_SYM_TEST_DIR
fi

##############################################################################

######################  IF ADD_UMI_TO_READ_ID  #########################################
# relevant only for SCR Projects where UMI is added to read ID

if [ $ADD_UMI_TO_READ_ID == "Y" ];then
	echo "Adding UMI to read ID............."

	UMI_ADD_COMMANDS_FILE=$MOC_SYM_TEST_UMI_DIR"/commands.txt"
	UMI_ADD_LOG_DIR=$MOC_SYM_TEST_UMI_DIR"/logdir"

	rm $UMI_ADD_COMMANDS_FILE

	echo "UMI_ADD_COMMANDS_FILE" $UMI_ADD_COMMANDS_FILE
	echo "UMI_ADD_LOG_DIR" $UMI_ADD_LOG_DIR

	mkdir -p $MOC_SYM_TEST_UMI_DIR
	mkdir -p $UMI_ADD_LOG_DIR

	ALL_FASTQ_READ1s=`ls -lrt $MOC_SYM_DIR | grep "unmapped.1.fastq.gz" | awk '{print $9}'`
	for FASTQ_READ1 in $ALL_FASTQ_READ1s
	do
		FASTQ_READ2="${FASTQ_READ1/unmapped.1.fastq.gz/unmapped.2.fastq.gz}"
		FASTQ_NAME="${FASTQ_READ1/1.fastq.gz/}"

		INPUT_READ1=$MOC_SYM_DIR"/"$FASTQ_READ1
		INPUT_READ2=$MOC_SYM_DIR"/"$FASTQ_READ2

		OUTPUT_READ1=$MOC_SYM_TEST_UMI_DIR"/"$FASTQ_READ1
		OUTPUT_READ2=$MOC_SYM_TEST_UMI_DIR"/"$FASTQ_READ2 

		echo "bash $ADD_UMI_TO_READ_ID_SCRIPT $INPUT_READ1 $INPUT_READ2 $OUTPUT_READ1 $OUTPUT_READ2 1> $UMI_ADD_LOG_DIR/$FASTQ_NAME'_out.txt' 2>  $UMI_ADD_LOG_DIR/$FASTQ_NAME'_err.txt' " >> $UMI_ADD_COMMANDS_FILE
	done

	python $UGER_CBP_PATH --cmds_file $UMI_ADD_COMMANDS_FILE --batch_size 1 --memory 4 --job_name add_umi_to_read_id --bash_header $scripts_dir/bash_header --tracking_dir $MOC_SYM_TEST_UMI_DIR/tmp.tracking --project_name broad

	### change permissions
	change_perms $MOC_SYM_TEST_UMI_DIR 

	MOC_SYM_DIR=$MOC_SYM_TEST_UMI_DIR
fi
##############################################################################

ANALYSIS_DIR=$MOC_SYM_DIR"/analysis"

echo "ANALYSIS_DIR: " $ANALYSIS_DIR

mkdir -p $ANALYSIS_DIR
change_perms $ANALYSIS_DIR

# master flag that sets/unsets -fastqc, -fastqc_sample, -adapter_analysis, -adapter_analysis_sample, -trimmomatic_sample
BC_ANALYSIS=`extract_option -bc_analysis Y 1 $@`

# the default value is based on the bc_analysis flag
FASTQC=`extract_option -fastqc $BC_ANALYSIS 1 $@`
ADAPTER_ANALYSIS=`extract_option -adapter_analysis $BC_ANALYSIS 1 $@`
FASTQC_SAMPLE=`extract_option -fastqc_sample $BC_ANALYSIS 1 $@`
ADAPTER_ANALYSIS_SAMPLE=`extract_option -adapter_analysis_sample $BC_ANALYSIS 1 $@`
TRIMMOMATIC_SAMPLE=`extract_option -trimmomatic_sample $BC_ANALYSIS 1 $@`

# print the values of all flags
echo "BC_ANALYSIS: " $BC_ANALYSIS
echo "FASTQC: " $FASTQC
echo "ADAPTER_ANALYSIS: " $ADAPTER_ANALYSIS
echo "FASTQC_SAMPLE: " $FASTQC_SAMPLE
echo "ADAPTER_ANALYSIS_SAMPLE: " $ADAPTER_ANALYSIS_SAMPLE
echo "TRIMMOMATIC_SAMPLE: " $TRIMMOMATIC_SAMPLE

############################ Preprocessing: Run FastQC on the raw sequences ################

if [ $FASTQC == "Y" ]; then

	echo "Running FastQC analysis............."
	
	FASTQC_DIR=$ANALYSIS_DIR"/fastqc"
	FASTQC_COMMANDS_FILE=$FASTQC_DIR"/commands.txt"
	FASTQC_TEMP_FILE=$TEMP_DIR$MOC_ID"_"$PROJ_ID"_fastqc_temp.txt"
	FASTQC_LOG_DIR=$FASTQC_DIR"/logdir"

	rm $FASTQC_COMMANDS_FILE

	echo "FASTQC_DIR: " $FASTQC_DIR
	echo "FASTQC_TEMP_FILE" $FASTQC_TEMP_FILE
	echo "FASTQC_COMMANDS_FILE" $FASTQC_COMMANDS_FILE
	echo "FASTQC_LOG_DIR" $FASTQC_LOG_DIR

	mkdir -p $FASTQC_DIR
	mkdir -p $FASTQC_LOG_DIR

	ALL_FASTQ=`ls -lrt $MOC_SYM_DIR | grep 'unmapped\..\.fastq' | awk '{print $9}'`
	echo $ALL_FASTQ
	for FASTQ in $ALL_FASTQ
	do
		IN_FILE=$MOC_SYM_DIR"/"$FASTQ
		OUT_DIR=$FASTQC_DIR 

		echo "fastqc $IN_FILE -o $FASTQC_DIR 1> $FASTQC_LOG_DIR/$FASTQ'_out.txt' 2>  $FASTQC_LOG_DIR/$FASTQ'_err.txt' " >> $FASTQC_COMMANDS_FILE
	done

	python $UGER_CBP_PATH --cmds_file $FASTQC_COMMANDS_FILE --batch_size 1 --memory 1 --job_name fastqc --bash_header $scripts_dir/bash_header --tracking_dir $FASTQC_DIR/tmp.tracking --project_name broad

	### change permissions for Fastqc dir
	change_perms $FASTQC_DIR 
fi

##########################################################################

############################ Preprocessing: Run adapter analysis ################

if [ $ADAPTER_ANALYSIS == "Y" ]; then

	echo "Running Adapter analysis............."

	ADAPTER_ANALYSIS_DIR=$ANALYSIS_DIR"/adapter_analysis"
	ADAPTER_ANALYSIS_COMMANDS_FILE=$ADAPTER_ANALYSIS_DIR"/commands.txt"
	ADAPTER_ANALYSIS_TEMP_FILE=$TEMP_DIR$MOC_ID"_"$PROJ_ID"_adapter_analysis_temp.txt"
	ADAPTER_ANALYSIS_LOG_DIR=$ADAPTER_ANALYSIS_DIR"/logdir"

	echo "ADAPTER_ANALYSIS_DIR: " $ADAPTER_ANALYSIS_DIR
	echo "ADAPTER_ANALYSIS_COMMANDS_FILE" $ADAPTER_ANALYSIS_COMMANDS_FILE
	echo "ADAPTER_ANALYSIS_TEMP_FILE" $ADAPTER_ANALYSIS_TEMP_FILE
	echo "ADAPTER_ANALYSIS_LOG_DIR" $ADAPTER_ANALYSIS_LOG_DIR

	rm -r $ADAPTER_ANALYSIS_DIR
	# rm $ADAPTER_ANALYSIS_COMMANDS_FILE

	mkdir -p $ADAPTER_ANALYSIS_DIR
	mkdir -p $ADAPTER_ANALYSIS_LOG_DIR

	ALL_FASTQ_GZ_READ2s=`ls -lrt $MOC_SYM_DIR | grep "unmapped.2.fastq.gz" | awk '{print $9}'`
	for FASTQ_GZ_READ2 in $ALL_FASTQ_GZ_READ2s
	do
		FASTQ_NAME="${FASTQ_GZ_READ2/2.fastq.gz/}"
		FASTQ_READ2="${FASTQ_GZ_READ2/.fastq.gz/.fastq}"
		FASTA_READ2="${FASTQ_READ2/.fastq/.fasta}"

		FASTQ_GZ_READ2_PATH=$MOC_SYM_DIR"/"$FASTQ_GZ_READ2
		FASTQ_READ2_PATH=$ADAPTER_ANALYSIS_DIR/$FASTQ_READ2
		FASTA_READ2_PATH=$ADAPTER_ANALYSIS_DIR/$FASTA_READ2

		# Decompressing
		echo "gzip -d -c $FASTQ_GZ_READ2_PATH > $FASTQ_READ2_PATH" >> $ADAPTER_ANALYSIS_COMMANDS_FILE
		# converting fastq to fasta (obtained from chatgpt)
		# run the analysis only on 100,000 reads max (so 200,000 lines)
		echo "awk 'NR%4==1{printf \">%s\n\", substr(\$0,2)} NR%4==2{print}' $FASTQ_READ2_PATH | head -200000 > $FASTA_READ2_PATH" >> $ADAPTER_ANALYSIS_COMMANDS_FILE

		# Maps each query (read) to the two adapters, the seed size is controlled by word size. Word size of 10 means there will be atleast 10 NT with perfect match between adapter and read
		# Output - csv format
		# csv columns - 'qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore'
		BLAST_OP_PATH="${FASTA_READ2_PATH%.fasta}_blast_op_ws_10.csv"
		echo "blastn -db $ADAPTER_ANALYSIS_ADAPTER_FILE -query $FASTA_READ2_PATH -out $BLAST_OP_PATH -outfmt 10 -ungapped  -word_size 10 -strand plus -num_threads 10" >> $ADAPTER_ANALYSIS_COMMANDS_FILE

		# Generating plots in Python
		echo "python $READ_INSERTION_ADAPTER_ANALYSIS_SCRIPT -csv $BLAST_OP_PATH -fasta $FASTA_READ2_PATH -lc_method $LC_method" >> $ADAPTER_ANALYSIS_COMMANDS_FILE

		# Remove intermediate files
		echo "rm $BLAST_OP_PATH" >> $ADAPTER_ANALYSIS_COMMANDS_FILE
		echo "rm $FASTQ_READ2_PATH" >> $ADAPTER_ANALYSIS_COMMANDS_FILE
		echo "rm $FASTA_READ2_PATH" >> $ADAPTER_ANALYSIS_COMMANDS_FILE
	done
	python $UGER_CBP_PATH --cmds_file $ADAPTER_ANALYSIS_COMMANDS_FILE --batch_size 7 --memory 8 --num_cores 1 --job_name read_insertion_adapter_analysis --bash_header $scripts_dir/bash_header --tracking_dir $ADAPTER_ANALYSIS_DIR/tmp.tracking --project_name broad

fi

##########################################################################


############################ Preprocessing: Run Trimmomatic to trim adapter sequences ################

TRIMMOMATIC=`extract_option -trimmomatic N 1 $@`

if [ $TRIMMOMATIC_SAMPLE == "N" ] && [ $TRIMMOMATIC == "Y" ] && [ $TRIM_READS == "N" ]; then

	echo "Running Trimmomatic to trim adapter from read sequences............."

	TRIMMOMATIC_DIR=$ANALYSIS_DIR"/trimmomatic"
	TRIMMOMATIC_UNPAIRED_DIR=$TRIMMOMATIC_DIR"/unpaired"
	
	TRIMMOMATIC_LOG_DIR=$TRIMMOMATIC_DIR"/logdir"
	TRIMMOMATIC_TEMP_FILE=$TEMP_DIR$MOC_ID"_"$PROJ_ID"_trimmomatic_temp.txt"
	TRIMMOMATIC_COMMANDS_FILE=$TRIMMOMATIC_DIR"/commands.txt"

	# rm $TRIMMOMATIC_COMMANDS_FILE
	rm -r $TRIMMOMATIC_DIR

	echo "TRIMMOMATIC_DIR: " $TRIMMOMATIC_DIR
	echo "TRIMMOMATIC_UNPAIRED_DIR: " $TRIMMOMATIC_UNPAIRED_DIR
	echo "TRIMMOMATIC_LOG_DIR: " $TRIMMOMATIC_LOG_DIR
	echo "TRIMMOMATIC_TEMP_FILE: " $TRIMMOMATIC_TEMP_FILE
	echo "TRIMMOMATIC_COMMANDS_FILE: " $TRIMMOMATIC_COMMANDS_FILE

	mkdir -p $TRIMMOMATIC_DIR
	mkdir -p $TRIMMOMATIC_UNPAIRED_DIR
	mkdir -p $TRIMMOMATIC_LOG_DIR

	ALL_FASTQ_READ1s=`ls -lrt $MOC_SYM_DIR | grep "unmapped.1.fastq" | awk '{print $9}'`
	for FASTQ_READ1 in $ALL_FASTQ_READ1s
	do
		FASTQ_READ2="${FASTQ_READ1/unmapped.1.fastq/unmapped.2.fastq}"
		FASTQ_NAME="${FASTQ_READ1/1.fastq.gz/}"

		INPUT_READ1=$MOC_SYM_DIR"/"$FASTQ_READ1
		INPUT_READ2=$MOC_SYM_DIR"/"$FASTQ_READ2

		OUTPUT_PAIRED_READ1=$TRIMMOMATIC_DIR"/"$FASTQ_READ1
		OUTPUT_PAIRED_READ2=$TRIMMOMATIC_DIR"/"$FASTQ_READ2
		OUTPUT_UNPAIRED_READ1=$TRIMMOMATIC_UNPAIRED_DIR"/"$FASTQ_READ1
		OUTPUT_UNPAIRED_READ2=$TRIMMOMATIC_UNPAIRED_DIR"/"$FASTQ_READ2
		
		# Trimmomatic Parameters
		# seed mismatches: 2
		# palindrome clip threshold: 10
		# simple clip threshold: 10
		# minAdapterLength: 8
		# --keep-both-reads: True
		# min read length to keep the reads after adapter trimming: 10
		echo "java -jar $TRIMMOMATIC_JAR PE -trimlog $TRIMMOMATIC_LOG_DIR/$FASTQ_NAME'_trimlog.txt' $INPUT_READ1 $INPUT_READ2 $OUTPUT_PAIRED_READ1 $OUTPUT_UNPAIRED_READ1 $OUTPUT_PAIRED_READ2 $OUTPUT_UNPAIRED_READ2 ILLUMINACLIP:$TRIMMOMATIC_ADAPTER_FILE:2:10:10:8:True MINLEN:$TRIM_MINLEN 1> $TRIMMOMATIC_LOG_DIR/$FASTQ_NAME'_out.txt' 2>  $TRIMMOMATIC_LOG_DIR/$FASTQ_NAME'_err.txt'" >> $TRIMMOMATIC_COMMANDS_FILE
		
		echo "$TRIMMOMATIC_STATS_SCRIPT $TRIMMOMATIC_LOG_DIR/$FASTQ_NAME'_trimlog.txt' $TRIMMOMATIC_LOG_DIR/$FASTQ_NAME'_err.txt'" >> $TRIMMOMATIC_COMMANDS_FILE
	done

	python $UGER_CBP_PATH --cmds_file $TRIMMOMATIC_COMMANDS_FILE --batch_size 2 --memory 1 --job_name trimmomatic --bash_header $scripts_dir/bash_header --tracking_dir $TRIMMOMATIC_DIR/tmp.tracking --project_name broad

	### change permissions for trimmomatic dir
	change_perms $TRIMMOMATIC_DIR 

	# point pipeline to run on trimmed sequences
	MOC_SYM_DIR=$TRIMMOMATIC_DIR
	echo "MOC_SYM_DIR: $MOC_SYM_DIR"
fi
##########################################################################

######################## RUN MOD 1: SPLIT ###########################

	############## Launch pipeline to split by barcode ##############

	if [ $SPLIT == "Y" ] || [ $SPLIT == "O" ] || [ $SPLIT == "R" ];then

		MOD_KEY_FILE=$KEY_FILE
		
		############## Launch pipeline to split demultiplexed fastqs ##############
		MOD_PIPE_OPTIONS=$PIPE_OPTIONS" --no_merge --no_align --no_count"
		
		echo "Launching analysis pipeline to split fastqs by inline barcode..."
		echo "python2 $PIPE_SCRIPT -c $CONFIG_FILE --key_path $MOD_KEY_FILE --raw_seq_path $MOC_SYM_DIR $MOD_PIPE_OPTIONS"
 		python2 $PIPE_SCRIPT -c $CONFIG_FILE --key_path $MOD_KEY_FILE --raw_seq_path $MOC_SYM_DIR $MOD_PIPE_OPTIONS

		######## Run metrics script to calculate distribution of reads per barcode
		MOD_KEY_FILE=$KEY_FILE

		echo "sh $SPLITMET_SCRIPT $MOC_ID $@"
		sh $SPLITMET_SCRIPT $MOC_ID $@
			
	fi
##########################################################################


################################# RUN MOD 2: MERGE ###################################

	if [ $MERGE == "Y" ] || [ $MERGE == "O" ] || [ $MERGE == "R" ];then
		
		CHECK_DIR=$MERGE_DIR
		ALL_SUFF="R1.fastq.gz,R2.fastq.gz" 
		MOD_KEY_FILE=$KEY_FILE

		if [ $MERGE == "R" ];then
			redo_key $CHECK_DIR
			MOD_KEY_FILE=$REDO_KEY_FILE
		fi
		
		############## Launch pipeline to merge split fastqs ##############
		MOD_PIPE_OPTIONS=$PIPE_OPTIONS" --no_split --no_align --no_count"
		
		echo "Launching analysis pipeline to merge split fastqs by sample..."
		echo "python2 $PIPE_SCRIPT -c $CONFIG_FILE --key_path $MOD_KEY_FILE --raw_seq_path $MOC_SYM_DIR $MOD_PIPE_OPTIONS"
		python2 $PIPE_SCRIPT -c $CONFIG_FILE --key_path $MOD_KEY_FILE --raw_seq_path $MOC_SYM_DIR $MOD_PIPE_OPTIONS
		MOD_KEY_FILE=$KEY_FILE
		
		############## Check if all files were merged ##############
		mod_check $MOC_ID $CHECK_DIR $ALL_SUFF -fail_exit N -email Y $@
	fi

##########################################################################

ANALYSIS_SAMPLE_DIR=$MERGE_DIR"/analysis"

echo "ANALYSIS_SAMPLE_DIR: " $ANALYSIS_SAMPLE_DIR

mkdir -p $ANALYSIS_SAMPLE_DIR
change_perms $ANALYSIS_SAMPLE_DIR


##//// added 3/30/25
############################ Trimming reads by set lengths ################
	
	if [ $TRIM_READS == "S" ];then
		
		MERGE_DIR=$MERGE_TRIM_DIR
	fi
	if [ $TRIM_READS == "Y" ];then
		###################
		
		mkdir -p $MERGE_TRIM_DIR

		echo "Making fastqs with R1 trimmed from $READ1_START to $READ1_END and R2 trimmed from $READ2_START to $READ2_END for all fastqs in $MERGE_DIR and writing them out to $MERGE_TRIM_DIR..."
		ALL_FASTQ=`ls -lrt $MERGE_DIR/*gz | grep fastq | awk '{print $9}'`
		
		SEG_FILE="FQ_trim_SGE.txt"
		TEMP_FILE=$MOC_ID"_trim_temp.txt"

		for FASTQ in $ALL_FASTQ
		do
	
			echo "Launching UGER job for "$FASTQ
			echo "sh $FASTQ_TRIM_SCRIPT $FASTQ $TRIM_LEN $MERGE_DIR $MERGE_TRIM_DIR"
			echo "sh $FASTQ_TRIM_SCRIPT $FASTQ $TRIM_LEN $MERGE_DIR $MERGE_TRIM_DIR" > $TEMP_FILE
			qsub $TEMP_FILE >> $SEG_FILE					
		done
		
		echo $SEG_FILE
		qstat
		echo "Jobs submitted - waiting for them to complete...."
		SGE_test $SEG_FILE	
	
		MERGE_DIR=$MERGE_TRIM_DIR
		ls -lrt $MERGE_DIR
		echo $MERGE_DIR
		echo $MERGE_TRIM_DIR
		echo $TRIM_READS
	
	fi
##############################################################################
##///////

############################ Preprocessing: Run Trimmomatic to trim adapter sequences on sample level data ################

if [ $TRIMMOMATIC_SAMPLE == "Y" ] && [ $TRIM_READS == "N" ]; then

	echo "Running Trimmomatic to trim adapter from read sequences on sample-level data............."

	TRIMMOMATIC_SAMPLE_DIR=$ANALYSIS_SAMPLE_DIR"/trimmomatic"
	TRIMMOMATIC_SAMPLE_UNPAIRED_DIR=$TRIMMOMATIC_SAMPLE_DIR"/unpaired"
	
	TRIMMOMATIC_SAMPLE_LOG_DIR=$TRIMMOMATIC_SAMPLE_DIR"/logdir"
	TRIMMOMATIC_SAMPLE_TEMP_FILE=$TEMP_DIR$MOC_ID"_"$PROJ_ID"_trimmomatic_sample_temp.txt"
	TRIMMOMATIC_SAMPLE_COMMANDS_FILE=$TRIMMOMATIC_SAMPLE_DIR"/commands.txt"

	# rm $TRIMMOMATIC_COMMANDS_FILE
	rm -r $TRIMMOMATIC_SAMPLE_DIR

	echo "TRIMMOMATIC_SAMPLE_DIR: " $TRIMMOMATIC_SAMPLE_DIR
	echo "TRIMMOMATIC_SAMPLE_UNPAIRED_DIR: " $TRIMMOMATIC_SAMPLE_UNPAIRED_DIR
	echo "TRIMMOMATIC_SAMPLE_LOG_DIR: " $TRIMMOMATIC_SAMPLE_LOG_DIR
	echo "TRIMMOMATIC_SAMPLE_TEMP_FILE: " $TRIMMOMATIC_SAMPLE_TEMP_FILE
	echo "TRIMMOMATIC_SAMPLE_COMMANDS_FILE: " $TRIMMOMATIC_SAMPLE_COMMANDS_FILE

	mkdir -p $TRIMMOMATIC_SAMPLE_DIR
	mkdir -p $TRIMMOMATIC_SAMPLE_UNPAIRED_DIR
	mkdir -p $TRIMMOMATIC_SAMPLE_LOG_DIR

	ALL_FASTQ_READ1s=`ls -lrt $MERGE_DIR | grep "R1.fastq" | awk '{print $9}'`
	for FASTQ_READ1 in $ALL_FASTQ_READ1s
	do
		FASTQ_READ2="${FASTQ_READ1/R1.fastq/R2.fastq}"
		FASTQ_NAME="${FASTQ_READ1/R1.fastq.gz/}"

		INPUT_READ1=$MERGE_DIR"/"$FASTQ_READ1
		INPUT_READ2=$MERGE_DIR"/"$FASTQ_READ2

		OUTPUT_PAIRED_READ1=$TRIMMOMATIC_SAMPLE_DIR"/"$FASTQ_READ1
		OUTPUT_PAIRED_READ2=$TRIMMOMATIC_SAMPLE_DIR"/"$FASTQ_READ2
		OUTPUT_UNPAIRED_READ1=$TRIMMOMATIC_SAMPLE_UNPAIRED_DIR"/"$FASTQ_READ1
		OUTPUT_UNPAIRED_READ2=$TRIMMOMATIC_SAMPLE_UNPAIRED_DIR"/"$FASTQ_READ2
		
		# Trimmomatic Parameters
		# seed mismatches: 2
		# palindrome clip threshold: 10
		# simple clip threshold: 10
		# minAdapterLength: 8
		# --keep-both-reads: True
		# min read length to keep the reads after adapter trimming: 10
		echo "java -jar $TRIMMOMATIC_JAR PE -trimlog $TRIMMOMATIC_SAMPLE_LOG_DIR/$FASTQ_NAME'_trimlog.txt' $INPUT_READ1 $INPUT_READ2 $OUTPUT_PAIRED_READ1 $OUTPUT_UNPAIRED_READ1 $OUTPUT_PAIRED_READ2 $OUTPUT_UNPAIRED_READ2 ILLUMINACLIP:$TRIMMOMATIC_ADAPTER_FILE:2:10:10:8:True MINLEN:$TRIM_MINLEN 1> $TRIMMOMATIC_SAMPLE_LOG_DIR/$FASTQ_NAME'_out.txt' 2>  $TRIMMOMATIC_SAMPLE_LOG_DIR/$FASTQ_NAME'_err.txt'" >> $TRIMMOMATIC_SAMPLE_COMMANDS_FILE
		
		echo "$TRIMMOMATIC_STATS_SCRIPT $TRIMMOMATIC_SAMPLE_LOG_DIR/$FASTQ_NAME'_trimlog.txt' $TRIMMOMATIC_SAMPLE_LOG_DIR/$FASTQ_NAME'_err.txt'" >> $TRIMMOMATIC_SAMPLE_COMMANDS_FILE
	done

	python $UGER_CBP_PATH --cmds_file $TRIMMOMATIC_SAMPLE_COMMANDS_FILE --batch_size 2 --memory 1 --job_name trimmomatic_sample --bash_header $scripts_dir/bash_header --tracking_dir $TRIMMOMATIC_SAMPLE_DIR/tmp.tracking --project_name broad

	### change permissions for trimmomatic dir
	change_perms $TRIMMOMATIC_SAMPLE_DIR 

	# point pipeline to run on trimmed sequences 
	# Think we need to point merge to dir to trimmomatic dir
	MERGE_DIR=$TRIMMOMATIC_SAMPLE_DIR
	echo "MERGE_DIR: $MERGE_DIR"
fi
##########################################################################

############################ Preprocessing: Run FastQC on sample sequences ################

if [ $FASTQC_SAMPLE == "Y" ]; then

	echo "Running FastQC analysis on sample-level data............."
	
	FASTQC_SAMPLE_DIR=$ANALYSIS_SAMPLE_DIR"/fastqc"
	FASTQC_SAMPLE_COMMANDS_FILE=$FASTQC_SAMPLE_DIR"/commands.txt"
	FASTQC_SAMPLE_TEMP_FILE=$TEMP_DIR$MOC_ID"_"$PROJ_ID"_fastqc_sample_temp.txt"
	FASTQC_SAMPLE_LOG_DIR=$FASTQC_SAMPLE_DIR"/logdir"

	rm $FASTQC_SAMPLE_COMMANDS_FILE

	echo "FASTQC_SAMPLE_DIR: " $FASTQC_SAMPLE_DIR
	echo "FASTQC_SAMPLE_TEMP_FILE" $FASTQC_SAMPLE_TEMP_FILE
	echo "FASTQC_SAMPLE_COMMANDS_FILE" $FASTQC_SAMPLE_COMMANDS_FILE
	echo "FASTQC_LOG_DIR" $FASTQC_LOG_DIR

	mkdir -p $FASTQC_SAMPLE_DIR
	mkdir -p $FASTQC_SAMPLE_LOG_DIR

	ALL_FASTQ=`ls -lrt $MERGE_DIR | grep 'fastq.gz' | awk '{print $9}'`
	echo $ALL_FASTQ
	for FASTQ in $ALL_FASTQ
	do
		IN_FILE=$MERGE_DIR"/"$FASTQ
		OUT_DIR=$FASTQC_SAMPLE_DIR 

		echo "fastqc $IN_FILE -o $FASTQC_SAMPLE_DIR 1> $FASTQC_SAMPLE_LOG_DIR/$FASTQ'_out.txt' 2>  $FASTQC_SAMPLE_LOG_DIR/$FASTQ'_err.txt' " >> $FASTQC_SAMPLE_COMMANDS_FILE
	done

	python $UGER_CBP_PATH --cmds_file $FASTQC_SAMPLE_COMMANDS_FILE --batch_size 1 --memory 1 --job_name fastqc_sample --bash_header $scripts_dir/bash_header --tracking_dir $FASTQC_SAMPLE_DIR/tmp.tracking --project_name broad

	### change permissions for Fastqc dir
	change_perms $FASTQC_SAMPLE_DIR 
fi

##########################################################################


############################ Preprocessing: Run adapter analysis on sample sequences ################

if [ $ADAPTER_ANALYSIS_SAMPLE == "Y" ]; then

	echo "Running Adapter analysis on sample-level data............."

	ADAPTER_ANALYSIS_SAMPLE_DIR=$ANALYSIS_SAMPLE_DIR"/adapter_analysis"
	ADAPTER_ANALYSIS_SAMPLE_COMMANDS_FILE=$ADAPTER_ANALYSIS_SAMPLE_DIR"/commands.txt"
	ADAPTER_ANALYSIS_SAMPLE_TEMP_FILE=$TEMP_DIR$MOC_ID"_"$PROJ_ID"_adapter_analysis_sample_temp.txt"
	ADAPTER_ANALYSIS_SAMPLE_LOG_DIR=$ADAPTER_ANALYSIS_SAMPLE_DIR"/logdir"

	echo "ADAPTER_ANALYSIS_SAMPLE_DIR: " $ADAPTER_ANALYSIS_SAMPLE_DIR
	echo "ADAPTER_ANALYSIS_SAMPLE_COMMANDS_FILE" $ADAPTER_ANALYSIS_SAMPLE_COMMANDS_FILE
	echo "ADAPTER_ANALYSIS_SAMPLE_TEMP_FILE" $ADAPTER_ANALYSIS_SAMPLE_TEMP_FILE
	echo "ADAPTER_ANALYSIS_SAMPLE_LOG_DIR" $ADAPTER_ANALYSIS_SAMPLE_LOG_DIR

	rm -r $ADAPTER_ANALYSIS_SAMPLE_DIR
	# rm $ADAPTER_ANALYSIS_SAMPLE_COMMANDS_FILE

	mkdir -p $ADAPTER_ANALYSIS_SAMPLE_DIR
	mkdir -p $ADAPTER_ANALYSIS_SAMPLE_LOG_DIR

	ALL_FASTQ_GZ_READ2s=`ls -lrt $MERGE_DIR | grep "R2\.fastq\.gz" | awk '{print $9}'`
	for FASTQ_GZ_READ2 in $ALL_FASTQ_GZ_READ2s
	do
		FASTQ_NAME="${FASTQ_GZ_READ2/R2.fastq.gz/}"
		FASTQ_READ2="${FASTQ_GZ_READ2/.fastq.gz/.fastq}"
		FASTA_READ2="${FASTQ_READ2/.fastq/.fasta}"

		FASTQ_GZ_READ2_PATH=$MERGE_DIR"/"$FASTQ_GZ_READ2
		FASTQ_READ2_PATH=$ADAPTER_ANALYSIS_SAMPLE_DIR/$FASTQ_READ2
		FASTA_READ2_PATH=$ADAPTER_ANALYSIS_SAMPLE_DIR/$FASTA_READ2

		# Decompressing
		echo "gzip -d -c $FASTQ_GZ_READ2_PATH > $FASTQ_READ2_PATH" >> $ADAPTER_ANALYSIS_SAMPLE_COMMANDS_FILE
		# converting fastq to fasta (obtained from chatgpt)
		# run the analysis only on 100,000 reads max (so 200,000 lines)
		echo "awk 'NR%4==1{printf \">%s\n\", substr(\$0,2)} NR%4==2{print}' $FASTQ_READ2_PATH | head -100000 > $FASTA_READ2_PATH" >> $ADAPTER_ANALYSIS_SAMPLE_COMMANDS_FILE

		# Maps each query (read) to the two adapters, the seed size is controlled by word size. Word size of 10 means there will be atleast 10 NT with perfect match between adapter and read
		# Output - csv format
		# csv columns - 'qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore'
		BLAST_OP_PATH="${FASTA_READ2_PATH%.fasta}_blast_op_ws_10.csv"
		echo "blastn -db $ADAPTER_ANALYSIS_ADAPTER_FILE -query $FASTA_READ2_PATH -out $BLAST_OP_PATH -outfmt 10 -ungapped  -word_size 10 -strand plus -num_threads 10" >> $ADAPTER_ANALYSIS_SAMPLE_COMMANDS_FILE

		# Generating plots in Python
		echo "python $READ_INSERTION_ADAPTER_ANALYSIS_SCRIPT -csv $BLAST_OP_PATH -fasta $FASTA_READ2_PATH -lc_method $LC_method" >> $ADAPTER_ANALYSIS_SAMPLE_COMMANDS_FILE

		# Remove intermediate files
		echo "rm $BLAST_OP_PATH" >> $ADAPTER_ANALYSIS_SAMPLE_COMMANDS_FILE
		echo "rm $FASTQ_READ2_PATH" >> $ADAPTER_ANALYSIS_SAMPLE_COMMANDS_FILE
		echo "rm $FASTA_READ2_PATH" >> $ADAPTER_ANALYSIS_SAMPLE_COMMANDS_FILE
	done
	python $UGER_CBP_PATH --cmds_file $ADAPTER_ANALYSIS_SAMPLE_COMMANDS_FILE --batch_size 7 --memory 2 --num_cores 1 --job_name read_insertion_adapter_analysis_sample --bash_header $scripts_dir/bash_header --tracking_dir $ADAPTER_ANALYSIS_SAMPLE_DIR/tmp.tracking --project_name broad

fi

##########################################################################

################################# RUN MOD 3: ALIGN ###################################

	############## Launch pipeline to align merged fastqs ##############
	if [ $ALIGN == "Y" ] || [ $ALIGN == "O" ] || [ $ALIGN == "R" ];then

		CHECK_DIR=$ALIGN_DIR
		ALL_SUFF="_u.bam,_pe.bam" 
		MOD_KEY_FILE=$KEY_FILE

		if [ $ALIGN == "R" ];then
			redo_key 
			MOD_KEY_FILE=$REDO_KEY_FILE
		fi
		
		############## Launch pipeline to align merged fastqs ##############
		MOD_PIPE_OPTIONS=$PIPE_OPTIONS" --no_split --no_merge --no_count"

		echo "Launching analysis pipeline to align merged fastqs to reference genomes..."
		echo "python2 $PIPE_SCRIPT -c $CONFIG_FILE --key_path $MOD_KEY_FILE --raw_seq_path $MOC_SYM_DIR $MOD_PIPE_OPTIONS --merge_dir $MERGE_DIR"
		python2 $PIPE_SCRIPT -c $CONFIG_FILE --key_path $MOD_KEY_FILE --raw_seq_path $MOC_SYM_DIR $MOD_PIPE_OPTIONS --merge_dir $MERGE_DIR
		
		############## Check if all files were merged ##############
		mod_check $MOC_ID $CHECK_DIR $ALL_SUFF -fail_exit N -email Y -ref Y $@
	fi
##########################################################################

################################# RUN MOD 4: COUNT ###################################

	############## Launch pipeline to count aligned bams ##############
	if [ $COUNT == "Y" ] || [ $COUNT == "O" ] || [ $COUNT == "R" ];then
	
		CHECK_DIR=$ALIGN_DIR
		ALL_SUFF=".counts" 
		MOD_KEY_FILE=$KEY_FILE

		MOD_PIPE_OPTIONS=$PIPE_OPTIONS" --no_split --no_merge --no_align"

		echo "Launching analysis pipeline to count reads per genes in aligned bams..."
		echo "python2 $PIPE_SCRIPT -c $CONFIG_FILE --key_path $MOD_KEY_FILE --raw_seq_path $MOC_SYM_DIR $MOD_PIPE_OPTIONS"
		python2 $PIPE_SCRIPT -c $CONFIG_FILE --key_path $MOD_KEY_FILE --raw_seq_path $MOC_SYM_DIR $MOD_PIPE_OPTIONS
		
		############## Check if all files were merged ##############
		mod_check $MOC_ID $CHECK_DIR $ALL_SUFF -fail_exit N -email Y -ref Y $@
	fi
##########################################################################


NUM_CG_PAIRS=`FIND_VALUES_FOR_HEADER CG_ID $KEY_FILE | wc -l`
PROJID_HEAD=`config_read $CONFIG_FILE Proj`
ALL_PROJIDS=`FIND_VALUES_FOR_HEADER $PROJID_HEAD $KEY_FILE | sort | uniq`


echo "NUM_MET_FILES:"	$NUM_MET_FILES
echo "NUM_COUNT_FILES:"	$NUM_COUNT_FILES
echo "NUM_CG_PAIRS:"	$NUM_CG_PAIRS
echo "ALL_PROJIDS:"		$ALL_PROJIDS

	
### run metric-key join script 
echo "Running "$JOIN_SCRIPT" to combine metrics and key files"
echo "sh $JOIN_SCRIPT $MOC_ID $SCRIPT_OPTIONS"
sh $JOIN_SCRIPT $MOC_ID $SCRIPT_OPTIONS

### test keymet file to ensure data has been generated for all samples
for PROJ_ID in $ALL_PROJIDS
do
	MET_FILE=`ls -lrt $RESULTS_DIR"/"$PROJ_ID"/"*"metrics.txt" | awk '{print $9}'`	
	JOIN_FILE=$JOIN_PATH"/"$MOC_ID"/"$PROJ_ID"_KeyMetrics.txt"
	echo "JOIN_FILE: $JOIN_FILE"
	ALL_FIELDS=`FIELD_HEADER $JOIN_FILE Sample_ID Pcnt_bc_in_pool Total_reads pcnt_aligned CDS_total_counts_for_replicon rRNA_pcnt_of_counted | tr '\n' ','`
	TEMP_FILE=$TEMP_DIR$MOC_ID"_"$PROJ_ID"_temp.txt"
	
	echo "Results directory: $RESULTS_DIR"/"$PROJ_ID"/"" > $TEMP_FILE
	echo "" >> $TEMP_FILE

	echo "Running report script..."
	echo "sh $REPORT_SCRIPT $@"
	echo "" >> $TEMP_FILE
	echo "sh $REPORT_SCRIPT $@" >> $TEMP_FILE
	echo "" >> $TEMP_FILE
	sh $REPORT_SCRIPT $@  | grep -v "Dropping" | grep -v "Prepending"  >> $TEMP_FILE
	echo "" >> $TEMP_FILE

	cat $JOIN_FILE | sed '/^$/d' | awk -F"\t" -v ALL_FIELDS=$ALL_FIELDS '{
														y=split(ALL_FIELDS,ar,",")
														for(i=1; i < y; i++)
														{
															if(i == 1)
																printf"%-25s\t", $(ar[i])
															else
																printf"%-10s\t", $(ar[i])
														}
														print ""
											
												}' | awk '{
																if(NF == 6) 
																{
																	for(i=1; i < NF; i++)
																		printf"%-10s\t", $i
																	print $NF
																
																}	
																else 
																{
																	for(i=1; i < NF+1; i++)
																		printf"%-10s\t", $i
																	print "*********DATA missing!***********"

																}
															}'  | sed 's/CDS_total_counts_for_replicon/total_CDS/g' | sort -k5n >> $TEMP_FILE
											
											
	MET_CHECK=`echo $TEMP_FILE	| awk '{print NF}' | sort | uniq | wc -l`
	echo $MET_CHECK	
	
	### Running keymetrics_analysis2.py
	echo "Running "$KMA_SCRIPT" for "$JOIN_FILE
	echo "python $KMA_SCRIPT $JOIN_FILE --outdir $RESULTS_DIR"
	python $KMA_SCRIPT $JOIN_FILE --outdir $RESULTS_DIR



	if [ $TRIMMOMATIC_SAMPLE == "Y" ]; then
		# JOIN_FILE_WITH_TRIMMOMATIC="${JOIN_FILE/.txt/_with_trimmomatic.txt}"
		JOIN_FILE_WITH_TRIMMOMATIC=$JOIN_FILE

		echo "Combining Trimmomatic stats file with key metrics file"

		echo "python $JOIN_KEY_METRICS_WITH_TRIMMOMATIC_SCRIPT --sample_metrics_file $JOIN_FILE --sample_trimmomatic_stats_dir $TRIMMOMATIC_SAMPLE_LOG_DIR --outfile $JOIN_FILE_WITH_TRIMMOMATIC"
		python $JOIN_KEY_METRICS_WITH_TRIMMOMATIC_SCRIPT --sample_metrics_file $JOIN_FILE --sample_trimmomatic_stats_dir $TRIMMOMATIC_SAMPLE_LOG_DIR --outfile $JOIN_FILE_WITH_TRIMMOMATIC
	
		JOIN_FILE=$JOIN_FILE_WITH_TRIMMOMATIC
	fi

### send email with metrics attachment for each project alerting that analysis is complete
	export TMPDIR=$TEMP_DIR
	
	cat $TEMP_FILE							
	cat $TEMP_FILE |  mailx -a $JOIN_FILE -s "Analysis of $MOC_ID $PROJ_ID is done" $USID"@broadinstitute.org"

	### Generating pool-wise metrics from sample metrics file
	POOLWISE_OUT_FILE="${JOIN_FILE/.txt/_poolwise.csv}"

	echo "python $POOLWISE_METRICS_SCRIPT --sample_metrics_file $JOIN_FILE --outfile $POOLWISE_OUT_FILE"
	python $POOLWISE_METRICS_SCRIPT --sample_metrics_file $JOIN_FILE --outfile $POOLWISE_OUT_FILE

	echo "Poolwise metrics generated: $POOLWISE_OUT_FILE" 

	cat $POOLWISE_OUT_FILE | mailx -a $POOLWISE_OUT_FILE -s "Pool-wise metrics of $MOC_ID $PROJ_ID is done" $USID"@broadinstitute.org"

done

 

if [ $NUM_CG_PAIRS -gt 0 ];then
	### run DE pipeline
	echo "Running "$DE_PIPE" to generate edgeR and DESeq2 comparisons"
	echo "sh $DE_PIPE $MOC_ID $SCRIPT_OPTIONS -move_key N"
	sh $DE_PIPE $MOC_ID $SCRIPT_OPTIONS -move_key N
fi

cp -R $DATA_DIR $RESULTS_DIR



### change permissions for Results and temp dirs
change_perms $MOC_SYM_DIR $RESULTS_DIR $TEMP_DIR $KEY_FILE $BAM_DIR



