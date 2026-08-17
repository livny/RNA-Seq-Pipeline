#!/bin/sh

path_suff ()
{
	USER_ID=`extract_option -user_id N 1 $@`
	MOCID_PATH=`extract_option -moc_id Y 1 $@`

	USID=`USID`
	MOC_ID=$1
	shift 

	RESPATH_SUFF=""

	if [ $USER_ID == "Y" ];then
		RESPATH_SUFF=$RESPATH_SUFF"/"$USID"/"
	fi
	if [ $USER_ID != "Y" ] && [ $USER_ID != "N" ];then
		RESPATH_SUFF=$RESPATH_SUFF"/"$USER_ID"/"
	fi

	if [ $MOCID_PATH == "Y" ];then
		RESPATH_SUFF=$RESPATH_SUFF"/"$MOC_ID"/"
	fi
	
	echo $RESPATH_SUFF
}

paths_and_headers ()
{
	# get path of the current file. if the file path is relative, convert it to absolute path
	file_path="${BASH_SOURCE[0]}"
	if [[ $file_path != /* ]]; then
		file_path="$PWD/${BASH_SOURCE[0]}"
	fi

	# get root path of the project
	PROJECT_ROOT_DIR="$(dirname $(dirname $(dirname $(dirname $(dirname $file_path)))))"

	MOC_ID=$1
	shift	

	### source all functions 
	# source "/idi/moc_ec//MOC/scripts/MOC_functions.sh"
	source $file_path

	### set path to config file
	# -conf: sets path to config file (default idi/moc_ec/MOC/config_files/PC_config.yaml)
	# CONFIG_FILE=`extract_option -conf "/idi/moc_ec/MOC/config_files/PC_config.yaml" 1 $@`
	DEFAULT_CONFIG_PATH="$(dirname $(dirname $file_path))"/config_files/PC_config.yaml
	CONFIG_FILE=`extract_option -conf $DEFAULT_CONFIG_PATH 1 $@`
	SCRIPT_OPTIONS=$@
	USID=`USID`

	#### set path append for user_id

	######
	
	PROJ_TYPE=`project_type $MOC_ID`

	if [ $MOC_ID != "none" ];then
		path_suff $@ "-moc_id "$MOC_ID_OPT
	fi
		
	### set paths to directories, files, and scripts from config file

	KEY_DIR=`config_read $CONFIG_FILE Key_base`
	BAM_PATH=`config_read $CONFIG_FILE Bam_path`
	RESULTS_PATH=`config_read $CONFIG_FILE Results_path`
	TEMP_PATH=`config_read $CONFIG_FILE Temp_path`
	SEQ_PATH=`config_read $CONFIG_FILE Seq_base`
	GUIDE_DIR=`config_read $CONFIG_FILE guide_dir`
	INDXSPLIT_PATH=`config_read $CONFIG_FILE IndSplit_path`
	ALN_DIR=`config_read $CONFIG_FILE Align_path`
	REF_PATH=`config_read $CONFIG_FILE Bacterial_Ref_path`
	GB_REF_PATH=`config_read $CONFIG_FILE genbank_ref_path`
	RAWSYM_PATH=`config_read $CONFIG_FILE RawSeq_sym_path`
	WU_PATH=`config_read $CONFIG_FILE Walkup_path`

	MOC_SCRIPT_PATH=`config_read $CONFIG_FILE MOC_script_path`
	if [[ $MOC_SCRIPT_PATH != /* ]]; then
		MOC_SCRIPT_PATH="$PROJECT_ROOT_DIR/$MOC_SCRIPT_PATH"
	fi

	UGER_CBP_PATH=`config_read $CONFIG_FILE UGER_cbp`
	if [[ $UGER_CBP_PATH != /* ]]; then
		UGER_CBP_PATH="$PROJECT_ROOT_DIR/$UGER_CBP_PATH"
	fi

	TRIMMOMATIC_JAR=`config_read $CONFIG_FILE trimmomatic_jar`
	if [[ $TRIMMOMATIC_JAR != /* ]]; then
		TRIMMOMATIC_JAR="$PROJECT_ROOT_DIR/$TRIMMOMATIC_JAR"
	fi

	TRIMMOMATIC_STATS_SCRIPT=`config_read $CONFIG_FILE trimmomatic_stats_script`
	if [[ $TRIMMOMATIC_STATS_SCRIPT != /* ]]; then
		TRIMMOMATIC_STATS_SCRIPT="$PROJECT_ROOT_DIR/$TRIMMOMATIC_STATS_SCRIPT"
	fi

	READ_INSERTION_ADAPTER_ANALYSIS_SCRIPT=`config_read $CONFIG_FILE read_insertion_adapter_analysis_script`
	if [[ $READ_INSERTION_ADAPTER_ANALYSIS_SCRIPT != /* ]]; then
		READ_INSERTION_ADAPTER_ANALYSIS_SCRIPT="$PROJECT_ROOT_DIR/$READ_INSERTION_ADAPTER_ANALYSIS_SCRIPT"
	fi

	### set path to key file 

	KEY_FILE=$KEY_DIR$MOC_ID"_key.txt"

	### identify LC method from config file and get the corresponding dict
	LC_method=`FIELD_CONFIG_HEADER_VALUE $KEY_FILE $CONFIG_FILE  "LC_method" `
	echo "LC_method: $LC_method"
	if [[ ${LC_method,,} == *'rts'* ]]; then
		echo "LC_method in the key file (first valid row) contains RtS"
		BC_FILE=`config_read $CONFIG_FILE RtS_dict_file`
		TRIMMOMATIC_ADAPTER_FILE=`config_read $CONFIG_FILE rts_trimmomatic_adapter_file`
		ADAPTER_ANALYSIS_ADAPTER_FILE=`config_read $CONFIG_FILE rts_adapter_analysis_adapter_file`
	elif [[ ${LC_method,,} == *'scr'* ]]; then
		echo  "LC_method in the key file (first valid row) contains SCR"
		BC_FILE=`config_read $CONFIG_FILE SCR_dict_file`
		TRIMMOMATIC_ADAPTER_FILE=`config_read $CONFIG_FILE scr_trimmomatic_adapter_file`
		ADAPTER_ANALYSIS_ADAPTER_FILE=`config_read $CONFIG_FILE scr_adapter_analysis_adapter_file`
	else
		echo "Error: LC_method in the key file (first valid row) neither contains RtS nor SCR"
		echo "LC_method: $LC_method"
	fi

	if [[ $BC_FILE != /* ]]; then
		BC_FILE="$PROJECT_ROOT_DIR/$BC_FILE"
	fi

	if [[ $TRIMMOMATIC_ADAPTER_FILE != /* ]]; then
		TRIMMOMATIC_ADAPTER_FILE="$PROJECT_ROOT_DIR/$TRIMMOMATIC_ADAPTER_FILE"
	fi

	if [[ $ADAPTER_ANALYSIS_ADAPTER_FILE != /* ]]; then
		ADAPTER_ANALYSIS_ADAPTER_FILE="$PROJECT_ROOT_DIR/$ADAPTER_ANALYSIS_ADAPTER_FILE"
	fi

	JOIN_PATH=`config_read $CONFIG_FILE join_path`
	JOIN_PATH=$JOIN_PATH"/"$RESPATH_SUFF"/"

	INDEX1_BARCODES=`config_read $CONFIG_FILE P7_barcodes`
	if [[ $INDEX1_BARCODES != /* ]]; then
		INDEX1_BARCODES="$PROJECT_ROOT_DIR/$INDEX1_BARCODES"
	fi

	DB_SCRIPT=`config_read $CONFIG_FILE DB_script`
	if [[ $DB_SCRIPT != /* ]]; then
		DB_SCRIPT="$PROJECT_ROOT_DIR/$DB_SCRIPT"
	fi

	PIPE_SCRIPT=`config_read $CONFIG_FILE pipeline`
	if [[ $PIPE_SCRIPT != /* ]]; then
		PIPE_SCRIPT="$PROJECT_ROOT_DIR/$PIPE_SCRIPT"	
	fi

	REPORT_SCRIPT=`config_read $CONFIG_FILE report_script`
	if [[ $REPORT_SCRIPT != /* ]]; then
		REPORT_SCRIPT="$PROJECT_ROOT_DIR/$REPORT_SCRIPT"	
	fi

	QSUB_SCRIPT=`config_read $CONFIG_FILE qsub_script`
	if [[ $QSUB_SCRIPT != /* ]]; then
		QSUB_SCRIPT="$PROJECT_ROOT_DIR/$QSUB_SCRIPT"
	fi

	KEY_SCRIPT=`config_read $CONFIG_FILE keyfile_importer`
	if [[ $KEY_SCRIPT != /* ]]; then
		KEY_SCRIPT="$PROJECT_ROOT_DIR/$KEY_SCRIPT"
	fi

	JOIN_SCRIPT=`config_read $CONFIG_FILE join_script`
	if [[ $JOIN_SCRIPT != /* ]]; then
		JOIN_SCRIPT="$PROJECT_ROOT_DIR/$JOIN_SCRIPT"
	fi
	
	POOLWISE_METRICS_SCRIPT=`config_read $CONFIG_FILE poolwise_metrics_script`
	if [[ $POOLWISE_METRICS_SCRIPT != /* ]]; then
		POOLWISE_METRICS_SCRIPT="$PROJECT_ROOT_DIR/$POOLWISE_METRICS_SCRIPT"
	fi

	ADD_UMI_TO_READ_ID_SCRIPT=`config_read $CONFIG_FILE add_umi_to_read_id_script`
	if [[ $ADD_UMI_TO_READ_ID_SCRIPT != /* ]]; then
		ADD_UMI_TO_READ_ID_SCRIPT="$PROJECT_ROOT_DIR/$ADD_UMI_TO_READ_ID_SCRIPT"
	fi

	JOIN_KEY_METRICS_WITH_TRIMMOMATIC_SCRIPT=`config_read $CONFIG_FILE join_key_metrics_with_trimmomatic_script`
	if [[ $JOIN_KEY_METRICS_WITH_TRIMMOMATIC_SCRIPT != /* ]]; then
		JOIN_KEY_METRICS_WITH_TRIMMOMATIC_SCRIPT="$PROJECT_ROOT_DIR/$JOIN_KEY_METRICS_WITH_TRIMMOMATIC_SCRIPT"
	fi

	GSIMPORT_SCRIPT=`config_read $CONFIG_FILE gs_importer`
	if [[ $GSIMPORT_SCRIPT != /* ]]; then
		GSIMPORT_SCRIPT="$PROJECT_ROOT_DIR/$GSIMPORT_SCRIPT"
	fi

	WU_MOVESPLIT=`config_read $CONFIG_FILE wu_movesplit`
	if [[ $WU_MOVESPLIT != /* ]]; then
		WU_MOVESPLIT="$PROJECT_ROOT_DIR/$WU_MOVESPLIT"
	fi

	DE_PIPE=`config_read $CONFIG_FILE DE_pipe`
	if [[ $DE_PIPE != /* ]]; then
		DE_PIPE="$PROJECT_ROOT_DIR/$DE_PIPE"
	fi

	DICT_BUILD=`config_read $CONFIG_FILE dict_builder`
	if [[ $DICT_BUILD != /* ]]; then
		DICT_BUILD="$PROJECT_ROOT_DIR/$DICT_BUILD"
	fi

	CHECKSUM_SCRIPT=`config_read $CONFIG_FILE Checksum_script`
	if [[ $CHECKSUM_SCRIPT != /* ]]; then
		CHECKSUM_SCRIPT="$PROJECT_ROOT_DIR/$CHECKSUM_SCRIPT"
	fi

	SPLITMET_SCRIPT=`config_read $CONFIG_FILE split_metrics_script`
	if [[ $SPLITMET_SCRIPT != /* ]]; then
		SPLITMET_SCRIPT="$PROJECT_ROOT_DIR/$SPLITMET_SCRIPT"
	fi

	REF_MOVE_SCRIPT=`config_read $CONFIG_FILE ref_move_parse_script`
	if [[ $REF_MOVE_SCRIPT != /* ]]; then
		REF_MOVE_SCRIPT="$PROJECT_ROOT_DIR/$REF_MOVE_SCRIPT"
	fi

	GFFPARSE_SCRIPT=`config_read $CONFIG_FILE gff_parse_script`
	if [[ $GFFPARSE_SCRIPT != /* ]]; then
		GFFPARSE_SCRIPT="$PROJECT_ROOT_DIR/$GFFPARSE_SCRIPT"
	fi

	### set paths to directories, files, and scripts from config file

	P7_BARCODES=`config_read $CONFIG_FILE P7_barcodes`
	if [[ $P7_BARCODES != /* ]]; then
		P7_BARCODES="$PROJECT_ROOT_DIR/$P7_BARCODES"
	fi

	P5_BARCODES=`config_read $CONFIG_FILE P5_barcodes`
	if [[ $P5_BARCODES != /* ]]; then
		P5_BARCODES="$PROJECT_ROOT_DIR/$P5_BARCODES"
	fi

	SINGLE_INDEX_SCRIPT=`config_read $CONFIG_FILE Single_Index_split_script`
	if [[ $SINGLE_INDEX_SCRIPT != /* ]]; then
		SINGLE_INDEX_SCRIPT="$PROJECT_ROOT_DIR/$SINGLE_INDEX_SCRIPT"
	fi

	DUAL_INDEX_SCRIPT=`config_read $CONFIG_FILE Dual_Index_split_script`
	if [[ $DUAL_INDEX_SCRIPT != /* ]]; then
		DUAL_INDEX_SCRIPT="$PROJECT_ROOT_DIR/$DUAL_INDEX_SCRIPT"
	fi
 
	WU_SCRIPT=`config_read $CONFIG_FILE wu_metrics_script`
	if [[ $WU_SCRIPT != /* ]]; then
		WU_SCRIPT="$PROJECT_ROOT_DIR/$WU_SCRIPT"
	fi

	WBMOV_SCRIPT=`config_read $CONFIG_FILE wbmov_metrics_script`
	if [[ $WBMOV_SCRIPT != /* ]]; then
		WBMOV_SCRIPT="$PROJECT_ROOT_DIR/$WBMOV_SCRIPT"
	fi

	CHECK_MOD_SCRIPT=`config_read $CONFIG_FILE check_module_script`
	if [[ $CHECK_MOD_SCRIPT != /* ]]; then
		CHECK_MOD_SCRIPT="$PROJECT_ROOT_DIR/$CHECK_MOD_SCRIPT"
	fi

	BASH_HEADER=`config_read $CONFIG_FILE bash_header`
	if [[ $BASH_HEADER != /* ]]; then
		BASH_HEADER="$PROJECT_ROOT_DIR/$BASH_HEADER"
	fi

	FASTQ_TRIM_SCRIPT=`config_read $CONFIG_FILE fastq_trimmer`
	if [[ $FASTQ_TRIM_SCRIPT != /* ]]; then
		FASTQ_TRIM_SCRIPT="$PROJECT_ROOT_DIR/$FASTQ_TRIM_SCRIPT"
	fi

	
	### set options for pipeline
	# -split: split fastqs by inline (default Y, O --> only split)
	# -merge: merge fastqs for each sample (default Y, O --> only merge)
	# -align: align merged fastqs to reference (default Y, O --> only align)
	# -count: count reads per gene (default Y, O --> only count)
	# -q: sets name of header for Q_VAL (default MOC_ID)
	# -move_key: setting to N skips moving google sheet to server (default Y)
	# -use_p7: indicates fastq file is not demultiplexed by P7 index (default Y)
	# -use_p5: indicates fastq file is not demultiplexed by P5 index (default N)
	# -no_pipe: including or setting to Y skips running pipeline (default N)
	# -qsub: run pipeline in UGER (default N)
	# -gid: enter google ID if missing from DB (default 0 => get it from DB)
	# -smocid: enter smocid if missing from DB (default 0 => get it from DB)
	# -import_gs: updates DBs from google drive on server (default N)
	# -user_id: add userID to temp and results paths (default N.  If Y, add login name, if value added after option that userID will be added)
	# -moc_id: add MOC_ID to temp and results paths (default Y)
	# -move_ref: move references from gdrive to moc dir in $REF_PATH (default Y)
	# -parse_ref: parse refs in $REF_PATH (default N)
	# -symlink: set path to directory named $SMOC_ID containing symlinks to raw data (default $RAWSYM_PATH from config)
	# -raw_seq_path: set path to directory $SMOC_ID containing raw data (default $SEQ_PATH from config)

	SPLIT=`extract_option -split Y 1 $SCRIPT_OPTIONS`
	MERGE=`extract_option -merge Y 1 $SCRIPT_OPTIONS`
	ALIGN=`extract_option -align Y 1 $SCRIPT_OPTIONS`
	COUNT=`extract_option -count Y 1 $SCRIPT_OPTIONS`
	USER=`extract_option -u N 1 $SCRIPT_OPTIONS`
	Q_HEAD=`extract_option -q MOC_ID 1 $SCRIPT_OPTIONS`
	MOVE_KEY=`extract_option -move_key Y 1 $SCRIPT_OPTIONS`
	USE_P7=`extract_option -use_p7 Y 1 $SCRIPT_OPTIONS`
	USE_P5=`extract_option -use_p5 N 1 $SCRIPT_OPTIONS`
	NO_PIPE=`extract_option -no_pipe N 1 $SCRIPT_OPTIONS`
	QSUB=`extract_option -qsub N 1 $SCRIPT_OPTIONS`
	GID_OPT=`extract_option -gid 0 1 $SCRIPT_OPTIONS`
	SMOCID_OPT=`extract_option -smocid 0 1 $SCRIPT_OPTIONS`
	IMPORT_GS=`extract_option -import_gs N 1 $SCRIPT_OPTIONS`
	USER_ID=`extract_option -user_id N 1 $SCRIPT_OPTIONS`
	MOC_ID_OPT=`extract_option -moc_id Y 1 $SCRIPT_OPTIONS`
	REFMOVE_OPT=`extract_option -move_ref Y 1 $SCRIPT_OPTIONS`
	PARSE_REF=`extract_option -parse_ref Y 1 $SCRIPT_OPTIONS`
	PSSWD=`extract_option -p N 1 $SCRIPT_OPTIONS`
	MOVE_DATA=`extract_option -move_data Y 1 $SCRIPT_OPTIONS`
	INDEX1_SPLIT=`extract_option -index1_split N 1 $SCRIPT_OPTIONS`
	INDEX2_SPLIT=`extract_option -index2_split N 1 $SCRIPT_OPTIONS`
	METRICS=`extract_option -metrics Y 1 $SCRIPT_OPTIONS`
	KEY_SHEET=`extract_option -key_sheet "Sample_Information" 1 $SCRIPT_OPTIONS | sed 's/Sample_Information/Sample Information/g'`
	KEY_TYPE=`extract_option -key_type P 1 $SCRIPT_OPTIONS`
	TEST_PIPE=`extract_option -test_pipe N 1 $SCRIPT_OPTIONS`
	NUM_TEST_READS=`extract_option -num_test_reads 10000 1 $SCRIPT_OPTIONS`
	TRIM_READS=`extract_option -trim_reads N 1 $SCRIPT_OPTIONS` # pre-trim reads
	TRIM_LEN=`extract_option -trim_len 0-50,5-55 1 $SCRIPT_OPTIONS` # target trim length
	DO_HOST=`extract_option -do_host N 1 $SCRIPT_OPTIONS`
	ADD_UMI_TO_READ_ID=`extract_option -add_umi_to_read_id N 1 $SCRIPT_OPTIONS`
	TRIM_MINLEN=`extract_option -trim_minlen 25 1 $SCRIPT_OPTIONS` # minimum length of read to keep after trimming/alignment
	WB_MOVE=`extract_option -wb_move Y 1 $SCRIPT_OPTIONS`
	CDS_ADD5=`extract_option -cds_add5 20 1 $SCRIPT_OPTIONS`
	CDS_ADD3=`extract_option -cds_add3 30 1 $SCRIPT_OPTIONS`
 	GENE_ADD5=`extract_option -gene_add5 0 1 $SCRIPT_OPTIONS`
	GENE_ADD3=`extract_option -gene_add3 0 1 $SCRIPT_OPTIONS`

	### set field numbers for various headers
	SID_COL=`FIELD_CONFIG_HEADER $KEY_FILE $CONFIG_FILE  "ID" `

	### set module options if one is set to "O"
	
	if [ $SPLIT == "O" ];then
		MERGE="N"
		ALIGN="N"
		COUNT="N"
	fi
	if [ $MERGE == "O" ] || [ $MERGE == "R" ];then
		
		SPLIT="N"
		if [ $MERGE == "O" ];then
			ALIGN="N"
			COUNT="N"
		fi
	fi
	if [ $ALIGN == "O" ] || [ $ALIGN == "R" ];then
		SPLIT="N"
		MERGE="N"
		if [ $ALIGN == "O" ];then
			COUNT="N"
		fi
	fi
	if [ $COUNT == "O" ] || [ $COUNT == "R" ];then
		SPLIT="N"
		MERGE="N"
		ALIGN="N"
	fi

	### set options to override paths in config file

	RAWSYM_PATH=`extract_option -symlink $RAWSYM_PATH 1 $SCRIPT_OPTIONS`
	SEQ_PATH=`extract_option -raw_seq_path $SEQ_PATH 1 $SCRIPT_OPTIONS`
	WU_PATH=`extract_option -wu_path $WU_PATH 1 $SCRIPT_OPTIONS`
	REF_PATH=`extract_option -ref_path $REF_PATH 1 $SCRIPT_OPTIONS`
	ALN_DIR=`extract_option -aln_dir $ALN_DIR 1 $SCRIPT_OPTIONS`

	
	
	#### find all project IDs
	
	ALL_PROJ=`cat $KEY_FILE | grep -v "###" | grep -v "COLLAB" | sed 1d | awk '{print $2}' | sort | uniq`
	echo $ALL_PROJ
	ALL_PROJID=`echo $ALL_PROJ | sed 's/ /_/g' `
	
	### set paths to all pipeline output directories
	
	TEMP_DIR=$TEMP_PATH"/"$RESPATH_SUFF"/"$ALL_PROJID"/"
	MERGE_DIR=$TEMP_DIR"mergedir/"
	MERGE_TRIM_DIR=$TEMP_DIR"mergedir/trimmed"
	SPLIT_DIR=$TEMP_DIR"splitdir/"
	DATA_DIR=$TEMP_DIR"datadir/"
	ALIGN_DIR=$TEMP_DIR"patho_result/"$ALL_PROJID"/"
	RESULTS_DIR=$RESULTS_PATH"/"$RESPATH_SUFF"/"
	BAM_DIR=$BAM_PATH"/"$RESPATH_SUFF"/"
	MOC_SYM_DIR=$RAWSYM_PATH"/"$MOC_ID
	MOC_SYM_TEST_DIR=$TEMP_DIR"/pipe_test/"
	MOC_SYM_TEST_UMI_DIR=$TEMP_DIR"/pipe_test_umi/"
	MOC_SYM_TRIM_DIR=$TEMP_DIR"/trimmed_reads/"

	SPLIT_DIR=`extract_option -split_dir $SPLIT_DIR 1 $@`
	MERGE_DIR=`extract_option -merge_dir $MERGE_DIR 1 $@`
	DATA_DIR=`extract_option -data_dir $DATA_DIR 1 $@`
	ALIGN_DIR=`extract_option -align_dir $ALIGN_DIR 1 $@`

	### set paths, GIDs to DB files

	SP_GID="140LlqfQEzOJjbM9dSJOMTc7Ylf_QdLwPT5iMXtbYbzA"
	DB_GID="13_dq9WcPHzxqYc8BN37N8ociXk7_5R7ob9GKXi2rJ38"
	PC_GID="1tF0Cc6CwbT_bS3JLKIFGA3oPK9IBqjilyu3gtgmYDas"
    BCS_GID="138QVw4Bf2Dkbb6bk19E323wZ1o2wA7JCRyHYVLfOw98"
    MOCS_GID="1WC8s_Y6uMbOCXNCQMIBWxBxglHOIo0HHlH5G51U7e1U"

	#idi/moc_ec//MOC/scripts/MOC_functions.sh
	# SCRIPTS_DIR="/idi/moc_ec/MOC/scripts/"
	SCRIPTS_DIR="$(dirname $file_path)"
	MOC_DIR="$(dirname $(dirname $file_path))"

	# SUB_DIR="/idi/moc_ec/MOC/SubmissionLogs/"
	SUB_DIR="$MOC_DIR/SubmissionLogs/"
	SUB_SUFF="_RtSSubLog.txt"

	# POOL_DIR="/idi/moc_ec/MOC/PoolLogs/"
	POOL_DIR="$MOC_DIR/PoolLogs/"
	POOL_SUFF="_RtSPoolLog.txt"

	# MOCDB_DIR="/idi/moc_ec/MOC/MOC_DB/"
	MOCDB_DIR="$MOC_DIR/MOC_DB/"
	MOCDB_SUFF="_MOC_DB.txt"
	
	# PCDB_DIR="/idi/moc_ec/MOC/PC_DB/"
	PCDB_DIR="$MOC_DIR/PC_DB/"
	PCDB_SUFF="_PC_DB.txt"

	# PCQ_DIR="/idi/moc_ec/MOC/PCQ_DB/"
	PCQ_DIR="$MOC_DIR/PCQ_DB/"
	PCQ_SUFF="_PCQ_DB.txt"

	# RTSDB_DIR="/idi/moc_ec/MOC/RTS_DB/"
	RTSDB_DIR="$MOC_DIR/RTS_DB/"
	RTSDB_SUFF="_RTS_DB.txt"
	
	# MOCSDB_DIR="/idi/moc_ec/MOC/MOCS_DB/"
	MOCSDB_DIR="$MOC_DIR/MOCS_DB/"
	MOCSDB_SUFF="_MOCS_DB.txt"
	MOCS_DB=$MOCSDB_DIR"/MOCS_DB.txt"
	
	# BCSDB_DIR="/idi/moc_ec/MOC/BCS_DB/"
	BCSDB_DIR="$MOC_DIR/BCS_DB/"
	BCS_FILE_NAME="BCS_DB."
	BCS_FILE_SUFF="txt"
	BCS_FILE=$BCSDB_DIR"/"$BCS_FILE_NAME$BCS_FILE_SUFF

}

###############  function for Pulling out paths, header names from config file ###############

config_read ()
{
	CONFIG_FILE=$1
	VAR_NAME=$2
	
	cat $CONFIG_FILE | grep $VAR_NAME":" | awk '{print $2}'
}

read_config ()
{

	CONFIG_FILE=$1

	# get path of the current file. if the file path is relative, convert it to absolute path
	file_path="${BASH_SOURCE[0]}"
	if [[ $file_path != /* ]]; then
		file_path="$PWD/${BASH_SOURCE[0]}"
	fi

	# get root path of the project
	PROJECT_ROOT_DIR="$(dirname $(dirname $(dirname $(dirname $(dirname $file_path)))))"

	KEY_DIR=`config_read $CONFIG_FILE Key_base`
	RESULTS_PATH=`config_read $CONFIG_FILE Results_path`
	TEMP_PATH=`config_read $CONFIG_FILE Temp_path`
	SEQ_PATH=`config_read $CONFIG_FILE Seq_base`
	GUIDE_DIR=`config_read $CONFIG_FILE guide_dir`
	INDXSPLIT_PATH=`config_read $CONFIG_FILE IndSplit_path`

	EDGER_SCRIPT=`config_read $CONFIG_FILE edgeR_script`
	if [[ $EDGER_SCRIPT != /* ]]; then
		EDGER_SCRIPT="$PROJECT_ROOT_DIR/$EDGER_SCRIPT"
	fi

	DESEQ_SCRIPT=`config_read $CONFIG_FILE deseq_script`
	if [[ $DESEQ_SCRIPT != /* ]]; then
		DESEQ_SCRIPT="$PROJECT_ROOT_DIR/$DESEQ_SCRIPT"
	fi

	CGID_NAME=`config_read $CONFIG_FILE CGID_NAME`
	RtS_ANPIPE=`config_read $CONFIG_FILE RtS_analysis_pipe`
	if [[ $RtS_ANPIPE != /* ]]; then
		RtS_ANPIPE="$PROJECT_ROOT_DIR/$RtS_ANPIPE"
	fi

}

###############  function for extracting options ###############

# Extracting options from the command line
extract_option () 
{
	option_name=$1
	shift
	default=$1
	shift 
	max=$1
	shift 

	typeset -i num
	num=`echo $@ | wc -w`
	if [ $num -eq 0 ];then

		echo $default
		exit
	
	fi

	echo $@ | awk -v def=$default -v name=$option_name -v flag="N" '{

		for(i=1; i < NF+1; i++)
		{
			# if option is found
			if($i==name)
			{
				flag="Y"
				y=substr($(i+1),1,1) 
				## if next option encountered or option last argument, print Y and exit
				if(y=="-" || y==":" || i==NF)
					print "Y"
				## otherwise print value after option
				else	
					print $(i+1)
			}
			
			# if option not found, print def
			if(flag=="N" && i==NF)
				print def
	
		}

	}' | tail -$max
}

#################   Finding field #'s using values from config  ##################

FIELD_CONFIG_HEADER ()
{
	KEY=$1
	shift
	CONFIG=$1
	shift
	ALL_HEADER_NAME=$@


	for CONFIG_NAME in $ALL_HEADER_NAME
	do
		HEADER_NAME=`config_read $CONFIG_FILE $CONFIG_NAME`
		
		KEY_HEADER=`cat $KEY | grep -v "###" | head -1 | awk -F"\t" -v HEADER_NAME=$HEADER_NAME '{	
																for(i=1; i < NF+1; i++)															
																	if($i==HEADER_NAME)
																	{	
																		print i
																		exit
																	}
																print "NOT FOUND"
															}'`
	
	
		echo $KEY_HEADER
		>&2 echo $CONFIG_NAME ":" $HEADER_NAME ":" $KEY_HEADER
	done
}

#################   Finding field header values using values from config  ##################
#################   Only works when the field header value is consistent across the entire key file (i.e.) same value in all rows

FIELD_CONFIG_HEADER_VALUE ()
{
	KEY=$1
	shift
	CONFIG=$1
	shift
	ALL_HEADER_NAME=$@


	for CONFIG_NAME in $ALL_HEADER_NAME
	do
		HEADER_NAME=`config_read $CONFIG_FILE $CONFIG_NAME`
		
		KEY_HEADER=`cat $KEY | grep -v "###" | head -1 | awk -F"\t" -v HEADER_NAME=$HEADER_NAME '{	
																for(i=1; i < NF+1; i++)															
																	if($i==HEADER_NAME)
																	{	
																		print i
																		exit
																	}
																print "NOT FOUND"
															}'`
													
	
		KEY_HEADER_VALUE=`cat $KEY | grep -v "###" | head -2 | tail -1 | awk -F"\t" -v KEY_HEADER=$KEY_HEADER '{ print $KEY_HEADER }'` 

		echo $KEY_HEADER_VALUE
		>&2 echo $CONFIG_NAME ":" $HEADER_NAME ":" $KEY_HEADER ":" $KEY_HEADER_VALUE
	done
}


#################   Finding field #'s using field headers   ##################

FIELD_HEADER ()
{
	FILE=$1
	shift
	ALL_HEADER_NAME=$@

	for HEADER_NAME in $ALL_HEADER_NAME
	do
		cat $FILE | grep -v "###" | grep -v "COLLABORATOR" | head -1 | tr '\r' '\n' | awk -F"\t" -v HEADER_NAME=$HEADER_NAME '{	
																for(i=1; i < NF+1; i++)															
																	if($i==HEADER_NAME)
																		print i
															}' 
	done
} 
#################   Finding value in field SIF of entry whose value is GCID in field CGF  ##################

FIND_FIELD ()
{
	
	if [ $# == 2 ];then
		FILE=$1
		SIF=$2
				
				cat $FILE | sed 's/ /_/g' | grep -v "###" | sed 1d  | awk -F"\t" -v SIF=$SIF '{	

															print $SIF
													}' 
	fi 
	if [ $# -ge 4 ];then
		FILE=$1
		shift
		CGF=$1
		shift
		GCID=$1
		shift
		ALL_SIF=$@
		
		for SIF in 	$ALL_SIF
		do
			cat $FILE | sed 's/ /_/g' | grep -v "###" | sed 1d | awk -F"\t" -v GCID=$GCID -v CGF=$CGF -v SIF=$SIF '{	

														if($CGF==GCID)
															printf "%s,", $SIF
													}' | tr ',' '\n' | sort | uniq | tr '\n' ',' | sed 's/,$/\n/g'
		done
	fi


} 

#####

###########################    Find values in column with R_HEAD for entries whose value is Q_VAL in column with header Q_HEAD ##################################
FIND_HEADER_AND_FIELD ()
{
	###########################   FIELD_HEADER  ##################################

	FIELD_HEADER ()
	{

		FILE=$1
		Q_HEAD=$2

		cat $FILE | sed '/^$/d' | grep -v "COLLAB" | awk '{if($1 !~ /#/) print $0}' | head -1 | sed 's/ /_/g' | awk -F"\t" -v Q_HEAD=$Q_HEAD '{	
																	for(i=1; i < NF+1; i++)															
																		if($i==Q_HEAD)
																			print i
																}' | tail -1
	}

	
	# Look in FILE, find line in which the value in Q_COL equals Q_VAL and return the values in R_COL 
	
	Q_VAL=$1
	shift
	Q_HEAD=$1
	shift
	R_HEAD=$1
	shift

	for FILE in $@
	do

		Q_COL=`FIELD_HEADER $FILE $Q_HEAD` 
		R_COL=`FIELD_HEADER $FILE $R_HEAD` 
		#echo $Q_COL,$R_COL,$FILE,$QVAL
#		
		cat $FILE | sed '/^$/d' | grep -v "COLLAB" | awk -F"\t" '{if($1 !~ /#/) print $0}' | sed 's/ /_/g' | awk -F"\t" -v Q_COL=$Q_COL -v R_COL=$R_COL -v Q_VAL=$Q_VAL -v RETURN_COL="-" '{	
																			
																			
																			RETURN_COL="-"
																			for(i=1; i < NF+1; i++)
																			{
																				# remove leading whitespace
																				gsub(/^[_\t]+/, "", $i)
																								
																				#print Q_COL_TRIMMED, Q_VAL, $Q_COL,$i
																				if($(Q_COL)==Q_VAL && R_COL != "")
																					RETURN_COL=$R_COL
																			}
																				if(RETURN_COL != "-")
																					print RETURN_COL

	}'	
	done		
														
} 

###########################    Find values in column with Q_HEAD in FILES $@ ##################################
FIND_VALUES_FOR_HEADER ()
{
	
	
	###########################   FIELD_HEADER  ##################################

	FIELD_HEADER ()
	{

		FILE=$1
		Q_HEAD=$2

		cat $FILE | awk -F"\t" '{if($1 !~ /###/) print $0}' | grep -v "COLLAB" | head -1 | sed 's/ /_/g' | awk -F"\t" -v Q_HEAD=$Q_HEAD '{	
																	for(i=1; i < NF+1; i++)															
																		if($i==Q_HEAD)
																			print i
																}' | tail -1
	}

	# Look in FILE, find line in which the value in Q_COL equals Q_VAL and return the values in R_COL 
	
	Q_HEAD=$1
	shift	
	
	for FILE in $@
	do
		
		Q_COL=`FIELD_HEADER $FILE $Q_HEAD` 
		
		if [ -z $Q_COL ];then
			echo $Q_HEAD" not found in "$FILE
			exit
		fi
		cat $FILE | awk '{if($1 !~ /###/) print $0}' | sed -e 's/ /_/g' -e 's/\###//g' | awk -F"\t" -v Q_COL=$Q_COL -v Q_HEAD=$Q_HEAD '{	

																				if($Q_COL != Q_HEAD)
																					print $Q_COL
															}'  
	done		
														
} 

##############################

USID ()
{
	id | cut -d"(" -f2 | cut -d")" -f1
}


############################  SGE_test ###############################

SGE_test ()
{	
	SGE_OUT=$1

	jobs_submit=`cat $SGE_OUT | awk '{if(NF>1)print $3;if(NF==1)print $1}'`
	
	echo "submitted jobs: $jobs_submit"
	typeset -i NUM

	while :
	do
		job_running=`qstat | awk '{if(NR > 2 ) print $1}'`
		ec=$?
		NUM=`echo $job_running $jobs_submit | tr ' ' '\n' | sort | uniq -c | awk '{if($1==2)print $0}' | wc -l`
		#echo $ec $NUM
		
		##if [ $NUM == 0 ];then
		
		if [ $NUM == 0 ] && [ $ec == 0 ];then
			echo "qstat jobs are complete"
			break
		fi
	
	done
}



######## change permissions of all files in directory ###########

change_perms ()
{
	for DIR in $@
	do
		chmod 777 -R $DIR 2>&1 | grep -v "Permission denied"
	done

}

######

project_type ()
{
	if [ $# -gt 0 ];then
		# get path of the current file. if the file path is relative, convert it to absolute path
		file_path="${BASH_SOURCE[0]}"
		if [[ $file_path != /* ]]; then
			file_path="$PWD/${BASH_SOURCE[0]}"
		fi

		MOC_ID=$1
		shift

		### source all functions 
		# source "/idi/moc_ec//MOC/scripts/MOC_functions.sh"
		source "$file_path"

		### set path to config file
		# -conf: sets path to config file (default idi/moc_ec/MOC/config_files/PC_config.yaml)
		# CONFIG_FILE=`extract_option -conf "/idi/moc_ec/MOC/config_files/PC_config.yaml" 1 $@`
		DEFAULT_CONFIG_PATH="$(dirname $(dirname $file_path))"/config_files/PC_config.yaml
		CONFIG_FILE=`extract_option -conf $DEFAULT_CONFIG_PATH 1 $@`
	
		### set prefixes for project types

		PROD_PREFIX=`config_read $CONFIG_FILE Production_prefixes`
		DEV_PREFIX=`config_read $CONFIG_FILE Dev_prefixes`
		TC_PREFIX=`config_read $CONFIG_FILE TC_prefixes`
		CIS_PREFIX=`config_read $CONFIG_FILE CIS_prefixes`

		MOCID_PREFIX=`echo $MOC_ID | cut -d"-" -f1`

		if [ `echo $PROD_PREFIX | grep $MOCID_PREFIX | wc -l` -eq 1 ];then
			PROJ_TYPE="P"
		fi
		if [ `echo $DEV_PREFIX | grep $MOCID_PREFIX | wc -l` -eq 1 ];then
			PROJ_TYPE="D"
		fi
		if [ `echo $TC_PREFIX | grep $MOCID_PREFIX | wc -l` -eq 1 ];then
			PROJ_TYPE="TC"
		fi
		if [ `echo $CIS_PREFIX | grep $MOCID_PREFIX | wc -l` -eq 1 ];then
			PROJ_TYPE="CIS"
		fi
		echo $PROJ_TYPE
	fi
}

all_smocindex_set ()
{
	# get path of the current file. if the file path is relative, convert it to absolute path
	file_path="${BASH_SOURCE[0]}"
	if [[ $file_path != /* ]]; then
		file_path="$PWD/${BASH_SOURCE[0]}"
	fi

	MOC_ID=$1
		

	### source all functions 
	# source "idi/moc_ec/MOC/scripts/MOC_functions.sh"
	source "$file_path"
	
	paths_and_headers $MOC_ID $@

	echo "sh $DB_SCRIPT $Q_HEAD,$MOC_ID -key_only Y Pool_ID"
	ALL_POOLS=`sh $DB_SCRIPT $Q_HEAD,$MOC_ID -key_only Y Pool_ID | sed 1d | sed 's/,/ /g' | awk -F":" '{print $2}' | awk '{for(i=1; i < NF+1; i++)print $i}'`
	ALL_PROJIDS=`sh $DB_SCRIPT $Q_HEAD,$MOC_ID -key_only Y Project_ID | sed 1d | sed 's/,/ /g' | awk -F":" '{print $2}'| awk '{for(i=1; i < NF+1; i++)print $i}'`
	echo "ALL_POOLS:" $ALL_POOLS
	echo "ALL_PROJIDS:" $ALL_PROJIDS
	
	### get sets of SMOCID and INDEX sequences for all pools associated with MOC_ID 
	# if no pool_ids found, pull out all SMOC_ID
	if [ -z "$ALL_POOLS" ];then
		ALL_SMOCINDEX_SETS=`sh $DB_SCRIPT $Q_HEAD,$MOC_ID -key_only Y MOCS_ID | sed 1d | sed 's/,/ /g' | awk -F":" '{print $2}' | awk '{for(i=1; i < NF+1; i++)print $i}' | sed 's/-//g' | tr ' ' '\n' | sort | uniq | tr '\n' ' ' | awk '{print $1";.;;"}'`

	# if pool_ids found, pull out all SMOC_IDs and Indexes
	else

		echo $KEY_FILE

		ALL_SMOCINDEX_SETS=""
		for POOL in $ALL_POOLS
		do
			echo "POOL: "$POOL
			ALL_S=`FIND_HEADER_AND_FIELD $POOL Pool_ID MOCS_ID $KEY_FILE | sort | uniq | sed 's/,/ /g'`
			
			echo "ALL_S:"$ALL_S
			
			for S in $ALL_S
			do
				echo $S
				I1=`FIND_HEADER_AND_FIELD $POOL Pool_ID Index1_seq $KEY_FILE | sort | uniq | awk '{if(NF==1)print $1; if(NF>1) print "MULTIPLE_I1_FOR_"'$POOL'}'`
				I2=`FIND_HEADER_AND_FIELD $POOL Pool_ID Index2_seq $KEY_FILE | sort | uniq | awk '{if(NF==1)print $1; if(NF>1) print "MULTIPLE_I2_FOR_"'$POOL'}'`
				
				echo $S";"$I1";"$I2";"
				ALL_SMOCINDEX_SETS=$ALL_SMOCINDEX_SETS" "$S";"$I1";"$I2";"
			done
		done
	fi
	
	NUM_SMOCINDEX_SETS=`echo $ALL_SMOCINDEX_SETS | wc -w`
	
	if [ $NUM_SMOCINDEX_SETS == 0 ];then

		echo "ALL_POOLS:" $ALL_POOLS
		echo "ALL_PROJIDS:" $ALL_PROJIDS
		echo "SMOC ID missing"
	fi

}

##########################################
##############  FUNCTIONS  #################

DE_FIND_FIELD ()
{
	FILE=$1
	shift
	PID_FIELD=$1
	shift
	PROJ_ID=$1
	shift
	GCID=$1
	shift
	SIF=$1
	shift
	
	for CGF in $@
	do
	
		cat $FILE | grep -v "###" | awk -F"\t" -v GCID=$GCID -v CGF=$CGF -v SIF=$SIF -v EXCLUDE=$EXCLUDE -v PID_FIELD=$PID_FIELD -v PROJ_ID=$PROJ_ID '{	
																
																													
															if($PID_FIELD==PROJ_ID)
															
															{
																y=split(GCID, ar, ";")
															
																for(i=1; i < y+1; i++)
																{
																	if($CGF == ar[i])
																	{
																		if($SIF ~ /;/)
																		{	
																			split($SIF, ar, ";")
																			printf ",%s,", ar[2]
																		}
																		if($SIF !~ /;/)
																			printf "%s,", $SIF
																	}	
																}
															}
														}'
	done 

} 
#######################

###############  function for getting GID from Gdrive ###############

gdrive_gid () 
{
	# get path of the current file. if the file path is relative, convert it to absolute path
	file_path="${BASH_SOURCE[0]}"
	if [[ $file_path != /* ]]; then
		file_path="$PWD/${BASH_SOURCE[0]}"
	fi

	MOC_ID=$1	

	# source /idi/moc_ec/MOC/scripts/bash_header
	source "$(dirname $file_path)"/bash_header

	### source all functions 
	# source "/idi/moc_ec/MOC/scripts/MOC_functions.sh"
	source "$file_path"

	### determining paths and headers 
	### default config file is /idi/moc_ec/MOC/config_files/PC_config.yaml
	paths_and_headers $MOC_ID $@

	# CONFIG_FILE=`extract_option -conf "/idi/moc_ec/MOC/config_files/PC_config.yaml" 1 $@`
	DEFAULT_CONFIG_PATH="$(dirname $(dirname $file_path))"/config_files/PC_config.yaml
	CONFIG_FILE=`extract_option -conf $DEFAULT_CONFIG_PATH 1 $@`
	PROJ_PATH=`extract_option -proj_type P 1 $@`

	### set paths to directories, files, and scripts from config file
	if [ $PROJ_PATH == "P" ];then
		GMOC_PATH=`config_read $CONFIG_FILE gdrivemoc_path`
		GKEY_FILE=$GMOC_PATH"/"$MOC_ID"/"$MOC_ID"_Key"
	fi
	if [ $PROJ_PATH == "D" ];then
		GMOC_PATH=`config_read $CONFIG_FILE gdriveDEV_path`
		TYPE=`echo $MOC_ID | cut -d"-" -f1`
		PROJ_ID=`echo $MOC_ID | cut -d"." -f1`
		GKEY_FILE=$GMOC_PATH"/"$TYPE"/Experiments/"$MOC_ID"/"$MOC_ID"_Key"
	fi
	if [ $PROJ_PATH == "TC" ];then
		GMOC_PATH=`config_read $CONFIG_FILE gdriveGCIDTC_path`
		TYPE=`echo $MOC_ID | cut -d"-" -f1`
		PROJ_ID=`echo $MOC_ID | cut -d"." -f1`
		GKEY_FILE=$GMOC_PATH"/"$TYPE"/Experiments/"$MOC_ID"/"$MOC_ID"_Key"
	fi
	if [ $PROJ_PATH == "CIS" ];then
		GMOC_PATH=`config_read $CONFIG_FILE gdriveCIS_path`
		TYPE=`echo $MOC_ID | cut -d"-" -f1`
		PROJ_ID=`echo $MOC_ID | cut -d"." -f1`
		GKEY_FILE=$GMOC_PATH"/"$TYPE"/Experiments/"$MOC_ID"/"$MOC_ID"_Key"
	fi

	GLOCAL_PATH=`config_read $CONFIG_FILE gdrivelocal_path`
	GDRIVE_SCRIPT=`config_read $CONFIG_FILE gdrive_script`

	cd $GLOCAL_PATH

	$GDRIVE_SCRIPT id $GKEY_FILE | cut -d'"' -f2 | awk '{print $NF}' | tail -1

}


############## function for identifying and getting the URLs of Sheets files on gdrive to be moved to the server ###################
############## calls move_sheet function to transfer sheet from Sheets file from gdrive to server ###################
get_URLS ()
{
	##### path to drive API dir
	GLOCAL_PATH=$1
	##### path to gdrive dir
	GDIR=$2
	##### path to local dir
	LDIR=$3
	##### name of sheet to be imported
	SHEET_NAME=$4
	##### suffix to be added to file name
	SUFF=$5
	##### regexp to filter for specific file names to be moved
	FILTER=$6
	##### rewrite all files on server
	REWRITE=$7
	##### file into which moved file names will be written
	ALL_MOVED_FILE=$8
	##### path to dir containing the GS_import.py script for move_sheet ()
	SCRIPTS_DIR=$9
	##### pull desktop files from gdrive 
	GDRIVE_PULL=${10}

	ALL_FILES=""


	#### move into drive API directory
	echo "cd $GLOCAL_PATH"
	cd $GLOCAL_PATH
	pwd 

	GDRIVE_BEFORE_FILE=$TEMP_DIR"/before.txt"
	GDRIVE_AFTER_FILE=$TEMP_DIR"/after.txt"
	
	ON_SERVER_FILE=$TEMP_DIR"/on_server.txt"
	GDRIVE_NO_SERVER=$TEMP_DIR"/gdrive_no_server.txt"

	echo "Identifying log files on server..."
	ls -lrt $LDIR/*$SUFF | rev | cut -d"/" -f1 | rev | sed 's/'$SUFF'//g' > $ON_SERVER_FILE
	echo "Identifying GDrive files on server before pulling files from GDrive..."
	ls -lrt $GLOCAL_PATH$GDIR/* | grep -v "template" | grep -v "desktop" | awk '{if(NF==9) print $0}'> $GDRIVE_BEFORE_FILE
	
	
	echo "Identifying log files on gdrive not on server..."
	ALL_GDRIVE=`cat $GDRIVE_BEFORE_FILE | rev | cut -d"/" -f1 | rev | sed 's/.desktop//g' | sort | uniq`
	echo "" | sed 1d > $GDRIVE_NO_SERVER 
	for LOG in $ALL_GDRIVE
	do
		NUM_MATCH=`cat $ON_SERVER_FILE | grep -w $LOG | wc -l`
		if [ $NUM_MATCH == 0 ];then
			echo $LOG
		fi
	done >> $GDRIVE_NO_SERVER

	if [ $GDRIVE_PULL == "Y" ];then
		echo "Pulling URL files for all logs from gdrive..."
	# 	echo "$GDRIVE_SCRIPT pull -no-prompt -files $GDIR"
		$GDRIVE_SCRIPT pull -no-prompt -ignore-name-clashes -files $GDIR 
		pwd
		echo $GDIR 
		ls -lrt $GLOCAL_PATH$GDIR/* | grep -v "template" | grep -v "desktop" | awk '{if(NF==9) print $0}' > $GDRIVE_AFTER_FILE
	else
		cat $GDRIVE_BEFORE_FILE > $GDRIVE_AFTER_FILE
	fi

	if [ $FILTER == "-" ];then
		echo "Identifying new, modified GDrive files..."
		ADDED_FILES=`diff $GDRIVE_BEFORE_FILE $GDRIVE_AFTER_FILE | grep ">" | rev | cut -d"/" -f1 | rev | sed 's/.desktop//g' | sort | uniq` 
		NO_SERVER_FILES=`cat $GDRIVE_NO_SERVER`
		FILES_TO_MOVE=$ADDED_FILES" "$NO_SERVER_FILES	
	else
		echo "Identifying GDrive files containing regexp $FILTER..."
		FILTER_FILES=`cat $GDRIVE_AFTER_FILE | rev | cut -d"/" -f1 | rev | sed 's/.desktop//g' | sort | uniq | grep $FILTER` 
		FILES_TO_MOVE=$FILTER_FILES
	fi
 	
 	if [ $REWRITE == "Y" ];then
		while true; do
			read -p "Are you sure you want to overwrite all server files? If so enter Y?	" yn
			case $yn in
				[Yy]* ) break;;
				[Nn]* ) exit;;
				* ) echo "Please answer Y or N";;
			esac
		done

		echo ""
		echo "Identifying all files on GDrive to prepare for rewrite on server..."
		ALL_FILES=`cat $GDRIVE_AFTER_FILE | grep -v template | rev | cut -d"/" -f1 | rev | sed 's/.desktop//g' | sort | uniq` 
		FILES_TO_MOVE=$ALL_FILES
	fi

	NUM_FILES=`echo $FILES_TO_MOVE | wc -w`
	echo $NUM_FILES "files to move: "$FILES_TO_MOVE

	if [ $NUM_FILES -gt 0 ];then
		echo "Moving the following $NUM_FILES GDrive files onto server..."
		echo $FILES_TO_MOVE
		for FILE in $FILES_TO_MOVE
		do
			GD_FILE=$GDIR"/"$FILE".desktop"
# 			echo move_sheet $SCRIPTS_DIR $GD_FILE $LDIR $SHEET_NAME $SUFF $ALL_MOVED_FILE
			move_sheet $SCRIPTS_DIR $GD_FILE $LDIR $SHEET_NAME $SUFF $ALL_MOVED_FILE
		done
 	else
 		echo "No files to move"
 	fi
 	
#  	ls -lrt $ALL_MOVED_FILE
}

############## function for moving files from gdrive to the server using GIDs from gdrive .desktop files ###################
move_sheet ()
{
		##### path to dir containing the GS_import.py script
		SCRIPTS_DIR=$1
		##### path to .desktop file
		FILE=$2
		##### path to dir in which to transfer GDrive sheet
		DIR=$3
		##### name of sheet
		SHEET_NAME=$4
		##### suffix to be added to file name
		SUFF=$5
		##### file into which moved file names will be appended
		ALL_MOVED_FILE=$6
		
		NAME=`cat $FILE | grep "Name=" | sed 's/Name=//g'`
		ID=`cat $FILE | grep "URL=" | awk -F"/" '{print $(NF-1)}'`
		ERROR_FILE=$TEMP_DIR"/error.txt"

		LOCAL_FILE=$DIR"/"$NAME$SUFF
		#echo $LOCAL_FILE
		rm $LOCAL_FILE

# 		printf "%s;%s\n" $NAME $ID

		############## moving log file to server ###############
		echo $SCRIPTS_DIR"/GS_import.py" -s $ID -t $SHEET_NAME -p $NAME --Key_dir $DIR -S $SUFF
		$SCRIPTS_DIR"/GS_import.py" -s $ID -t $SHEET_NAME -p $NAME --Key_dir $DIR -S $SUFF > $ERROR_FILE 2>&1
		########################################################	
		
		#### check if API transfer quota exceeded
		QUOTA_FLAG=`cat $ERROR_FILE | grep -e "service is currently unavailable" -e "Quota exceeded" | wc -l`
		
		#### if so wait 50s and try again
		if [ ! -e $LOCAL_FILE ];then
			if [ $QUOTA_FLAG -gt 0 ];then
				echo "******************************"
				echo $LOCAL_FILE" not moved, sleeping for 50s and trying again"
				echo "******************************"
				sleep 50
				move_sheet $SCRIPTS_DIR $GD_FILE $LDIR $SHEET_NAME $SUFF $ALL_MOVED_FILE
			else 
				cat $ERROR_FILE
				exit
			fi
		fi
		ls -lrt $LOCAL_FILE | awk '{print $NF}' >> $ALL_MOVED_FILE
 		ls -lrt $LOCAL_FILE 
}


############################  UGER_test ###############################

UGER_test ()
{	
	SGE_OUT=$1
	
	jobs_submit=`cat $SGE_OUT`
	
	typeset -i NUM
	
	while :
	do
			
		job_running=`qstat | awk '{if(NR > 2 ) print $1}'`
		NUM=`echo $job_running $jobs_submit | tr ' ' '\n' | sort | uniq -c | awk '{if($1==2)print $0}' | wc -l`
		if [ $NUM == 0 ];then
		
			echo "qstat jobs are complete"
			break
		fi
		
	done
}

###########################  Move key from Gdrive to server #################################

move_key () 
{ 
	
	if [ $GID_OPT == "0" ];then
		echo "Getting GID from Gdrive using the path in $CONFIG_FILE"
		echo "gdrive_gid $MOC_ID -conf $CONFIG_FILE -proj_type $PROJ_TYPE | grep -v Dropping | grep -v Prepending | tail -1"
		G_ID=`gdrive_gid $MOC_ID -conf $CONFIG_FILE -proj_type $PROJ_TYPE | grep -v Dropping | grep -v Prepending | tail -1`
	else
		G_ID=$GID_OPT
	fi

	if [ -z $G_ID ];then

		echo "G_ID not found in gdrive or entered in command line with -gid option"
		exit
	fi

	echo "GID:" $G_ID 

	if [ $MOVE_KEY == "Y" ];then 
	
		echo "Removing old key"
		rm -rf $KEY_FILE
	
		echo $KEY_SHEET
	
		echo "Moving key file to server..."
		echo "python $KEY_SCRIPT -s $G_ID -t \"$KEY_SHEET\" -p $MOC_ID --Key_dir $KEY_DIR"
	
		python $KEY_SCRIPT -s $G_ID -t "$KEY_SHEET" -p $MOC_ID --Key_dir $KEY_DIR
			
		check_file $KEY_FILE $FUNCNAME
		chmod 777 $KEY_FILE
	fi

}

####################
check_file ()
{
	FILE=$1
	FUNC=$2
	
	### if key file not found or empty, stop pipeline
	if [ ! -s $FILE ];then
		ls -lrt $FILE
		echo $FILE "is missing"
		echo "exit error: "$FUNC
		if [ $EXIT == "Y" ];then
			exit
		fi
	fi
}
#################
mod_check ()
{
	# get path of the current file. if the file path is relative, convert it to absolute path
	file_path="${BASH_SOURCE[0]}"
	if [[ $file_path != /* ]]; then
		file_path="$PWD/${BASH_SOURCE[0]}"
	fi

	MOC_ID=$1
	shift
	DIR=$1
	shift
	ALL_SUFF=$1
	shift	

	### source all functions 
	# source "/idi/moc_ec/MOC/scripts/MOC_functions.sh"
	source "$file_path"

	FAIL_EXIT=`extract_option -fail_exit N 1 $@`
	CHECK_MOD_FILE=$DIR"check_file.txt"


	echo "sh $CHECK_MOD_SCRIPT $MOC_ID $DIR $ALL_SUFF $CHECK_MOD_FILE $@"
	sh $CHECK_MOD_SCRIPT $MOC_ID $DIR $ALL_SUFF $CHECK_MOD_FILE $@
	
	NUM_MISSING=`cat $CHECK_MOD_FILE | grep -e ISSING -e issing | grep -v "0 miss" | grep -v "0 Miss" | wc -l`
	if [ $NUM_MISSING -gt 0 ];then
		cat $CHECK_MOD_FILE
		if [ $FAIL_EXIT == "Y" ];then
			exit
		fi
	fi
}

###################

redo_key ()
{
	
	DIR=$1
	
	CHECK_MOD_FILE=$DIR"check_file.txt"

	ALL_MISSING=`cat $CHECK_MOD_FILE`

	for MISS_ID in $ALL_MISSING
	do
		cat $KEY_FILE | grep -v "###" | awk -F"\t" -v SID_F=$SID_F -v SID=$MISS_ID '{
																	if($SID_F==SID || $SID_F=="Sample_ID")
																		print $0
																}' 

	done > $REDO_KEY_FILE

	ls -lrt $REDO_KEY_FILE
}

###################

make_test_fastqs ()
{
	NUM_READS=$1
	NUM_FASTQ_LINES=`echo $NUM_READS | awk '{print $1*4}'`
	
	
	echo "Making test fastqs with $NUM_TEST_READS reads ($NUM_FASTQ_LINES fastq lines) for all fastqs in $MOC_SYM_DIR..."
	ALL_FASTQ=`ls -lrt $MOC_SYM_DIR | grep fastq | awk '{print $9}'`
	for FASTQ in $ALL_FASTQ
	do
		IN_FILE=$MOC_SYM_DIR"/"$FASTQ		
		OUT_FILE=$MOC_SYM_TEST_DIR"/"$FASTQ
		zcat $IN_FILE | head -$NUM_FASTQ_LINES | gzip > $OUT_FILE
	done
}

############### function to create RtS pool, index, and MOCS database from pool and sub wbs ######################

mocs_sub_to_db ()
{
	
	MOCSDB_DIR=$1
	DB_LIMIT=$2
	MOCS_DB=$3
	
	ALL_POOLS=`cat $MOCSDB_DIR/*_Pool_Sub_WB.txt | grep $DB_LIMIT | grep -v "MOCS_ID" | grep -v "sid:" | grep "MOCS" | grep -v "MOCS-ID" | awk '{print $2}' | sort | uniq`
	ALL_MOCS=`cat $MOCSDB_DIR/*_Pool_Sub_WB.txt | grep $DB_LIMIT | grep -v "MOCS_ID" | grep -v "sid:" | grep "MOCS" | grep -v "MOCS-ID" | awk '{print $1}' | sort | uniq`

	ls -lrt $MOCSDB_DIR/*

	echo $ALL_POOLS
	echo ""
	echo $ALL_MOCS


	for POOL in $ALL_POOLS
	do
		ALL_COMBOS=`cat $MOCSDB_DIR/*_Pool_Sub_WB.txt | awk -F"\t" -v POOL=$POOL '{if($2==POOL)print $1","$4","$5}'`	
	
		
		printf "%s\t" $POOL
	
		for COMBO in $ALL_COMBOS
		do
			MOCS=`echo $COMBO | cut -d"," -f1 | sed 's/\-//g'`
			ID1=`echo $COMBO | cut -d"," -f2`
			ID2=`echo $COMBO | cut -d"," -f3`

			ISEQ1=`get_bcs_seq $BCS_FILE $ID1 2` 
			ISEQ2=`get_bcs_seq $BCS_FILE $ID2 2` 
		
	
			printf "%s;%s;%s;%s;%s\t" $MOCS $ISEQ1 $ISEQ2 $ID1 $ID2
		done
		echo "" 


	done > $MOCS_DB

	ls -lrt $MOCS_DB
}

############### USING RTS MOCS DB - function to create RtS pool, index, and MOCS database from pool and sub wbs ######################

mocs_sub_to_db_2 ()
{
	
	MOCS_DB_IN=$1
	DB_LIMIT=$2
	MOCS_DB_OUT=$3
	
	ALL_POOLS=`cat $MOCS_DB_IN | grep $DB_LIMIT | grep -v "Index1_ID"| awk '{print $1}' | sort | uniq`
	ALL_MOCS=`cat $MOCS_DB_IN | grep $DB_LIMIT | grep -v "Index1_ID"  | awk '{print $4}' | sort | uniq`


echo $ALL_POOLS

	for POOL in $ALL_POOLS
	do
		ALL_COMBOS=`cat $MOCS_DB_IN | awk -F"\t" -v POOL=$POOL '{if($1==POOL)print $4","$5","$7}'`	
		
		printf "%s\t" $POOL
	
		for COMBO in $ALL_COMBOS
		do
			MOCS=`echo $COMBO | cut -d"," -f1 | sed 's/\-//g'`
			ID1=`echo $COMBO | cut -d"," -f2`
			ID2=`echo $COMBO | cut -d"," -f3`

			ISEQ1=`get_bcs_seq $BCS_FILE $ID1 2` 
			ISEQ2=`get_bcs_seq $BCS_FILE $ID2 2` 
		
	
			printf "%s;%s;%s;%s;%s\t" $MOCS $ISEQ1 $ISEQ2 $ID1 $ID2
		done
		echo "" 


	done > $MOCS_DB_OUT

	ls -lrt $MOCS_DB_OUT
}

############### Function to pull out value in column TH_VAL and row in column QH_VAL with value Q_VAL  ######################

Index ()
{
	FILE=$1
	QH_VAL=$2
	TH_VAL=$3
	Q_VAL=$4

	Q_COL=`cat $FILE | sed 's/ /_/g' | sed 's/\t_/\t/g' | awk -F"\t" -v QH_VAL=$QH_VAL '{
										for(i=0; i< NF+1; i++)
											if($i==QH_VAL)
												print i
								}' | head -1`

	T_COL=`cat $FILE | sed 's/ /_/g' | sed 's/\t_/\t/g' | awk -F"\t" -v TH_VAL=$TH_VAL '{
								
										for(i=0; i< NF+1; i++)
										{
											if($i==TH_VAL)
												print i
										}
								}'`

	Q_ROW=`cat $FILE | sed 's/ /_/g' | sed 's/\t_/\t/g' | awk -F"\t" -v Q_COL=$Q_COL -v Q_VAL=$Q_VAL '{
								
									if($Q_COL==Q_VAL)
										print NR
								}'| head -1`


	cat $FILE | sed 's/ /_/g' | awk -F"\t" -v Q_ROW=$Q_ROW -v T_COL=$T_COL '{
													
													if(NR==Q_ROW)
														print $T_COL
												
													}'

}



############### Function to identify projects in MOCS_DB whose status has changed in > # days  ######################

 time_id ()
{
	DB=$1
	DAYS=$2
	TIME_OUTFILE=$3
	TYPE=$4

	TEMP_FILE=$TEMP_PATH"/data_email_temp.txt"
	TEMP_FILE1=$TEMP_PATH"/data_email_temp1.txt"
	TEMP_FILE2=$TEMP_PATH"/data_email_temp2.txt"

	ALL_IDs=`cat $DB | sed 1d | awk '{print $2}' | sort | uniq`

	echo "" | sed 1d > $TEMP_FILE
	for ID in $ALL_IDs
	do
		cat $DB | grep $ID | tail -1 >> $TEMP_FILE
	done

	stamp=`date +%s`
	cat $TEMP_FILE | awk -v DAYS=$DAYS -v TYPE=$TYPE '{
	
									if((('$stamp'-$4)/60000)+1 > DAYS && $1 == TYPE) 
									{									
										printf "%.0f\t", (('$stamp'-$4)/60000)+1
										print $0
									}
								}' > $TEMP_FILE1							
	ALL_COMBOs=`cat $TEMP_FILE1 | awk '{print $3";"$1}' | sort | uniq`

	echo "" | sed 1d > $TIME_OUTFILE

	for COMBO in $ALL_COMBOs
	do
		ID=`echo $COMBO | sed 's/;/ /g' | awk '{print $1}'`
		DAYS=`echo $COMBO | sed 's/;/ /g' | awk '{print $2}'`
		ls -lrt $RAWSYM_PATH"/"$ID | awk -v ID=$ID -v DAYS=$DAYS '{print ID, $NF, DAYS}' | grep fastq
		echo ""
	done > $TIME_OUTFILE

}