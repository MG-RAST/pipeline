#!/usr/bin/env python

import sys, os
from optparse import OptionParser
from Bio.SeqIO.QualityIO import FastqGeneralIterator

__doc__ = """
Merge Illumina format index file (fastq) with sequence file (fastq) to make single file inline barcode file.
"""

def main(args):
    usage  = "usage: %prog [options] -i <input index file> -s <input seq file> -o <output merge file>"+__doc__
    parser = OptionParser(usage)
    parser.add_option("-i", "--index", dest="index", default=None, help="Input index fastq file.")
    parser.add_option("-s", "--seq", dest="seq", default=None, help="Input seq fastq file.")
    parser.add_option("-o", "--output", dest="output", default=None, help="Output barcode file.")
    
    (opts, args) = parser.parse_args()
    if not (opts.index and os.path.isfile(opts.index) and opts.seq and os.path.isfile(opts.seq) and opts.output):
        parser.error("Missing input and/or output")
    
    outh = open(opts.output+'.tmp', 'w')
    itr1 = FastqGeneralIterator(open(opts.seq))
    itr2 = FastqGeneralIterator(open(opts.index))
    (h1, s1, q1) = itr1.next()
    (h2, s2, q2) = itr2.next()
    while 1:
        h1 = h1.split()[0]
        h2 = h2.split()[0]
        while h1 != h2:
            try:
                (h2, s2, q2) = itr2.next()
                h2 = h2.split()[0]
            except (StopIteration, IOError):
                break
        outh.write("@%s\n%s%s\n+\n%s%s\n" %(h1, s2, s1, q2, q1))
        try:
            (h1, s1, q1) = itr1.next()
            (h2, s2, q2) = itr2.next()
        except (StopIteration, IOError):
            break
    outh.close()
    os.rename(opts.output+'.tmp', opts.output)
    
    return 0
    
if __name__ == "__main__":
    sys.exit(main(sys.argv))
