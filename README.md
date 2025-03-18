# RNA-Seq Pipeline

## Downloading and Installing the code

### If you are only going to run the pipeline

Download the code on to your $HOME folder in the Broad server
```bash
# go to your $HOME folder
cd 
# download the code
git clone https://github.com/livny/RNA-Seq-Pipeline.git
```

### If you are going to make changes to the pipeline

1. Setting up ssh on the Broad server

    Follow the instructions below to create an SSH key and connecting it to your GitHub account

    https://docs.github.com/en/authentication/connecting-to-github-with-ssh

    **Note**: 
    In step 2 of https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#adding-your-ssh-key-to-the-ssh-agent: 

    - If you are installing on the Broad server, choose not to add a passphrase to your key, and omit the UseKeychain line.
    - If you see a Bad configuration option: usekeychain error, add an additional line to the configuration's' Host *.github.com section.


2. Download the code on to your $HOME folder in the Broad server
    ```bash
    # go to your $HOME folder
    cd 
    # download the code
    git clone git@github.com:livny/RNA-Seq-Pipeline.git
    ```

## Making changes to the code

Once you finish making changes to the code, use the commands in the following order to push the changes online

1. ```git add --all```
2. ```git commit -m "Your commit message"```
3. ```git push origin main```

## Guidelines
### Acquiring a node on the Broad server
```bash
use UGER
ish
```

### Running commands
It is advised to run all commands from the project root directory, i.e., 

```bash
cd $HOME/RNA-Seq-Pipeline
```
### Running python files directly
Since the Broad server has moved away from providing support for Anaconda2, we have installed Anaconda2 locally on the server. To invoke its corresponding Python binary, please use ```/broad/IDP-Dx_work/hsethura/anaconda2-5.3.1/bin/python```

For example, to move the key file from Google drive to the server, the command would be as follows:

```/broad/IDP-Dx_work/hsethura/anaconda2-5.3.1/bin/python idi/moc_ec/MOC/RtS_pipeline/beta/quickstart.py -s 1fis9sp_KFV9yXpfItTo4qcJQd3Uox3BIRaQe_RE8Brg -t "Sample Information" -p SCR-0002.3 --Key_dir /idi/moc_ec/MOC/Key_files/```

### Relative paths

All relative paths mentioned below are with respect to $HOME/RNA-Seq-Pipeline

## Commands for running the pipeline in the background

**Note**: If you would like to run the pipeline in an interactive mode, invoke "MOC_RtS_pipe_v2.sh" instead of "QSUB_RtS_analysis_launch.sh"

**Running the pipeline with only bacterial analysis:**
```
sh idi/moc_ec/MOC/scripts/QSUB_RtS_analysis_launch.sh <MOC-ID> -user_id
```

**Running the pipeline with host and bacterial analysis:**
```
sh idi/moc_ec/MOC/scripts/QSUB_RtS_analysis_launch.sh <MOC-ID> -user_id :--do_host:
```

**Running the pipeline with only host analysis:**
```
sh idi/moc_ec/MOC/scripts/QSUB_RtS_analysis_launch.sh <MOC-ID> -user_id -move_ref N -do_host
```

**Running the pipeline on a subset of reads (100k in this example):**
```
sh idi/moc_ec/MOC/scripts/QSUB_RtS_analysis_launch.sh <MOC-ID> -user_id -test_pipe Y -num_test_reads 100000
```

**Running the pipeline with no fastqc, no adapter analysis, and no trimmomatic:**
```
sh idi/moc_ec/MOC/scripts/QSUB_RtS_analysis_launch.sh <MOC-ID> -user_id -bc_analysis N
```

**Running the pipeline with no fastqc, no adapter analysis but using trimmomatic:**
```
sh idi/moc_ec/MOC/scripts/QSUB_RtS_analysis_launch.sh <MOC-ID> -user_id -bc_analysis N -trimmomatic_sample Y
```

**Running the pipeline using bwa-mem for alignment:**

For DAB experiments, when the molecules are shorter (e.g. <150bp) than the sequencing size (e.g. 150bp on each end), we have noticed that the Read 2's are not mapped to the genome using the default aligner. This is because, after adapter trimming, R2 still contains the inline sequence due to read through. The default aligner (bwa align) uses the first 20bp as seeds to search for alignment, and this first 20bp of R2 almost always contains the inline sequence.
```
sh idi/moc_ec/MOC/scripts/QSUB_RtS_analysis_launch.sh <MOC-ID> -user_id :--bwa_mem:
```

