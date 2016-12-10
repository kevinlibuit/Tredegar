#!/bin/bash

HELP="
seq_ID:  A bioinformatics pipeline for organism identification and sample-label verification of whole genome sequence (WGS) data produced at the DCLS

Usage $0 -i <input_dir> -o <output_dir>

options:
-h, --help              Show brief help.
-i, --input=DIR         Name of DCLS BaseSpace project. Seq_ID assumes input to be a DCLS BaseSpace project within the mounted BaseSpace profile that contains multiple samples and read files ending in  R[1,2]_001.fastq.gz
-o, --output-dir=DIR    specify a directory to store output

After running, a seq_ID report can be found within the output directory specificed and opened in Microsoft Excel.
"


# Set options 
while test $# -gt 0; do
        case "$1" in
                -h|--help)
                        echo "$HELP"
                        exit 0
                        ;;
                -i)
                        shift
                        if test $# -gt 0; then
                                input_dir=$1
                        else
                                echo "no process specified"
                                exit 1
                        fi
                        shift
                        ;;
                --input*)
                        input_dir=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                -o)
                        shift
                        if test $# -gt 0; then
                                output_dir=$1
                        else
                                echo "no output dir specified"
                                exit 1
                        fi
                        shift
                        ;;
                --output-dir*)
                        output_dir=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                *)
                        break
                        ;;
        esac
done

# Check if seq_id report already exists; skip analysis if so
if ls  ./${output_dir}/*seq_ID_report.csv 1> /dev/null 2>&1; then
	echo "A seq_ID_report already exists in ${output_dir}. The .csv file can be opened and analyzed in Microsoft Excel."
elif ls ~/BaseSpace/Projects/${input_dir}/Samples/*/Files/*.fastq.gz 1> /dev/null 2>&1; then
	# Create the proper directories and run the pipeline
	mkdir ./${output_dir}/raw_reads/ -p && ln -s ~/BaseSpace/Projects/${input_dir}/Samples/*/Files/*.fastq.gz ./${output_dir}/raw_reads/ && rename_basespace_files.sh ${output_dir} && copy_seq_ID_makefile ${output_dir} && make -C ./${output_dir}
else
	echo "No read files found in BaseSpace project ${input_dir}. Please enter valid project path to run seq_ID."
fi

echo "DONE"
