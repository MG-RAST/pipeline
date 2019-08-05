#!/usr/bin/env python

import os
import sys
import re
from pymongo import MongoClient
from collections import defaultdict
from operator import itemgetter
from optparse import OptionParser

__doc__ = """
Input:  m8 format blast / blat file - sorted by query | top hit
Output: top hit for each query per source (protein or rna formats)
    1. filtered sims: same format as m8
    2. rna expanded sims: see below
    3. lca expanded (rna): see below
  OR
    1. filtered sims: same format as m8
    2. expanded sims: see below
    3. ontology sims: see below
    4. lca expanded (protein): see below

m8: query|md5, subject|fragment, identity, length, mismatch, gaps, q_start, q_end, s_start, s_end, evalue, bit_score
expanded: md5|query, fragment|subject, identity, length, evalue, function, organism, source
rna:      md5|query, fragment|subject, identity, length, evalue, function, organism, source, is_rna
ontology: md5|query, fragment|subject, identity, length, evalue, function, ontology, source
LCA:      md5|query list, fragment|subject, identity list, length list, evalue list, lca string, depth of lca (1-8)
"""

# global variables
GET_RNA = False
GET_LCA = False
ACH_HDL = None
SRC_MAP = None
EVAL_RE = re.compile('^(\d\.\d)e([-+])(\d+)$')

# get mongo collection handle from options
def get_collection(opts):
    global ACH_HDL
    try:
        col = 'v'+opts.version
        mcl = MongoClient(opts.host)
        mdb = mcl[opts.name]
        mdb.authenticate(opts.user, opts.password)
        ACH_HDL = mdb[col]
    except:
        sys.stderr.write("[error] unable to connect to mongodb\n")
        os._exit(1)

# get source info from mongodb
def get_sources():
    global SRC_MAP
    sys.stdout.write("Loading ach source data for mapping ... ")
    sources = ACH_HDL.find_one({'key': 'source'})
    if sources and ('data' in sources) and (len(sources['data']) > 0):
        SRC_MAP = sources['data']
    else:
        sys.stderr.write("[error] unable to get source data from mongodb\n")
        os._exit(1)
    sys.stdout.write("Done\n")

# return e-value as exponent int
def get_exp (evalue):
    val = None
    eval_set = EVAL_RE.match(evalue)
    if eval_set:
        (pre, sign, exp) = eval_set.groups()
        if (pre == '0.0') and (exp == '00'):
            val = 0
        elif sign == '-':
            val = -1 * int(exp)
    return val

def get_md5_data(md5s):
    ann   = {}
    lca   = {}
    md5id = {}
    for doc in ACH_HDL.find( {'key': {'$in': md5s}} ):
        m, info = doc['key'], doc['data']
        if 'ann' in info:
            ann[m] = info['ann']
        if GET_LCA and ('lca' in info):
            lca[m] = info['lca']
        if 'id' in info:
            md5id[m] = info['id']
    return ann, lca, md5id

def get_lca(md5s, md5_lca):
    # variables
    cover = defaultdict(lambda: defaultdict(int))
    lca  = []
    pos  = 0
    maxx = 0
    # get coverage
    cover = defaultdict(lambda: defaultdict(int))
    for m in filter(lambda x: x in md5_lca, md5s):
        for taxa in md5_lca[m]:
            for i, t in enumerate(taxa):
                if t:
                    cover[i+1][t] += 1
    # validate
    if (len(cover) < 8) or (len(cover[1]) > 1):
        return []
    # build lca
    for key in sorted(cover):
        num = len(cover[key])
        if (num <= maxx) or (maxx == 0):
            maxx = num
            pos = key
    if len(cover[pos]) == 1:
        lca = map(lambda i: cover[i].keys(), range(1, pos+1))
        if pos < 8:
            lca.append( ['-' for i in range(pos+1, 9)] )
        lca.append(pos)
    return lca

