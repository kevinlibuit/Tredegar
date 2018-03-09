#!/bin/bash
set -e
set -o pipefail


HELP="
Shell script part of the Tredegar pipeline. Assumes a project directory with a 'mash_output' subdirectory that contains *_distance.tab files generated after running initial_id.sh.

Running in the project directory will parse through the mash_output/*distance_tab files to identify the top MASH hit for each sample and the associated Mash-distance. tredegar_report.sh will then generate create a csv (./sample_id/raw.csv) file with this information organized into the following fields: Sample, MASH-ID, Mash-distance, SeqSero, SerotypeFinder.

*Note: fields for SeqSero and SerotypeFinder will be filled with a placeholder ('-'). This will be edited for Salmonella spp. and E.coli isolates once Seqsero and SerotypeFinder results are generated by running add_sal_sero.sh and add_ecoli_sero.sh, respectively.
"

# Give user help with -h tag
if [[ "$1" == "-h" ]] ; then
  echo "$HELP"
  exit 0
fi

# create sample_id directory and raw.csv. This raw.csv file will be edited after SeqSero and serotypeFinder results have been generated"
mkdir ./sample_id/ && touch ./sample_id/raw.csv

# specify delimiter and create header
echo "sep=;"  >> ./sample_id/raw.csv && echo "Sample; MASH-ID; MASH-distance; SeqSero; SerotypeFinder" >> ./sample_id/raw.csv

# Fill raw.csv with appropriate data
for i in ./raw_reads/*R1.fastq.gz
do
  # Strip path to get just sample file
  sample_file="$(echo $i| awk -F'/' '{print $3}')"
  # Strip off the _1.fastq.gz to get just the sample name
  sample_name="$(echo $sample_file | sed 's/_R1\.fastq.gz//g')"
  # Get MASH output and compile data into single csv file
  echo "${sample_name}; $(head -1 ./mash_output/${sample_name}_distance.tab | sed 's/.*-\.-//' | grep -o '^\S*' | sed -e 's/\(..fna\)*$//g'); $(head -1 ./mash_output/${sample_name}_distance.tab | awk '{ print $3 }'); -; -" >> ./sample_id/raw.csv
done

