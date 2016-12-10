#!/bin/bash
set -e
set -o pipefail

# database of H and O type genes 
database="/opt/genomes/seroTF_database/"
# serotypeFinder requires legacy blast
blast="/opt/software/blast-2.2.26/"


HELP="
Shell script of the seq_ID pipeline. Assumes E.coli assemblies exists in the project directory within the subdirecotires /ecoli_assemblies/<sample_name>/

Running in the project directory will serotype E.coli isolates using serotypeFinder. Serotype results will be located in a new direcotry, <project_dir>/serotypeFinder_output/<sample_name>. If no E.coli isolates exist in the project, serotypeFinder_output will be an empty directory.

Output from running ecoli_serotype.sh can be used to update <project_dir>/sample_id/raw.csv by running add_ecoli_serotype.sh

"

# Give user help with -h tag
if [[ "$1" == "-h" ]] ; then
  echo "$HELP"
  exit 0
fi


# Create list of samples identified as E.coli by MASH
ecoli_isoaltes="$(awk -F ';' '$2 ~ /Escherichia_coli/' ./sample_id/raw.csv | awk -F ';' '{print$1}')"

# Check to see if a serotypeFinder_output dir already exsits. If not, make one
if ls ./serotypeFinder_output/  1> /dev/null 2>&1; then
  echo "serotypeFinder output dir exists."  
else 
  mkdir serotypeFinder_output
fi

echo "Beginning E.coli serotyping with serotypeFinder. . ."
for i in $ecoli_isoaltes
do
  # Check if serotypeFinder output exists for each E.coli isolate; skip if so
  if ls ./serotypeFinder_output/${i}/results_table.txt  1> /dev/null 2>&1; then
    echo "Skipping ${i}. ${i} has already been serotyped with serotypeFinder."
  else
    # Run serotypeFinder for all Ecoli isolates and output to serotypeFinder_output/<sample_name>
    serotypefinder.pl -d $database -i ./ecoli_assemblies/${i}/contigs.fasta -b $blast  -o ./serotypeFinder_output/${i}/ -s ecoli -k 95.00 -l 0.60
  fi
done

# flag for makefile 
touch ./flag_files/seroTF.happened
