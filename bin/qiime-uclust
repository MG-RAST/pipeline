#!/usr/bin/env python

import os, sys, pprint, subprocess
from optparse import OptionParser
from Bio import SeqIO
from qiime.pycogent_backports.uclust import Uclust

usage = "usage: %prog [options]\n"

def cluster(infasta, outclust, pid, rev, tmpdir):
    params = {'--id': pid}
    if rev:
        params['--rev'] = True
    app = Uclust(params,HALT_EXEC=False,TmpDir=tmpdir)
    app_result = app({'--input': infasta,'--uc': outclust})
    if app_result['ExitStatus'] != 0:
        sys.stderr.write( app_result['StdErr'].read() )
        sys.exit( app_result['ExitStatus'] )
    app_result['ClusterFile'].close()

def search(infasta, inlib, outclust, pid, rev, tmpdir):
    params = {'--id': pid, '--lib': inlib, '--libonly': True}
    if rev:
        params['--rev'] = True
    app = Uclust(params,HALT_EXEC=False,TmpDir=tmpdir)
    app_result = app({'--input': infasta,'--uc': outclust})
    if app_result['ExitStatus'] != 0:
        sys.stderr.write( app_result['StdErr'].read() )
        sys.exit( app_result['ExitStatus'] )
    app_result['ClusterFile'].close()

def uc2fasta(infasta, inclust, outfasta, types, nameonly, tmpdir):
    typeSet  = dict([(x, 1) for x in types])
    outTmp   = os.path.join(tmpdir, os.path.basename(outfasta)+'.tmp')
    tmpHdl   = open(outTmp, 'w')
    fastaHdl = open(infasta, 'rU')
    clustHdl = open(inclust, 'rU')
    fastaItr = SeqIO.parse(fastaHdl, 'fasta')
    curFasta = fastaItr.next()

    for line in clustHdl:
        if line.startswith('#'):
            continue
        parts = line.split("\t")
        (ctype, cname, pid, sname) = (parts[0], parts[1], parts[3], parts[8])
        if ctype not in typeSet:
            continue
        while sname != curFasta.id:
            try:
                curFasta = fastaItr.next()
            except StopIteration:
                break
            if not curFasta:
                break
        if nameonly:
            tmpHdl.write("%s\t%s\n"%(sname, str(curFasta.seq)))
        else:
            pidStr = pid if pid == '*' else pid+'%'
            tmpHdl.write("%s|%s|%s\t%s\n"%(cname, pidStr, sname, str(curFasta.seq)))
    clustHdl.close()
    fastaHdl.close()
    tmpHdl.close()

    sortTmp = outTmp+'.sort'
    if nameonly:
        args = ["sort", "-u", "-T", tmpdir, "-o", sortTmp, outTmp]
    else:
        args = ["sort", "-T", tmpdir, "-t", "|", "-k", "1,1n", "-k", "2,2n", "-o", sortTmp, outTmp]
    proc = subprocess.Popen(args)
    proc.communicate()
    SeqIO.convert(sortTmp, "tab", outfasta, "fasta")
    os.remove(outTmp)
    os.remove(sortTmp)
    
def seqSort(infasta, outfasta, tmpdir):
    params = {'--tmpdir': tmpdir}
    app = Uclust(params,HALT_EXEC=False,TmpDir=tmpdir)
    app_result = app(data={'--mergesort': infasta, '--output': outfasta})
    if app_result['ExitStatus'] != 0:
        sys.stderr.write( app_result['StdErr'].read() )
        sys.exit( app_result['ExitStatus'] )
    app_result['Output'].close()

def main(args):
    parser = OptionParser(usage=usage)
    parser.add_option("--input", dest="input", default=None, help="Input fasta file, sorted by sequence length")
    parser.add_option("--sort", dest="sort", default=None, help="Input fasta file to sort")
    parser.add_option("--mergesort", dest="mergesort", default=None, help="Input large fasta file to sort")
    parser.add_option("--tmpdir", dest="tmpdir", default="/tmp", help="Dir to store temperary files [default '/tmp']")
    parser.add_option("--output", dest="output", default=None, help="Output fasta file for mergesort/sort/uc2fasta")
    parser.add_option("--uc", dest="uc", default=None, help="Output uc file for clustering/searching")
    parser.add_option("--uc2fasta", dest="uc2fasta", default=None, help="Input uc file for creating fasta from it")
    parser.add_option("--lib", dest="lib", default=None, help="Library file for searching, a reference of sequences representing pre-existing clusters")
    parser.add_option("--types", dest="types", default='SH', help="Record types to include for uc2fasta [default SH]")
    parser.add_option("--id", dest="id", type="float", default=0.9, help="Minimum identity for a hit [default 0.9]")
    parser.add_option("--rev", dest="rev", action="store_true", default=False, help="Reverse strand matching [default plus strand only]")
    parser.add_option("--origheader", dest="origheader", action="store_true", default=False, help="Output origional fasta header when using uc2fasta [default add cluster name and percent identity]")

    (opts, args) = parser.parse_args()
    if not os.path.isdir(opts.tmpdir):
        parser.print_help()
        print "[error] invalid tmpdir"
        return 1
    if opts.input and os.path.isfile(opts.input) and opts.lib and os.path.isfile(opts.lib) and opts.uc:
        search(opts.input, opts.lib, opts.uc, opts.id, opts.rev, opts.tmpdir)
    elif opts.input and os.path.isfile(opts.input) and opts.uc:
        cluster(opts.input, opts.uc, opts.id, opts.rev, opts.tmpdir)
    elif opts.input and os.path.isfile(opts.input) and opts.uc2fasta and os.path.isfile(opts.uc2fasta) and opts.output:
        uc2fasta(opts.input, opts.uc2fasta, opts.output, opts.types, opts.origheader, opts.tmpdir)
    elif opts.sort and os.path.isfile(opts.sort) and opts.output:
        seqSort(opts.sort, opts.output, opts.tmpdir)
    elif opts.mergesort and os.path.isfile(opts.mergesort) and opts.output:
        seqSort(opts.mergesort, opts.output, opts.tmpdir)
    else:
        parser.print_help()
        print "[error] must give valid command, use one of sort, mergesort, uc, or uc2fasta"
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
