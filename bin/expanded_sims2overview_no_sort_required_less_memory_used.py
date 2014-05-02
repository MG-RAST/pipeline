#!/usr/bin/env python

# NOTE: This new version of expanded_sims2overview does not require the input expand
#       files be sorted.  However, it does rely on the read -> md5 hits being grouped
#       together for the md5 summary.  This means, all rows with the same read and
#       md5 pair should be grouped together in the expand file so that this pair is
#       only counted once.
#
# ALSO NOTE: This script does not enforce an e-value cutoff.  Instead, it relies on
#       bleachsims being run on the rna sims and process_sims_by_source_mem employing
#       an e-value cutoff of 0.001 on the protein sims.

import os
import re
import sys
import math
import numpy as np
from collections import defaultdict
from optparse import OptionParser

# constants
SOURCES = 18
ev_re  = re.compile(r"^(\d\.\d)e([-+])(\d+)$")
TYPES  = ['md5', 'function', 'organism', 'ontology', 'lca', 'source']
EVALS  = [-5 , -10 , -20 , -30 , -1000]
IDENTS = [60 , 80 , 90 , 97 , 100]
JOBID  = None
DB_VER = None

# numpy dtypes
DTYPES = {
    'md5': np.dtype([ ('abun', np.uint32), ('esum', np.float32), ('esos', np.float32),
                      ('lsum', np.float32), ('lsos', np.float32), ('isum', np.float32),
                      ('isos', np.float32), ('ebin', np.uint16, (1,5)), ('isp', np.bool_) ]),
    'lca': np.dtype([ ('abun', np.uint32), ('esum', np.float32), ('esos', np.float32),
                      ('lsum', np.float32), ('lsos', np.float32), ('isum', np.float32),
                      ('isos', np.float32), ('lvl', np.uint8) ]),
    'other': np.dtype([ ('source', np.uint8), ('abun', np.uint32), ('esum', np.float32),   
                        ('esos', np.float32), ('lsum', np.float32), ('lsos', np.float32),
                        ('isum', np.float32), ('isos', np.float32) ])
}

def memory_usage():
    """Memory usage of the current process in kilobytes."""
    status = None
    result = {'peak': 0, 'rss': 0}
    try:
        # This will only work on systems with a /proc file system
        # (like Linux).
        status = open('/proc/self/status')
        for line in status:
            parts = line.split()
            key = parts[0][2:-1].lower()
            if key in result:
                result[key] = int(parts[1])
    finally:
        if status is not None:
            status.close()
    return result

def parse_file(fname, ftype):
    if not (fname and os.path.isfile(fname)):
        return {}
    data = {}
    with open(fname, 'rU') as fhdl:
        for line in fhdl:
            tabs = line.strip().split('\t')
            if ftype == 'coverage':
                data[tabs[0]] = tabs[1]
            elif ftype == 'cluster':
                ids = tabs[2].split(',') # old way
                ids.append(tabs[1])
                #ids = tabs[1].split(',') # new way
                data[tabs[0]] = ids
            elif ftype == 'index':
                data[tabs[0]] = (tabs[1], tabs[2])
    return data

def get_e_bin(val):
    if (val == 0) or (val < EVALS[-1]):
        return EVALS[-1]
    for e in EVALS:
        if val >= e:
            return e
    return "error"

def get_i_bin(val):
    for i in IDENTS:
        if val <= i:
            return i
    return "error"

def update_e_bin(exp, abun, bins):
    if exp == 0:
        bins[-1] += abun
    else:
        for i, e in enumerate(EVALS):
            if exp >= e:
                bins[i] += abun
                break
    return bins

def get_abundance(frag, amap, cmap):
    abun = 0
    if frag in cmap:
        for x in cmap[frag]:
            abun += amap[x] if x in amap else 1
    else:
        abun += amap[frag] if frag in amap else 1
    return abun

