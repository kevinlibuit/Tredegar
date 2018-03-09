tredegar_dir := ~/Tredegar/scripts/
current_dir := $(shell basename $(CURDIR))
all: ./flag_files/mash.happened ./sample_id/raw.csv ./flag_files/spades.happened ./flag_files/seroTF.happened ./sample_id/ecoli.csv ./flag_files/seqsero.happened ./${current_dir}_tredegar_report.csv

clean:
	rm -rf ./mash_output/* ./ecoli_assemblies/* ./serotypeFinder_output/* ./seqsero_output/* ./sample_id.csv ./flag_files

.PHONY: all clean

# Run raw reads through MASH
./flag_files/mash.happened: ./raw_reads/*.fastq.gz
	${tredegar_dir}initial_id.sh

# Organize top MASH hits into sinlge csv file
./sample_id/raw.csv: ./flag_files/mash.happened
	${tredegar_dir}tredegar_report.sh

# Find isolates ID'ed as ecoli and generate assemblies for serotypeFinder input
./flag_files/spades.happened: ./sample_id/raw.csv
	${tredegar_dir}assemble_ecoli.sh

# Serotype assembled ecoli isolates
./flag_files/seroTF.happened: ./flag_files/spades.happened
	${tredegar_dir}ecoli_serotype.sh

# Edit sample-id.csv to include seerotypeFinder resutls
./sample_id/ecoli.csv: ./flag_files/seroTF.happened
	${tredegar_dir}add_ecoli_sero.sh

# Find isolates ID'ed as salmonella and serotype with seqsero
./flag_files/seqsero.happened: ./sample_id/ecoli.csv
	${tredegar_dir}sal_serotype.sh

# Edit sample-id.csv to include seqsero results
./${current_dir}_tredegar_report.csv: ./flag_files/seqsero.happened
	${tredegar_dir}add_sal_sero.sh
	cp ./sample_id/ecoli_sal.csv ./${current_dir}_tredegar_report.csv
