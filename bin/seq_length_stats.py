#!/usr/bin/env python

import os, sys, math, subprocess
from collections import defaultdict
from optparse import OptionParser
from Bio import SeqIO
from Bio.SeqIO.QualityIO import FastqGeneralIterator

__doc__ = """
Calculate statistics for fasta files.

OUTPUT:
  bp_count
  sequence_count
  average_length
  standard_deviation_length
  length_min
  length_max
  average_gc_content
  standard_deviation_gc_content
  average_gc_ratio
  standard_deviation_gc_ratio
  ambig_char_count
  ambig_sequence_count
  average_ambig_chars
  sequence_type"""

def sum_map(aMap):
    total = 0
    for k, v in aMap.iteritems():
        total += (float(k) * v)
    return total

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

def get_mean_stdev(count, data):
    total = sum_map(data)
    mean  = (total * 1.0) / count
    tmp   = 0
    for k, v in data.iteritems():
        for i in range(0, v):
            dev  = float(k) - mean
            tmp += (dev * dev)
    return mean, math.sqrt(tmp / count)

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

def output_bins(data, outf):
    out_hdl = open(outf, "w")
    keys = data.keys()
    keys.sort(lambda a,b: cmp(float(a), float(b)))
    for k in keys:
        out_hdl.write("%s\t%d\n"%(k, data[k]))
    out_hdl.close()


usage = "usage: %prog [options] -i input_fasta" + __doc__

def main(args):
    parser = OptionParser(usage=usage)
    parser.add_option("-i", "--input", dest="input", default=None, help="Input sequence file")
    parser.add_option("-o", "--output", dest="output", default=None, help="Output stats file, if not called prints to STDOUT")
    parser.add_option("-t", "--type", dest="type", default="fasta", help="Input file type. Must be fasta or fastq [default 'fasta']")
    parser.add_option("-l", "--length_bin", dest="len_bin", metavar="FILE", default=None, help="File to place length bins [default is no output]")
    parser.add_option("-g", "--gc_percent_bin", dest="gc_bin", metavar="FILE", default=None, help="File to place % gc bins [default is no output]")
    parser.add_option("-f", "--fast", dest="fast", default=False, action="store_true", help="Fast mode, only calculate length stats")
    parser.add_option("-s", "--seq_type", dest="seq_type", default=False, action="store_true", help="Guess sequence type [wgs|amplicon] from kmer entropy")
    parser.add_option("-m", "--seq_max", dest="seq_max", default=100000, type="int", help="max number of seqs to process (for kmer entropy) [default 100000]")

    # check options
    (opts, args) = parser.parse_args()
    if not opts.input:
        sys.stderr.write("[error] missing input file\n")
        os._exit(1)
    if (opts.type != 'fasta') and (opts.type != 'fastq'):
        sys.stderr.write("[error] file type '%s' is invalid\n" %opts.type)
        os._exit(1)

    # set variables
    seqnum   = 0
    lengths  = defaultdict(int)
    gc_perc  = defaultdict(int)
    gc_ratio = defaultdict(int)
    ambig_char = 0
    ambig_seq  = 0
    kmer_len   = 16
    kmer_num   = 0
    prefix_map = defaultdict(int)
    in_hdl = open(opts.input, "rU")

    # parse sequences
    try:
        for rec in seq_iter(in_hdl, opts.type):
            head, seq, qual = split_rec(rec, opts.type)
            slen = len(seq)
            seqnum += 1
            lengths[slen] += 1
            
            if not opts.fast:
                char = {'A': 0, 'T': 0, 'G': 0, 'C': 0}
                for c in seq:
                    if c in char:
                        char[c] += 1
                atgc  = char['A'] + char['T'] + char['G'] + char['C']
                ambig = slen - atgc;
                gc_p  = "0"
                gc_r  = "0"
                if atgc > 0:
                    gc_p = "%.1f"%((1.0 * (char['G'] + char['C']) / atgc) * 100)
                if (char['G'] + char['C']) > 0:
                    gc_r = "%.1f"%(1.0 * (char['A'] + char['T']) / (char['G'] + char['C']))
                gc_perc[gc_p] += 1
                gc_ratio[gc_r] += 1
                if ambig > 0:
                    ambig_char += ambig
                    ambig_seq += 1
            if opts.seq_type and (slen >= kmer_len) and (kmer_num < opts.seq_max):
                prefix_map[ seq[:kmer_len] ] += 1
                kmer_num += 1
    except ValueError as e:
        sys.stderr.write("[error] possible file truncation: %s\n" %e)
        os._exit(1)

    # get stats
    if seqnum == 0:
        sys.stderr.write("[error] invalid %s file, unable to find sequence records\n"%opts.type)
        os._exit(1)
    len_mean, len_stdev = get_mean_stdev(seqnum, lengths)
    min_len   = min( lengths.iterkeys() )
    max_len   = max( lengths.iterkeys() )
    stat_text = [ "bp_count\t%d"%sum_map(lengths),
                  "sequence_count\t%d"%seqnum,
                  "average_length\t%.3f"%len_mean,
                  "standard_deviation_length\t%.3f"%len_stdev,
                  "length_min\t%d"%min_len,
                  "length_max\t%d"%max_len ]

    if not opts.fast:
        gcp_mean, gcp_stdev = get_mean_stdev(seqnum, gc_perc)
        gcr_mean, gcr_stdev = get_mean_stdev(seqnum, gc_ratio)
        stat_text.extend([ "average_gc_content\t%.3f"%gcp_mean,
                           "standard_deviation_gc_content\t%.3f"%gcp_stdev,
                           "average_gc_ratio\t%.3f"%gcr_mean,
                           "standard_deviation_gc_ratio\t%.3f"%gcr_stdev,
                           "ambig_char_count\t%d"%ambig_char,
                           "ambig_sequence_count\t%d"%ambig_seq,
                           "average_ambig_chars\t%.3f"%((ambig_char * 1.0) / seqnum) ])
    if opts.seq_type:
        seq_type_guess = get_seq_type(kmer_len, prefix_map)
        stat_text.append("sequence_type\t%s"%seq_type_guess)

    # output stats
    if not opts.output:
        sys.stdout.write( "\n".join(stat_text) + "\n" )
    else:
        out_hdl = open(opts.output, "w")
        out_hdl.write( "\n".join(stat_text) + "\n" )
        out_hdl.close()

    # get binned stats
    if opts.len_bin:
        output_bins(lengths, opts.len_bin)
    if opts.gc_bin and (not opts.fast):
        output_bins(gc_perc, opts.gc_bin)

    return 0

if __name__ == "__main__":
    sys.exit( main(sys.argv) )
