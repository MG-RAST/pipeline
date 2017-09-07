#!/usr/bin/env python

import os
import re
import sys
import json
import datetime
from optparse import OptionParser

TAX_RE = re.compile(r"^[k|p|c|o|f|g|s]__(.*)$")

def sparse_to_dense(sMatrix, rmax, cmax):
    dMatrix = [[0 for i in range(cmax)] for j in range(rmax)]
    for sd in sMatrix:
        r, c, v = sd
        dMatrix[r][c] = v
    return dMatrix

def lca_from_taxa(row):
    taxa = []
    try:
        taxa = row['metadata']['taxonomy']
    except:
        return []
    lca = []
    for t in taxa:
        tax_match = TAX_RE.match(t)
        if tax_match and (tax_match.group(1) != ''):
            lca.append(tax_match.group(1))
    return lca


usage = "usage: %prog [options]\n"

def main(args):
    parser = OptionParser(usage=usage)
    parser.add_option('-i', '--input', dest="input", default=None, help="input file: qiime otu biom file")
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
    
    # get matrix
    biom = None
    matrix = []
    try:
        biom = json.load(open(opts.input, 'rU'))
    except:
        sys.stderr("Input %s not valid json\n"%opts.input)
        return 1
    
    if biom['matrix_type'] == 'sparse':
        matrix = sparse_to_dense(biom['data'], biom['shape'][0], biom['shape'][1])
    else:
        matrix = biom['data']
    
    # get lca abundace
    lca_map = {}
    for i, row in enumerate(biom['rows']):
        lca = lca_from_taxa(row)
        if len(lca) > 0:
            clust_size = int(sum(matrix[i]))
            lca_full = ['-'] * 8
            for i, t in enumerate(lca):
                lca_full[i] = t
            lca_str = ";".join(lca_full)
            if lca_str in lca_map:
                lca_map[lca_str][0] += clust_size
                lca_map[lca_str][2] += 1
            else:
                lca_map[lca_str] = [ clust_size, i+1, 1 ]
    
    # output profile
    outhdl  = open(opts.output, 'w')
    lca_obj = {
        'id'        : opts.mgid,
        'created'   : datetime.datetime.now().isoformat(),
        'version'   : 1,
        'source'    : 'QIIME',
        'columns'   : ["lca", "abundance", "e-value", "percent identity", "alignment length", "otus", "level"],
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
