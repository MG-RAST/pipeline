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
import time
import math
import numpy as np
import subprocess
from collections import defaultdict
from optparse import OptionParser

# constants
SOURCES = None
ev_re  = re.compile(r"^(\d(\.\d)?)e([-+])?0?(\d+)$") # .group(4) == abs(exponent)
TYPES  = ['md5', 'function', 'organism', 'ontology', 'lca', 'source']
EVALS  = [-5 , -10 , -20 , -30 , -1000]
IDENTS = [60 , 80 , 90 , 97 , 100]
JOBID  = None
DB_VER = None

# numpy dtypes
DTYPES = {
    'md5': np.dtype([ ('abun', np.uint32), ('esum', np.float32), ('esos', np.float32),
                      ('lsum', np.float32), ('lsos', np.float32), ('isum', np.float32),
                      ('isos', np.float32), ('ebin', np.uint16, (5)), ('isp', np.bool_) ]),
    'lca': np.dtype([ ('abun', np.uint32), ('esum', np.float32), ('esos', np.float32),
                      ('lsum', np.float32), ('lsos', np.float32), ('isum', np.float32),
                      ('isos', np.float32), ('lvl', np.uint8) ]),
    'other': np.dtype([ ('source', np.uint8), ('abun', np.uint32), ('esum', np.float32),   
                        ('esos', np.float32), ('lsum', np.float32), ('lsos', np.float32),
                        ('isum', np.float32), ('isos', np.float32) ])
}

def memory_usage(pid):
    """Memory usage of a process in kilobytes."""
    status = None
    result = {'peak': 0, 'rss': 0}
    try:
        # This will only work on systems with a /proc file system (like Linux).
        status = open('/proc/%s/status'%(str(pid) if pid else 'self'))
        for line in status:
            parts = line.split()
            key = parts[0][2:-1].lower()
            if key in result:
                result[key] = int(parts[1])
    finally:
        if status is not None:
            status.close()
    return result

def index_map(fname):
    if not (fname and os.path.isfile(fname)):
        return None
    # line count
    p = subprocess.Popen(['wc', '-l', fname], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    result, err = p.communicate()
    if p.returncode != 0:
        raise IOError(err)
    length = int(result.strip().split()[0])
    # make array
    dt = np.dtype([ ('md5', np.uint32), ('seek', np.uint64), ('length', np.uint32) ])
    ia = np.zeros(length, dtype=dt)
    # populate array
    with open(fname, 'rU') as fhdl:
        for i, line in enumerate(fhdl):
            tabs = line.strip().split('\t')
            if len(tabs) != 3:
                continue
            ia[i][0] = int(tabs[0])
            ia[i][1] = int(tabs[1])
            ia[i][2] = int(tabs[2])
    return ia

def abundance_map(afile, cfile):
    data = defaultdict(int)
    if afile and os.path.isfile(afile):
        with open(afile, 'rU') as fhdl:
            for line in fhdl:
                tabs = line.strip().split('\t')
                # string may be an int or float / need to cast as int
                try:
                    data[tabs[0]] = int(tabs[1])
                except ValueError:
                    try:
                        data[tabs[0]] = int(float(tabs[1]))
                    except ValueError:
                        data[tabs[0]] = 0
    if cfile and os.path.isfile(cfile):
        with open(cfile, 'rU') as fhdl:
            for line in fhdl:
                tabs = line.strip().split('\t')
                #ids = tabs[2].split(',') # old way
                #ids.append(tabs[1])      # old way
                ids = tabs[1].split(',') # new way
                for i in ids:
                    if i in data:
                        data[tabs[0]] += data[i]
                    else:
                        data[tabs[0]] += 1
    return data

def get_e_bin(val):
    if (val == 0) or (val < EVALS[-1]):
        return EVALS[-1]
    for e in EVALS:
        if val >= e:
            return e
    return EVALS[0]

def get_i_bin(val):
    for i in IDENTS:
        if val <= i:
            return i
    return IDENTS[0]

def update_e_bin(exp, abun, bins):
    if exp == 0:
        bins[-1] += abun
    else:
        for i, e in enumerate(EVALS):
            if exp >= e:
                bins[i] += abun
                break

def get_abundance(frag, amap):
    abun = amap[frag] if frag in amap else 1
    return math.ceil(abun)

def get_exponent(e_val):
    if e_val == 0:
        return 0
    ev_match = ev_re.match(str(e_val))
    if not ev_match:
        try:
            (i, f) = str(e_val).split('.')
            return len(f) * -1
        except:
            sys.stderr.write("[warning] bad e-value: "+str(e_val))
            os._exit(1)
        return len(f) * -1
    if ev_match.group(3) and (ev_match.group(3) == '-'):
        return int(ev_match.group(4)) * -1
    else:
        return int(ev_match.group(4))

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
    if len(data) == 0:
        return
    for md5 in sorted(data):
        stats  = data[md5][0]
        e_mean = stats['esum'] / stats['abun']
        l_mean = stats['lsum'] / stats['abun']
        i_mean = stats['isum'] / stats['abun']
        # get indexes
        seek, length = '', ''
        if imap is not None:
            match = np.where(imap['md5']==md5)
            if len(match[0]) > 0:
                row = match[0][0]
                # length must be less than or equal to 2147483647
                if imap[row][2] <= 2147483647:
                    seek, length = str(imap[row][1]), str(imap[row][2])
        # output
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
                 "1" if stats['isp'] else "0" ]
        ohdl.write("\t".join(line)+"\n")

