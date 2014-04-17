#!/usr/bin/env python

import os
import sys
import hashlib
from Bio import SeqIO
from Bio.SeqIO.QualityIO import FastqGeneralIterator
from optparse import OptionParser

TMP_DIR = None

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

def create_prefix_file(in_file, out_file, prefix_len, memory, fformat):
    tmp_file  = out_file+'.tmp'
    tmp_hdl   = open(tmp_file, 'w')
    input_hdl = open(in_file, 'rU')
    try:
        for rec in seq_iter(input_hdl, fformat):
            head, seq, qual = split_rec(rec, fformat)
            if len(seq) <= prefix_len:
                md5 = hashlib.md5( seq ).hexdigest()
            else:
                md5 = hashlib.md5( seq[:prefix_len] ).hexdigest()
            tmp_hdl.write("%s\t%s\t%d\t%s\n" %(md5, head, len(seq), seq))
    finally:
        input_hdl.close()
        tmp_hdl.close()
    run_cmd(['sort', '-T', TMP_DIR, '-S', memory, '-t', "\t", '-k', '1,1', '-k', '3,3nr', '-o', out_file, tmp_file])
    os.remove(tmp_file)

def remove_reps(rep_file, pass_file, fail_file):
    pass_hdl = open(pass_file, 'w')
    fail_hdl = open(fail_file, 'w')
    last_md5 = ""
    with open(rep_file, 'r') as infile:
        for line in infile:
            (md5, sid, length, seq) = line.strip().split('\t')
            if md5 != last_md5:
                pass_hdl.write(">%s\n%s\n"%(sid, seq))
            else:
                fail_hdl.write(">%s\n%s\n"%(sid, seq))
            last_md5 = md5
    pass_hdl.close()
    fail_hdl.close()

usage = "usage: %prog [options] input_fasta output_name\n"

def main(args):
    global TMP_DIR
    parser = OptionParser(usage=usage)
    parser.add_option("-l", "--prefix_length", dest="prefix_length", type="int", default=50, help="Length of prefix [default '50']")
    parser.add_option("-s", "--seq_type", dest="seq_type", default='fasta', help="Sequence type: fasta, fastq [default 'fasta']")
    parser.add_option("-d", "--tmp_dir", dest="tmpdir", default="/tmp", help="DIR for sorting files (must be full path) [default '/tmp']")
    parser.add_option("-m", "--memory", dest="memory", default='4G', help="Memory for sorting [default '4G']")
    
    (opts, args) = parser.parse_args()
    if len(args) != 2:
        parser.print_help()
        print "[error] incorrect number of arguments"
        return 1
    if not os.path.isdir(opts.tmpdir):
        parser.print_help()
        print "[error] invalid tmpdir"
        return 1

    (in_seq, out_name) = args
    TMP_DIR = opts.tmpdir
    
    rep_file  = out_name+'.derep'
    pass_file = out_name+'.passed.fna'
    fail_file = out_name+'.removed.fna'
    create_prefix_file(in_seq, rep_file, opts.prefix, opts.memory, opts.seq_type)
    remove_reps(rep_file, pass_file, fail_file)
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