**Running the pipeline for SCR projects:**

The only neccesary addition is the config file option. SCR project has a config named 'PC_config_BacDrop.yml' inside the config folder; this is different from the default config file used for RtS projects. If you are finding an error using this config file, provide an absolute path instead of a relative path to the file.
```
sh idi/moc_ec/MOC/scripts/QSUB_RtS_analysis_launch.sh <MOC-ID> -user_id -conf $HOME/RNA-Seq-Pipeline/idi/moc_ec/MOC/config_files/PC_config_BacDrop.yml
```

**Running the pipeline for fungal projects:**

Note that fungal is an eukaryote, so it is treated as a host in the pipeline.So, we need to provide options to the script that run the pipeline with aligning only to host.

In addition, we need to change the config file option. Fungal project has a config named 'PC_config_fungal.yaml' inside the config folder; this is different from the default config file used for RtS projects. If you are finding an error using this config file, provide an absolute path instead of a relative path to the file.
```
sh idi/moc_ec/MOC/scripts/QSUB_RtS_analysis_launch.sh <MOC-ID> -user_id -conf $HOME/RNA-Seq-Pipeline/idi/moc_ec/MOC/config_files/PC_config_fungal.yaml -move_ref N -do_host
```

**Running the pipeline for fungal SCR projects:**

We need to provide input as "fungal" in the Host_reference tab of the key file. The pipeline would align the reads to candida glabrata.

Note that fungal is an eukaryote, so it is treated as a host in the pipeline.So, we need to provide options to the script that run the pipeline with aligning only to host.

In addition, we need to change the config file option. SCR fungal project has a config named 'PC_config_fungal_BacDrop.yml' inside the config folder; this is different from the default config file used for RtS projects. If you are finding an error using this config file, provide an absolute path instead of a relative path to the file.

Sometime, in SCR projects, we have noticed errors trying to align reads to the host genome. The source of the error orignates to the pipeline unable to correctly parse the "Host_reference" tab in the Key file. This only happens to the SCR Key Files.
```
sh idi/moc_ec/MOC/scripts/QSUB_RtS_analysis_launch.sh <MOC-ID> -user_id -conf $HOME/RNA-Seq-Pipeline/idi/moc_ec/MOC/config_files/PC_config_fungal_BacDrop.yml -move_ref N -do_host
```

**Running the pipeline without split:**
```
sh idi/moc_ec/MOC/scripts/QSUB_RtS_analysis_launch.sh <MOC-ID> -user_id -split N
```

**Running the pipeline without split and merge:**
```
sh idi/moc_ec/MOC/scripts/QSUB_RtS_analysis_launch.sh <MOC-ID> -user_id -split N -merge N
```

**Running the pipeline without split, merge, and align:**
```
sh idi/moc_ec/MOC/scripts/QSUB_RtS_analysis_launch.sh <MOC-ID> -user_id -split N -merge N -align N
```

**Running the pipeline without split, merge, align, and count:**
```
sh idi/moc_ec/MOC/scripts/QSUB_RtS_analysis_launch.sh <MOC-ID> -user_id -split N -merge N -align N -count N
```

## Advanced: Different options that can be provided to run the pipeline & Invoking scripts in the pipeline separately

### Add URL to the “WB_linking” sheet

