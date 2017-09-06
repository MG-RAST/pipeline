#!/usr/bin/env python

import os
import re
import sys
from collections import defaultdict
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
    parser.add_option('-o', '--output', dest="output", default=None, help="output file: lca abundance file")
    
    (opts, args) = parser.parse_args()
    if not (opts.input and os.path.isfile(opts.input)):
        parser.error("[error] missing required input file")
        return 1
    if not opts.output:
        parser.error("[error] missing required output file")
        return 1
    
    lca_map = defaultdict(int)
    
    # get lca abundace
    inhdl = open(opts.input, 'rU')
    for line in inhdl:
        parts = line.strip().split("\t")
        id_match = ID_RE.match(parts[0])
        if id_match:
            clust_size = int(id_match.group(1))
            lca = parse_lca(parts[1])
            if len(lca) > 0:
                lca_str = ";".join(lca)
                lca_map[lca_str] += clust_size
    inhdl.close()
    
    # output profile
    outhdl = open(opts.output, 'w')
    for lca in sorted(lca_map):
        lca_list = ['-'] * 8
        for i, t in enumerate(lca.split(';')):
            lca_list[i] = t
        lvl_num = i + 1
        lca_str = ";".join(lca_list)
        outhdl.write("\t".join([lca_str, str(lca_map[lca]), str(lvl_num)])+"\n")
    outhdl.close()
    
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))