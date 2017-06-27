#!/usr/bin/env python

import os
import re
import sys
import subprocess
from optparse import OptionParser
from Bio import SeqIO
from Bio.SeqIO.QualityIO import FastqGeneralIterator

COVRE = re.compile(r'^(\S+_\[cov=(\S+)\]\S*).*$')
SEQRE = re.compile(r'^(\S+).*$')

def seq_iter(file_hdl, stype):
    if stype == 'fastq':
        return FastqGeneralIterator(file_hdl)
    else:
        return SeqIO.parse(file_hdl, stype)

def split_rec(rec, stype):
    if stype == 'fastq':
        return rec[0].split()[0], rec[1].upper(), rec[2]
    else:
        return rec.id, str(rec.seq).upper(), None

def determinetype(infile):
    cmd = ["head", "-n", "1", infile]
    p1 = subprocess.check_output(cmd)
    firstchar = p1[0]
    if firstchar == "@":
        return "fastq"
    elif firstchar == ">":
        return "fasta"
    sys.stderr.write("Cannot determine file type of %s\n"%(infile))
    exit(1)


if __name__ == '__main__':
    usage  = "usage: %prog -i <input sequence file> -o <output file>"
    parser = OptionParser(usage)
    parser.add_option("-i", "--input", dest="input", default=None, help="input sequence file")
    parser.add_option("-c", "--coverage", dest="coverage", default=None, help="coverage file")
    parser.add_option("-s", "--stats", dest="stats", default=None, help="stats file")
    parser.add_option("-t", "--type", dest="type", default=None, help="file type: fasta, fastq")
    
    (opts, args) = parser.parse_args()
    if not (opts.input and os.path.isfile(opts.input) and opts.output):
        parser.error("Missing input/output files")
    if not opts.type:
        opts.type = determinetype(opts.input)
    
    ihdl = open(opts.input, 'rU')
    ohdl = open(opts.coverage, 'w')
    has_cov = 0
    for i, rec in enumerate(seq_iter(ihdl, opts.type)):
        head, seq, qual = split_rec(rec, opts.type)
        covm = COVRE.match(head)
        seqm = SEQRE.match(head)
        if covm:
            ohdl.write(covm.group(1)+"\t"+covm.group(2)+"\n")
            has_cov += 1
        elif seqm:
            ohdl.write(seqm.group(1)+"\t1\n")
    ohdl.close()
    ihdl.close()
    
    per_cov = ( ((has_cov / (i * 1.0)) * 10000) + 0.5 ) / 100
    shdl = open(opts.stats, 'w')
    shdl.write("percent_reads_with_coverage\t%.2f\n"%per_cov)
    shdl.close()

