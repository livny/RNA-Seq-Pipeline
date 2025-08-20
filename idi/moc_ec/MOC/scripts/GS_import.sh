#!/bin/sh

# source /idi/moc_ec/MOC/scripts/bash_header


### source all functions 
# source "/idi/moc_ec/MOC/scripts/MOC_functions.sh"

# get path of the current file. if the file path is relative, convert it to absolute path
file_path="${BASH_SOURCE[0]}"
if [[ $file_path != /* ]]; then
  file_path="$PWD/${BASH_SOURCE[0]}"
fi

# get parent directory
scripts_dir="$(dirname $file_path)"

# source /idi/moc_ec/MOC/scripts/bash_header
source "$scripts_dir/bash_header"

### source all functions 
# source "/idi/moc_ec/MOC/scripts/MOC_functions.sh"
source "$scripts_dir/MOC_functions.sh"

  
### determining paths and headers 
### default config file is /broad/IDP-Dx_storage/MOC/config_files/Universal_config.yaml
paths_and_headers $MOC_ID $@

mkdir -p $SUB_DIR
mkdir -p $POOL_DIR
mkdir -p $MOCDB_DIR
mkdir -p $MOCSDB_DIR
mkdir -p $PCDB_DIR
mkdir -p $PCQ_DIR

MAX_SUB=2
MAX_POOL=2
MAX_DB=2

DSTAMP=`date +%s`

keep_max_files ()
{
	DIR=$1
	MAX=$2

	top=`ls -lrt $DIR | grep -v total | wc -l | awk -v max=$MAX '{print $1-max}'`

	echo $top

	rm_files=`ls -lrt $DIR/* | grep -v total | head -$top | awk '{print $9}'`

	echo -f $rm_files
	rm -f $rm_files

	ls -lrt $DIR*
}

#$SCRIPTS_DIR"GS_import.py" -s $SP_GID -t "BETA submission log" -p $DSTAMP --Key_dir $SUB_DIR -S $SUB_SUFF
#$SCRIPTS_DIR"GS_import.py" -s $SP_GID -t "BETA pooling log" -p $DSTAMP --Key_dir $POOL_DIR -S $POOL_SUFF
#$SCRIPTS_DIR"GS_import.py" -s $DB_GID -t "MOC Project Database" -p $DSTAMP --Key_dir $MOCDB_DIR -S $MOCDB_SUFF
echo "$scripts_dir/"GS_import.py" -s $MOCS_GID -t "MOCS DB" -p $DSTAMP --Key_dir $MOCSDB_DIR -S $MOCSDB_SUFF"
$scripts_dir"/GS_import.py" -s $MOCS_GID -t "MOCS DB" -p $DSTAMP --Key_dir $MOCSDB_DIR -S $MOCSDB_SUFF
echo "$scripts_dir/"GS_import.py" -s $PC_GID -t "Production Database" -p $DSTAMP --Key_dir $PCDB_DIR -S $PCDB_SUFF"
$scripts_dir"/GS_import.py" -s $PC_GID -t "Production Database" -p $DSTAMP --Key_dir $PCDB_DIR -S $PCDB_SUFF
echo "$scripts_dir/"GS_import.py" -s $PC_GID -t "Production Quote DB" -p $DSTAMP --Key_dir $PCQ_DIR -S $PCQ_SUFF"
$scripts_dir"/GS_import.py" -s $PC_GID -t "Production Quote DB" -p $DSTAMP --Key_dir $PCQ_DIR -S $PCQ_SUFF

change_perms $SUB_DIR $POOL_DIR $MOCDB_DIR $PCDB_DIR

# keep_max_files $SUB_DIR $MAX_SUB
# keep_max_files $POOL_DIR $MAX_POOL
# keep_max_files $MOCDB_DIR $MAX_DB
# keep_max_files $RTSDB_DIR $MAX_SUB
keep_max_files $MOCSDB_DIR $MAX_DB
keep_max_files $PCDB_DIR $MAX_DB
keep_max_files $PCQ_DIR $MAX_DB