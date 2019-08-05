#!/usr/bin/env python

import os
import re
import sys
import json
import logging
import itertools
from optparse import OptionParser

__doc__ = """
Script to create LCA for contigs from seperate Protein and rRNA (feature) LCAs.
Features mapped to contigs based on ID prefix:
    feature ID = PREFIX_start_stop_stand
    contig ID = PREFIX
LCA file format, TSV, same for inputs and outputs:
    md5 list, feature id, identity list, length list, evalue list, lca string, depth of lca (1-8)"""

# logging
LOG_FORMAT = '[%(asctime)-15s] [%(levelname)-5s] %(message)s'
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)
logger = logging.getLogger()

# regex
id_re = re.compile(r"^(\S+?)_\d+_\d+_[-|+]$") # .group(1) == contig name

def process_line(line):
    parts = line.strip().split('\t')
    if len(parts) < 7:
        return "", None
    (md5, frag, ident, length, e_val, lca, lvl) = parts[:7]
    if not (frag and md5 and lca):
        return "", None
    id_match = id_re.match(frag)
    if not id_match:
        return "", None
    return id_match.group(1), [ md5.split(';'), frag, ident.split(';'), length.split(';'), e_val.split(';'), lca.split(';'), lvl ]

def merge_rows(cid, rows, scgs=set()):
    md5, ident, length, e_val = (set() for i in range(4))
    lca = ["-"] * 8
    lvl = 0
    lca_scg = []   # [ [length, lca] ]
    lcamatrix = [] # [ lcas ]
    
    for row in rows:
        # get scg lcas if any
        if scgs and any(m in scgs for m in row[0]):
            lca_scg.append([max(row[3]), row[5]])
        md5.update(row[0])
        ident.update(row[2])
        length.update(row[3])
        e_val.update(row[4])
    
    if len(lca_scg) == 0:
        # no SCGs, use all LCAs
        lcamatrix = [row[5] for row in rows]
    else:
        # get LCA for best hit SCG
        maxlen = max([x[0] for x in lca_scg])
        lcamatrix = [x[1] for x in filter(lambda y: y[0] == maxlen, lca_scg)]
    
    # find LCA of LCAs
    lcarotate = zip(*lcamatrix)
    for i, x in enumerate(lcarotate):
        if all_equal(x):
            lca[i] = x[0]
            lvl = i + 1
        else:
            break
    return [ list(md5), cid, list(ident), list(length), list(e_val), lca, lvl ]

def all_equal(iterable):
    "Returns True if all the elements are equal to each other"
    g = itertools.groupby(iterable)
    return next(g, True) and not next(g, False)

def print_row(hdl, row):
    for i, r in enumerate(row):
        if isinstance(r, list):
            row[i] = ";".join(r)
        if isinstance(r, int):
            row[i] = str(r)
    hdl.write("\t".join(row)+"\n")

def load_scgs(fname):
    md5s = set()
    try:
        data = json.load(open(fname, 'r'))
        md5s = set(data.keys())
    except:
        pass
    return md5s

usage = "usage: %prog [options]\n" + __doc__
def main(args):
    parser = OptionParser(usage=usage)
    parser.add_option("--rna", dest="rna", default=None, help="input file: expanded rna lca")
    parser.add_option("--prot", dest="prot", default=None, help="input file: expanded protein lca")
    parser.add_option("--scg", dest="scg", default=None, help="input file: json format map of md5s that are SCGs")
    parser.add_option("-o", "--output", dest="output", default=None, help="output file: expanded contig lca")
    parser.add_option("-v", "--verbose", dest="verbose", action="store_true", help="Print informational messages.")
    
    (opts, args) = parser.parse_args()
    if not (opts.rna and os.path.isfile(opts.rna)):
        logger.error("missing required input rna lca file")
        return 1
    if not (opts.prot and os.path.isfile(opts.prot)):
        logger.error("missing required input protein lca file")
        return 1
    if not opts.output:
        logger.error("missing required output file")
        return 1
    
    rna_contigs = set()
    ohdl = open(opts.output, 'w')   
    rhdl = open(opts.rna, 'rU')
    
    # create contig LCAs for RNA features first, take precidence over protein features
    if opts.verbose:
        print "Reading file %s ... "%(opts.rna)
    
    # get first parsable line
    prev = ""
    row  = []
    data = []
    while prev == "":
        firstline = rhdl.readline()
        prev, row = process_line(firstline)
    
    data.append(row)
    rctg = 0
    rrna = 1
    
    # process remaining lines
    for line in rhdl:
        cid, row = process_line(line)
        if cid == "":
            continue
        if cid != prev:
            # new contig found, process old
            mrow = merge_rows(prev, data)
            rna_contigs.add(prev)
            print_row(ohdl, mrow)
            # reset
            prev = cid
            data = []
            rctg += 1
        data.append(row)
        rrna += 1
    
    # process last contig
    if len(data) > 0:
        mrow = merge_rows(prev, data)
        rna_contigs.add(prev)
        print_row(ohdl, mrow)
        rctg += 1
    
    rhdl.close()
    if opts.verbose:
        print "Done: %d contigs with %d rRNAs processed"%(rctg, rrna)
    
    md5_scgs = load_scgs(opts.scg)
    phdl = open(opts.prot, 'rU')
    if opts.verbose:
        "Reading file %s ... "%(opts.prot)
    
    # get first parsable line
    prev = ""
    row  = []
    data = []
    while prev == "":
        firstline = phdl.readline()
        prev, row = process_line(firstline)
    
    data.append(row)
    pctg = 0
    prot = 1
    
    # process remaining lines
    for line in phdl:
        cid, row = process_line(line)
        if (cid == "") or (cid in rna_contigs):
            # skip those found with rnas
            continue
        if cid != prev:
            # new contig found, process old
            mrow = merge_rows(prev, data, md5_scgs)
            print_row(ohdl, mrow)
            # reset
            prev = cid
            data = []
            pctg += 1
        data.append(row)
        prot += 1
    
    # process last contig
    if len(data) > 0:
        mrow = merge_rows(prev, data)
        print_row(ohdl, mrow)
        prot += 1
    
    phdl.close()
    ohdl.close()
    if opts.verbose:
        print "Done: %d contigs with %d proteins processed"%(pctg, prot)
    
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