def print_lca_stats(ohdl, data, md5s):
    if len(data) == 0:
        return
    for lca in sorted(data):
        stats  = data[lca][0]
        e_mean = stats['esum'] / stats['abun']
        l_mean = stats['lsum'] / stats['abun']
        i_mean = stats['isum'] / stats['abun']
        line = [ DB_VER,
                 JOBID,
                 str(lca),
                 str(stats['abun']),
                 str_round(e_mean),
                 str_round(stddev(e_mean, stats['esos'], stats['abun'])),
                 str_round(l_mean),
                 str_round(stddev(e_mean, stats['esos'], stats['abun'])),
                 str_round(i_mean),
                 str_round(stddev(l_mean, stats['isos'], stats['abun'])),
                 str(len(md5s[lca])),
                 str(stats['lvl']) ]
        ohdl.write("\t".join(line)+"\n")

def print_type_stats(ohdl, data, md5s):
    if len(data) == 0:
        return
    for aid in sorted(data):
        for i in range(len(data[aid])):
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
                     "{"+",".join(map(str, md5s[aid][stats['source']]))+"}",
                     str(stats['source']) ]
            ohdl.write("\t".join(line)+"\n")

def print_source_stats(ohdl, data):
    if len(data) == 0:
        return
    for i in range(SOURCES+2):
        source = i+1
        if source not in data['e_val']:
            continue
        ohdl.write(str(source))
        for e in EVALS:
            if e in data['e_val'][source]:
                ohdl.write("\t%d"%data['e_val'][source][e])
            else:
                ohdl.write("\t0")
        for i in IDENTS:
            if i in data['ident'][source]:
                ohdl.write("\t%d"%data['ident'][source][i])
            else:
                ohdl.write("\t0")
        ohdl.write("\n")


usage = "usage: %prog [options]\n"

