#!/bin/sh

MOCS=$1

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

	echo $Q_COL, $Q_ROW, $T_COL, $Q_VAL
	cat $FILE | sed 's/ /_/g' | awk -F"\t" -v Q_ROW=$Q_ROW -v T_COL=$T_COL '{
													
													if(NR==Q_ROW)
														print $T_COL
												
													}'
													
}


########################################################################

DEFAULT_CONFIG_PATH="$(dirname $(dirname $file_path))"/config_files/PC_config.yaml
CONFIG_FILE=`extract_option -conf $DEFAULT_CONFIG_PATH 1 $@`
if [[ $CONFIG_FILE != /* ]]; then
	CONFIG_FILE="$PROJECT_ROOT_DIR/$CONFIG_FILE"
fi

TEMP_PATH=`config_read $CONFIG_FILE Temp_path`
DB_SCRIPT=`config_read $CONFIG_FILE DB_script`
ORPHAN_SCRIPT=`config_read $CONFIG_FILE orphan_script`
RAW_SYM_PATH=`extract_option -symlink $RAWSYM_PATH 1 $@`
MAKE_COUNTS=`extract_option -make_counts Y 1 $@`
SEQ_LANE=`extract_option -lane "B" 1 $@`
ORPHAN_SCRIPT=`config_read $CONFIG_FILE orphan_script`
WU_DIR=`config_read $CONFIG_FILE Walkup_path`
########################################################################

MOCS_SYMDIR=$RAWSYM_PATH"/"$MOCS"/"

echo $IMPORT_GS
USID=`USID`

MOCS_ID=`echo $MOCS | sed 's/-//g'`
OUT_DIR=$TEMP_PATH$MOCS_ID"/"
TEMP_DIR=$TEMP_PATH$MOCS_ID"/"$USID"/"

mkdir -p $OUT_DIR
mkdir -p $TEMP_DIR

METRICS_FILE=$OUT_DIR"/"$MOCS"_walkup_metrics.txt"
TEMP_METRICS_FILE=$OUT_DIR"/"$MOCS"_walkup_metrics_temp.txt"
SEG_FILE=$TEMP_DIR$MOCS_ID"SGE_file.txt"

# Set directory paths
MOCS_WB=`ls -lrt $MOCSDB_DIR* | grep $MOCS | grep _WB |  awk '{print $9}'`

echo $MOCSDB_DIR
echo $MOCS_SYMDIR
echo $MOCS_WB

ALL_FC=`ls -lrt $MOCS_SYMDIR  | grep fastq | grep -v "Undetermined" | awk '{print $9}' | cut -d"_" -f1  | cut -d"." -f1 | sort | uniq`


# Pull out all INDEX IDs
ALL_WU_INDEXES=`ls -lrt $MOCS_SYMDIR | grep fastq | grep -v "Undetermined" | awk '{print $9}'  | grep -v SCE | awk '{

		y=split($1,ar,"_")
		FULL_INDEX=ar[4]
		split(FULL_INDEX, pr, "-")
		print pr[1]"-"pr[2]

	}' | sort | uniq`

echo $ALL_WU_INDEXES

# Pull out all lane IDs
ALL_LANES=`ls -lrt $MOCS_SYMDIR  | grep fastq | grep -v Undetermined | awk '{y=split($9,ar,"_");print ar[y-2]}' | sort | uniq`

# Pull out all read IDs
ALL_READS=`ls -lrt $MOCS_SYMDIR  | grep fastq | grep -v Undetermined | awk '{y=split($9,ar,"_");print ar[y-1]}' | sort | uniq`

echo $ALL_LANES
echo $ALL_READS


echo "Metrics for $MOCS" > $METRICS_FILE	
echo "" >> $METRICS_FILE	

# Pull out num files for each lane
for FC in $ALL_FC
do
	echo "Total files for FC "$FC"..."
	for LANE in $ALL_LANES
	do 
		printf "LANE %s:\t" $LANE
		ls -lrt $MOCS_SYMDIR"/"$FC*$LANE*fastq* | wc -l
	done >> $METRICS_FILE	
	
done 

# Pull out num files for each index
for FC in $ALL_FC 
do	
	echo "Total files for FC "$FC"..."
	for INDEX in $ALL_WU_INDEXES
	do
		printf "INDEX %s:\t" $INDEX
		ls -lrt $MOCS_SYMDIR"/"*$FC*$INDEX*fastq* | awk '{print $NF}' | sort | uniq | wc -l
	done
	
done >> $METRICS_FILE	

#### Generate count files for each fastq 

if [ $MAKE_COUNTS != "N" ];then
	ALL_SUFFIX=`ls -lrt $MOCS_SYMDIR  | grep fastq | grep -v "Undetermined" | awk '{y=split($9,ar,"_");print ar[y]}' | sort | uniq`

	echo $ALL_SUFFIX

	echo "" | sed 1d > $SEG_FILE

	### if IDs entered in make_counts option
	if [ $MAKE_COUNTS != "Y" ];then
	
		ALL_WU_INDEXES=`echo $MAKE_COUNTS | sed 's/,/ /g'`
		for INDEX in $ALL_WU_INDEXES
		do
			rm -f $OUT_DIR"/"*$INDEX"_"*"_R1"*"_counts.txt"
		done

	### if not, remove all count files
	else 
		#Removing old counts file for each fastq
		echo "Removing old counts file for each fastq"
		rm -f $OUT_DIR"/"*"_counts.txt"
	fi

	NUM_INDEX=`echo $ALL_WU_INDEXES | wc -w`

	echo "SEQ_DIR:" $MOCS_SYMDIR
	echo "ALL_WU_INDEXES:" $ALL_WU_INDEXES 
	echo "NUM_INDEX:"	$NUM_INDEX 
	echo "ALL_FC :"	$ALL_FC 
	echo "ALL_LANES :"	$ALL_LANES 


	typeset -i NUM_FILES

	echo "" | sed 1d > ~/temp.txt



	#Getting counts for each fastq
	echo "Getting counts for each fastq"
	for FC in $ALL_FC
	do
		for INDEX in $ALL_WU_INDEXES
		do
			for LANE in $ALL_LANES
			do
				for READ in $ALL_READS
				do
					for SUFF in $ALL_SUFFIX
					do
											
				
							FASTQ=`ls -lrt $MOCS_SYMDIR | grep -v Undetermined | grep fastq | grep $SUFF | awk -v INDEX=$INDEX -v FC=$FC -v SUFF=$SUFF -v LANE=$LANE -v READ=$READ '{
														
																y=split($9,ar,"_")
																split(ar[4], pr, "-")
																FASTQ_INDEX=pr[1]"-"pr[2]
																if(ar[1]==FC && FASTQ_INDEX==INDEX && ar[y-2]==LANE && ar[y-1]==READ)
																	print $9

																}'`
								
						
							NUM_FILES=`echo $FASTQ | wc -w`
							if [ $NUM_FILES != 1 ];then
								echo "NUM_FILES = "$NUM_FILES
								echo "FASTQ: "$FASTQ 
								echo "NUM_FILES != 1"
								echo "FASTQ: "$FASTQ 
								exit
							fi
							
							echo "FASTQ: "$FASTQ 
							echo "INDEX: "$INDEX 
							FASTQ_PATH=$MOCS_SYMDIR$FASTQ
							ROOT=`basename $FASTQ .fastq.gz`
							COUNT_FILE=$OUT_DIR"/"$ROOT"_counts.txt"
							echo "Launching UGER job for "$FASTQ_PATH" to generate "$COUNT_FILE
					
							echo "echo $FC, $INDEX, $LANE, $SUFF, $FASTQ | tr '\n' ' ' > $COUNT_FILE" > $TEMP_DIR/temp_qsub.txt
							echo "zcat $FASTQ_PATH | grep @ | wc -l >> $COUNT_FILE" >> $TEMP_DIR/temp_qsub.txt
							echo "zcat $FASTQ_PATH | grep @ | wc -l"						
							qsub $TEMP_DIR/temp_qsub.txt >> $SEG_FILE
							echo $TEMP_DIR/temp_qsub.txt

# 						else 
# 							echo "Problem..."
# 							echo $SUFF $INDEX $FC $NUM_FILES $FASTQ
# 							echo $MOCS_SYMDIR
# 						
# 						fi
					
					
					done
				done
			done
		done
	done

	# Generating count files for index unmatched fastqs
	ALL_UNMATCHED_FQ=`ls -lrt $MOCS_SYMDIR* | grep Undeterm | awk '{print $9}'`
	for FASTQ in $ALL_UNMATCHED_FQ
	do
		ROOT=`basename $FASTQ .fastq.gz`
		COUNT_FILE=$OUT_DIR"/"$ROOT"_counts.txt"
		echo "Launching UGER job for "$FASTQ" to generate "$COUNT_FILE
		echo "echo Undetermined, Undetermined, -, Undetermined, $FASTQ | tr '\n' ' ' > $COUNT_FILE" > ~/temp.txt
		echo "zcat $FASTQ | grep @ | wc -l >> $COUNT_FILE" >> ~/temp.txt
		qsub ~/temp.txt >> $SEG_FILE
	done
 
	echo "Jobs submitted - waiting for them to complete...."

	echo $SEG_FILE
	qstat

	#testing that all jobs launched are finished
	SGE_test $SEG_FILE	
	echo "All Jobs completed...."
fi
#############


############# Generating summary metrics for run for each index/poolID
	echo "Generating summary metrics for run for each index/poolID"
	printf "%s	%s	%s	%s" "Flowcell" "TotalMReads"	"MReadsMatchedToIndex:(pcnt)" "MReadsNotMatchedToIndex:(pcnt)" >> $METRICS_FILE	
	for LANE in $ALL_LANES
	do
		printf "	Pcnt_Lane_%s" $LANE >> $METRICS_FILE

	done 
	echo "" >> $METRICS_FILE

	for FC in $ALL_FC
	do
		total_reads=`cat $OUT_DIR"/"*"_counts.txt" | awk -v total=0 '{total=total+$NF; print total/10^6}' | tail -1`
		total_unmatched=`cat $OUT_DIR"/"*"Undetermined"*"_counts.txt" | awk -v total=0 '{total=total+$NF; print total/10^6}' | tail -1`
		total_matched=`echo $total_reads $total_unmatched | awk '{print $1-$2}'`
		pcnt_unmatched=`echo $total_unmatched $total_reads | awk '{print $1/$2*100}' ` 
		printf "%s	%s	%s	%s(%s)	" $FC $total_reads $total_matched $total_unmatched $pcnt_unmatched >> $METRICS_FILE
		for LANE in $ALL_LANES
		do
			total_lane=`cat $OUT_DIR"/"*"$LANE"*"_counts.txt" | awk -v total=0 -v total_reads=$total_reads '{total=total+$NF; print total/10^6/total_reads*100}' | tail -1`
			printf "%s\t" $total_lane >> $METRICS_FILE
		done
		echo "" >> $METRICS_FILE

	done

	ls -lrt $METRICS_FILE

	echo "" >> $METRICS_FILE

############# Generating metrics for each index/poolID
	echo "Generating metrics for each index/poolID"

	echo "POOL_ID	INDEX	TOTAL_M_READS PCNT_OF_TOTAL_READS	PCNT_OF_TARGET_READS" >> $METRICS_FILE

	rm $TEMP_METRICS_FILE
	touch $TEMP_METRICS_FILE
	for INDEX in $ALL_WU_INDEXES
	do
		echo $INDEX
	
		ALL_COUNT_FILES=`ls $OUT_DIR"/"*$INDEX*"_R1"*"_counts.txt"`
		NUM_COUNT_FILES=`ls $OUT_DIR"/"*$INDEX*"_R1"*"_counts.txt" | wc -l`

	
		POOL_ID=`echo $ALL_COUNT_FILES | awk '{
												y=split($1,ar,"/")
												split(ar[y],pr,"_")
												x=split(pr[4],qr,"-")
												
												if(x==2)
													print "-"
												if(x==5)
													print qr[4]"-"qr[5]
												if(x==6)
													print qr[4]"-"qr[5]

											}'`
		
		if [ $NUM_COUNT_FILES == 0 ];then
			R1_TOT="NF"
			R1_PCNT="NA"
			PCNT_TARGET="NA"
		else
			echo "POOL_ID:" $POOL_ID
			echo $ALL_COUNT_FILES

			R1_TOT=`cat $ALL_COUNT_FILES | awk -v total=0 -v total_matched=$total_matched '{total=total+$NF;print total/10^6}' | tail -1`
			R1_PCNT=`echo $R1_TOT $total_matched | awk '{print $1/$2*100*2}' `
			PCNT_TARGET=`Index $MOCS_WB "Pool_ID" "Total_reads_per_pool_(M)" $POOL_ID | awk -v R1_TOT=$R1_TOT '{print R1_TOT/$1*100}' `
		fi
		echo $POOL_ID"	"$INDEX"	"$R1_TOT"	"$R1_PCNT"	"$PCNT_TARGET >> $TEMP_METRICS_FILE

	done

	cat $TEMP_METRICS_FILE | sort -k3gr >> $METRICS_FILE
	cp $METRICS_FILE $MOCS_SYMDIR
##############

export TMPDIR=$TEMP_PATH

echo "Sending email to $USID with $METRICS_FILE attached"
cat $METRICS_FILE |  mailx -a $METRICS_FILE -s "Metrics for $MOCS" $USID"@broadinstitute.org"

chmod 777 $SEQ_DIR/$METRICS_FILE
change_perms $METRICS_FILE $TEMP_DIR $OUT_DIR