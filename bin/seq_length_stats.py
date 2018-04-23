#!/usr/bin/env python

import os, re, sys, math, json, subprocess
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

IUPAC_DNA = [
    'a', 'c', 'g', 't', 'u', 'r', 'y', 's', 'w', 'k', 'm', 'b', 'd', 'h', 'v', 'n', 'x',
    'A', 'C', 'G', 'T', 'U', 'R', 'Y', 'S', 'W', 'K', 'M', 'B', 'D', 'H', 'V', 'N', 'X',
    '-', ' ', '\n'
]

IUPAC_DNA_STRICT = [
    'A', 'C', 'G', 'T', 'U', 'R', 'Y', 'S', 'W', 'K', 'M', 'B', 'D', 'H', 'V', 'N', 'X'
]

IUPAC_AA = [
    'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',
    'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
    '*', ' ', '\n'
]

IUPAC_AA_STRICT = [
    'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'
]

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
    parser.add_option("-j", "--json", dest="json", default=False, action="store_true", help="Output stats in json format, default is tabbed text")
    parser.add_option("-t", "--type", dest="type", default="fasta", help="Input file type. Must be fasta or fastq [default 'fasta']")
    parser.add_option("-p", "--protein", dest="protein", default=False, action="store_true", help="Input file is Protein sequences [default is DNA/RNA]")
    parser.add_option("-x", "--x_percent", dest="x_percent", default=100, help="Percent of protein sequence characters that are Xs or DNA for it to be counted [default is 100]")
    parser.add_option("-l", "--length_bin", dest="len_bin", metavar="FILE", default=None, help="File to place length bins [default is no output]")
    parser.add_option("-g", "--gc_percent_bin", dest="gc_bin", metavar="FILE", default=None, help="File to place % gc bins [default is no output]")
    parser.add_option("-f", "--fast", dest="fast", default=False, action="store_true", help="Fast mode, only calculate length stats")
    parser.add_option("-s", "--seq_type", dest="seq_type", default=False, action="store_true", help="Guess sequence type [wgs|amplicon] from kmer entropy")
    parser.add_option("-m", "--seq_max", dest="seq_max", default=100000, type="int", help="max number of seqs to process (for kmer entropy) [default 100000]")
    parser.add_option("-c", "--ignore_comma", dest="ignore_comma", default=False, action="store_true", help="Ignore commas in header ID [default is to throw error]")
    parser.add_option("--strict", dest="strict", default=False, action="store_true", help="Strict sequence checking, invalidate those with lowercase or whitespace")
    parser.add_option("--iupac", dest="iupac", default=False, action="store_true", help="Count sequences with non-iupac characters, do not die when encountered")

    # check options
    (opts, args) = parser.parse_args()
    if not opts.input:
        sys.stderr.write("[error] missing input file\n")
        os._exit(1)
    if (opts.type != 'fasta') and (opts.type != 'fastq'):
        sys.stderr.write("[error] file type '%s' is invalid\n" %opts.type)
        os._exit(1)
    if opts.protein and (opts.type == 'fastq'):
        sys.stderr.write("[error] protein fastq is invalid combination\n")
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
    non_iupac  = 0
    x_count    = 0
    bp_count   = 0
    x_percent  = float(opts.x_percent) / 100.0
    prefix_map = defaultdict(int)
    in_hdl = open(opts.input, "rU")
    
    # set namespace
    iupac_set = []
    if opts.protein and opts.strict:
        iupac_set = IUPAC_AA_STRICT
    elif opts.protein:
        iupac_set = IUPAC_AA
    elif opts.strict:
        iupac_set = IUPAC_DNA_STRICT
    else:
        iupac_set = IUPAC_DNA

    # test valid sequence file
    first_char = in_hdl.read(1)
    if (opts.type == 'fasta') and (first_char != '>'):
        sys.stderr.write("[error] invalid fasta file, first character must be '>'\n")
        os._exit(1)
    elif (opts.type == 'fastq') and (first_char != '@'):
        sys.stderr.write("[error] invalid fastq file, first character must be '@'\n")
        os._exit(1)

    # parse sequences
    in_hdl.seek(0)
    try:
        for rec in seq_iter(in_hdl, opts.type):
            head, seq, qual = split_rec(rec, opts.type)
            if (opts.type == 'fasta') and (re.match('^\s', rec.description)):
                sys.stderr.write("[error] invalid fasta file, first character following '>' in header must be non-whitespace\n")
                os._exit(1)
            if (not opts.ignore_comma) and ("," in head):
                sys.stderr.write("[error] invalid sequence file, header may not contain a comma (,)\n")
                os._exit(1)

            slen = len(seq)
            seqnum += 1
            lengths[slen] += 1
            
            if opts.fast:
                continue
            
            if opts.protein:
                x_char = 0
                bp_char = 0
                for i, c in enumerate(seq):
                    if c not in iupac_set:
                        if opts.iupac:
                            non_iupac += 1
                        else:
                            try:
                                ord(c)
                                sys.stderr.write("[error] character '%s' (position %d) in sequence: %s (sequence number %d) is not a valid IUPAC code\n" %(c, i, head, seqnum))
                                os._exit(1)
                            except:
                                sys.stderr.write("[error] non-ASCII character at position %d in sequence: %s (sequence number %d) is not a valid IUPAC code\n" %(i, head, seqnum))
                                os._exit(1)
                    if (c == 'X') or (c == 'x'):
                        x_char += 1
                    if c in "ATCGNatcgn":
                        bp_char += 1
                # check if this is all Xs
                if x_char >= (slen * x_percent):
                    x_count += 1
                # check if this is all dna
                if bp_char >= (slen * x_percent):
                    bp_count += 1
            else:
                if opts.type == 'fastq':
                    for q in qual:
                        ascii_value = ord(q)
                        if ascii_value < 33 or ascii_value > 126:
                            sys.stderr.write("[error] quality value with ASCII value: %d in sequence: %s (sequence number %d) is not within ASCII range 33 to 126\n" %(ascii_value, head, seqnum))
                            os._exit(1)
                char = {'A': 0, 'T': 0, 'G': 0, 'C': 0}
                for i, c in enumerate(seq):
                    if c not in iupac_set:
                        if opts.iupac:
                            non_iupac += 1
                        else:
                            try:
                                ord(c)
                                sys.stderr.write("[error] character '%s' (position %d) in sequence: %s (sequence number %d) is not a valid IUPAC code\n" %(c, i, head, seqnum))
                                os._exit(1)
                            except:
                                sys.stderr.write("[error] non-ASCII character at position %d in sequence: %s (sequence number %d) is not a valid IUPAC code\n" %(i, head, seqnum))
                                os._exit(1)
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
        sys.stderr.write("[error] %s\n" %e)
        os._exit(1)

    # get stats
    if seqnum == 0:
        sys.stderr.write("[error] invalid %s file, unable to find sequence records\n"%opts.type)
        os._exit(1)
    len_mean, len_stdev = get_mean_stdev(seqnum, lengths)
    min_len   = min( lengths.iterkeys() )
    max_len   = max( lengths.iterkeys() )
    stat_text = [
        "bp_count\t%d"%sum_map(lengths),
        "sequence_count\t%d"%seqnum,
        "average_length\t%.3f"%len_mean,
        "standard_deviation_length\t%.3f"%len_stdev,
        "length_min\t%d"%min_len,
        "length_max\t%d"%max_len
    ]
    stat_map = {
        "bp_count" : sum_map(lengths),
        "sequence_count": seqnum,
        "average_length": len_mean,
        "standard_deviation_length": len_stdev,
        "length_min": min_len,
        "length_max": max_len
    }
    
    if not opts.fast:
        if opts.protein:
            stat_text.append("all_X_sequence_count\t%d"%x_count)
            stat_map["all_X_sequence_count"] = x_count
            stat_text.append("all_DNA_sequence_count\t%d"%bp_count)
            stat_map["all_DNA_sequence_count"] = bp_count
        else:
            gcp_mean, gcp_stdev = get_mean_stdev(seqnum, gc_perc)
            gcr_mean, gcr_stdev = get_mean_stdev(seqnum, gc_ratio)
            stat_text.extend([
                "average_gc_content\t%.3f"%gcp_mean,
                "standard_deviation_gc_content\t%.3f"%gcp_stdev,
                "average_gc_ratio\t%.3f"%gcr_mean,
                "standard_deviation_gc_ratio\t%.3f"%gcr_stdev,
                "ambig_char_count\t%d"%ambig_char,
                "ambig_sequence_count\t%d"%ambig_seq,
                "average_ambig_chars\t%.3f"%((ambig_char * 1.0) / seqnum)
            ])
            stat_map["average_gc_content"] = gcp_mean
            stat_map["standard_deviation_gc_content"] = gcp_stdev
            stat_map["average_gc_ratio"] = gcr_mean
            stat_map["standard_deviation_gc_ratio"] = gcr_stdev
            stat_map["ambig_char_count"] = ambig_char
            stat_map["ambig_sequence_count"] = ambig_seq
            stat_map["average_ambig_chars"] = ((ambig_char * 1.0) / seqnum)

            if opts.seq_type:
                seq_type_guess = get_seq_type(kmer_len, prefix_map)
                stat_text.append("sequence_type\t%s"%seq_type_guess)
                stat_map["sequence_type"] = seq_type_guess

    if opts.iupac:
        stat_text.append("non_iupac_count\t%s"%non_iupac)
        stat_map["non_iupac_count"] = non_iupac
    
    # output stats
    if not opts.output:
        sys.stdout.write( "\n".join(stat_text) + "\n" )
    else:
        out_hdl = open(opts.output, "w")
        if opts.json:
            json.dump(stat_map, out_hdl)
        else:
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