def get_exponent(e_val):
    if e_val == 0:
        return 0
    ev_match = ev_re.match(str(e_val))
    if not ev_match:
        (i, f) = str(e_val).split('.')
        return len(f) * -1
    if ev_match.group(2) == '-':
        return int(ev_match.group(3)) * -1
    else:
        return int(ev_match.group(3))

# round to nearest thousandth
def str_round(val):
    if int(val) == val:
        return str(val)
    else:
        return "%.3f"%(math.ceil(val * 1000) / 1000)

def stddev(mean, sos, n):
    tmp = (sos / n) - (mean * mean)
    return math.sqrt(tmp) if tmp > 0 else 0

def print_md5_stats(ohdl, data, imap):
    for md5 in sorted(data):
        stats  = data[md5][0]
        e_mean = stats['esum'] / stats['abun']
        l_mean = stats['lsum'] / stats['abun']
        i_mean = stats['isum'] / stats['abun']
        (seek, length) = imap[md5] if md5 in imap else ('', '')
        line = [ DB_VER,
                 JOBID,
                 str(md5),
                 str(stats['abun']),
                 "{"+",".join(map(str, stats['ebin']))+"}",
                 str_round(e_mean),
                 str_round(stddev(e_mean, stats['esos'], stats['abun'])),
                 str_round(l_mean),
                 str_round(stddev(e_mean, stats['esos'], stats['abun'])),
                 str_round(i_mean),
                 str_round(stddev(l_mean, stats['isos'], stats['abun'])),
                 seek,
                 length,
                 "1" if stats['isp'] else "2" ]
        ohdl.write("\t".join(line)+"\n")

def print_type_stats(ohdl, data, md5s):
    for aid in sorted(data):
        for i in range(SOURCES):
            stats = data[aid][i]
            if stats['source'] == 0:
                continue
            e_mean = stats['esum'] / stats['abun']
            l_mean = stats['lsum'] / stats['abun']
            i_mean = stats['isum'] / stats['abun']
            line = [ DB_VER,
                     JOBID,
                     str(aid),
                     str(stats['abun']),
                     str_round(e_mean),
                     str_round(stddev(e_mean, stats['esos'], stats['abun'])),
                     str_round(l_mean),
                     str_round(stddev(e_mean, stats['esos'], stats['abun'])),
                     str_round(i_mean),
                     str_round(stddev(l_mean, stats['isos'], stats['abun'])),
                     "{"+",".join(map(str, md5s[aid]))+"}",
                     str_round(stats['source']) ]
            ohdl.write("\t".join(line)+"\n")

usage = "usage: %prog [options]\n"

