#!/usr/bin/env python

import sys, os
from optparse import OptionParser
from Bio.Seq import Seq
from Bio.SeqIO.QualityIO import FastqGeneralIterator

__doc__ = """
Parse Illumina format index file (fastq) to create MG-RAST format barcode file. Add names if prefix given.
"""

def main(args):
    usage  = "usage: %prog [options] -i <input index file> -o <output barcode file>"+__doc__
    parser = OptionParser(usage)
    parser.add_option("-i", "--input", dest="input", default=None, help="Input index fastq file.")
    parser.add_option("-o", "--output", dest="output", default=None, help="Output barcode file.")
    parser.add_option("-p", "--prefix", dest="prefix", default=None, help="Optional string to prepend to names.")
    parser.add_option("-r", "--revcomp", dest="revcomp", action="store_true", default=False, help="Print reverse complement of index sequences for barcodes [default is same].")

    (opts, args) = parser.parse_args()
    if not (opts.input and os.path.isfile(opts.input) and opts.output):
        parser.error("Missing input and/or output")

    # parse index file - build map
    barcodes  = {}
    input_hdl = open(opts.input, 'rU')
    for rec in FastqGeneralIterator(input_hdl):
        seq = rec[1].upper()
        barcodes[seq] = 1
    input_hdl.close()
    
    # print to output
    output_hdl = open(opts.output, 'w')
    for i, bc in enumerate(barcodes.keys()):
        if opts.revcomp:
            bcseq = Seq(bc, generic_dna)
            bc = bcseq.reverse_complement()
        if opts.prefix:
            output_hdl.write("%s.%d\t%s\n"%(opts.prefix, i+1, bc))
        else:
            output_hdl.write(bc+"\n")
    output_hdl.close()
    
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
