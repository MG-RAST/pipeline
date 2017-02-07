#!/usr/bin/env python

import os
import sys
import time
import json
import bsddb
import logging
from collections import defaultdict

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

def output_for_type(atype, obj=None):
    temp = {}
    if atype == 'function':
        if obj is None:
            temp = defaultdict(int)
        else:
            temp = [ [k, v] for k, v in obj.iteritems() ]
    elif atype == 'organism':
        if obj is None:
            for t in TAXA:
                temp[t] = defaultdict(int)
        else:
            for name, taxa in obj.iteritems():
                temp[name] = [ [k, v] for k, v in taxa.iteritems() ]
    elif atype == 'ontology':
        if obj is not None:
            for name, level in obj.iteritems():
                temp[name] = [ [k, v] for k, v in level.iteritems() ]
    return temp


def main(args):
    global TMP_DIR
    parser = OptionParser(usage=usage)
    parser.add_option("-t", "--type", dest="type", default=None, help="annotation type, one of: organism, ontology, function")
    parser.add_option("-o", "--output", dest="output", default=None, help="output filename")
    parser.add_option("-i", "--input", dest="input", default=None, help="input filename")
    parser.add_option("-d", "--database", dest="database", default=None, help="m5nr berkeleydb file")
    parser.add_option("-h", "--hierarchy", dest="hierarchy", default=None, help="hierarchy mapping file, for organism or ontology")
    parser.add_option('-m', '--memory', dest="memory", type="int", default=0, help="log memory usage to *.mem.log [default off]")
    
    (opts, args) = parser.parse_args()
    if opts.type not in ['function', 'organism', 'ontology']:
        logger.error("incorrect annotation type")
        return 1
    if (not opts.hierarchy) and (opts.type != 'function')
        logger.error("missing hierarchy file")
        return 1
    if not (opts.input and opts.database):
        logger.error("[error] missing input / database file")
        return 1
    if not opts.output:
        logger.error("[error] missing output filename")
        return 1
    
    # get output object for type
    output = output_for_type(opts.type)
    
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
        hier_map = json.load(open(opts.hierarchy, 'rU'))
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
            data = json.loads(m5nr_map[md5])
            for rec in data:
                found += 1
                if (opts.type == 'function') and rec['function']:
                    for f in rec['function']:
                        output[f] += abund
                elif (opts.type == 'organism') and rec['organism']:
                    for o in rec['organism']:
                        if o not in hier_map:
                            continue
                        skip_m = SKIP_RE.match(o)
                        for i, t in enumerate(TAXA):
                            if (t == 'domain') and skip_m:
                                continue
                            output[t][hier_map[o][i]] += abund
                elif (opts.type == 'ontology') and (rec['source'] in hier_map) and rec['accession']:
                    if rec['source'] not in output:
                        output[rec['source']] = defaultdict(int)
                    for a in rec['accession']:
                        if a in hier_map[rec['source']]:
                            level = hier_map[rec['source']][a]
                            output[rec['source']][level] += abund
        
        logger.info("completed - annotated %d out of %d md5s"%(found, total))
    
        # reformat and dump output for type
        newoutput = output_for_type(opts.type, obj=output)
        json.dump(newoutput, open(opts.output, 'w'))
    
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
