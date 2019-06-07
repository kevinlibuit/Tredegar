#!/bin/bash
set -e
set -o pipefail

HELP="
Shell script part of the Tredegar piepeline. Assumes E.coli isolates have been serotyped with serotypeFinder and results exist in the proect directroy within the subdirectories /serotypeFinder_output/<sample_name>/ 

Running in the project directory will parse through serotypeFinder output to update <projecti_dir>/sample_id/raw.csv. The updated file will be renamed to <project_dir>/sample_id/ecoli.csv. If no E.coli isoaltes exist in the current project, <projecti_dir>/sample_id/raw.csv and <projecti_dir>/sample_id/ecoli.csv will be identical. 
"

# Give user help with -h tag
if [[ "$1" == "-h" ]] ; then
  echo "$HELP"
  exit 0
fi

# Create list of samples identified as E.coli by MASH
ecoli_isolates="$(awk -F';' '$2 ~ /Escherichia_col/' ./sample_id/raw.csv | awk -F ';' '{print$1}')"

# Copy raw.csv 
cp ./sample_id/raw.csv ./sample_id/ecoli.csv

# for all ecoli isolates
for i in $ecoli_isolates
do
  # Identify the sample's row number within sample_id.csv
  row_number="$(grep -n ${i} ./sample_id/ecoli.csv | cut -d : -f 1)"
  # Copy SeqSero's predicted serotype
  o_type="$(awk -F $'\t' 'FNR == 8 {print $6}' ./serotypeFinder_output/${i}/results_table.txt)"
  if [ -z "$o_type" ]
  then
      o_type="$(awk -F $'\t' 'FNR == 7 {print $6}' ./serotypeFinder_output/${i}/results_table.txt)"
  fi
  h_type="$(awk -F $'\t' 'FNR == 3 {print $6}' ./serotypeFinder_output/${i}/results_table.txt)"
  ecoli_serotype="${o_type}:${h_type}"
  # Edit ecoli.csv to include SeqSero results
  echo "awk -F';' 'FNR == ${row_number} {\$5 =\" ${ecoli_serotype}\"; print}' ./sample_id/ecoli.csv >> ./sample_id/ecoli.csv" | bash && echo "sed -i ${row_number}d ./sample_id/ecoli.csv" | bash
done

# Add semicolon back to edited row
sed 's/  \{1,\}/; /g' ./sample_id/ecoli.csv >> tmp.csv && rm -rf ./sample_id/ecoli.csv && mv tmp.csv ./sample_id/ecoli.csv

