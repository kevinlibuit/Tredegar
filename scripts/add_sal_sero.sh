#!/bin/bash
set -e
set -o pipefail

HELP="
Shell script part of the seq_ID piepeline. Assumes Salmonella spp. isolates have been serotyped with SeqSero and results exist in the proect directroy within the subdirectories /SeqSero_output/<sample_name>/

Running in the project directory will parse through SeqSero output to update <projecti_dir>/sample_id/ecoli.csv. The updated file will be renamed to <project_dir>/sample_id/ecoli_sal.csv. If no Salmonella spp. isoaltes exist in the current project, <projecti_dir>/sample_id/ecoli.csv and <projecti_dir>/sample_id/ecoli_sal.csv will be identical.
"
# Give user help with -h tag
if [[ "$1" == "-h" ]] ; then
  echo "$HELP"
  exit 0
fi


# create list of samples identified as Salmonella spp. by MASH
sal_isolates="$(awk -F';' '$2 ~ /Salmonella/' ./sample_id/ecoli.csv | awk -F ';' '{print$1}')"
# catch ambiguous SeqSero results
oddity="See comments below*"

# Copy ecoli.csv
cp ./sample_id/ecoli.csv ./sample_id/ecoli_sal.csv

# for all salmonella isolates
for i in $sal_isolates
do
  # Identify the sample's row number within sample_id.csv  
  row_number="$(grep -n ${i} ./sample_id/ecoli_sal.csv | cut -d : -f 1)"
  # Copy SeqSero's predicted serotype
  sal_serotype="$(grep 'Predicted serotype(s):' ./SeqSero_output/${i}/Seqsero_result.txt | awk -F$'\t' '{print $2}')"
  # Check for ambigious results; edit sample.csv as needed
  if [ "$sal_serotype" == "$oddity" ] ; then
    comment="$(grep '*' ./SeqSero_output/${i}/Seqsero_result.txt| awk 'NR==2' | tr -s " ")"
    echo "awk -F';' 'FNR == ${row_number} {\$4 =\" ${comment}\"; print}' ./sample_id/ecoli_sal.csv >> ./sample_id/ecoli_sal.csv" | bash && echo "sed -i ${row_number}d ./sample_id/ecoli_sal.csv" | bash
  else
  # Edit sample_id.csv using sample's row number and SeqSero results
    echo "awk -F';' 'FNR == ${row_number} {\$4 =\" ${sal_serotype}\"; print}' ./sample_id/ecoli_sal.csv >> ./sample_id/ecoli_sal.csv" | bash && echo "sed -i ${row_number}d ./sample_id/ecoli_sal.csv" | bash
  fi
done

# Add semicolon back to edited row
sed 's/  \{1,\}/; /g' ./sample_id/ecoli_sal.csv >> tmp.csv && rm -rf ./sample_id/ecoli_sal.csv && mv tmp.csv ./sample_id/ecoli_sal.csv


