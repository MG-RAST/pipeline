#!/usr/bin/env python

import os, re, sys, time, datetime, logging
import subprocess as sub
from optparse import OptionParser

MIN_HITS = 20
MAX_EVAL = 0.001
ID_RE = re.compile(r'^(\S+)\t')
EXIT_MISSING_INPUT = 1
EXIT_MISSING_OUTPUT = 1
EXIT_RUNDIAMOND_FAIL = 2

# logging
LOG_FORMAT = '[%(asctime)-15s] [%(levelname)-5s] %(message)s'
logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)
logger = logging.getLogger()

def sortandbleach(sim_files, out_file, sort_dir):
    start = datetime.datetime.utcnow()
    merge_file = "%s.merge"%(out_file)
    # sort merge files
    cmd  = "sort -m -t '\t' -k 1,1 -k 12,12nr -k 3,3nr -T %s -o %s %s"%(sort_dir, merge_file, " ".join(sim_files))
    proc = sub.Popen([cmd], shell=True, stdout=sub.PIPE)
    while proc.returncode == None:
        proc.poll()
        if proc.returncode != None:
            break
        time.sleep(5)
        
    for f in sim_files:
        os.remove(f)
    
    sims_handle = open(merge_file, "Ur")
    out_handle = open(out_file, "w")
    curid = None
    cursims = []
    for l in sims_handle:
        idmatch = ID_RE.match(l)
        if idmatch == None:
            continue
        thisid = idmatch.group(1)
        if curid == None:
            curid = thisid
        if thisid == curid:
            cursims.append(l)
        else:
            printLines(cursims, out_handle)
            curid = thisid
            cursims = [l]
    printLines(cursims, out_handle)
    sims_handle.close()            
    out_handle.close()
    os.remove(merge_file)
       
    logger.info("sortandbleach - finished - time: %s m"%((datetime.datetime.utcnow() - start).seconds / 60))
    return

def printLines(lines, out):
    if len(lines) > MIN_HITS:
        lines = lines[:MIN_HITS]
    for l in lines:
        out.write(l)

def runDiamondProcess(infile, nr, parts, size, output):
    result_files = []
    
    try:
        start = datetime.datetime.utcnow()

        for i in range(1, parts+1):
            tmp_out = "%s.%d"%(output, i)
            tmp_nr = "%s.%d.dmnd"%(nr, i)
            cmd  = "diamond blastp -t /dev/shm -e %f -k %d -b %d -d %s -q %s -o %s"%(MAX_EVAL, MIN_HITS, size, tmp_nr, infile, tmp_out)
            proc = sub.Popen([cmd], shell=True, stdout=sub.PIPE)
            while (proc.returncode == None):
                proc.poll()
                if (proc.returncode != None):
                    break
                else:
                    time.sleep(5)
            result_files.append(tmp_out)

        logger.info("runDiamondProcess - finished - time: %s m"%((datetime.datetime.utcnow() - start).seconds / 60))
        return result_files
    except (KeyboardInterrupt, SystemExit):
        logger.error("runBlatProcess - killed")
        sys.exit(EXIT_RUNDIAMOND_FAIL)

if __name__ == "__main__":
    usage  = "usage: mgrast_diamond_prot.py --input=<input file name (*.faa)> --output=<output file name>"
    parser = OptionParser(usage)
    parser.add_option("-i", "--input", dest="input", type = "string", default=None, help="input file path")
    parser.add_option("-o", "--output", dest="output", type = "string", default=None, help="output file path")
    parser.add_option("-p", "--m5nr_prefix", dest="m5nr_prefix", type = "string", default="m5nr", help="prefix of m5nr file")
    parser.add_option("-n", "--m5nr_parts", dest="m5nr_parts", type = "int", default=4, help="number of files m5nr is divided into")
    parser.add_option("-b", "--block_size", dest="block_size", type = "int", default=10, help="control memory useage, this number x 6 in GB")
    parser.add_option("-d", "--sort_dir", dest="sort_dir", type = "string", default='.', help="temporary sort directory")
    (opts, args) = parser.parse_args()
    
    if not (opts.input and os.path.isfile(opts.input)):
        logger.error("Missing input src file %s"%opts.input)
        sys.exit(EXIT_MISSING_INPUT)
    if not opts.output:
        logger.error("Missing output file name")
        sys.exit(EXIT_MISSING_OUTPUT)
    
    diamond_hits = runDiamondProcess(opts.input, opts.m5nr_prefix, opts.m5nr_parts, opts.block_size, opts.output)
    sortandbleach(diamond_hits, opts.output, opts.sort_dir)
    