def get_min_md5s_by_source(md5s, md5_ach, seen_srcs, seen_md5s):
    # variables
    sub_md5s  = defaultdict(set)
    avil_srcs = set()
    cur_md5s  = defaultdict(set)
    cur_srcs  = set()
    # get avaiable sources
    for m in filter(lambda x: (x in md5_ach) and (x not in seen_md5s), md5s):
        for s in filter(lambda x: x not in seen_srcs, md5_ach[m].keys()):
            sub_md5s[m].add(s)
            avil_srcs.add(s)
    # get min md5s
    max_srcs = len(avil_srcs)
    for m, srcs in sorted(sub_md5s.items(), key=lambda x: len(x[1]), reverse=True):
        for s in filter(lambda x: x not in cur_srcs, srcs):
            cur_md5s[m].add(s)
            cur_srcs.add(s)
        if len(cur_srcs) >= max_srcs:
            break
    return cur_md5s, cur_srcs

def get_top_hits(total_md5s, data):
    filter_text   = ''
    protein_text  = ''
    ontology_text = ''
    rna_text      = ''
    lca_text      = ''
    data_min_md5  = defaultdict(dict)
    total_min_md5 = set()
    frag_srcs     = defaultdict(set)
    frag_md5s     = defaultdict(list)
    frag_lca      = {}
    
    # get data for md5s from mongodb
    # ach = md5: source: function: (organism | ontology_id)
    # lca = md5: [lca]
    # id  = md5: md5id
    md5_ach, md5_lca, md5_id = get_md5_data(list(total_md5s))
    
    # get md5 and sources per frag
    # frag_srcs = frag: ( source )
    # frag_md5s = frag: [[ md5, exp, data[frag][score][md5] ]]
    for f, fset in data.iteritems():
        for s, sset in fset.iteritems():
            for m, sim in sset.iteritems():
                if GET_LCA:
        	        exp = get_exp(sim[8])
        	        if exp is not None:
        	            frag_md5s[f].append([m, exp, sim])
        	    if m in md5_ach:
        	        for sid in md5_ach[m].iterkeys():
                        frag_srcs[f].add(sid)
    
    # get lca per frag = frag: { md5s: [md5], sims: [sim], lca: [lca] }
    if GET_LCA:
        for f, fset in frag_md5s.iteritems():
            md5s_lca  = {}
            sort_md5s = []
            # get 0 eval and sort rest by eval            
            for s in fset:
                if s[1] == 0:
                    md5s_lca[s[0]] = s[2]
                elif s[1] < 0:
                    sort_md5s.append(s)
            sort_md5s.sort(key=itemgetter(1))
            # add those with eval from cutoff
            if len(sort_md5s) > 0:
                cutoff = sort_md5s[0][1] - int(sort_md5s[0][1] * 0.2)
                for sim in sort_md5s:
                    if sim[1] <= cutoff:
                        md5s_lca[sim[0]] = sim[2]
            # add to master dict if we have an lca
            if len(md5s_lca) > 0:
                lca = get_lca(md5s_lca.keys(), md5_lca)
                if len(lca) == 9:
                    frag_lca[f] = {
                        'md5s': md5s_lca.keys(),
                        'sims': md5s_lca.values(),
                        'lca': lca
                    }
        
    # get min md5s for max sources, ordered by score = frag: {score: {md5: {source}}}
    for f, fset in data.iteritems():
        seen_srcs = set()
        seen_md5s = set()
        for score in sorted(fset, reverse=True):
            if len(seen_srcs) >= len(frag_srcs[f]):
                break
            min_md5, srcs = get_min_md5s_by_source(fset[score].keys(), md5_ach, seen_srcs, seen_md5s)
            data_min_md5[f][score] = min_md5
            for mm in min_md5.iterkeys():
                total_min_md5.add(mm)
                seen_md5s.add(mm)
            for s in srcs:
                seen_srcs.add(s)
    
    # output expanded info
    for f, fset in data.iteritems():
        # lca text
        if GET_LCA and (f in frag_lca):
            level = frag_lca[f]['lca'].pop()
            lca_text += "\t".join([
                ";".join([ md5_id[m] for m in frag_lca[f]['md5s'] if m in md5_id ]), # md5s
                f,
                ";".join([ s[0] for s in frag_lca[s]['md5s'] ]), # identity
                ";".join([ s[1] for s in frag_lca[s]['md5s'] ]), # length
                ";".join([ s[8] for s in frag_lca[s]['md5s'] ]), # evalue
                ";".join( frag_lca[f]['lca'] ),                  # taxa
                level
            ])+"\n"
        if f not in data_min_md5:
            continue
        # process min md5s
        for s, sset in fset.iteritems():
            if s not in data_min_md5[f]:
                continue
            for m, sim in sset.iteritems():
                # sim: [ identity, length, mismatch, gaps, q_start, q_end, s_start, s_end, evalue, bit_score ]
                if (m not in md5_id) and (m not in data_min_md5[f][s]):
                    continue
                # filter text
                filter_text += "%s\t%s\t%s\n"%(f, m, "\t".join(map(str, sim)))
                # md5_ach: md5 => source => function => { 'organism' => [], 'ontology' => [] }
        	    # src_map: id => [ name, type ]
                for src in filter(lambda x: (x in md5_ach[m]) and (x in SRC_MAP), data_min_md5[f][s][m]):
                    sname, stype = SRC_MAP[src]
                    # iterate through annotations
                    for func in md5_ach[m][src].iterkeys():
                        for otype in md5_ach[m][src][func].iterkeys():
                            for other in md5_ach[m][src][func][otype]:
                                # expand text
                                func = func if func else ""
                                expand_text = "\t".join([md5_id[m], f, sim[0], sim[1], sim[8], func, other, src])
                                expand_wout_fo_text = "\t".join([md5_id[m], f, sim[0], sim[1], sim[8], "", "", src])
                                if (otype == 'organism') and (stype == 'rna') and GET_RNA:
                                    rna_text += expand_text+"\t1\n"
                                elif (otype == 'organism') and (stype == 'protein') and (not GET_RNA):
                                    protein_text += expand_text+"\n"
                                elif (otype == 'ontology') and (stype == 'ontology') and (not GET_RNA):
                                    if int(other) > 71073:
                                        continue
                                    ontology_text += expand_text+"\n"
                                    protein_text += expand_wout_fo_text+"\n"
    # end expand output (frag loop)
    # cleanup
    data_min_md5.clear()
    total_min_md5.clear()
    frag_srcs.clear()
    frag_md5s.clear()
    frag_lca.clear()
    md5_ach.clear()
    md5_lca.clear()
    md5_id.clear()
    return filter_text, protein_text, ontology_text, rna_text, lca_text
    

