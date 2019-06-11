#!/usr/bin/env python3

#author: Kevin Libuit
#email: kevin.libuit@dgs.virginia.gov

import os
import sys
import argparse
import csv
import pandas
import datetime
sys.path.append(os.path.abspath(os.path.dirname(__file__) + '/' + '../..'))

from Tredegar.lib import run_mash, run_cg_pipeline, run_seqsero, run_serotypefinder

def main():
    parser = argparse.ArgumentParser(usage="tredegar.py <input> [options]")
    parser.add_argument("input", type=str, nargs='?', help="path to dir containing read files")
    parser.add_argument("-o", default="", nargs='?', type=str, help="Name of output_dir")

    if len(sys.argv[1:]) == 0:
        parser.print_help()
        parser.exit()
    args = parser.parse_args()

    path=args.input
    output_dir = args.o

    if not output_dir:
        output_dir = os.path.abspath("tredegar_output")

    if output_dir.endswith('/'):
        output_dir = output_dir[:-1]

    if '/' in output_dir and "tredegar_output" not in output_dir:
        project = output_dir.split('/')
        project = project[-1]
    elif "tredegar_output" in output_dir:
        project = datetime.datetime.today().strftime('%Y-%m-%d')
    else:
        project = output_dir

    #Run MASH, CG_Pipeline, SeqSero, and SerotypeFinder results
    isolate_qual = {}

    mash_obj = run_mash.Mash(path=path,output_dir=output_dir)
    mash_species = mash_obj.mash_species()

    cgpipeline_obj = run_cg_pipeline.CGPipeline(path=path,output_dir=output_dir)
    cgpipeline_obj.read_metrics()

    seqsero_obj = run_seqsero.SeqSero(path=path,output_dir=output_dir)
    seqsero_obj.seqSero()

    serotypefinder_obj = run_serotypefinder.SerotypeFinder(path=path,output_dir=output_dir)
    serotypefinder_obj.serotypeFinder()

    matched_wzx = ["O2","O50","O17","O77","O118","O151","O169","O141ab","O141ac"]
    matched_wzy = ["O13","O135","O17","O44","O123","O186"]
    # Store results in single dictionary
    for id in mash_species:
        isolate_qual[id] = {"r1_q": None, "r2_q": None, "est_cvg": None, "species": None, "serotype": None}

        isolate_qual[id]["species"] = mash_species[id]

        with open("%s/cg_pipeline_output/%s_readMetrics.tsv"%(output_dir,id)) as tsv_file:
            tsv_reader = list(csv.DictReader(tsv_file, delimiter="\t"))

            for line in tsv_reader:
                if any(fwd_format in line["File"] for fwd_format in ["_1.fastq", "_R1.fastq"]):
                    isolate_qual[id]["r1_q"] = line["avgQuality"]
                    isolate_qual[id]["est_cvg"] = float(line["coverage"])
                if any(rev_format in line["File"] for rev_format in ["_2.fastq", "_R2.fastq"]):
                    isolate_qual[id]["r2_q"] = line["avgQuality"]
                    isolate_qual[id]["est_cvg"] += float(line["coverage"])

        if os.path.isfile("%s/seqsero_output/%s/Seqsero_result.txt" % (output_dir, id)):
            with open("%s/seqsero_output/%s/Seqsero_result.txt" % (output_dir, id)) as tsv_file:
                tsv_reader = csv.reader(tsv_file, delimiter="\t")
                for line in tsv_reader:
                    if "Predicted serotype(s)" in line[0]:
                        isolate_qual[id]["serotype"] = line[1]

        if os.path.isfile("%s/serotypeFinder_output/%s/results_tab.txt" % (output_dir, id)):
            with open("%s/serotypeFinder_output/%s/results_tab.txt" % (output_dir, id)) as tsv_file:
                tsv_reader = csv.reader(tsv_file, delimiter="\t")
                h_type=""
                wzx_allele=""
                wzy_allele=""
                wzm_allele=""

                for line in tsv_reader:
                    if "fl" in line[0]:
                        h_type = line[5]

                    if line[0] == "wzx":
                        wzx_allele = line[5]
                    if line[0] == "wzy":
                        wzy_allele = line[5]
                    if line[0] == "wzm":
                        wzm_allele = line[5]

                o_type = wzx_allele
                if not wzx_allele:
                    o_type = wzy_allele
                if not wzx_allele and not wzy_allele:
                    o_type = wzm_allele

                if o_type in matched_wzx:
                    o_type = wzy_allele
                if o_type in matched_wzy:
                    o_type = wzx_allele
                isolate_qual[id]["serotype"] = "%s:%s"%(h_type,o_type)

    # Curate Tredegar report

    reports_dir = output_dir + "/reports/"

    tredegar_out = "%s/%s_tredegar_report.csv"%(reports_dir,project)

    if not os.path.isdir(reports_dir):
        os.makedirs(reports_dir)
        print("Directory for WGS reports made:", reports_dir)

    # Change data dictionary to dataframe to csv
    df = pandas.DataFrame(isolate_qual).T[["r1_q", "r2_q", "est_cvg", "species", "serotype"]]
    df.to_csv(tredegar_out)

    print("Tredegar is complete! Output saved as %s"%tredegar_out)


if __name__ == '__main__':
    main()
