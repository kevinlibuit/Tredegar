#!/bin/bash
set -e
set -o pipefail

HELP="
Shell script part of the seq_ID pipeline. Assumes ./sample_id/ecoli.csv exists in the project working directory.

Running in the project directory will serotype Salmonella spp. isolates using SeqSero. Serotype results will be located in a new direcotry, <project_dir>/SeqSero_output/<sample_name>. If no Salmonella spp. isolates exist in the project, SeqSero_output will be an empty directory.

Output from running sal_serotype.sh can be used to update <project_dir>/sample_id/ecoli.csv by running add_sal_serotype.sh

"

#  Give user help with -h tag
if [[ "$1" == "-h" ]] ; then
  echo "$HELP"
  exit 0
fi

# Create list of samples identified as E.coli by MASH
sal_isolates="$(awk -F';' '$2 ~ /Salmonella/' ./sample_id/ecoli.csv | awk -F';' '{print$1}')"

echo "Beginning Salmonella spp. serotypeing. . ."
for i in $sal_isolates
do
  # Check if SeqSero output exists for each Salmonenlla spp. isolate; skip if so
  if ls ./SeqSero_output/${i}/Seqsero_result.txt 1> /dev/null 2>&1; then
    echo "Skipping ${i}. ${i} has already been serotyped with SeqSero."
  else
    # Run SeqSero for all Salmonella spp. isolates and output to SeqSero_output/<sample_name>"
    SeqSero.py -m2 -i ./raw_reads/${i}_R[1,2].fastq.gz
    mkdir -p ./SeqSero_output/$i
    mv ./SeqSero_result*/*.txt ./SeqSero_output/$i
    rm -rf ./SeqSero_result*
  fi
done

# flag for makefile
touch ./flag_files/seqsero.happened