usage = "usage: %prog [options]\n"

def main(args):
    global GET_RNA, GET_LCA
    parser = OptionParser(usage=usage)
    # file names
    parser.add_option('-i', '--input', dest="input", default=None, help="input: m8 format sim file")
    parser.add_option('--filter', dest="filter", default=None, help="output: filtered sim file")
    parser.add_option('--expand', dest="expand", default=None, help="output: expanded protein sim file (protein mode only)")
    parser.add_option('--ontology', dest="ontology", default=None, help="output: expanded ontology sim file (protein mode only)")
    parser.add_option('--rna', dest="rna", default=None, help="output: expanded rna sim file (rna mode only)")
    parser.add_option('--lca', dest="lca", default=None, help="output: expanded LCA file (protein and rna mode)")
    # options
    parser.add_option('--frag_num', dest="frag_num", default=1000, type="int", help="fragment chunks to load before processing, default is 1000")
    parser.add_option('--version', dest="version", default=None, help="version of ach data in mongodb")
    parser.add_option('--host', dest="host", default=None, help="mongo server with ach data")
    parser.add_option('--name', dest="name", default=None, help="name of mongo db with ach data")   
    parser.add_option('--user', dest="user", default=None, help="owner of mongo db with ach data")
    parser.add_option('--password', dest="password", default=None, help="password of mongo db with ach data")
    
    # validate options
    (opts, args) = parser.parse_args()
    if not (opts.input and os.path.isfile(opts.input)):
        parser.error("[error] missing required input sims file")
        return 1
    if not opts.filter:
        parser.error("[error] missing required output filter file")
        return 1
    if opts.rna:
        sys.stdout.write("Running in rna sim mode.\n")
        GET_RNA = True
    elif opts.expand and opts.ontology:
        sys.stdout.write("Running in protein sim mode.\n")
    if opts.lca:
        sys.stdout.write("Running in lca mode.\n")
        GET_LCA = True
    
    # mongo data
    get_collection(opts)
    get_sources()

    # open filehandels
    sims_fh = open(opts.input, 'rU')
    filt_fh = open(opts.filter, 'w')
    rna_fh, exp_fh, ont_fh, lca_fh = None, None, None, None
    if GET_RNA:
        rna_fh = open(opts.rna, 'w')
    else:
        exp_fh = open(opts.expand, 'w')
        ont_fh = open(opts.ontology, 'w')
    if GET_LCA:
        lca_fh = open(opts.lca, 'w')
    
    # set variables
    data  = {}
    md5s  = set()
    count = 0
    frags = 0
    curr  = ''
    
    sys.stdout.write("Parsing file %s in %d fragment size chunks ...\n"%(opts.input, opts.frag_num))
    # parse input file
    # line = md5, fragment, identity, length, mismatch, gaps, q_start, q_end, s_start, s_end, evalue, bit_score
    for line in sims_fh:
        try:
            parts = line.split('\t')
            frag  = parts.pop(0)
            md5   = parts.pop(0)
            score = int(float(parts[-1]))
        except:
            continue
        if md5.startswith('lcl|'):
            md5 = md5[4:]
        if not ((len(md5) == 32) and (len(parts) == 10) and (float(parts[-2]) <= 0.001)):
            continue
        if curr == '':
            curr = frag
        # get top hits for each fragment
        if curr != frag:
            if frags >= opts.frag_num:
                filt_t, exp_t, ont_t, rna_t, lca_t = get_top_hits(md5s, data)
                if filt_t: filt_fh.write(filt_t)
                if exp_t: exp_fh.write(exp_t)
                if ont_t: ont_fh.write(ont_t)
                if rna_t: rna_fh.write(rna_t)
                if lca_t: lca_fh.write(lca_t)
                md5s.clear()
                data.clear()
                frags = 0
            curr = frag
            count += 1
            frags += 1
        # populate data struct
        md5s.add(md5)
        if frag not in data:
            data[frag] = {}
        if score not in data[frag]:
            data[frag][score] = {}
        if md5 not in data[frag][score]:
            data[frag][score][md5] = parts
    # done parsing
    sims_fh.close()
    
    # finish last iteration
    if len(data) > 0:
        filt_t, exp_t, ont_t, rna_t, lca_t = get_top_hits(md5s, data)
        if filt_t: filt_fh.write(filt_t)
        if exp_t: exp_fh.write(exp_t)
        if ont_t: ont_fh.write(ont_t)
        if rna_t: rna_fh.write(rna_t)
        if lca_t: lca_fh.write(lca_t)
    
    # close filehandels
    filt_fh.close()
    if GET_RNA:
        rna_fh.close()
    else:
        exp_fh.close()
        ont_fh.close()
    if GET_LCA:
        lca_fh.close()
    
    sys.stdout.write("Done - %d fragments parsed\n"%count)
    
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
