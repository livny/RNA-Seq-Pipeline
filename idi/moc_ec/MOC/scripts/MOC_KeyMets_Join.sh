#!/bin/sh

MOC_ID=$1
shift

# get path of the current file. if the file path is relative, convert it to absolute path
file_path="${BASH_SOURCE[0]}"
if [[ $file_path != /* ]]; then
  file_path="$PWD/${BASH_SOURCE[0]}"
fi

PROJECT_ROOT_DIR="$(dirname $(dirname $(dirname $(dirname $(dirname $file_path)))))"

# get parent directory
scripts_dir="$(dirname $file_path)"

### source all functions 
source "$scripts_dir/MOC_functions.sh"

### determining paths and headers 
### default config file is /idi/moc_ec/MOC/config_files/PC_config.yaml
paths_and_headers $MOC_ID $@

### run path_suff function to set RESPATH_SUFF.
##	If -moc_id N included in command line, do not moc_ID to RESPATH_SUFF.  
##	If -user_id included with Y or no string add USID to RESPATH_SUFF.  
##	If -user_id followed by userID, add userID to RESPATH_SUFF.

path_suff $MOC_ID $@
echo $RESPATH_SUFF

USID=`USID`

QUERY_HEADER="Sample"
KEY_HEADER="Sample_ID"

# CONFIG_FILE=`extract_option -conf "/idi/moc_ec/MOC/config_files/PC_config.yaml" 1 $@`
DEFAULT_CONFIG_PATH="$(dirname $(dirname $file_path))"/config_files/PC_config.yaml
CONFIG_FILE=`extract_option -conf $DEFAULT_CONFIG_PATH 1 $@`
if [[ $CONFIG_FILE != /* ]]; then
  CONFIG_FILE="$PROJECT_ROOT_DIR/$CONFIG_FILE"
fi

USERID_OPT=`extract_option -USER_ID N 1 $@`
MOCID_OPT=`extract_option -MOC_ID Y 1 $@`
KEY_DIR=`config_read $CONFIG_FILE Key_base`
RESULTS_PATH=`config_read $CONFIG_FILE Results_path`
TEMP_PATH=`config_read $CONFIG_FILE Temp_path`
JOIN_PATH=`config_read $CONFIG_FILE join_path`

TEMP_DIR=$TEMP_PATH"/"$RESPATH_SUFF"/"
JOIN_DIR=$JOIN_PATH$RESPATH_SUFF"/"$MOC_ID"/"

echo "JOIN_DIR: $JOIN_DIR"

mkdir -p $JOIN_DIR
mkdir -p $TEMP_DIR


TEMP_KEY_FILE=$TEMP_DIR"/"$MOC_ID"_key_temp.txt"

cat $KEY_FILE | sed 's/ /_/g' | grep -v "###" | sed 's/\"//g' | sed 1d > $TEMP_KEY_FILE

ls -lrt $KEY_FILE 

SID_HNAME=`config_read $CONFIG_FILE ID`
BREF_HNAME=`config_read $CONFIG_FILE Ref_accession`
PID_HNAME=`config_read $CONFIG_FILE Proj`
END_HNAME=`config_read $CONFIG_FILE Key_end`
P7_HNAME=`config_read $CONFIG_FILE P7`
P5_HNAME=`config_read $CONFIG_FILE P5`
BC_HNAME=`config_read $CONFIG_FILE bc`

KEY_F=`FIELD_HEADER $KEY_FILE $SID_HNAME`
KEY_REF_F=`FIELD_HEADER $KEY_FILE $BREF_HNAME`
KEY_PID_F=`FIELD_HEADER $KEY_FILE $PID_HNAME`
PATH_F=`FIELD_HEADER $KEY_FILE $END_HNAME`
INDEX1_F=`FIELD_HEADER $KEY_FILE $P7_HNAME`
INDEX2_F=`FIELD_HEADER $KEY_FILE $P5_HNAME`
BC_F=`FIELD_HEADER $KEY_FILE $BC_HNAME`

echo "PATH_F:$PATH_F"
echo "END_HNAME:$END_HNAME"

typeset -i NL
typeset -i i

NL=`cat $TEMP_KEY_FILE | wc -l`
p=1

LAST_PROJID="-"

echo $NL


while [ $p -le $NL ]
do
	
	KEY_SAMPID=`cat $TEMP_KEY_FILE | awk -F"\t" -v p=$p '{
														if(NR==p)
														{
															if($'$KEY_F' != "")
																print $'$KEY_F'
															if($'$KEY_F' == "")
																print ""
														}
													}'`
	
	KEY_REF=`cat $TEMP_KEY_FILE  | awk -F"\t" -v p=$p '{
													if(NR==p)
													if($'$KEY_REF_F' ~ /;/)
													{
														split($'$KEY_REF_F', ar, ";")
														print ar[2]
													}
													else
														print $'$KEY_REF_F'
												}' | head -1 | sed 's/All_//g'`	
	

	KEY_PROJID=`cat $TEMP_KEY_FILE | awk -F"\t" -v p=$p '{
														if(NR==p)
															print $'$KEY_PID_F'
													}' | head -1 | sed 's/_combined//g'`
													#}' | head -1 | sed 's/_combined//g'`
	KEY_INDEX1=`cat $TEMP_KEY_FILE | awk -F"\t" -v p=$p '{
														if(NR==p)
															print $'$INDEX1_F'
													}' | head -1`
	
	KEY_INDEX2=`cat $TEMP_KEY_FILE | awk -F"\t" -v p=$p '{
													if(NR==p)
														print $'$INDEX2_F'
												}' | head -1`
																		
	KEY_BC=`cat $TEMP_KEY_FILE | awk -F"\t" -v p=$p '{
													if(NR==p)
														print $'$BC_F'
												}' | head -1`
	
	echo $KEY_SAMPID, $KEY_PROJID, $KEY_BC

	#echo $KEY_PROJID
	if [ $KEY_SAMPID != "" ];then
		

		echo $KEY_SAMPID
		echo $KEY_REF
		RESULTS_DIR=$RESULTS_PATH"/"$RESPATH_SUFF"/"$KEY_PROJID"/"

		METRICS_FILE=$RESULTS_DIR"/"$KEY_PROJID"_metrics.txt"
		
		ls -lrt $METRICS_FILE
		
		
		JOIN_FILE=$JOIN_DIR"/"$KEY_PROJID"_KeyMetrics.txt"
		BC_FILE=$RESULTS_DIR"/"$KEY_PROJID"_bcLogfile.txt"
		
		ls -lrt $BC_FILE
																
		if [ $LAST_PROJID != $KEY_PROJID ] || [ $p == 1 ];then
			NEW_PROJ="Y"
		else			
			NEW_PROJ="N"
		fi
			
		if [ $NEW_PROJ == "Y" ];then
# 			echo $NEW_PROJ
# 			echo $KEY_PROJID
# 			echo $LAST_PROJID

			cat $KEY_FILE | grep -v "###" | head -1 | awk -F"\t"  '{ 				
																							for(i=1; i < '$PATH_F'; i++) 
																								printf "%s\t", $i
	
																				}' > $JOIN_FILE
			if [ -s $BC_FILE ];then
				printf "Pcnt_bc_in_pool\tNum_bc_reads\t"	>> $JOIN_FILE																		
			fi
			
			echo $JOIN_FILE																	
		fi
	
		LAST_PROJID=$KEY_PROJID
			
		if [ -s $METRICS_FILE ];then
			QUERY_F=`FIELD_HEADER $METRICS_FILE $QUERY_HEADER`
			MET_REP_F=`FIELD_HEADER $METRICS_FILE "For_replicon..."`
			#ALL=`cat $METRICS_FILE | grep $KEY_REF | sed 's/_combined//' | awk -F"\t" -v KEY_SAMPID=$KEY_SAMPID -v QUERY_F=$QUERY_F -v KEY_REF=$KEY_REF '{if($QUERY_F==KEY_SAMPID"_"KEY_REF)print $'$MET_REP_F'}' | grep "ALL" | wc -l`		
			ALL=`cat $METRICS_FILE | grep $KEY_REF | awk -F"\t" -v KEY_SAMPID=$KEY_SAMPID -v QUERY_F=$QUERY_F -v KEY_REF=$KEY_REF '{if($QUERY_F==KEY_SAMPID"_"KEY_REF)print $'$MET_REP_F'}' | grep "ALL" | wc -l`		
			echo "ALL: "$ALL
			echo "MET_REP_F: "$MET_REP_F
			echo "QUERY_F: "$QUERY_F

		fi

		if [ $NEW_PROJ == "Y" ] && [ -s $METRICS_FILE ];then
		
			echo "Adding metrics to $JOIN_FILE"
			cat $METRICS_FILE | grep -v "#" | head -1 | awk -F"\t" -v p=$p -v KEY_F=$KEY_F '{ 				
								for(i=1; i < NF+1; i++) 
									printf "%s\t", $i
					}' >> $JOIN_FILE
			
				
		fi
		
		printf "\n"	>> $JOIN_FILE																		
	
		cat $KEY_FILE | grep -v "###" | sed 1d | sed 's/ /_/g' | awk -F"\t" -v p=$p '{
			
				if(NR==p)
				{
					for(i=1; i < '$PATH_F'; i++) 
						printf "%s\t", $i
				}
			}' >> $JOIN_FILE

		
		if [ -s $BC_FILE ];then
			
			DUAL=`cat $BC_FILE | head -1 | awk '{y=split($NF, ar, "_"); if(y>1)print "Y";if(y==1)print "N"}'`

			echo $DUAL
			
			if [ $DUAL=="Y" ];then
			
				KEY_INDEX=$KEY_INDEX1"_"$KEY_INDEX2
			else
				KEY_INDEX=$KEY_INDEX1
			fi
				
			echo $KEY_INDEX
			echo $KEY_BC
			
			
			#cat $BC_FILE | grep -v "#" | sed 's/_combined//' | awk -F"\t" -v p=$p -v KEY_INDEX=$KEY_INDEX -v KEY_BC=$KEY_BC -v ALL=$ALL '{
			cat $BC_FILE | grep -v "#"  | awk -F"\t" -v p=$p -v KEY_INDEX=$KEY_INDEX -v KEY_BC=$KEY_BC -v ALL=$ALL '{
								
								if(NR==1)
								{
									pcnt_bc=0
									total=1
									for(i=1; i < NF+1; i++)
										if(KEY_INDEX==$i)
											COL=i
								}
								if(KEY_BC==$1)
									pcnt_bc=$COL
								if($1=="Total_Reads:")
								{	
									total=$COL
									printf "%s\t%i\t", pcnt_bc, (pcnt_bc/100)*total
								}
					}' >> $JOIN_FILE
		fi

		if [ -s $METRICS_FILE ];then

			#cat $METRICS_FILE | grep -v "#" | grep $KEY_REF | sed 's/_combined//' | awk -F"\t" -v p=$p -v KEY_REF=$KEY_REF -v KEY_SAMPID=$KEY_SAMPID -v QUERY_F=$QUERY_F -v ALL=$ALL '{
			cat $METRICS_FILE | grep -v "#" | grep $KEY_REF  | awk -F"\t" -v p=$p -v KEY_REF=$KEY_REF -v KEY_SAMPID=$KEY_SAMPID -v QUERY_F=$QUERY_F -v ALL=$ALL '{
																								#print $0
																								if($QUERY_F==KEY_SAMPID"_"KEY_REF && (ALL=="0" || $'$MET_REP_F'=="ALL"))
																									for(i=1; i < NF+1; i++) 
																										printf "%s\t", $i
																							}' >> $JOIN_FILE
		fi
		printf "\n"	>> $JOIN_FILE																	

	fi
	
	cp $JOIN_FILE $RESULTS_DIR
	p=`expr $p + 1`
done

### change permissions for Results and temp dirs
change_perms $JOIN_DIR

echo $JOIN_FILE

