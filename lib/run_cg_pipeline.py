#!/usr/bin/env python3

#author: Kevin Libuit
#email: kevin.libuit@dgs.virginia.gov

import os,sys
sys.path.append(os.path.abspath(os.path.dirname(__file__) + '/' + '../..'))

import argparse
import csv
from Tredegar.core import fileparser
from Tredegar.core import calldocker
from Tredegar.lib import run_quast

class CGPipeline:
    #class object to contain fastq file information
    runfiles = None
    #path to fastq files
    path = None
    #output directory
    output_dir = None

    def __init__(self, runfiles=None, path=None, output_dir = ""):
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

        self.cg_out_dir = self.output_dir + "/cg_pipeline_output/"

    def read_metrics(self):
        cg_out_dir = self.cg_out_dir
        if not os.path.isdir(cg_out_dir):
            os.makedirs(cg_out_dir)
            print("Directory for CG Pipeline output made: ", cg_out_dir)

        for read in self.runfiles.reads:
            #get id
            id = self.runfiles.reads[read].id
            cgp_result = id + "_readMetrics.tsv"



            if not os.path.isfile(cg_out_dir + cgp_result):

                # change self.path to local dir if path is a basemounted dir
                if os.path.isdir(self.path + "/AppResults"):
                    self.path = self.output_dir

                # get paths to fastq files
                fwd = os.path.abspath(self.runfiles.reads[read].fwd).replace(self.path, "")

                if "R1.fastq" in fwd:
                    reads = fwd.replace("R1.fastq", "*.fastq")
                else:
                    reads = fwd.replace("_1.fastq", "*.fastq")

                # create paths for data
                mounting = {self.path:'/datain', cg_out_dir:'/dataout'}
                out_dir = '/dataout'
                in_dir = '/datain'

                with open("%s/quast_output/%s/report.tsv" % (self.output_dir, id)) as tsv_file:
                    tsv_reader = csv.reader(tsv_file, delimiter="\t")
                    for line in tsv_reader:
                        if "Total length" in line[0]:
                            genome_length = line[1]

                print("Estimated genome length for isolate %s: " % id + str(int(genome_length)))

                # build command for running run_assembly_readMetrics.pl
                command = "bash -c 'run_assembly_readMetrics.pl {in_dir}/{reads} -e {genome_length} > " \
                          "{out_dir}/{cgp_result}'".format(in_dir=in_dir,out_dir=out_dir,reads=reads,
                                                           genome_length=genome_length,cgp_result=cgp_result)

                # call the docker process
                print("Getting read metrics for isolate %s"%(id))
                calldocker.call("staphb/lyveset:1.1.4f",command,'/dataout',mounting)

            print("CG Pipeline results for isolate %s saved to: %s%s"%(id,cg_out_dir,cgp_result))


if __name__ == '__main__':
    def str2bool(v):
        if v.lower() in ('yes', 'true', 't', 'y', '1'):
            return True
        elif v.lower() in ('no', 'false', 'f', 'n', '0'):
            return False
        else:
            raise argprase.ArgumentTypeError('Boolean value expected.')

    parser = argparse.ArgumentParser(usage="run_cg_pipeline.py <input> [options]")
    parser.add_argument("input", type=str, nargs='?', help="path to dir containing read files")
    parser.add_argument("-o", default="", nargs='?', type=str, help="Name of output_dir")

    if len(sys.argv[1:]) == 0:
        parser.print_help()
        parser.exit()
    args = parser.parse_args()

    path = os.path.abspath(args.input)
    output_dir = args.o

    if not output_dir:
        output_dir = os.getcwd()

    CGPipeline_obj = CGPipeline(path=path, output_dir=output_dir)
    CGPipeline_obj.read_metrics()
