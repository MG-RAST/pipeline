#!/usr/bin/env python

import os
import re
import sys
import json
import string
import random
import shutil
import leveldb
import argparse
import subprocess
from Bio import SeqIO

SEED = ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(6))

def get_seq_stats(fname):
    stats = {}
    cmd   = ["seq_length_stats.py", "-f", "-i", fname]
    proc  = subprocess.Popen( cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE )
    stdout, stderr = proc.communicate()
    if proc.returncode != 0:
        print "[warning] seq_length_stats.py returns: "+stderr
        return {}
    for line in stdout.strip().split("\n"):
        parts = line.split("\t")
        try:
            val = int(parts[1])
        except ValueError:
            try:
                val = float(parts[1])
            except ValueError:
                val = None
        stats[parts[0]] = val
    return stats

def main(args):
    parser = argparse.ArgumentParser(description="Script to extract darkmatter - predicted proteins with no similarities")
    parser.add_argument("-i", "--input", dest="input", help="Name of input genecall fasta file.")
    parser.add_argument("-o", "--output", dest="output", help="Name of output darkmatter fasta file.")
    parser.add_argument("-s", "--sims", dest="sims", default=[], help="One or more similarity files", action='append')
    parser.add_argument("-m", "--maps", dest="maps", default=[], help="One or more cluster map files", action='append')
    parser.add_argument("-d", "--db", dest="db", default=".", help="Directory to store LevelDB, default CWD")
    parser.add_argument("--stats", dest="stats", action="store_true", default=False, help="Compute sequence stats on output")
    parser.add_argument("-v", "--verbose", dest="verbose", action="store_true", default=False, help="Print informational messages")
    args = parser.parse_args()
    
    has_sims = False
    for s in args.sims:
        if os.stat(s).st_size > 0:
            has_sims = True
    if not has_sims:
        print "Similarity file(s) was omitted or is empty, copying %s to %s ... " % (args.input, args.output)
        shutil.copyfile(args.input, args.output)
        return 0
    
    db = leveldb.LevelDB(args.db)
    
    if args.verbose:
        print "Processing cluster files"
    for mfile in args.maps:
        mhdl = open(mfile, 'rU')
        if args.verbose:
            print "\treading file %s ... "%(mfile)
        for line in mhdl:
            parts = line.strip().split('\t')
            query = SEED + parts[0]
            ids = {}
            if len(parts) == 4:
                # old format
                ids[parts[1]] = 1
                for id in parts[2].split(','):
                    ids[id] = 1
            elif len(parts) == 3:
                # new format
                ids[parts[0]] = 1
                for id in parts[1].split(','):
                    ids[id] = 1
            try:
                val = db.Get(query)
            except KeyError:
    	        val = None
            if val:
                for k in json.loads(val).keys():
                    ids[k] = 1
            db.Put(query, json.dumps(ids))
        mhdl.close()
    
    if args.verbose:
        print "Done"
        print "Processing similarity files"
    for sfile in args.sims:
        shdl = open(sfile, 'rU')
        if args.verbose:
            print "\treading file %s ... "%(sfile)
        
        for line in shdl:
            parts = line.strip().split('\t')
            query = SEED + parts[0]
            try:
                val = db.Get(query)
            except KeyError:
    	        val = None
            if val:
                for k in json.loads(val).keys():
                    db.Put(k, "X")
            else:
                db.Put(parts[0], "X")
        shdl.close()
    
    g_num = 0
    d_num = 0
    ihdl = open(args.input, 'rU')
    ohdl = open(args.output, 'w')
    
    if args.verbose:
        print "Done"
        print "Processing file %s ... " % args.input
    for rec in SeqIO.parse(ihdl, 'fasta'):
        g_num += 1
        try:
            val = db.Get(rec.id)
        except KeyError:
            d_num += 1
            ohdl.write(">%s\n%s\n"%(rec.id, str(rec.seq).upper()))
    
    ohdl.close()
    ihdl.close()
    
    if args.stats:
        jhdl = open(args.output+".stats", 'w')
        json.dump(get_seq_stats(args.output), jhdl)
        jhdl.close()
    
    if args.verbose:
        print "Done: %d darkmatter genes found out of %d total" %(d_num, g_num)
    return 0

if __name__ == "__main__":
    sys.exit( main(sys.argv) )