def main(args):
    global JOBID, DB_VER
    parser = OptionParser(usage=usage)
    parser.add_option('-i', '--input', dest="input", default=None, help="input file: expanded sims")
    parser.add_option('-o', '--output', dest="output", default=None, help="output file: summary abundace")
    parser.add_option('-j', '--job', dest="job", default=None, help="job identifier")
    parser.add_option('-t', '--type', dest="type", default=None, help="type of summary, one of: "+",".join(TYPES))
    parser.add_option('-v', '--m5nr_version', dest="m5nr_version", type="int", default=1, help="version of m5nr annotation")   
    parser.add_option('-m', '--memory', dest="memory", action="store_true", default=False, help="output memory usage to memory.log [default off]")
    parser.add_option('--coverage', dest="coverage", default=None, help="optional input file: assembely coverage")
    parser.add_option('--cluster', dest="cluster", default=None, help="optional input file: cluster mapping")
    parser.add_option('--md5_index', dest="md5_index", default=None, help="optional input file: md5,seek,length")
    
    (opts, args) = parser.parse_args()
    if not (opts.input and os.path.isfile(opts.input)):
        parser.error("[error] missing required input file")
        return 1
    if not opts.output:
        parser.error("[error] missing required output file")
        return 1
    if not opts.job:
        parser.error("[error] missing required job identifier")
        return 1
    if not (opts.type and (opts.type in TYPES)):
        parser.error("[error] missing or invalid type")
        return 1
    JOBID  = opts.job
    DB_VER = str(opts.m5nr_version)
    
    # fork the process
    pid = os.fork()
    if pid:
        # we are the parent
        
    
    # get optional file info
    amap = parse_file(opts.coverage, 'coverage')
    cmap = parse_file(opts.cluster, 'cluster')
    imap = parse_file(opts.md5_index, 'index')
    
    # Variables used to track which entries to record.  If the fragment ID (read
    #  or cluster ID) has changed, then the frag_keys hash will be emptied.  But,
    #  as long as we're on the same read (the only thing we know the expand file
    #  to be sorted by), then we want to record all the ID's we're recording so
    #  that nothing gets recorded in duplicate.
    prev_frag = ""
    frag_keys = set()
    
    # data structs to fill
    data = {}
    md5s = {}
    dt = DTYPES[opts.type] if opts.type in DTYPES else DTYPES['other']
    
    # parse expand file
    ihdl = open(opts.input, 'rU')
    for line in ihdl:
        parts = line.strip().split('\t')
        (md5, frag, ident, length, e_val, fid, oid, source) = parts[:8]
        is_protein = False if (len(parts) > 8) and (parts[8] == 1) else True
        if not (frag and md5):
            continue
        
        if opts.type == 'md5':
            if frag != prev_frag:
                frag_keys.clear()
            if md5 not in frag_keys:
                if md5 not in data:
                    data[md5] = np.zeros(1, dtype=dt)
                eval_exp = get_exponent(e_val)
                abun = get_abundance(frag, amap, cmap)
                if abun < 1:
                    continue
                data[md5][0]['abun'] += abun
                data[md5][0]['esum'] += abun * eval_exp
                data[md5][0]['esos'] += abun * eval_exp * eval_exp
                data[md5][0]['lsum'] += abun * length
                data[md5][0]['lsos'] += abun * length * length
                data[md5][0]['isum'] += abun * ident
                data[md5][0]['isos'] += abun * ident * ident
                data[md5][0]['ebin'] = update_e_bin(eval_exp, abun, data[md5][0]['ebin'])
                data[md5][0]['isp']  = is_protein
                frag_keys.add(md5)
        elif opts.type in ['function', 'organism', 'ontology']:
            if opts.type == 'function':
                aid = fid
                akey = (fid, source)
            elif (opts.type == 'ontology') or (opts.type == 'organism'):
                aid = oid
                akey = (oid, source)                
            if not aid:
                continue
            if frag != prev_frag:
                frag_keys.clear()
            if akey not in frag_keys:
                if aid not in data:
                    data[aid] = np.zeros(SOURCES, dtype=dt)
                    md5s[aid] = defaultdict(set)
                eval_exp = get_exponent(e_val)
                abun = get_abundance(frag, amap, cmap)
                if abun < 1:
                    continue
                data[fid][source-1]['source'] = source
                data[fid][source-1]['abun'] += abun
                data[fid][source-1]['esum'] += abun * eval_exp
                data[fid][source-1]['esos'] += abun * eval_exp * eval_exp
                data[fid][source-1]['lsum'] += abun * length
                data[fid][source-1]['lsos'] += abun * length * length
                data[fid][source-1]['isum'] += abun * ident
                data[fid][source-1]['isos'] += abun * ident * ident
                md5s[fid][source].add(md5)
                frag_keys.add(akey)                
        
        prev_frag = frag
        # end of file looping
    ihdl.close()
    
    # no stats !
    if len(data) == 0:
        open(opts.output, 'w').close()
        print "[warning] no summary data computed"
        return 0
    
    # output stats        
    ohdl = open(opts.output, 'w')
    if opts.type == 'md5':
        print_md5_stats(ohdl, data, imap)
    elif opts.type in ['function', 'organism', 'ontology']:
        print_md5_stats(ohdl, data, md5s)
    ohdl.close()
    
    return 0
    
if __name__ == "__main__":
    sys.exit(main(sys.argv))
