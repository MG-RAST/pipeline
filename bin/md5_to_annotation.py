#!/usr/bin/env python

import os
import re
import sys
import time
import json
import bsddb
import logging
from collections import defaultdict
from optparse import OptionParser

TAXA = ['domain', 'phylum', 'class', 'order', 'family', 'genus', 'species']
SKIP_RE = re.compile('other|unknown|unclassified')

# logging
LOG_FORMAT = '[%(asctime)-15s] [%(levelname)-5s] %(message)s'
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)
logger = logging.getLogger()

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

usage = "usage: %prog [options]\n"

def main(args):
    global TMP_DIR
    parser = OptionParser(usage=usage)
    parser.add_option("-f", "--function", dest="function", default=None, help="output function filename")
    parser.add_option("-t", "--taxonomy", dest="organism", default=None, help="output taxonomy filename")
    parser.add_option("-o", "--ontology", dest="accession", default=None, help="output ontology (functional category) filename")
    parser.add_option("-i", "--input", dest="input", default=None, help="input filename")
    parser.add_option("-d", "--database", dest="database", default=None, help="m5nr berkeleydb file")
    parser.add_option("--tax_map", dest="tax_map", default=None, help="taxonomy (organism hierarchy) mapping file")
    parser.add_option("--ont_map", dest="ont_map", default=None, help="ontology (functional category) mapping file")
    parser.add_option('-m', '--memory', dest="memory", type="int", default=0, help="log memory usage to *.mem.log [default off]")
    
    (opts, args) = parser.parse_args()
    if not (opts.function or opts.organism or opts.accession):
        logger.error("need at least one output type")
        return 1
    if opts.organism and (not opts.tax_map):
        logger.error("missing taxonomy mapping file")
        return 1
    if opts.accession and (not opts.ont_map):
        logger.error("missing ontology mapping file")
        return 1
    if not opts.input:
        logger.error("missing input md5 file")
        return 1
    if not opts.database:
        logger.error("missing m5nr database file")
        return 1
    
    # fork the process
    pid = None
    if opts.memory:
        pid = os.fork()
    
    # we are the parent
    if pid:
        info = os.waitpid(pid, os.WNOHANG)
        mhdl = open(opts.output+'.mem.log', 'w')
        mhdl.write("start %d\n"%time.time())
        while(info[0] == 0):
            mem = memory_usage(pid)['rss']
            mhdl.write("%d\n"%int(mem/1024))
            mhdl.flush()
            time.sleep(opts.memory)
            info = os.waitpid(pid, os.WNOHANG)
        mhdl.write("stop %d\n"%time.time())
        mhdl.close()
    
    # we are child or no forking
    else:
        # initalize output objects
        func_map = defaultdict(int)
        org_map  = dict([ (t, defaultdict(int)) for t in TAXA ])
        acc_map  = {}
        
        # get handles
        tax_hier = json.load(open(opts.tax_map, 'rU')) if opts.organism else {}
        ont_hier = json.load(open(opts.ont_map, 'rU')) if opts.accession else {}
        m5nr_map = bsddb.hashopen(opts.database, 'r')
        file_hdl = open(opts.input, 'rU')
    
        # proccess input file
        total = 0
        found = 0
        logger.info("started parsing md5 file")
        for line in file_hdl:
            total += 1
            parts = line.strip().split("\t")
            md5, abund = parts[0], int(parts[1])
            if md5 not in m5nr_map:
                continue
            has_ann = 0
            data = json.loads(m5nr_map[md5])
            for rec in data:
                if opts.function and rec['function']:
                    for f in rec['function']:
                        func_map[f] += abund
                        has_ann = 1
                if opts.organism and rec['organism']:
                    for o in rec['organism']:
                        if o not in tax_hier:
                            continue
                        skip_m = SKIP_RE.match(o)
                        for i, t in enumerate(TAXA):
                            if ((t == 'domain') and skip_m) or (not tax_hier[o][i]):
                                continue
                            org_map[t][tax_hier[o][i]] += abund
                            has_ann = 1
                if opts.accession and rec['accession'] and (rec['source'] in ont_hier):
                    if rec['source'] not in acc_map:
                        acc_map[rec['source']] = defaultdict(int)
                    for a in rec['accession']:
                        if a in ont_hier[rec['source']]:
                            level = ont_hier[rec['source']][a]
                            acc_map[rec['source']][level] += abund
                            has_ann = 1
            if has_ann:
                found += 1
        
        logger.info("completed - annotated %d out of %d md5s"%(found, total))
    
        # reformat and dump output for each type
        if opts.function:
            temp = [ [k, v] for k, v in func_map.iteritems() ]
            json.dump(temp, open(opts.function, 'w'))
        if opts.organism:
            temp = {}
            for name, taxa in org_map.iteritems():
                temp[name] = [ [k, v] for k, v in taxa.iteritems() ]
            json.dump(temp, open(opts.organism, 'w'))
        if opts.accession:
            temp = {}
            for name, level in acc_map.iteritems():
                temp[name] = [ [k, v] for k, v in level.iteritems() ]
            json.dump(temp, open(opts.accession, 'w'))
    
    # exit if child fork
    if pid == 0:
        os._exit(0)
    else:
        return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
