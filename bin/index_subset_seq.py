#!/usr/bin/env python

import os
import sys
import subprocess as sub
from Bio import SeqIO
from optparse import OptionParser

__doc__ = """
Given a parent sequence file and one or more children sequence files
(the child containing a subset of the parents sequences),
return a sorted list of the record numbers of child with reference to parent.
Output is same as child file name + '.index'"""

TMP_DIR = None
MAX_MEM = None

def seq_type(file_hdl):
    first_char = file_hdl.read(1)
    file_hdl.seek(0)
    if first_char == '>':
        return 'fasta'
    elif first_char == '@':
        return 'fastq'
    else:
        sys.stderr.write("[error] invalid sequence file\n")
        sys.exit(1)

# if is_sorted == True then is a sequence file, otherwise id list
def get_iter(fname, is_sorted):
    fhdl = open(fname, 'rU')
    if is_sorted:
        ftype = seq_type(fhdl)
        return SeqIO.parse(fhdl, ftype)
    else:
        return fhdl

def sorted_ids(ifile, num=False):
    ihdl = open(ifile, 'rU')
    ohdl = open(ifile+'.sort', 'w')
    ftype = seq_type(ihdl)
    for i, rec in enumerate(SeqIO.parse(ihdl, ftype)):
        if num:
            ohdl.write("%s\t%d\n"%(rec.id, i+1))
        else:
            ohdl.write(rec.id+"\n")
    ihdl.close()
    ohdl.close()
    sort_file(ifile+'.sort')
    return ifile+'.sort'

def sort_file(fname, num=False):
    sortfile = open(fname+'.tmp', 'w')
    cmd = ["sort", "-T", TMP_DIR, "-S", str(MAX_MEM)+'M', "-k", "1,1", "-t", "\t", fname]
    if num:
        cmd.append('-n')
    p1 = sub.Popen(cmd, stdout=sortfile)
    p1.communicate()
    sortfile.close()
    os.remove(fname)
    os.rename(fname+'.tmp', fname)

usage = "usage: %prog [options] -p <parent file> -c <child file>\n" + __doc__

def main(args):
    global TMP_DIR, MAX_MEM
    parser = OptionParser(usage=usage)
    parser.add_option("-p", "--parent", dest="parent", default=None, help="parent sequence file")
    parser.add_option("-c", "--children", dest="children", type="string", action="append", default=[], help="One or more child seq files")
    parser.add_option("-s", "--sorted", dest="sorted", action="store_true", default=False, help="parent and child are sorted by header IDs [default false]")
    parser.add_option("-m", "--memory", dest="memory", type="int", default=4, help="sort memory in GB (default 4)")
    parser.add_option("-t", "--temp", dest="temp", default=".", help="temp dir for files [default current working dir]")
    
    (opts, args) = parser.parse_args()
    if not (opts.parent and os.path.isfile(opts.parent) and (len(opts.children) > 0)):
        parser.error("Missing input sequence files")
    for c in opts.children:
        if not os.path.isfile(c):
            parser.error("Invalid input sequence file: "+c)
    if not os.path.isdir(opts.temp):
        parser.error("Missing temp dir")
    
    # set variables
    MAX_MEM = opts.memory*1024
    TMP_DIR = opts.temp
    parent  = opts.parent if opts.sorted else sorted_ids(opts.parent, num=True)
    
    # skip empty children files
    valid_children = []
    for c in opts.children:
        if os.path.getsize(c) == 0:
            open(c+'.index', 'w').close()
        else:
            valid_children.append(c)
    if len(valid_children) == 0:
        sys.stderr.write("[error] children sequence file(s) empty\n")
        sys.exit(1)
    
    # open filehandles
    phdl = get_iter(parent, opts.sorted)
    to_index = []
    for c in valid_children:
        fname = c if opts.sorted else sorted_ids(c)
        cinfo = {
            'ifile': fname,
            'ofile': c+'.index',
            'ihdl': get_iter(fname, opts.sorted),
            'ohdl': open(c+'.index', 'w'),
            'curr': None
        }
        try:
            cinfo['curr'] = cinfo['ihdl'].next()
        except StopIteration:
            break
        to_index.append(cinfo)
    
    # process files
    # note: if opts.sorted == True these are sequence files, else id list files
    for i, rec in enumerate(phdl):
        if opts.sorted:
            key = rec.id
            num = i+1
        else:
            key, num = rec.strip().split('\t')
        for x in to_index:
            if not x['ihdl']:
                continue
            x_key = x['curr'].id if opts.sorted else x['curr'].strip()
            if x_key == key:
                x['ohdl'].write(str(num)+'\n')
                try:
                    x['curr'] = x['ihdl'].next()
                except StopIteration:
                    x['ihdl'].close()
                    x['ihdl'] = None
    phdl.close()
        
    # move and cleanup
    for x in to_index:
        if x['ihdl']:
            x['ihdl'].close()
        if x['ohdl']:
            x['ohdl'].close()
        if not opts.sorted:
            sort_file(x['ofile'], num=True)
    
    return 0


if __name__ == "__main__":
    sys.exit( main(sys.argv) )