def main(args):
    global SOURCES, JOBID, DB_VER
    parser = OptionParser(usage=usage)
    parser.add_option('-i', '--input', dest="input", default=None, help="input file: expanded sims")
    parser.add_option('-o', '--output', dest="output", default=None, help="output file: summary abundace")
    parser.add_option('-j', '--job', dest="job", default=None, help="job identifier")
    parser.add_option('-t', '--type', dest="type", default=None, help="type of summary, one of: "+",".join(TYPES))
    parser.add_option('-s', '--m5nr_sources', dest="m5nr_sources", type="int", default=18, help="number of real sources in m5nr")
    parser.add_option('-v', '--m5nr_version', dest="m5nr_version", type="int", default=1, help="version of m5nr annotation")
    parser.add_option('-m', '--memory', dest="memory", type="int", default=0, help="log memory usage to *.mem.log [default off]")
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
    SOURCES = opts.m5nr_sources
    JOBID   = opts.job
    DB_VER  = str(opts.m5nr_version)
    
    # fork the process
    pid = None
    if opts.memory:
        pid = os.fork()
    
    # we are the parent
    if pid:
        info = os.waitpid(pid, os.WNOHANG)
        mhdl = open(opts.output+'.mem.log', 'w')
        while(info[0] == 0):
            mem = memory_usage(pid)['rss']
            mhdl.write("%d\n"%int(mem/1024))
            mhdl.flush()
            time.sleep(opts.memory)
            info = os.waitpid(pid, os.WNOHANG)
        mhdl.close()
    
    # we are child or no forking
    else:
        # get optional file info
        imap = index_map(opts.md5_index)
        amap = abundance_map(opts.coverage, opts.cluster)
        
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
        if opts.type == 'source':
            data['e_val'] = defaultdict(lambda: defaultdict(int))
            data['ident'] = defaultdict(lambda: defaultdict(int))
        
        # parse expand file
        ihdl = open(opts.input, 'rU')
        for line in ihdl:
            parts = line.strip().split('\t')
            if len(parts) < 7:
                continue
            (md5, frag, ident, length, e_val, fid, oid) = parts[:7]
            is_protein = True
            if (len(parts) > 8) and (parts[8] == "1"):
                is_protein = False
            if not (frag and md5):
                continue
            if opts.type != 'lca':
                (md5, ident, length, e_val, source) = (int(md5), float(ident), int(length), float(e_val), int(parts[7]))
            
            if opts.type == 'md5':
                if frag != prev_frag:
                    frag_keys.clear()
                if md5 not in frag_keys:
                    if md5 not in data:
                        data[md5] = np.zeros(1, dtype=dt)
                    eval_exp = get_exponent(e_val)
                    abun = get_abundance(frag, amap)
                    if abun < 1:
                        continue
                    data[md5][0]['abun'] += abun
                    data[md5][0]['esum'] += abun * eval_exp
                    data[md5][0]['esos'] += abun * eval_exp * eval_exp
                    data[md5][0]['lsum'] += abun * length
                    data[md5][0]['lsos'] += abun * length * length
                    data[md5][0]['isum'] += abun * ident
                    data[md5][0]['isos'] += abun * ident * ident
                    data[md5][0]['isp']  = is_protein
                    update_e_bin(eval_exp, abun, data[md5][0]['ebin'])
                    frag_keys.add(md5)
            elif opts.type == 'lca':
                if not fid:
                    continue
                lca = fid
                level = int(oid)
                if lca not in data:
                    data[lca] = np.zeros(1, dtype=dt)
                    md5s[lca] = set()
                abun = get_abundance(frag, amap)
                if abun < 1:
                    continue
                e_line_sum = sum(map(lambda x: get_exponent(float(x)), e_val.split(';')))
                l_line_sum = sum(map(int, length.split(';')))
                i_line_sum = sum(map(float, ident.split(';')))
                md5_count  = 0
                for m in md5.split(';'):
                    md5_count += 1
                    md5s[lca].add(int(m))
                e_avg = e_line_sum / md5_count
                l_avg = l_line_sum / md5_count
                i_avg = i_line_sum / md5_count
                data[lca][0]['abun'] += abun
                data[lca][0]['esum'] += abun * e_avg
                data[lca][0]['esos'] += abun * e_avg * e_avg
                data[lca][0]['lsum'] += abun * l_avg
                data[lca][0]['lsos'] += abun * l_avg * l_avg
                data[lca][0]['isum'] += abun * i_avg
                data[lca][0]['isos'] += abun * i_avg * i_avg
                data[lca][0]['lvl']  = level
            elif opts.type in ['function', 'organism', 'ontology']:
                if fid and (opts.type == 'function'):
                    aid = int(fid)
                elif oid and ((opts.type == 'ontology') or (opts.type == 'organism')):
                    aid = int(oid)
                else:
                    continue
                akey = (aid, source)
                if frag != prev_frag:
                    frag_keys.clear()
                if akey not in frag_keys:
                    if aid not in data:
                        if opts.type == 'organism':
                            data[aid] = np.zeros(SOURCES+2, dtype=dt)
                        else:
                            data[aid] = np.zeros(SOURCES, dtype=dt)
                        md5s[aid] = defaultdict(set)
                    eval_exp = get_exponent(e_val)
                    abun = get_abundance(frag, amap)
                    if abun < 1:
                        continue
                    data[aid][source-1]['source'] = source
                    data[aid][source-1]['abun'] += abun
                    data[aid][source-1]['esum'] += abun * eval_exp
                    data[aid][source-1]['esos'] += abun * eval_exp * eval_exp
                    data[aid][source-1]['lsum'] += abun * length
                    data[aid][source-1]['lsos'] += abun * length * length
                    data[aid][source-1]['isum'] += abun * ident
                    data[aid][source-1]['isos'] += abun * ident * ident
                    md5s[aid][source].add(md5)
                    frag_keys.add(akey)                
                    if opts.type == 'organism':
                        merge = 20 if is_protein else 19
                        akey  = (aid, merge)
                        data[aid][merge-1]['source'] = merge
                        data[aid][merge-1]['abun'] += abun
                        data[aid][merge-1]['esum'] += abun * eval_exp
                        data[aid][merge-1]['esos'] += abun * eval_exp * eval_exp
                        data[aid][merge-1]['lsum'] += abun * length
                        data[aid][merge-1]['lsos'] += abun * length * length
                        data[aid][merge-1]['isum'] += abun * ident
                        data[aid][merge-1]['isos'] += abun * ident * ident
                        md5s[aid][merge].add(md5)
                        frag_keys.add(akey)                
            elif opts.type == 'source':
                if not source:
                    continue
                eval_exp = get_exponent(e_val)
                abun = get_abundance(frag, amap)
                if abun < 1:
                    continue
                e_bin = get_e_bin(eval_exp)
                i_bin = get_i_bin(ident)
                data['e_val'][source][e_bin] += abun
                data['ident'][source][i_bin] += abun
            prev_frag = frag
            # end of file looping
        ihdl.close()
    
        # output stats        
        ohdl = open(opts.output, 'w')
        if opts.type == 'md5':
            print_md5_stats(ohdl, data, imap)
        elif opts.type == 'lca':
            print_lca_stats(ohdl, data, md5s)
        elif opts.type in ['function', 'organism', 'ontology']:
            print_type_stats(ohdl, data, md5s)
        elif opts.type == 'source':
            print_source_stats(ohdl, data)
        ohdl.close()
    
    # exit if child fork
    if pid == 0:
        os._exit(0)
    else:
        return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
