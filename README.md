# Seq_ID
A bioinformatics pipeline for organism identification and sample-label verification of whole genome sequence (WGS) data produced at the DCLS

----

Data workflow:
![seq_ID pipeline](./docs/seq_ID.png)


----

Basic usage: 

````sh
$ seq_id.sh -i <input> -o <output_dir>
````

Seq\_ID assumes input to be a DCLS BaseSpace project within the mounted BaseSpace profile that contains multiple samples and read files ending in  R[1,2]_001.fastq.gz 


Note: if the pipeline breaks durring analysis, do **not** restart seq_ID by running the same command. Instead, change to the output directory and type `make`.

````sh
$ cd <output_dir>
$ make
````