#!/usr/bin/env python

import sys, os, shlex, string, random, subprocess
from optparse import OptionParser
from Bio.Seq import Seq
from Bio.Alphabet import generic_dna
from Bio.SeqIO.QualityIO import FastqGeneralIterator

__doc__ = """
Join paired-end fastq files. Unjoined IDs uniquified.
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
    for head, seq, qual in FastqGeneralIterator(open(fname)):
        tmphdl.write("@%s.%s\n%s\n+\n%s\n" %(head.split()[0], text, seq, qual))
    tmphdl.close()
    os.rename(fname+'.tmp', fname)

def stitch_seqs(outfile, file1, file2, blen):
    bseq  = 'N' * blen
    bqual = '!' * blen
    itr1 = FastqGeneralIterator(open(file1))
    itr2 = FastqGeneralIterator(open(file2))
    rec1 = itr1.next()
    rec2 = itr2.next()
    outh = open(outfile, 'w')
    while 1:
        seq2 = Seq(rec2[1], generic_dna)
        outh.write("@%s\n%s%s%s\n+\n%s%s%s\n" %(rec1[0].split()[0], rec1[1], bseq, str(seq2.reverse_complement()), rec1[2], bqual, rec2[2][::-1]))
        try:
            rec1 = itr1.next()
            rec2 = itr2.next()
        except (StopIteration, IOError):
            break
    outh.close()

def prepend_barcode(seqfile, bcfile, rc, text=''):
    tmph = open(seqfile+'.tmp', 'w')
    itr1 = FastqGeneralIterator(open(seqfile))
    itr2 = FastqGeneralIterator(open(bcfile))
    (h1, s1, q1) = itr1.next()
    (h2, s2, q2) = itr2.next()
    while 1:
        h1 = h1.split()[0]
        h2 = h2.split()[0]
        while h1 != h2:
            try:
                (h2, s2, q2) = itr2.next()
                h2 = h2.split()[0]
            except (StopIteration, IOError):
                break
        if rc:
            rcs = Seq(s2, generic_dna)
            s2 = rcs.reverse_complement()
            q2 = q2[::-1]
        if text:
            h1 = h1+'.'+text
        tmph.write("@%s\n%s%s\n+\n%s%s\n" %(h1, s2, s1, q2, q1))
        try:
            (h1, s1, q1) = itr1.next()
            (h2, s2, q2) = itr2.next()
        except (StopIteration, IOError):
            break
    tmph.close()
    os.rename(seqfile+'.tmp', seqfile)

def main(args):
    usage  = "usage: %prog -o <output file> <read 1 file> <read 2 file>"+__doc__
    parser = OptionParser(usage)
    parser.add_option("-o", "--output", dest="output", default=None, help="Output joined fastq file.")
    parser.add_option("-m", "--min_overlap", dest="min_overlap", type="int", default=6, help="N-minimum overlap [default 6]")
    parser.add_option("-p", "--per_diff", dest="per_diff", type="int", default=20, help="N-percent maximum difference [default 20 %]")
    parser.add_option("-u", "--unique_id", dest="unique_id", action="store_true", default=False, help="Mate pair IDs are different [default same in read1 and read2].")
    parser.add_option("-i", "--index", dest="index", default=None, help="Have index file of barcodes, will prepend barcodes to output. Barcode id must be same as read1 id.")
    parser.add_option("-r", "--rc_index", dest="rc_index", action="store_true", default=False, help="Sequences in index file are reverse complement of barcodes [default is same].")
    parser.add_option("-j", "--join_only", dest="join_only", action="store_true", default=False, help="Only keep joined seqs [default add singlets].")
    parser.add_option("-s", "--stitch", dest="stitch", action="store_true", default=False, help="Stitch together singlet pairs [default add seperatly].")
    parser.add_option("-n", "--n_num", dest="n_num", type="int", default=10, help="Number of Ns to stitch singlets together with [default 10]")
    parser.add_option("-t", "--tmp_dir", dest="tmpdir", default="/tmp", help="DIR for intermediate files (must be full path), deleted at end [default '/tmp']")
    parser.add_option("-v", "--verbose", dest="verbose", action="store_true", default=False, help="Wordy [default off]")

    (opts, args) = parser.parse_args()
    if len(args) != 2:
        parser.error("Incorrect number of arguments")
    if not opts.output:
        parser.error("Missing output file")
    (input1, input2) = args
    if not (os.path.isfile(input1) and os.path.isfile(input2)):
        parser.error("Missing input files")

    if opts.verbose: sys.stdout.write("Joining %s and %s ... "%(input1, input2))
    tmp_prefix = os.path.join(opts.tmpdir, random_str())
    # join id = read1 id
    sout, serr = run_cmd(['fastq-join', '-m', str(opts.min_overlap), '-p', str(opts.per_diff), input1, input2, '-o', tmp_prefix+'.u1', '-o', tmp_prefix+'.u2', '-o', tmp_prefix+'.join'], None)
    if opts.verbose: sys.stdout.write("Done\n%s"%sout)

    if opts.index and os.path.isfile(opts.index):
        if opts.verbose: sys.stdout.write("Adding barcodes to join file ... ")
        prepend_barcode(tmp_prefix+'.join', opts.index, opts.rc_index)
        if opts.verbose: sys.stdout.write("Done\n")

    if opts.join_only:
        os.rename(tmp_prefix+'.join', opts.output)
        os.remove(tmp_prefix+'.u1')
        os.remove(tmp_prefix+'.u2')
        return 0

    if opts.verbose: sys.stdout.write("Merging joined and un-joined files ... ")
    out_hdl = open(opts.output, 'w')
    if opts.stitch:
        # stitch id = read1 id
        stitch_seqs(tmp_prefix+'.stitch', tmp_prefix+'.u1', tmp_prefix+'.u2', opts.n_num)
        if opts.index and os.path.isfile(opts.index):
            if opts.verbose: sys.stdout.write("\nAdding barcodes to stitch file ... ")
            prepend_barcode(tmp_prefix+'.stitch', opts.index, opts.rc_index)
            if opts.verbose: sys.stdout.write("Done\n")
        _so, _se = run_cmd(['cat', tmp_prefix+'.join', tmp_prefix+'.stitch'], out_hdl)
        os.remove(tmp_prefix+'.stitch')
    else:
        if not opts.unique_id:
            if opts.index and os.path.isfile(opts.index):
                if opts.verbose: sys.stdout.write("\nAdding barcodes to singlet files ... ")
                prepend_barcode(tmp_prefix+'.u1', opts.index, opts.rc_index, '1')
                prepend_barcode(tmp_prefix+'.u2', opts.index, opts.rc_index, '2')
                if opts.verbose: sys.stdout.write("Done\n")
            else:
                append_id(tmp_prefix+'.u1', '1')
                append_id(tmp_prefix+'.u2', '2')
        _so, _se = run_cmd(['cat', tmp_prefix+'.join', tmp_prefix+'.u1', tmp_prefix+'.u2'], out_hdl)
    out_hdl.close()
    os.remove(tmp_prefix+'.u1')
    os.remove(tmp_prefix+'.u2')
    os.remove(tmp_prefix+'.join')
    if opts.verbose: sys.stdout.write("Done\n")
    
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
