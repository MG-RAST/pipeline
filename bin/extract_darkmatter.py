#!/usr/bin/env python

import argparse
import leveldb
import os
import shutil
import sys
from Bio import SeqIO

def main(args):
    parser = argparse.ArgumentParser(description="Script to extract darkmatter - predicted proteins with no similarities")
    parser.add_argument("-i", "--input", help="Name of input genecall fasta file.")
    parser.add_argument("-o", "--output", help="Name of output darkmatter fasta file.")
    parser.add_argument("-s", "--sims", dest="cfile", help="Name of similarity file")
    parser.add_argument("-d", "--db", dest="db", default=".", help="Directory to store LevelDB, default CWD")
    parser.add_argument("-v", "--verbose", dest="verbose", action="store_true", help="Print informational messages")
    args = parser.parse_args()

    if ('sims' not in args) or (os.stat(args.sims).st_size == 0):
        print "Similarity file was omitted or is empty, copying %s to %s ... " % (args.ifile, args.ofile)
        shutil.copyfile(args.ifile, args.ofile)
        return 0

    db = leveldb.LevelDB(args.db)
    shdl = open(args.sims, 'rU')

    if args.verbose:
        print "Reading file %s ... " % args.sims

    for line in shdl:
        parts = line.strip().split('\t')
        db.Put(parts[0], 1)
    
    shdl.close()
    if args.verbose:
        print "Done"
        print "Reading file %s ... " % args.input

    ihdl = open(args.input, 'rU')
    ohdl = open(args.output, 'w')

    g_num = 0
    d_num = 0
    for rec in SeqIO.parse(ihdl, 'fasta'):
        g_num += 1
        try:
            val = db.Get(rec.id)
        except KeyError:
            d_num += 1
            ohdl.write("%s\n%s\n"%(rec.id, str(rec.seq).upper()))

    ihdl.close()
    ohdl.close()
    if args.verbose:
        print "Done: %d darkmatter genes found out of %d total" %(d_num, g_num)
    return 0

if __name__ == "__main__":
    sys.exit( main(sys.argv) )
