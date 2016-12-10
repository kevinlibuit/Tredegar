#!/bin/bash
set -e
set -o pipefail

HELP="
Shell script part of the seq_ID pipeline. Assumes ./sample_id/raw.csv exists in the project working directory. 

Running in the project directory will generate assemblies for isolates identified as E.coli by MASH. Assemblies will be located in a new direcotry, ecoli_assemblies/<sample_name>.

Output from running assemble_ecoli.sh can be used as input for serotyping by serotypeFinder by running ecoli_serotype.sh

"

# Give user help with -h tag
if [[ "$1" == "-h" ]] ; then
  echo "$HELP"
  exit 0
fi

# Get sample name of isolates identified as E.coli by MASH
ecoli_isolates="$(awk -F ";" '$2 ~ /Escherichia_col/' ./sample_id/raw.csv |awk -F ';' '{print$1}')"

# Assemble E.coli isolates
for i in $ecoli_isolates
do
  # Check if assembly already exists for each sample; skip if so" 
  if ls ./ecoli_assemblies/${i}/contigs.fasta 1> /dev/null 2>&1; then
    echo "${i} already assembled."
  else
    echo "$i being assempled by SPAdes"
    # Full path to pair end reads
    r1=./raw_reads/${i}_R1.fastq.gz
    r2=./raw_reads/${i}_R2.fastq.gz
    # Use SPAdes to generate assemblies 
    spades.py -1 $r1 -2 $r2 -o ./ecoli_assemblies/${i}/
  fi
done


# flag for makefile
touch ./flag_files/spades.happened 
