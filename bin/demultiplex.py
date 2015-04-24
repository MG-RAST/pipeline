#!/usr/bin/env python

import sys, os, shutil, pprint, subprocess
from collections import defaultdict
from optparse import OptionParser
from Bio import SeqIO
from Bio.SeqIO.QualityIO import FastqGeneralIterator

__doc__ = """
Demultiplex fasta or fastq file with given barcode list. Barcode is trimmed from beginning of sequence.
List may contain only barcodes (output filename is barcode) or barcode \\t name (output filename is name).
Allows multiple barcodes to write to one file and mutliple files to get seqs from one barcode.
"""

BLEN = 0

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

def write_rec(out_hdl, head, seq, qual):
    if qual is None:
        out_hdl.write(">%s\n%s\n" %(head, seq))
    else:
        out_hdl.write("@%s\n%s\n+\n%s\n" %(head, seq, qual))

def barcode_files(bfile, odir, stype, prefix):
    global BLEN
    uniq_fname = {}
    barc_fname = defaultdict(list)
    bhdl  = open(bfile, 'rU')
    stype = 'fna' if stype == 'fasta' else stype
    for b in bhdl:
        if not b:
            continue
        bset = b.strip().split("\t")
        if not bset[0]:
            continue
        barc = prefix.upper() + bset[0].upper()
        name = os.path.join(odir, "%s.%s"%(bset[0] if len(bset) == 1 else bset[1], stype))
        clen = len(barc)
        if BLEN == 0:
            BLEN = clen
        elif BLEN != clen:
            sys.stderr.write("[error] barcode lengths are not the same\n")
            os._exit(1)
        barc_fname[barc].append(name)
        uniq_fname[name] = None
    return barc_fname, uniq_fname

def main(args):
    usage  = "usage: %prog [options] -b <barcode list> -i <input sequence file> -o <output dir>"+__doc__
    parser = OptionParser(usage)
    parser.add_option("-i", "--input", dest="input", default=None, help="Input sequence file.")
    parser.add_option("-o", "--output", dest="output", default=".", help="Output dir (default cwd), filenames will be 'barcode.type' or 'name.type'")
    parser.add_option("-f", "--format", dest="format", default='fasta', help="File format: fasta, fastq [default 'fasta']")
    parser.add_option("-b", "--barcode", dest="barcode", default=None, help="File with list of barcodes or list of barcode name pairs")
    parser.add_option("-p", "--prefix", dest="prefix", default="", help="Optional sequence to prepend to barcodes")
    parser.add_option("-v", "--verbose", dest="verbose", action="store_true", default=False, help="Wordy [default off]")

    (opts, args) = parser.parse_args()
    if not (opts.input and os.path.isfile(opts.input) and opts.output and os.path.isdir(opts.output)):
        parser.error("Missing input and/or output")
    if not (opts.barcode and os.path.isfile(opts.barcode)):
        parser.error("Missing barcode list")

    # get barcode / filename
    barc_fname, uniq_fname = barcode_files(opts.barcode, opts.output, opts.format, opts.prefix)
    # open filehandles
    for f in uniq_fname.iterkeys():
        uniq_fname[f] = open(f, 'w')
    missing = open(os.path.join(opts.output, 'nobarcode.'+os.path.basename(opts.input)), 'w')

    # parse sequence file
    # allows multiple barcodes to write to one file and mutliple files to get seqs from one barcode
    bar_count  = defaultdict(int)
    miss_count = 0
    input_hdl  = open(opts.input, 'rU')
    for rec in seq_iter(input_hdl, opts.format):
        head, seq, qual = split_rec(rec, opts.format)
        seqbar = seq[:BLEN]
        seq  = seq[BLEN:]
        qual = qual[BLEN:] if qual is not None else None
        if seqbar in barc_fname:
            bar_count[seqbar] += 1
            for f in barc_fname[seqbar]:
                write_rec(uniq_fname[f], head, seq, qual)
        else:
            miss_count += 1
            write_rec(missing, head, seq, qual)

    #close filehandles
    missing.close()
    for fhdl in uniq_fname.itervalues():
        fhdl.close()

    if opts.verbose:
        print "%d sequences split amoung %d barcodes. %d sequences without barcodes"%(sum(bar_count.values()), len(bar_count.keys()), miss_count)

    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
