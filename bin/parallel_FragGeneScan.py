#!/usr/bin/env python

import os, sys, re
import subprocess
from optparse import OptionParser
from multiprocessing import Pool

__doc__ = """
Script to run run_FragGeneScan.pl in parallel.
Splits input fasta_file and runs parts on seperate cpus.

will produce 3 output files based on inputed output_name:
    output_name.faa
    output_name.fna
    output_name.out"""

run_fgs  = "run_FragGeneScan.pl";
fasta_re = re.compile('^>')
min_size = 1
T_TYPE   = ''

def write_file(text, file, append):
    if append:
        mode = 'a'
    else:
        mode = 'w'
    outhdl = open(file, mode)
    outhdl.write(text)
    outhdl.close()

def split_fasta(infile, bytes, dir):
    num   = 1
    char  = 0
    text  = ''
    files = []
    fname = os.path.join(dir, os.path.basename(infile))
    inhdl = open(infile, "rU")
    for line in inhdl:
        head = fasta_re.match(line)
        if head and (char >= bytes):
            files.append("%s.%d"%(fname, num))
            write_file(text, "%s.%d"%(fname, num), 0)
            num += 1
            char = 0
            text = ''
        text += line
        char += len(line)
    if text != '':
        files.append("%s.%d"%(fname, num))
        write_file(text, "%s.%d"%(fname, num), 0)
    inhdl.close()
    return files

def run_fraggenescan(fname):
    outf = fname + '.fgs'
    cmd  = [run_fgs, '-genome', fname, '-out', outf, '-complete', '0', '-train', T_TYPE]
    proc = subprocess.Popen( cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE )
    stdout, stderr = proc.communicate()
    if proc.returncode != 0:
        raise IOError(stderr)
    write_file(stderr+"\n"+stdout, outf+".out", 1)
    return outf

def merge_fgs_files(files, out_name):
    faa_files = map( lambda x: "%s.faa"%x, files )
    ffn_files = map( lambda x: "%s.ffn"%x, files )
    out_files = map( lambda x: "%s.out"%x, files )

    os.system( "cat %s > %s.faa"%( " ".join(faa_files), out_name ) )
    os.system( "cat %s > %s.fna"%( " ".join(ffn_files), out_name ) )
    os.system( "cat %s > %s.out"%( " ".join(out_files), out_name ) )

    for f in faa_files: os.remove(f)
    for f in ffn_files: os.remove(f)
    for f in out_files: os.remove(f)
    return
    
usage = "usage: %prog [options] input_fasta output_name\n" + __doc__

def main(args):
    global T_TYPE
    parser = OptionParser(usage=usage)
    parser.add_option("-p", "--processes", dest="processes", metavar="NUM_PROCESSES", type="int", default=4, help="Number of processes to use [default '4']")
    parser.add_option("-s", "--byte_size", dest="size", metavar="BYTE_SIZE", type="int", default=100, help="Max byte size to split fasta file (in MB) [default '100']")
    parser.add_option("-t", "--type", dest="type", metavar="TYPE",  default='454_30', help="Technology type (sanger_10,454_30,illumina_10,complete) [default '454_30']")
    parser.add_option("-d", "--tmp_dir", dest="tmpdir", metavar="DIR", default="/tmp", help="DIR for intermediate files (must be full path), deleted at end [default '/tmp']")
    parser.add_option("-v", "--verbose", dest="verbose", action="store_true", default=False, help="Wordy [default is off]")
    
    (opts, args) = parser.parse_args()
    if len(args) != 2:
        parser.error("Incorrect number of arguments")

    (in_fasta, out_name) = args
    T_TYPE = opts.type

    try:
        bytes = os.path.getsize(in_fasta)
    except os.error:
        parser.error("Missing input fasta")

    max_byte = opts.size * 1024 * 1024
    min_byte = min_size * 1024 * 1024
    sub_byte = int(bytes / opts.processes) + 1
    if sub_byte > max_byte:
        sub_byte = max_byte
    elif sub_byte < min_byte:
        sub_byte = min_byte
    
    if opts.verbose: sys.stdout.write("Splitting file %s ... "%in_fasta)
    sfiles = split_fasta(in_fasta, sub_byte, opts.tmpdir)
    scount = len(sfiles)
    if opts.verbose: sys.stdout.write("Done - %d splits\n%s\n"%(scount, "\n".join(sfiles)))

    if scount < opts.processes:
        min_proc = scount
    else:
        min_proc = opts.processes
    
    if opts.verbose: sys.stdout.write("FragGeneScan using %d threades ... "%min_proc)
    pool   = Pool(processes=min_proc)
    rfiles = pool.map(run_fraggenescan, sfiles, 1)
    pool.close()
    pool.join()
    if opts.verbose: sys.stdout.write("Done\n")

    if opts.verbose: sys.stdout.write("Merging %d outputs ... "%len(rfiles))
    merge_fgs_files(rfiles, out_name)
    for f in sfiles: os.remove(f)
    if opts.verbose: sys.stdout.write("Done\n")
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
