#!/usr/bin/env python

import os, sys, math, random, subprocess, gzip
from collections import defaultdict
from optparse import OptionParser
from Bio import SeqIO
from Bio.SeqIO.QualityIO import FastqGeneralIterator

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

def countseqs(infile, gzip, stype):
    headchar = '>'
    if stype == 'fastq':
        headchar = '@'
    if gzip:
        proc_in = subprocess.Popen( ['zcat', infile], stdout=subprocess.PIPE )
        proc    = subprocess.Popen( ['grep', '-c', "^%s"%headchar], stdin=proc_in.stdout, stdout=subprocess.PIPE, stderr=subprocess.PIPE )
    else:
        proc = subprocess.Popen( ['grep', '-c', "^%s"%headchar, infile], stdout=subprocess.PIPE, stderr=subprocess.PIPE )
    stdout, stderr = proc.communicate()
    if proc.returncode != 0:
        raise IOError("%s\n%s"%(" ".join(cmd), stderr))
    slen = stdout.strip()
    if not slen:
        sys.stderr.write("%s is invalid %s file\n"%(infile, stype))
        exit(1)
    return int(slen)

def get_seq_type(size, data):
    kset  = []
    total = sum( data.values() )
    for i in range(1, size+1):
        kset.append( sub_kmer(i, total, data) )
    # black box logic
    if (kset[15] < 9.8) and (kset[10] < 6):
        return "Amplicon"
    else:
        return "WGS"
    
def sub_kmer(pos, total, data):
    sub_data = defaultdict(int)
    entropy  = 0
    for kmer, num in data.iteritems():
        sub_data[ kmer[:pos] ] += num
    for skmer, snum in sub_data.iteritems():
        sratio = float(snum) / total
        entropy += (-1 * sratio) * math.log(sratio, 2)
    return entropy

def main(args):
    usage  = "usage: %prog [options] -i input_fasta"
    parser = OptionParser(usage=usage)
    parser.add_option("-i", "--input", dest="input", default=None, help="Input sequence file")
    parser.add_option("-o", "--output", dest="output", default=None, help="Output guess, if not called prints to STDOUT")
    parser.add_option("-t", "--type", dest="type", default="fasta", help="Input file type. Must be fasta or fastq [default 'fasta']")
    parser.add_option("-z", "--gzip", dest="gzip", default=False, action="store_true", help="Input file is gzipped [default is not]")
    parser.add_option("-m", "--max_seq", dest="max_seq", default=100000, type="int", help="max number of seqs process [default 100000]")

    # check options
    (opts, args) = parser.parse_args()
    if not opts.input:
        parser.error("Missing input file")
    if (opts.type != 'fasta') and (opts.type != 'fastq'):
        parser.error("File type '%s' is invalid" %opts.type)

    # set variables
    if opts.gzip:
        in_hdl = gzip.open(opts.input, "rb")
    else:
        in_hdl = open(opts.input, "rU")
    seqnum = countseqs(opts.input, opts.gzip, opts.type)
    seqper = (opts.max_seq * 1.0) / seqnum
    kmer_len = 16
    prefix_map = defaultdict(int)

    # parse sequences
    snum = 0
    for rec in seq_iter(in_hdl, opts.type):
        head, seq, qual = split_rec(rec, opts.type)
        if (len(seq) >= kmer_len) and (seqper >= random.random()):
            prefix_map[ seq[:kmer_len] ] += 1
            snum += 1

    # get stats
    seq_type_guess = get_seq_type(kmer_len, prefix_map)
    if not opts.output:
        sys.stdout.write(seq_type_guess+"\n")
    else:
        out_hdl = open(opts.output, "w")
        out_hdl.write(seq_type_guess+"\n")
        out_hdl.close()
    return 0

if __name__ == "__main__":
    sys.exit( main(sys.argv) )
