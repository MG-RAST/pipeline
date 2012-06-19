#!/usr/bin/env python

import sys, os, shlex, string, random, subprocess
from optparse import OptionParser
from Bio import SeqIO

__doc__ = """
Join paired-end fastq files.  Unjoined IDs uniquified.
Input files must be fastq format."""

def run_cmd(cmd, out_hdl):
    if not out_hdl:
        out_hdl = subprocess.PIPE
    proc = subprocess.Popen( cmd, stdout=out_hdl, stderr=subprocess.PIPE )
    stdout, stderr = proc.communicate()
    if proc.returncode != 0:
        raise IOError("%s\n%s"%(" ".join(cmd), stderr))
    return stdout, stderr

def random_str(size=6):
    chars = string.ascii_letters + string.digits
    return ''.join(random.choice(chars) for x in range(size))

def append_id(fname, text):
    tmphdl = open(fname+'.tmp', 'w')
    for rec in SeqIO.parse(fname, 'fastq'):
        rec.id = rec.id+'.'+text
        tmphdl.write(rec.format('fastq'))
    tmphdl.close()
    os.rename(fname+'.tmp', fname)

def main(args):
    usage  = "usage: %prog -o <output file> <read 1 file> <read 2 file>"+__doc__
    parser = OptionParser(usage)
    parser.add_option("-o", "--output", dest="output", default=None, help="Output joined fastq file.")
    parser.add_option("-t", "--tmp_dir", dest="tmpdir", default="/tmp", help="DIR for intermediate files (must be full path), deleted at end [default '/tmp']")
    parser.add_option("-v", "--verbose", dest="verbose", action="store_true", default=False, help="Wordy [default off]")

    (opts, args) = parser.parse_args()
    if len(args) != 2:
        parser.error("Incorrect number of arguments")
    if not opts.output:
        parser.error("Missing output file")
    (input1, input2) = args

    if opts.verbose: sys.stdout.write("Joining %s and %s ... "%(input1, input2))
    tmp_prefix = os.path.join(opts.tmpdir, random_str())
    sout, serr = run_cmd(['fastq-join', '-m', '10', input1, input2, '-o', tmp_prefix+'.u1', '-o', tmp_prefix+'.u2', '-o', tmp_prefix+'.join'], None)
    if opts.verbose: sys.stdout.write("Done\n%s"%sout)

    if opts.verbose: sys.stdout.write("Merging joined and un-joined files ... ")
    append_id(tmp_prefix+'.u1', '1')
    append_id(tmp_prefix+'.u2', '2')
    out_hdl  = open(opts.output, 'w')
    _so, _se = run_cmd(['cat', tmp_prefix+'.u1', tmp_prefix+'.u2', tmp_prefix+'.join'], out_hdl)
    out_hdl.close()
    os.remove(tmp_prefix+'.u1')
    os.remove(tmp_prefix+'.u2')
    os.remove(tmp_prefix+'.join')
    if opts.verbose: sys.stdout.write("Done\n")


if __name__ == "__main__":
    sys.exit(main(sys.argv))
