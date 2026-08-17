#!/bin/sh

MOC_ID=$1

source /broad/software/scripts/useuse

# use Python-2.7

# get path of the current file. if the file path is relative, convert it to absolute path
file_path="${BASH_SOURCE[0]}"
if [[ $file_path != /* ]]; then
  file_path="$PWD/${BASH_SOURCE[0]}"
fi

PROJECT_ROOT_DIR="$(dirname $(dirname $(dirname $(dirname $(dirname $file_path)))))"

# get parent directory
scripts_dir="$(dirname $file_path)"

# source idi/moc_ec/MOC/scripts/bash_header
source "$scripts_dir/bash_header"

### source all functions 
# source "/idi/moc_ec/MOC/scripts/MOC_functions.sh"
source "$scripts_dir/MOC_functions.sh"


# CONFIG_FILE=`extract_option -conf "/idi/moc_ec/MOC/config_files/Universal_config.yaml" 1 $@`
DEFAULT_CONFIG_PATH="$(dirname $(dirname $file_path))"/config_files/PC_config.yaml
CONFIG_FILE=`extract_option -conf $DEFAULT_CONFIG_PATH 1 $@`
if [[ $CONFIG_FILE != /* ]]; then
  CONFIG_FILE="$PROJECT_ROOT_DIR/$CONFIG_FILE"
fi

ALL_REFS_OPT=`extract_option -all_refs - 1 $@`
GREF=`extract_option -gref Y 1 $@`
PROJ_TYPE=`extract_option -proj_type P 1 $@`

### determining paths and headers 
### default config file is /idi/moc_ec/MOC/config_files/Universal_config.yaml
paths_and_headers $MOC_ID $@


###########################

fna_extract ()
{ 

	FNA_FILE=$1
	ACC_PARSED=$2
	GFF_ACC=$3
	
	typeset -i NUM_MATCH
	NUM_MATCH=`	awk -v flag="N" -v GFF_ACC=$GFF_ACC -v ACC_PARSED=$ACC_PARSED '{
			if($1 ~ /'$ACC_PARSED'/ && $1 ~ />/ )
			{	
				print ">"GFF_ACC
			}
		}' $FNA_FILE | wc -l`

	
	cat $FNA_FILE | tr '\r' '\n' | awk -v flag="N" -v GFF_ACC=$GFF_ACC -v ACC_PARSED=$ACC_PARSED -v NUM_MATCH=$NUM_MATCH '{
	
					
					if($1 ~ />/ && flag=="Y")
						flag="N"
					if(flag=="Y" && $1 !~ />/)
 						print $1
					if ($1 ~ />/ )
					{
						if(NUM_MATCH==1)
						{
					
							if($1 ~ /'$ACC_PARSED'/)
							{	
								print ">"GFF_ACC
								flag="Y"
							}
						}
						if(NUM_MATCH > 1)
						{
							if($1 == ">"ACC_PARSED)
							{	
								print ">"GFF_ACC
								flag="Y"
							}
						}
					}
	}' | sed '/^$/d' 

}
############################


### set paths to directories, files, and scripts from config file

KEY_DIR=`config_read $CONFIG_FILE Key_base`
RESULTS_PATH=`config_read $CONFIG_FILE Results_path`
TEMP_PATH=`config_read $CONFIG_FILE Temp_path`

KEY_SCRIPT=`config_read $CONFIG_FILE keyfile_importer`
if [[ $KEY_SCRIPT != /* ]]; then
	KEY_SCRIPT="$PROJECT_ROOT_DIR/$KEY_SCRIPT"
fi

GLOCAL_PATH=`config_read $CONFIG_FILE gdrivelocal_path`
GDRIVE_SCRIPT=`config_read $CONFIG_FILE gdrive_script`
REF_PATH=`config_read $CONFIG_FILE Bacterial_Ref_path`

GREF_DIR=$GMOC_PATH"/"$MOC_ID"/Reference_files/"
GKEY_FILE=$GMOC_PATH"/"$MOC_ID"/"$MOC_ID"_Key"
REF_DIR=$REF_PATH"/"$MOC_ID"/"
TEMP_DIR=$TEMP_PATH"/reference_rep_files/"$MOC_ID"/"

PARSE=`extract_option -parse Y 1 $@`
DATA_DIR=`extract_option -data_dir $REF_DIR 1 $@`


### set paths to directories, files, and scripts from config file
if [ $PROJ_TYPE == "P" ];then
	GMOC_PATH=`config_read $CONFIG_FILE gdrivemoc_path`
	GREF_DIR=$GMOC_PATH"/"$MOC_ID"/Reference_files/"
else

	TYPE=`echo $MOC_ID | cut -d"-" -f1`
	PROJ_ID=`echo $MOC_ID | cut -d"." -f1`
	if [ $PROJ_TYPE == "D" ];then
		GMOC_PATH=`config_read $CONFIG_FILE gdriveDEV_path`
	fi
	if [ $PROJ_TYPE == "TC" ];then
		GMOC_PATH=`config_read $CONFIG_FILE gdriveGCIDTC_path`
	fi
	if [ $PROJ_TYPE == "CIS" ];then
		GMOC_PATH=`config_read $CONFIG_FILE gdriveCIS_path`
	fi

	GREF_DIR=$GMOC_PATH"/"$TYPE"/Experiments/"$MOC_ID"/Reference_files/"
	
	if [ $PROJ_TYPE == "TRF" ];then
		GMOC_PATH=`config_read $CONFIG_FILE gdriveTRF_path`
		GREF_DIR=$GMOC_PATH"/Experiments/"$MOC_ID"/Reference_files/"
	fi
	if [ $PROJ_TYPE == "HVP" ];then
		GMOC_PATH=`config_read $CONFIG_FILE gdriveHVP_path`
		GREF_DIR=$GMOC_PATH"/Experiments/"$MOC_ID"/Reference_files/"
	fi

fi

GLOCAL_DIR=$GLOCAL_PATH"/"$GREF_DIR

echo $GLOCAL_DIR
echo $DATA_DIR

rm -r $PARSE_DIR
rm -r $REF_DIR

mkdir -p $TEMP_DIR
mkdir -p $REF_DIR
mkdir -p $PARSE_DIR
mkdir -p $GLOCAL_DIR
mkdir -p $GLOCAL_DIR

echo "cd $GLOCAL_PATH"
cd $GLOCAL_PATH
echo $REF_DIR
pwd 

echo $MOVE_KEY


############# moving key file to server ###############

if [ $MOVE_KEY == "Y" ];then 
	
	
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
	echo "Removing old key"
	rm -rf $KEY_FILE
	
	echo $KEY_SHEET
	
	echo "Moving key file to server..."
	echo "$KEY_SCRIPT -s $G_ID -t \"$KEY_SHEET\" -p $MOC_ID --Key_dir $KEY_DIR"
	
	python $KEY_SCRIPT -s $G_ID -t "$KEY_SHEET" -p $MOC_ID --Key_dir $KEY_DIR
	### if key file not found or empty, stop pipeline
	if [ ! -s $KEY_FILE ];then
		ls -lrt $KEY_FILE 
		exit
	fi
	chmod 777 $KEY_FILE
fi

########################################################

# get all project IDs and setting data dir path 
ALL_PROJ=`cat $KEY_FILE | grep -v "###" | sed 1d | awk '{print $2}' | sort | uniq`
ALL_PROJ_DIR=`echo $ALL_PROJ | sed 's/ /_/g'`


### Get ref names for  for all samples in key
REF_F=`FIELD_HEADER $KEY_FILE Bacterial_reference`

echo "FIELD_HEADER $KEY_FILE Bacterial_reference"
FIELD_HEADER $KEY_FILE Bacterial_reference
echo "REF_F:" $REF_F


if [ $ALL_REFS_OPT == "-" ];then
	ALL_REFS=`cat $KEY_FILE | grep -v "###" | grep -v "COLLAB"  | sed 1d | awk -F"\t" '{y=split($'$REF_F', ar, ";"); print ar[y]}' | sort | uniq`
else
	ALL_REFS=$ALL_REFS_OPT
fi 

echo "All references:"
echo $ALL_REFS

####### working to move ref files from Gdrive

echo "Pulling all files from "$GREF_DIR
echo "$GDRIVE_SCRIPT pull -no-prompt -files $GREF_DIR"
$GDRIVE_SCRIPT pull -no-prompt -files $GREF_DIR

ALL_FILES=`ls -lrt $GLOCAL_DIR* | grep desk | awk '{print $NF}'`

echo $ALL_FILES

for FILE in $ALL_FILES
do

	GID=`cat $FILE | grep "URL" | cut -d"/" -f6`
	NAME=`cat $FILE | grep "Name=" | cut -d"=" -f2 | sed 's/_Pool_Sub_WB//g'`

	$SCRIPTS_DIR"/GS_import.py" -s $GID -t "Sheet1" -p "gff_ann" --Key_dir $GLOCAL_DIR -S "_key.txt" 

done

ls -lrt $GLOCAL_DIR

cp $GLOCAL_DIR* $REF_DIR
echo $REF_DIR	

ls -lrt $REF_DIR

echo "ALL REFS:" $ALL_REFS

for REF in $ALL_REFS
do
	### determine if any files for REF are gz and if so unzip
	GZ=`ls -lrt $REF_DIR | grep $REF | grep gz| wc -l`
	
	if [ $GZ -gt 0 ];then
		echo "unzipping files in $REF_DIR"
		gunzip -f $REF_DIR"/"$REF*

		GFF_IN=`ls $REF_DIR"/"$REF* | grep gff`
		GFF_OUT="$REF_DIR"/"$REF.gff"
	
		FASTA_IN=`ls $REF_DIR"/"$REF* | grep -e fna -e fasta`
		FASTA_OUT="$REF_DIR"/"$REF.fna"
	
		mv $GFF_IN $GFF_OUT
		mv $FASTA_IN $FASTA_OUT

	fi
	### determine if any files for REF are missing and if so attempt to get them from server
	
	if [ -s $REF_PATH$REF".gff" ] && [ ! -s $REF_DIR"/"$REF".gff" ];then
		echo $REF_DIR"/"$REF".gff not found - attempting to cp $REF".gff" from "$REF_PATH
		echo "cp $REF_PATH$REF".gff" $REF_DIR"
		cp $REF_PATH$REF".gff" $REF_DIR
	fi
	if [ -s $REF_PATH$REF".fna" ] && [ ! -s $REF_DIR"/"$REF".fna" ];then
		echo $REF_DIR"/"$REF".fna not found - attempting to cp $REF".fna" from "$REF_PATH
		echo "cp $REF_PATH$REF".fna" $REF_DIR"
		cp $REF_PATH$REF".fna" $REF_DIR
	fi
	
done

cat $REF_DIR*gff > $REF_DIR$MOC_ID"_combined.gff"
cat $REF_DIR*fna > $REF_DIR$MOC_ID"_combined.fna"

#ALL_REFS=$ALL_REFS" "$MOC_ID"_combined"

echo $ALL_REFS
ls -lrt $REF_DIR
echo $REF_DIR
mkdir -p $DATA_DIR


### change permissions for dirs
change_perms $REF_DIR $PARSE_DIR $TEMP_DIR $GREF_DIR

### determine if any files for REF were not found on Gdrive OR server
EXIT="N"

ALL_REFS_FOUND="Y"
for REF in $ALL_REFS
do

	if [ ! -s $REF_DIR"/"$REF".gff" ];then
		echo "***********************************"
		echo "FAILURE:"$REF".gff missing from "$REF_DIR"!"
		echo "***********************************"
		EXIT="Y"
	fi
	if [ ! -s $REF_DIR"/"$REF".fna" ];then
		echo "***********************************"
		echo "FAILURE:"$REF".fna missing from "$REF_DIR"!"
		echo "***********************************"
		EXIT="Y"
	fi

done

ls -lrt $DATA_DIR

if [ $EXIT == "Y" ];then
	
	exit
fi


ls -lrt $REF_DIR*
echo "All reference files have been found and moved to "$REF_DIR


SEG_FILE=$TEMP_DIR$"gffparse_SGE_file.txt"
TEMP_FILE=$TEMP_DIR"temp.txt"

echo "" | sed 1d >  $SEG_FILE

JOBS_LAUNCHED="N"

EXIT="N"


GFF_KEY=$REF_DIR"/gff_ann_key.txt"


if [ -f $GFF_KEY ];then
	echo "GFF annotation file found"
	ls -lrt $GFF_KEY
	LOCUS_TAG=`cat $GFF_KEY | awk '{if($1=="LOCUS") print $2}'`	
	GENE_TAG=`cat $GFF_KEY | awk '{if($1=="GENE") print $2}'`	
	PROD_TAG=`cat $GFF_KEY | awk '{if($1=="PROD") print $2}'`	
	ID_TAG=`cat $GFF_KEY | awk '{if($1=="ID") print $2}'`	
	NAME_TAG=`cat $GFF_KEY | awk '{if($1=="NAME") print $2}'`
else
	echo "No GFF annotation file found: Using default values"
	LOCUS_TAG="locus_tag"
	GENE_TAG="gene"	
	PROD_TAG="product"	
	ID_TAG="ID"
	NAME_TAG="name"
fi
 

if [ $PARSE == "QC" ];then
	echo "Running QC on gff and fna files in $REF_DIR ..."
	for REF in $ALL_REFS
	do
		GFF_FILE=$REF_DIR"/"*$REF*".gff"
		FNA_FILE=$REF_DIR"/"*$REF*"fna"
		ALL_FASTA=`cat $FNA_FILE | grep ">" | sed 's/ /_/g'`		
		ALL_GFFACC=`cat $GFF_FILE | tr '\r' '\n' | sed 1d | sed -e 's/ /_/g' -e 's/(//g' -e 's/)//g' -e 's/|/ /g' | awk '{if($1 ~ /FASTA/) exit; print $1}' |  sed '/^$/d' | sort -T /broad/hptmp/ | uniq | grep -v "#" `
		
	
		echo "ALL_FASTA:" $ALL_FASTA
		echo "ALL_GFFACC:" $ALL_GFFACC
						
		ALL_GFF_FOUND="Y"
		MULT_ACC=""
		
		for GFFACC in $ALL_GFFACC 
		do
			GFF_FOUND="Y"
			NUM_FOUND=`echo $ALL_FASTA | grep -w -o $GFFACC | wc -l`
			if [ $NUM_FOUND	-eq 0 ];then
				echo $GFFACC" not found in "$ALL_FASTA
				ALL_GFF_FOUND="N"
			fi					
			if [ $NUM_FOUND	-gt 1 ];then
				echo "Multiple ("$NUM_FOUND") occurances of "$GFFACC" found in "$ALL_FASTA
				ALL_GFF_FOUND="N"
				MULT_ACC=$MULT_ACC","$GFFACC
			fi					
			if [ $GFF_FOUND == "N" ];then
				echo "Unmatched fna accessions for $GFFACC"
			fi
# 				echo "1 fna accession match found for $GFFACC"
		done
	
	
		ALL_REPS=`cat $GFF_FILE | tr '\r' '\n' | sed 1d | sed -e 's/ /_/g' -e 's/(//g' -e 's/)//g' -e 's/|/ /g' | awk '{if($1 ~ /FASTA/) exit; print $1}' |  sed '/^$/d' | sort -T /broad/hptmp/ | uniq | grep -v "#" `

		
		for REP in $ALL_REPS
		do
			
			
			NON_UNIQ=`cat $GFF_FILE | grep -v "#" | sed '/^$/d'  | awk -F"\t" -v REP=$REP -v LOCUS_TAG=$LOCUS_TAG -v GENE_TAG=$GENE_TAG -v PROD_TAG=$PROD_TAG -v ID_TAG=$ID_TAG -v NAME_TAG=$NAME_TAG '{
												
													
													if($3 !~ /region/ && $3 !~ /ource/ && $1 == REP)
													{	
														ACC=$1
														TAG=$3
														LEN=$5-$4
														DIR=$7
												
														y=split($9, ar, ";")
														LC="-"
														GENE="-"
														PROD="-"
														ID="-"
														NAME="-"
														for(i=0; i < y+1; i++)
														{
															split(ar[i], pr, "=")
								
															if(pr[1]==LOCUS_TAG)
																LC=pr[2] 
															if(pr[1]==GENE_TAG)
																GENE=pr[2] 
															if(pr[1]==PROD_TAG)
																PROD=pr[2] 
															if(pr[1]==ID_TAG)
																ID=pr[2] 
															if(pr[1]==NAME_TAG)
																NAME=pr[2] 
														}
																								
														F_INFO="type="TAG";full_tag="TAG":"LC":"GENE":"PROD":"ID":"NAME":"LEN":"DIR":end"
														print F_INFO
													}
									

											}' | sort | uniq -c | sort | awk '{if($1 > 1) print $0}'`
											
			NUM_NONUNIQ=`echo $NON_UNIQ | wc -w`
			if [ $NUM_NONUNIQ -gt 0 ];then
				echo "***************************************"
				echo "FAILURE: non-unique enteries for $REP in file $GFF_FILE "
				echo $NON_UNIQ
				echo "***************************************"
				EXIT="Y"
			else
				echo "***************************************"
				echo "SUCCESS: no non-unique enteries for $REP in file $GFF_FILE"
				echo "***************************************"
				
			fi
		done								
	

	done 
	if [ $ALL_GFF_FOUND == "N" ];then
		echo "***************************************"
		echo "FAILURE: No or multiple fna accessions found the following accessions:"
		echo $MULT_ACC
		echo "In the following file:"
		echo $GFF_FILE
		echo "Please fix before proceeding"
		echo "***************************************"
	else
		echo "***********************************"
		echo "SUCCESS: 1 fna accession found for all gff accessions"
		echo "***********************************"
	fi		

	if [ $EXIT == "Y" ];then
		echo "***************************************"
		echo "FAILURE: non-unique gff annotations found"
		echo "Please fix before proceeding"
		echo "***************************************"
	else
		echo "***********************************"
		echo "SUCCESS: No non-unique gff annotations found"
		echo "***********************************"
	fi		

fi

echo "ALL_REFS:" $ALL_REFS

if [ $PARSE == "Y" ] || [ $PARSE == "O" ];then
	echo "Parsing all reference files in $REF_DIR and writing them out to $DATA_DIR ..."
	for REF in $ALL_REFS
	do
		GFF_LINES=`cat $DATA_DIR"/"*$REF*"_ALL.gff" | wc -l`
		FNA_FILE=$DATA_DIR"/"*$REF*"fna"
		
		ls -lrt $FNA_FILE
		echo "GFF_LINES:" $GFF_LINES
		
		if [ $GFF_LINES -lt 500 ] || [ ! -s $FNA_FILE ] || [ $PARSE == "O" ];then
			echo "Moving all files from $REF_DIR to $DATA_DIR"
			cp $REF_DIR* $DATA_DIR
			ls -lrt $DATA_DIR
			JOBS_LAUNCHED="Y"
			echo $REF
			echo "Running $GFFPARSE_SCRIPT for $REF"
			echo "sh $GFFPARSE_SCRIPT $REF_DIR $DATA_DIR $TEMP_DIR $REF $@" > $TEMP_FILE
			cat $TEMP_FILE
			qsub $TEMP_FILE >> $SEG_FILE					

		else 
			echo "Parsed GFF file found for $REF"
			ls -lrt $DATA_DIR"/"*$REF*"_ALL.gff"

		fi
	done
	
	if [ $JOBS_LAUNCHED == "Y" ];then
		echo "Jobs submitted - waiting for them to complete...."

		echo $SEG_FILE
		qstat

		###testing that all jobs launched are finished
		SGE_test $SEG_FILE	
		echo "All Jobs completed...."
	fi
fi

### change permissions for Results and temp dirs
change_perms $PARSE_DIR $DATA_DIR $TEMP_DIR

 