#!/usr/bin/env python

import os, sys, time, datetime, operator, shutil
import subprocess as sub
from optparse import OptionParser

Min_Hits = 20
Max_Eval = 0.001
EXIT_MISSING_INPUT = 1
EXIT_RUNBLAT_FAIL = 2
ENV_VAR_DBPATH = 'REFDBPATH'
Info_log = open("awe_blat_prot_serial.info", "w")

def sortandbleach(sims_file, out_file, sort_dir):
    print "started sort and bleach"
    sorted_file = "%s.sorted"%sims_file
    # sort by id, bleach functions sorts by bitscore
    cmd  = "sort -t '\t' -k 1,1 -T %s %s > %s"%(sort_dir, sims_file, sorted_file)
    proc = sub.Popen([cmd], shell=True, stdout=sub.PIPE)
    while proc.returncode == None:
        proc.poll()
        if proc.returncode != None:
            break
        time.sleep(5)
        
    os.remove(sims_file)
    sims_handle = open(sorted_file, "Ur")
    out_handle = open(out_file, "w")
    curid = None
    cursims = []
    for l in sims_handle:
        v = l[:-1].split("\t")
        if curid == None:
            curid = v[0]
        if v[0] == curid:
            cursims.append(v)
        else:
            bleach(cursims, out_handle)
            curid = v[0]
            cursims = [v]
    bleach(cursims, out_handle)
    sims_handle.close()            
    out_handle.close()
    os.remove(sorted_file)
       
    Info_log.write("sortandbleach - finished")
    print "finished sort and bleach"
    return out_file

def bleach(sims, out):
    count = 1
    # sort by bitscore
    sims.sort(cmp=lambda a, b: cmp(float(a), float(b)), key=operator.itemgetter(11), reverse=True)
    for s in sims:
        # only output at most 20 hits better than e-03
        if (count > Min_Hits) or (float(s[10]) > Max_Eval):
            break
        out.write("\t".join(s)+"\n")
        count += 1

def runBlatProcess(infile, nr, parts, output):
    try:
        start = datetime.datetime.utcnow()
        cat_output = "%s.cat_blat"%output
        destination = open(cat_output,'wb')

        for i in range(1,parts+1):
            tmp_out = "%s.%s"%(output,i)
            tmp_nr = "%s.%s"%(nr,i)
            cmd  = "superblat -prot -fastMap -out=blast8 %s %s %s"%(tmp_nr, infile, tmp_out)
            proc = sub.Popen([cmd], shell=True, stdout=sub.PIPE)
            while (proc.returncode == None):
                proc.poll()
                if (proc.returncode != None):
                    break
                else:
                    time.sleep(5)
            shutil.copyfileobj(open(tmp_out,'rb'), destination)
            os.remove(tmp_out)

        destination.close()
        print "finished running superblat - time: %s m\n"%((datetime.datetime.utcnow() - start).seconds / 60)
        Info_log.write("runBlatProcess - finished - time: %s m\n"%((datetime.datetime.utcnow() - start).seconds / 60))
        return
    except (KeyboardInterrupt, SystemExit):
        Info_log.write("runBlatProcessPara - killed")
        sys.exit(EXIT_RUNBLAT_FAIL)

if __name__ == "__main__":
    usage  = "usage: awe_blat_prot_serial.py --input=<input file name (*.faa)> --output=<output file name>"
    parser = OptionParser(usage)
    parser.add_option("-i", "--input", dest="input", type = "string", default=None, help="input file path")
    parser.add_option("-o", "--output", dest="output", type = "string", default=None, help="output file path")
    parser.add_option("-m", "--m5nr_version", dest="m5nr_version", type = "string", default="10", help="version of m5nr")
    parser.add_option("-p", "--m5nr_parts", dest="m5nr_parts", type = "int", default="5", help="number of files m5nr is divided into")
    parser.add_option("-d", "--sort_dir", dest="sort_dir", type = "string", default='.', help="temporary sort directory")
    (opts, args) = parser.parse_args()
    
    if not (opts.input and os.path.isfile(opts.input)):
        parser.error("Missing input src file %s"%opts.input)
        sys.exit(EXIT_MISSING_INPUT)
    
    infile = opts.input
    if opts.output:
        outfile = opts.output
    else:
        outfile = "blat_output"
    if os.environ.get('REFDBPATH'):
        refdb = "%s/md5nr_v%s"%(os.environ.get(ENV_VAR_DBPATH), opts.m5nr_version)
    else:
        refdb = "md5nr_v%s"%(opts.m5nr_version)
    
    blat_hits = runBlatProcess(infile, refdb, opts.m5nr_parts, outfile)
    sortandbleach("%s.cat_blat"%outfile, outfile, opts.sort_dir)
    
    Info_log.close()
