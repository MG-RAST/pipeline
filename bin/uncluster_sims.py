#!/usr/bin/env python

import argparse
import json
import leveldb
import os
import shutil
import sys

def main(args):
    parser = argparse.ArgumentParser(description="Script to expand the sims file to include cluster members. If cluster file is not included, input file is copied to output file")
    parser.add_argument("ifile", metavar="IFILE", help="Name of input sim file.")
    parser.add_argument("ofile", metavar="OFILE", help="Name of output sim file.")
    parser.add_argument("-d", "--db", metavar="DBDIR", default="./db", help="Directory to store LevelDB.")
    parser.add_argument("-c", "--cfile", metavar="CFILE", help="Name of cluster mapping file")
    parser.add_argument("-v", "--verbose", action="store_true", help="Print informational messages.")
    args = parser.parse_args()

    if ('cfile' not in args) or (os.stat(args.cfile).st_size == 0):
        print "Cluster file was omitted or is empty, copying %s to %s ... " % (args.ifile, args.ofile)
        shutil.copyfile(args.ifile, args.ofile)
        return 0

    db = leveldb.LevelDB(args.db)
    chdl = open(args.cfile, 'rU')

    if args.verbose:
        print "Reading file %s ... " % args.cfile

    for line in chdl:
        parts = line.strip().split('\t')
        seed = parts[0]
        ids = {}
        for id in parts[1].split(','):
            ids[id] = 1
        try:
            val = db.Get(seed)
        except KeyError:
    	    val = None

        if val:
            for i in json.loads(val):
                ids[i] = 1

        if seed in ids:
            del ids[seed]

        db.Put(seed, json.dumps(ids))
    chdl.close()

    if args.verbose:
        print "Done"
        print "Reading file %s ... " % args.ifile

    ihdl = open(args.ifile, 'rU')
    ohdl = open(args.ofile, 'w')

    s_num = 0
    q_num = 0
    for line in ihdl:
        parts = line.strip().split('\t')
        s_num += 1
        query = parts[0]
        if query:
            q_num += 1
            ohdl.write("%s\t%s\n" % (query, "\t".join(parts[1:])))
            try:
                val = db.Get(query)
            except KeyError:
        	    val = None

            if val:
                for i in json.loads(val):
                    q_num += 1
                    ohdl.write("%s\t%s\n" % (i, "\t".join(parts[1:])))
        else:
            next

    ihdl.close()
    ohdl.close()

    if args.verbose:
        print "Done: %s sim queries expanded to %s queries" % (s_num, q_num)
    return 0

if __name__ == "__main__":
    sys.exit( main(sys.argv) )