Following completion of the MOCS-XXXX_Pool_Sub_WB, add it’s URL to the “WB_linking” sheet of [RtS MOCS DB](https://docs.google.com/spreadsheets/d/1WC8s_Y6uMbOCXNCQMIBWxBxglHOIo0HHlH5G51U7e1U/edit#gid=426292915) and insure the pools appear in the “MOCS DB” sheet.

### Moving data from walkup moc server

Once email is received indicating sequencing has been completed for a flowcell, move data from walkup moc server.  For this you will need the MOCS-ID and the flowcell ID, the latter can be found in the walkup email subject line.  Run the following command

```bash
sh idi/moc_ec/MOC/scripts/MOC_wu_move.sh <MOCS-ID> <FLOWCELL-ID>
```

**Example:**
```
sh idi/moc_ec/MOC/scripts/MOC_wu_move.sh MOCS-0004 H52G2DMXY	
```

**Command line options:**
```
-move_data: include if you want to move data from getsite.  (Default Y)
-conf: path to config file.  (Default $HOME/RNA-Seq-Pipeline/idi/moc_ec/MOC/config_files/PC_config.yaml)
-metrics: run metrics script (Default Y)
-raw_seq_path: the target location for the data (Defaults path designated by “Seq_base:” in the config file)
```

All files will be generated in a directory named MOCSID (with hyphen removed) in the path designated by “Seq_base:” in the config file (/idi/moc_ec/RawSeq_data/RtS/ in default config) or -raw_seq_path 

Metrics file will be emailed to you and copied into the seq dir.

> **Note:** Usually there must be the same number of files per lane in the metrics file. If there are uneven read counts among each lane it may mean an incomplete download.  Repeat and review the submission (i.e. check that there weren’t different pools submitted for each lane). Contact Tammy (tamason@broadinstitute.org) and report the error.

**Example of an incomplete download:**
```FC: H2527BGX9
LANE 1: 168
LANE 2: 168
LANE 3: 78
LANE 4: 42
```

**Example of a complete download:**
```
FC: H2J32BGX9
LANE 1: 168
LANE 2: 168
LANE 3: 168
LANE 4: 168
```


This script runs another script that sets symlinks for all of the projects.  If there are changes to the MOCS spreadsheet this needs to be rerun to correct the symlinks

```
sh idi/moc_ec/MOC/scripts/MOCS_move.sh -limit <MOCS_ID>
```

### Review the metrics file. 

Verify that all flowcells and all lanes generated sufficient read numbers:

**Expected output:**
```
NextSeq: >400M reads total, >80%matched to an index, even coverage across 4 lanes
```

If total reads or “orphan” rates are significantly lower or higher, respectively than indicated above, look to see if there are a high % of unmatched reads aligning to known index sequences.  If the data are dual barcoded, run the following script to look for P7 and P5 pairs enriched in the unmatched reads:

```
sh idi/moc_ec/MOC/scripts/dual_orphan_find.sh <path to *1.unmatched.barcode_1.fastq.gz>
```

Contact Jonathan to get input on possible reasons for these discrepancies and discuss the possible need to contact the walkup team for resequencing/redemultiplexing.

### Copy paste file contents into “MOCS metrics”

Copy paste file contents into “MOCS metrics” sheet of MOCS WB (you may need to “split text to column” in Data scroll down menu) to compare output to target depth

### Launching analysis pipeline

Launch analysis pipeline with the following command:
```
sh idi/moc_ec/MOC/scripts/MOC_RtS_pipe_v2.sh <MOC-ID> -user_id [script options] :[pipeline options]:
```

**Example:**
```
sh idi/moc_ec/MOC/scripts/MOC_RtS_pipe_v2.sh MOCP-0035 -user_id 

sh idi/moc_ec/MOC/scripts/MOC_RtS_pipe_v2.sh MOCP-0001 -user_id -move_key N :--no_split --no_merge --no_align:
```

**Script options (see script for full list)**
```
# -conf: sets path to config file (default idi/moc_ec/MOC/config_files/PC_config.yaml)
# -q: sets name of header for Q_VAL (default MOC-ID)
# -move_key: setting to N skips moving google sheet to server (default Y)
# -use_p7: indicates fastq file is demultiplexed by P7 index (default Y)
# -use_p5: indicates fastq file is demulitplexed by P5 index (default N)
# -no_pipe: including or setting to Y skips running pipeline (default N)
# -qsub: run pipeline in UGER (default N)
# -gid: enter google ID if missing from DB (default 0 => get it from DB)
# -smocid: enter smocid if missing from DB (default 0 => get it from DB)
# -import_gs: updates DBs from google drive on server (default Y)
# -user_id: add userID to temp and results paths (default N.  If Y, add login name, if value added after option that userID will be added)
# -moc_id: add MOC-ID to temp and results paths (default Y)
# -move_ref: move reference files from Gdrive/server to ref directory  (default Y)
# -raw_seq_path: path to raw data (overrides path in config file) * remember to include the terminal “/”
# -symlink: path to directory where symlinks to raw data are located
# -key_sheet: name of sheet in key file to be used by pipeline (default "Sample_Information")
# -split:  split fastqs by inline barcode (default Y)
# -merge:  merge split fastqs (default Y)
# -align:  align merged fastqs to reference (default Y)
# -count:  count reads per features from aligned bams (default Y)
# -fastqc: fastqc on the raw files. Fastqc files are written to $MOC_SYM_DIR\analysis\fastqc (default Y)
# -fastqc_sample: fastqc on the sample-level files. Fastqc files are written to $MERGE_DIR\analysis\fastqc (default Y)
# -adapter_analysis: Adapter analysis on read 2 of the raw files. Adapter analysis files are written to $MOC_SYM_DIR\analysis\adapter_analysis (default Y)
# -adapter_analysis_sample: Adapter analysis on read 2 of the sample-level files. Adapter analysis files are written to $MERGE_DIR\analysis\adapter_analysis (default Y)
# -trimmomatic: Adapter trimming using Trimmomatic. Trimmomatic files are written to $MOC_SYM_DIR\analysis\trimmomatic (default N)
# -trimmomatic_sample: Adapter trimming using Trimmomatic. Trimmomatic files are written to $MERGE_DIR\analysis\trimmomatic_sample (default Y)
```

**Pipeline options**
The default pipeline options are the following:
```
 --ADD3 30 --ADD5 20 --remove_splitted --do_patho --MOC_id_ref $MOC_ID
 ```

> **Note**: If you’d like to add these options to the default options them enter :<other options> on command line.  If you want to override them with other option enter :<other options --no_def_opt>: MAKE SURE TO INCLUDE “:” ON EITHER SIDE OF THESE OPTIONS. 

One key option is --MOC_id_ref.  Use this followed by the MOC-ID when moving ref files from GDrive using GDrive_fetch.sh.
 
Other commonly used pipeline options are described [here](https://docs.google.com/document/d/1BiWyl7-nz7QPbAwAXIZiKD6HeLVVTNlieBTQCU_nynE/edit).

If you have an error indicating authentication issues (if the word json appears in the error output) follow these [instructions](https://docs.google.com/document/d/16sVTq8PN4Er8E2GUUp2jTWSsalV8IWlhyD0lXtWrJXw/edit)

**Launching analysis pipeline using UGER**

If you want to launch the pipeline through UGER, use the following command:
```
 sh idi/moc_ec/MOC/scripts/QSUB_RtS_analysis_launch.sh <MOC-ID> [script options] :[pipeline options]:
```

Uses same options as regular script.  Creates a directory $RESULTS_PATH”/UGER/” into which the UGER err and out files appended with a timestamp are written.


If you have resequenced some of the samples and want to merge the old and new data, add the information for the redo samples to the key and give the samples their original sample ID appended by “_add”.  Then after downloading the data from both seq runs run this in lieu of the normal pipeline:

```
sh idi/moc_ec/MOC/scripts/redo_merge_RtS.sh <MOC-ID> [script options]
```

> **NOTE**: The sequences of inline barcodes are here:

```
/broad/idi/moc_ec/MOC/files/rts_bcs.txt

/broad/idi/moc_ec/MOC/files/scr_bcs.txt
```
If changed ensure no blank lines at the end of the file

### Running the pipeline to get only split metrics

If you’re just splitting and merging and want split metrics, run the following command:
```
sh idi/moc_ec/MOC/scripts/Split_distribution_metrics.sh MOC-XXX
```

If someone else ran the initial split and merged, add the following option:
-uid <userid of person who ran the pipeline>

### Running DESeq2

As long as CG_IDs and CG_pairs are filled in in the key file, DESeq2 and edgeR will be automatically launched.  If you want to launch these independently use the following command:

```
sh idi/moc_ec/MOC/scripts/Key_DE_launch2.sh <MOC-ID>
```

By default, this will look for files in the results and temp paths in the config file WITHOUT the userID and WITH the MOC ID.  To change this use the -moc_id and -user_id options.  For example:

```
sh idi/moc_ec/MOC/scripts/Key_DE_launch2.sh <MOC-ID> -user_id -moc_id N
```

...will append your userID and not a MOC-ID

## Data Interpretation

A guide for interpreting data from the pipeline can be found [here](https://docs.google.com/document/d/1FXtmN9AWRTp3VoGEgodAb9QddS0Uyz6R/edit)

## Data Transfer

To share data with collaborators, run the following command 

```
sh idi/moc_ec/MOC/scripts/MOC_data_transfer2.sh <MOC-ID>
```
	
**Options:**
```
# -fastq: include fastq files along with bams in Aspera (default N)
# -internal: is this an internal or external project (default whatever is in DB)
# -import_gs: import databases (default N)
# -import_key: import key file (default N)
# -user_id: add if analysis was run with this option.  
```

This should create a directory in Transfer_path (/broad/hptmp/MOC/transfer/MOC) to which the user guide will be added.  All result files, DE directory, and user guide will be moved to a results directory in the MOC-ID directory of the gdrive that contains the key and ref files.  If an internal project, you should get an email you can forward to the collaborator telling them where the data live on the server.  If an external project, you should get an email with an attached manifest and instructions that you can use to set up an Aspera site [here](https://transfer.broadinstitute.org/auth/login).  Once the site is set up you can forward that email to the collaborator. 

Once you’ve sent the email(s), enter the date in the “Data DB” sheet in the [MOC Production DB](https://docs.google.com/spreadsheets/d/1tF0Cc6CwbT_bS3JLKIFGA3oPK9IBqjilyu3gtgmYDas/edit#gid=290518403)

## Location of pipeline results
Example links are provided for RtS project MOCP-0108. Replace RtS with SCR if needed and MOCP-0108 with your project name.

### Data from Walkup
```/idi/moc_ec/RawSeq_data/Walkup/```

### Symlink files to data from Walkup
RtS: ```/idi/moc_ec/RawSeq_data/RtS/SymLinks/MOCP-0108```

SCR: ```/idi/moc_ec/RawSeq_data/SCR/SymLinks/SCR-0015.1```

### Pool-level QC outputs
An 'analysis' folder is created where the pool-level raw sequences are located. 

Analysis folder: ```/idi/moc_ec/RawSeq_data/RtS/SymLinks/MOCP-0108/analysis```

Adapter-analysis charts: ```/idi/moc_ec/RawSeq_data/RtS/SymLinks/MOCP-0108/analysis/adapter_analysis/```

Fastqc files: ```/idi/moc_ec/RawSeq_data/RtS/SymLinks/MOCP-0108/analysis/fastqc/```

Trimmomatic files: ```/idi/moc_ec/RawSeq_data/RtS/SymLinks/MOCP-0108/analysis/trimmomatic/```

> **Note**: If the -test_pipe option was used to run the pipeline, then the analysis folder would be created where the test reads are generated.

Analysis folder: ```/broad/hptmp/RNASeq_proj/MOC/hsethura/MOCP-0108/intracellular_Saureus/pipe_test/analysis```

Adapter-analysis charts: ```/broad/hptmp/RNASeq_proj/MOC/hsethura/MOCP-0108/intracellular_Saureus/pipe_test/analysis/adapter_analysis```

Fastqc files: ```/broad/hptmp/RNASeq_proj/MOC/hsethura/MOCP-0108/intracellular_Saureus/pipe_test/analysis/fastqc```

Trimmomatic files: ```/broad/hptmp/RNASeq_proj/MOC/hsethura/MOCP-0108/intracellular_Saureus/pipe_test/analysis/trimmomatic```


### Sample-level QC outputs (Temporary storage)
An 'analysis' folder is created inside the mergedir. 

Analysis folder: ```/broad/hptmp/RNASeq_proj/MOC/hsethura/MOCP-0108/intracellular_Saureus/merge_dir/analysis```

Adapter-analysis charts: ```/broad/hptmp/RNASeq_proj/MOC/hsethura/MOCP-0108/intracellular_Saureus/merge_dir/analysis/adapter_analysis```

Fastqc files: ```/broad/hptmp/RNASeq_proj/MOC/hsethura/MOCP-0108/intracellular_Saureus/merge_dir/analysis/fastqc```

Trimmomatic files: ```/broad/hptmp/RNASeq_proj/MOC/hsethura/MOCP-0108/intracellular_Saureus/merge_dir/analysis/trimmomatic```

### Pipeline intermediate outputs (Temporary storage)

Files split by all possible barcodes: ```/broad/hptmp/RNASeq_proj/MOC/hsethura/MOCP-0108/intracellular_Saureus/splitdir```

Sample-level files: ```/broad/hptmp/RNASeq_proj/MOC/hsethura/MOCP-0108/intracellular_Saureus/mergedir```

Pathogen alignment and count files: ```/broad/hptmp/RNASeq_proj/MOC/hsethura/MOCP-0108/intracellular_Saureus/patho_result```

Host alignment and count files: ```/broad/hptmp/RNASeq_proj/MOC/hsethura/MOCP-0108/intracellular_Saureus/host_result```

### Final results

Host and pathogen metrics, key metrics, pool-wise metrics, and gene-level count files: ```/idi/moc_ec/RNASeq_results/MOC/hsethura/MOCP-0108/intracellular_Saureus/```

DE outputs: ```/idi/moc_ec/RNASeq_results/MOC/hsethura/MOCP-0108/intracellular_Saureus/DE```

bam and tdf files: ```/idi/moc_ec/idpweb/data/MOC/hsethura/MOCP-0108/intracellular_Saureus/```

## Adding a new eukaryotic organism

Here I am adding a new fungal organism (candida albicans). 
### Adding data 
- Copy assembly and annotation files to `/home/unix/hsethura/fungal/ncbi_dataset/data/`. You should have the .gff and .fna file. I have these files inside `/home/unix/hsethura/fungal/ncbi_dataset/data/GCF_000182965.3` 

### Building BBMap Index
```
/home/unix/hsethura/RNA-Seq-Pipeline/broad/IDP-Dx_work/nirmalya/local/bin/bbmap.sh -Xmx30g ambiguous=random ref=/home/unix/hsethura/fungal/data/candida_albicans_SC5314.fna path=/home/unix/hsethura/fungal/BBMap/candida_albicans_SC5314
```

### Generating transcript gene mapping file
- Look at `generate_fungal_ann_and_sequences.ipynb` file and modify as needed. Make sure to have
```
output_fasta = 'data/candida_albicans_SC5314.fna'
output_mapping = 'data/candida_albicans_SC5314_transcript_gene.txt'
```


### Changes to the config file (PC_config_fungal.yaml)
- Modify `host_dbpath: /home/unix/hsethura/fungal/` to specify where the data would be stored
- Add the line `candida_albicans_ref_str: candida_albicans_SC5314`. `candida_albicans_SC5314` is the reference name to be specified in the key file. `candida_albicans_ref_str` would be internally referred in the pipeline scipts.
- Add the line `candida_albicans_SC5314_transcript_gene: /home/unix/hsethura/fungal/data/candida_albicans_SC5314_transcript_gene.txt`

### Changes to /Users/hsethura/home/RNA-Seq-Pipeline/idi/moc_ec/MOC/RtS_pipeline/beta/lib/alignerbbmap.py
- Delete alignerbbmap.pyc file
- To `__init__` function, add
```
elif re.search('candida_albicans_SC5314', l_host_str, re.IGNORECASE):
    self.host_transcript_gene = cldict.candida_albicans_SC5314_transcript_gene
```
- To `get_host_fna_path` function, add 
```
elif re.search('candida_albicans_SC5314', l_host_str, re.IGNORECASE):
    self.host_ref_str = cldict.candida_albicans_ref_str
```
- To `get_host_ref_path` function, add
```
elif re.search('candida_albicans_SC5314', l_host_str, re.IGNORECASE):
    self.host_ref_str = cldict.candida_albicans_ref_str
```

### Changes to /Users/hsethura/home/RNA-Seq-Pipeline/idi/moc_ec/MOC/RtS_pipeline/beta/lib/confdict.py
- Delete confdict.pyc
- To `storeConfigFromKeyTbl` function, add
```
elif re.search('candida_albicans_SC5314', l_host_str, re.IGNORECASE):
    self.host_ref_str = self.candida_albicans_ref_str
    self.host_transcript_gene = self.candida_albicans_SC5314_transcript_gene
```
- To `storeConfigFromConfig` function, add
```
self.candida_albicans_ref_str = self.get_from_mydict('candida_albicans_ref_str')
self.candida_albicans_SC5314_transcript_gene = self.get_from_mydict('candida_albicans_SC5314_transcript_gene')
```

test
