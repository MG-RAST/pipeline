#!/usr/bin/env python


import os, sys, time, datetime, operator, shutil
import subprocess as sub
from optparse import OptionParser

Min_Hits = 20
EXIT_MISSING_INPUT = 1
EXIT_RUNBLAT_FAIL = 2
ENV_VAR_DBPATH = 'REFDBPATH'
Info_log = open("awe_blat.info", "w")


def sortandbleach(sims_file, out_file):
    print "started sort and bleach"
    sorted_file = "%s.sorted" % sims_file
    cmd = "sort -t '\t' -k 1,1 -T . %s > %s" % (sims_file, sorted_file)
    proc = sub.Popen([cmd], shell=True, stdout=sub.PIPE)
    while (proc.returncode == None):
        proc.poll()
        if (proc.returncode != None):
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
    count = 0 
    sims.sort(cmp=lambda a, b: cmp(float(a), float(b)), key=operator.itemgetter(11), reverse=True)
    for s in sims:
        if ( count < Min_Hits ):            
            out.write("%s\n" % ("\t".join(s)))
            count += 1

def runBlatProcess(infile, nr, output):
    try:
        tmp_out1 = "%s.1" % output
        tmp_out2 = "%s.2" % output
        cmd1 = "superblat -prot -fastMap -out=blast8 %s.1 %s %s" % (nr, infile, tmp_out1)
        cmd2 = "superblat -prot -fastMap -out=blast8 %s.2 %s %s" % (nr, infile, tmp_out2)
        start = datetime.datetime.utcnow()

        proc1 = sub.Popen([cmd1], shell=True, stdout=sub.PIPE)
        proc2 = sub.Popen([cmd2], shell=True, stdout=sub.PIPE)

        while (proc1.returncode == None or proc2.returncode == None):
                proc1.poll()
                proc2.poll()
                if (proc1.returncode != None and proc2.returncode != None):
                        break
                else:
                        time.sleep(5)
                        
        cat_output = "%s.cat_blat" % output
        
        destination = open(cat_output,'wb')
        shutil.copyfileobj(open(tmp_out1,'rb'), destination)
        shutil.copyfileobj(open(tmp_out2,'rb'), destination)
        destination.close()
        os.remove(tmp_out1)
        os.remove(tmp_out2)
        print "finished running superblat - time: %s m\n" % ((datetime.datetime.utcnow() - start).seconds / 60)
        Info_log.write("runBlatProcess - finished - time: %s m\n" % ((datetime.datetime.utcnow() - start).seconds / 60))
        return
        
    except (KeyboardInterrupt, SystemExit):
        Info_log.write("runBlatProcessPara - killed")
        sys.exit(EXIT_RUNBLAT_FAIL)

if __name__ == "__main__":
    usage  = "usage: awe_blat.py --input=<input file name (*.faa)> --output=<output file name>"
    parser = OptionParser(usage)
    parser.add_option("-i", "--input",  dest="input", type = "string", default=None, help="input file path")
    parser.add_option("-o", "--output", dest="output", type = "string", default=None, help="output file path")
    
    (opts, args) = parser.parse_args()
    
    if not (opts.input and os.path.isfile(opts.input) ):
        parser.error("Missing input src file %s"%(opts.input, ))
        sys.exit(EXIT_MISSING_INPUT)
        
    infile = opts.input
    
    if opts.output:
        outfile = opts.output
    else:
        outfile = "blat_output"
        
    if os.environ.get('REFDBPATH'):
        refdb = "%s/md5nr" % (os.environ.get(ENV_VAR_DBPATH))
    else:
        refdb = "md5nr"
        
    blat_hits = runBlatProcess(infile, refdb, outfile)
        
    sortandbleach("%s.cat_blat" % outfile, outfile)
    
    Info_log.close()
