#!/bin/bash
set -e
set -u
set -o pipefail

HELP="
Shell script part of the seq_ID pipeline. Assumes pair end fastq files exist in the project directory within the subdirectroy /raw_reads/. 

Running in the project directory will strip the MiSeq set number (001) from the file name.
"

# Give user help with -h tag
if [[ "$1" == "-h" ]] ; then
  echo "$HELP"
  exit 0
fi

# Remove MiSeq set number from pair end file names
for i in ./"$1"/raw_reads/*.fastq.gz
do
  mv "$i" "${i/_001/}"
done

