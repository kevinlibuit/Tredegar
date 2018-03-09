#!/bin/bash
set -e
set -o pipefail


HELP="
Shell script part of the Tredegar pipeline. Assumes pair end files ending in .fastq.gz exist in the project directory within the subdirectory /raw_reads/.

Running in the project directory will concatenate the raw reads and use the concatonated will be input to MASH--a fast genome and metagenome distance estimation using MinHash--for genome identication. Mash output for all samples will be sent to /project_dir/mash_output/. Additionally, the *distance.tab files will be sorted by p-value, lowest to highest.


E.g. From a project directory containing a 'raw_reads' directory of pair end fastq.gz files:


$ tree
├── raw_reads
│   ├── samp1_R1.fastq.gz
│   ├── samp1_R2.fastq.gz
│   ├── samp2_R1.fastq.gz
│   ├── samp2_R2.fastq.gz


initial_id.sh will concatonate pair end reads, run MASH, and place all MASH output (including the concatonated file) into a new dir:


$ ./initial_id.sh
$ ls 
├── mash_output
│   ├── samp1_distance.tab
│   ├── samp1.fastq
│   ├── samp1.fastq.msh
│   ├── samp2_distance.tab
│   ├── samp2.fastq
│   ├── samp2.fastq.msh
│   ├── samp2_distance.tab
├── raw_reads
│   ├── samp1_R1.fastq.gz
│   ├── samp1_R2.fastq.gz
│   ├── samp2_R1.fastq.gz
│   ├── samp2_R2.fastq.gz
"

# Give user help with -h tag
if [[ "$1" == "-h" ]] ; then
  echo "$HELP"
  exit 0
fi

echo "Begining organism identification through MASH. . ."

# Run MASH for all relevant samples
for i in ./raw_reads/*R1.fastq.gz
do
  # Strip path to get just sample file 
  sample_file="$(echo $i| awk -F'/' '{print $3}')"
  # Strip off the _1.fastq.gz to get just the sample name
  sample_name="$(echo $sample_file | sed 's/_R1\.fastq.gz//g')"
  # Full path to pair end reads 
  r1=./raw_reads/${sample_name}_R1.fastq.gz
  r2=./raw_reads/${sample_name}_R2.fastq.gz
  # Check to see if MASH output already exists for each sample; skip if so"
  if ls ./mash_output/${sample_name}_distance.tab 1> /dev/null 2>&1; then
    echo "Skipping ${sample_name}. ${sample_name} has already been MASHED."
  else
    # Run MASH
    echo "${sample_name} is being MASHED..."
    cat $r1 $r2 > ./${sample_name}.fastq && mash sketch -m 2 ./${sample_name}.fastq
    mash dist /opt/genomes/RefSeqSketchesDefaults.msh ./${sample_name}.fastq.msh > ${sample_name}_distance.tab
    # Sort output by p-value--lowest to highest
    sort -gk3 ${sample_name}_distance.tab -o ${sample_name}_distance.tab
  fi
done

# place all output into a separate output directory
mkdir mash_output
mv -iv -- *.{fastq,fastq.msh,tab} ./mash_output/  && mkdir flag_files && touch ./flag_files/mash.happened

