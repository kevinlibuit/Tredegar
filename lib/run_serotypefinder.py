#!/usr/bin/env python3

#author: Kevin Libuit
#email: kevin.libuit@dgs.virginia.gov

import os,sys, glob
sys.path.append(os.path.abspath(os.path.dirname(__file__) + '/' + '../..'))

import argparse
import shutil
from Tredegar.core import fileparser, calldocker
from Tredegar.lib import run_mash, run_shovill

class SerotypeFinder:
    #class object to contain fastq file information
    runfiles = None
    #path to fastq files
    path = None
    #output directory
    output_dir = None

    def __init__(self, runfiles=None, path=None, output_dir = "", threads=None):
        if output_dir:
            self.output_dir = os.path.abspath(output_dir)
        else:
            self.output_dir = os.getcwd()

        if not os.path.isdir(self.output_dir):
            os.makedirs(self.output_dir)

        if runfiles:
            self.runfiles = runfiles
        else:
            self.path = path
            self.runfiles = fileparser.RunFiles(self.path, output_dir=output_dir)

        self.threads = threads

        self.serotypeFinder_out_dir = self.output_dir + "/serotypeFinder_output/"

    def serotypeFinder(self, from_mash=True, assembler="shovill"):
        serotypeFinder_out_dir = self.serotypeFinder_out_dir
        if not os.path.isdir(serotypeFinder_out_dir):
            os.makedirs(serotypeFinder_out_dir)
            print("Directory for serotypeFinder output made: ", serotypeFinder_out_dir)
        mash_species = {}

        if from_mash:
            mash_samples = run_mash.Mash(path=self.path, output_dir=self.output_dir)
            mash_species = mash_samples.mash_species()

        for read in self.runfiles.reads:
            #get id
            id = self.runfiles.reads[read].id

            serotypeFinder_results = "%s/%s/"%(serotypeFinder_out_dir, id)
            if not os.path.isdir(serotypeFinder_results):
                os.makedirs(serotypeFinder_results)

            if not os.path.isfile(serotypeFinder_results + "/results_table.txt"):

                # change self.path to local dir if path is a basemounted dir
                if os.path.isdir(self.path + "/AppResults"):
                    self.path = self.output_dir

                # get paths to fastq files
                if self.runfiles.reads[read].paired:
                    fwd = os.path.abspath(self.runfiles.reads[read].fwd).replace(self.path, "")
                    rev = os.path.abspath(self.runfiles.reads[read].rev).replace(self.path,"")
                else:
                    fastq = os.path.basename(self.runfiles.reads[read].path)

                # create paths for data
                # create paths for data
                mounting = {self.path:'/datain',serotypeFinder_results:'/dataout'}
                out_dir = '/dataout'
                in_dir = '/datain'

                if from_mash:
                    # set expected genome lengths according to mash hits
                    if 'Escherichia' not in mash_species[id]:
                        pass

                    else:

                        shovill_obj = run_shovill.Shovill(path=self.path, threads=self.threads,
                                                      output_dir=self.output_dir)
                        shovill_obj.shovill()
                        contigs = "/shovill_output/%s/contigs.fa"%id

                        print("Contig file: " + self.path + contigs)

                        command = "bash -c 'serotypefinder.pl -d /serotypefinder/database/ -i {in_dir}/{contigs} " \
                                  "-b /blast-2.2.26/ -o {out_dir}/ -s ecoli -k 95.00 -l 0.60'" \
                                  "".format(in_dir=in_dir,out_dir=out_dir, contigs=contigs)

                        # call the docker process
                        print("Predicting E.coli serotype for isolate " + id)
                        calldocker.call("staphb/serotypefinder:1.1", command,'/dataout',mounting)

                else:
                    if assembler == shovill:
                        shovill_obj = run_shovill.Shovill(path=self.path, threads=threads, output_dir=self.output_dir,
                                              extra_params=extra_params)
                        shovill_obj.shovill()
                        contigs = "%s/shovill_output/%s/contigs.fa" % (self.path, id)

                    elif assembler == spades:
                        spades_obj = Spades(path=path, threads=threads, output_dir=output_dir,
                                            extra_params=extra_params)
                        spades_obj.spades()
                        contigs = "%s/spades_output/%s/contigs.fasta" % (self.path, id)

                    command = "bash -c 'serotypefinder.pl -d /serotypefinder/database/ -i {in_dir}/{contigs} " \
                              "-b /opt/blast-2.2.26 -o {out_dir}/ -s ecoli -k 95.00 -l 0.60'" \
                              "".format(in_dir=in_dir, out_dir=out_dir, contigs=contigs)

                    # call the docker process
                    print("Predicting E.coli serotype for isolate " + id)
                    calldocker.call("staphb/serotypefinder:1.1", command, '/dataout', mounting)


if __name__ == '__main__':
    def str2bool(v):
        if v.lower() in ('yes', 'true', 't', 'y', '1'):
            return True
        elif v.lower() in ('no', 'false', 'f', 'n', '0'):
            return False
        else:
            raise argprase.ArgumentTypeError('Boolean value expected.')

    parser = argparse.ArgumentParser(usage="serotypefinder.py <input> [options]")
    parser.add_argument("input", type=str, nargs='?', help="path to dir containing read files")
    parser.add_argument("-o", default="", nargs='?', type=str, help="Name of output_dir")
    parser.add_argument("-t",default=16,type=int,help="number of threads")
    parser.add_argument("-a", default="shovill", nargs='?', type=str, help="Assembler used to genearte assemlby input")
    parser.add_argument("-from_mash", nargs='?', type=str2bool, default=True, help="Set expected genome length "
                                                                                   "according to MASH species "
                                                                                   "prediction. default: "
                                                                                   "-from_mash=True")

    if len(sys.argv[1:]) == 0:
        parser.print_help()
        parser.exit()
    args = parser.parse_args()

    path = os.path.abspath(args.input)
    output_dir = args.o
    from_mash = args.from_mash
    threads = args.t
    assembler = args.a

    if not output_dir:
        output_dir = os.getcwd()

    serotypeFinder_obj = SerotypeFinder(path=path, output_dir=output_dir, threads=threads)
    serotypeFinder_obj.serotypeFinder(from_mash=from_mash, assembler=assembler)
