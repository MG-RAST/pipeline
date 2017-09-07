#!/usr/bin/env python

import os
import re
import sys
import json
import datetime
from optparse import OptionParser

TAXA_PREFIX = ['d_', 'p_', 'c_', 'o_', 'f_', 'g_']
TAX_RE = re.compile(r"^(.+)\(\d+\)$")
ID_RE = re.compile(r"^\S+;size=(\d+);$")

def parse_lca(lca_str):
    new_taxa = []
    old_taxa = lca_str.split(";")
    # skip if missing domain
    if not old_taxa[0].startswith(TAXA_PREFIX[0]):
        return []
    
    i = 0
    for pre in TAXA_PREFIX:
        if (not old_taxa[i]) or (old_taxa[i] == 'unclassified'):
            i += 1
        elif old_taxa[i].startswith(pre):
            temp = old_taxa[i][2:]
            tax_match = TAX_RE.match(temp)
            if tax_match:
                temp = tax_match.group(1)
            new_taxa.append(temp)
            i += 1
        else:
            temp = "unclassified (derived from " + new_taxa[i-1] + ")"
            new_taxa.append(temp)
    return new_taxa


usage = "usage: %prog [options]\n"

def main(args):
    parser = OptionParser(usage=usage)
    parser.add_option('-i', '--input', dest="input", default=None, help="input file: mothur taxonomy file")
    parser.add_option('-o', '--output', dest="output", default=None, help="output file: lca abundance file: lca text, abundance, # otus, level")
    parser.add_option('-m', '--mgid', dest="mgid", default=None, help="MG-RAST ID of metagenome, used in json output")
    parser.add_option('-j', '--json', dest="json", action="store_true", help="output format json, default is tabbed text")
    
    (opts, args) = parser.parse_args()
    if not (opts.input and os.path.isfile(opts.input)):
        parser.error("[error] missing required input file")
        return 1
    if not opts.output:
        parser.error("[error] missing required output file")
        return 1
    
    lca_map = {}
    
    # get lca abundace
    inhdl = open(opts.input, 'rU')
    for line in inhdl:
        parts = line.strip().split("\t")
        id_match = ID_RE.match(parts[0])
        if id_match:
            clust_size = int(id_match.group(1))
            lca = parse_lca(parts[1])
            if len(lca) > 0:
                lca_full = ['-'] * 8
                for i, t in enumerate(lca):
                    lca_full[i] = t
                lca_str = ";".join(lca_full)
                if lca_str in lca_map:
                    lca_map[lca_str][0] += clust_size
                    lca_map[lca_str][2] += 1
                else:
                    lca_map[lca_str] = [ clust_size, i+1, 1 ]
    inhdl.close()
    
    # output profile
    outhdl  = open(opts.output, 'w')
    lca_obj = {
        'id'        : opts.mgid,
        'created'   : datetime.datetime.now().isoformat(),
        'version'   : 1,
        'source'    : 'TAP',
        'columns'   : ["lca", "abundance", "e-value", "percent identity", "alignment length", "md5s", "level"],
        'row_total' : len(lca_map),
        'data'      : []
    }
    for lca in sorted(lca_map):
        if opts.json:
            lca_obj['data'].append([ lca, lca_map[lca][0], -1, 1, 1, lca_map[lca][2], lca_map[lca][1] ])
        else:
            outhdl.write("\t".join([ lca, str(lca_map[lca][0]), str(lca_map[lca][2]), str(lca_map[lca][1]) ])+"\n")
    if opts.json:
        json.dump(lca_obj, outhdl)
    outhdl.close()
    
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
