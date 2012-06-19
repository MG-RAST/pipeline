#!/usr/bin/env python

import sys, os, shlex, shutil, random, subprocess
from collections import defaultdict
from optparse import OptionParser
from multiprocessing import Pool
from Bio import SeqIO

def run_cmd(cmd):
    proc = subprocess.Popen( cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE )
    stdout, stderr = proc.communicate()
    if proc.returncode != 0:
        raise IOError("%s\n%s"%(" ".join(cmd), stderr))
    return stdout, stderr

def countseqs(infile, sformat):
    headchar = '>'
    if sformat == 'fastq':
        headchar = '@'
    sout, serr = run_cmd(['grep', '-c', "^%s"%headchar, infile])
    slen = sout.strip()
    if not slen:
        sys.stderr.write("%s is invalid %s file\n"%(infile, sformat))
        exit(1)
    return int(slen)

def subfasta(infile, outfile, sformat, Smax, Sratio, verb):
    seqnum = 0
    outhdl = open(outfile, 'w')
    if verb: sys.stdout.write("Creating %d sequence fasta subset of %s ... "%(Smax, infile))
    for i, rec in enumerate(SeqIO.parse(infile, sformat)):
        if seqnum >= Smax:
            break
        if Sratio < random.random():
            continue
        outhdl.write(">%s\n%s\n"%(rec.id, rec.seq))
        seqnum += 1
    if verb: sys.stdout.write("Done\n")
    return seqnum

def adapter_map(adap_file):
    amap = {}
    for rec in SeqIO.parse(adap_file, 'fasta'):
        amap[rec.id] = str(rec.seq)
    return amap

def fastq2fasta(in_file, out_file):
    in_hdl  = open(in_file, 'rU')
    out_hdl = open(out_file, 'w')
    seqnum  = SeqIO.convert(in_hdl, 'fastq', out_hdl, 'fasta')
    in_hdl.close()
    out_hdl.close()
    return seqnum

def rankIDs(blat_file):
    adaps = defaultdict(int)
    bhdl  = open(blat_file, 'rU')
    for line in bhdl:
        sid = line.strip().split('\t')[1]
        adaps[sid] += 1
    return sorted(adaps.items(), key=lambda x: x[1], reverse=True)

def trim_fastq(cmd_str):
    cmd = shlex.split(str(cmd_str))
    sout, serr = run_cmd(cmd)
    return sout

def main(args):
    usage  = "usage: %prog [options] -d <adapter DB> -i <input sequence file> -o <output file>"
    parser = OptionParser(usage)
    parser.add_option("-i", "--input", dest="input", default=None, help="Input sequence file.")
    parser.add_option("", "--rev_input", dest="rev_input", default=None, help="Reverse sequence file, paired-end seqs only.")
    parser.add_option("-o", "--output", dest="output", default=None, help="Output file.")
    parser.add_option("", "--rev_output", dest="rev_output", default=None, help="Reverse sequence file output, paired-end seqs only.")
    parser.add_option("-f", "--format", dest="format", default='fasta', help="file format: fasta, fastq [default 'fasta']")
    parser.add_option("", "--screen_only", dest="screen", action="store_true", default=False, help="Only screen for adaptors (output identified) [default off]")
    parser.add_option("", "--trim_only", dest="trim", default=None, help="Only trim adaptors [default off]")
    parser.add_option("-m", "--max_screen", dest="max_screen", default=100000, type="int", help="max number of seqs to screen [default 100000]")
    parser.add_option("-d", "--db_adaptor", dest="db_adaptor", default=None, help="Fasta file DB of adaptors")
    parser.add_option("-t", "--tmp_dir", dest="tmpdir", default="/tmp", help="DIR for intermediate files (must be full path), deleted at end [default '/tmp']")
    parser.add_option("-v", "--verbose", dest="verbose", action="store_true", default=False, help="Wordy [default off]")
  
    (opts, args) = parser.parse_args()
    if not (opts.input and os.path.isfile(opts.input) and opts.output):
        parser.error("Missing input/output files")
    if not (opts.db_adaptor and os.path.isfile(opts.db_adaptor)):
        parser.error("Missing adapter DB")
    in_seqs   = opts.input
    map_adapt = adapter_map(opts.db_adaptor)
    top_adapt = opts.trim

    # skip screen if adaptor inputted
    if not (opts.trim and (opts.trim in map_adapt)):
        if opts.verbose: sys.stdout.write("Adaptor Screening %s\n"%in_seqs)
        # convert fastq / sub-sample
        seqtotal = countseqs(in_seqs, opts.format)
        seqper   = (opts.max_screen * 1.0) / seqtotal
        to_sub   = False
        if opts.max_screen < seqtotal:
            to_sub = True
        if opts.format == 'fastq':
            fastaf = os.path.join(opts.tmpdir, os.path.basename(in_seqs)+'.fna')
            if to_sub:
                seqnum = subfasta(in_seqs, fastaf, opts.format, opts.max_screen, seqper, opts.verbose)
            else:
                if opts.verbose: sys.stdout.write("Converting %s to fasta ... "%in_seqs)
                seqnum = fastq2fasta(in_seqs, fastaf)
            if opts.verbose: sys.stdout.write("Done converting %d sequences\n"%seqnum)
            in_seqs = fastaf
        elif (opts.format == 'fasta') and to_sub:
            subfile = os.path.join(opts.tmpdir, os.path.basename(in_seqs)+'.sub')
            seqnum  = subfasta(in_seqs, subfile, opts.format, opts.max_screen, seqper, opts.verbose)
            in_seqs = subfile        
        # run blat
        if opts.verbose: sys.stdout.write("Running blat ... ")
        blatf = os.path.join(opts.tmpdir, os.path.basename(in_seqs)+'.blat')
        sout, serr = run_cmd(['blat', '-t=dna', '-fastMap', '-out=blast8', opts.db_adaptor, in_seqs, blatf])
        idset = rankIDs(blatf)
        if opts.verbose: sys.stdout.write("Done\n")
        # output if only screening
        if opts.screen:
            if len(idset) == 0:
                if opts.verbose: sys.stdout.write("No adapter sequences found\n")
            else:
                ohdl = open(opts.output, 'w')
                for s in idset:
                    ohdl.write("%s\t%d\n"%(s[0], s[1]))
                ohdl.close()
            os.remove(blatf)
            if in_seqs != opts.input:
                os.remove(in_seqs)
            return 0
        # end if no adapters found
        if len(idset) == 0:
            if opts.verbose: sys.stdout.write("No adapter sequences found\n")
            shutil.copyfile(opts.input, opts.output)
            if opts.rev_input and os.path.isfile(opts.rev_input) and opts.rev_output:
                shutil.copyfile(opts.rev_input, opts.rev_output)
        #found it!
        top_adapt = idset[0][0]

    # trim adapters
    cmd_str = "cutadapt -O 10 -f %s -b %s -o %s %s"%(opts.format, map_adapt[top_adapt], opts.output, opts.input)
    # trim in parallel if paired-end
    if opts.rev_input and os.path.isfile(opts.rev_input) and opts.rev_output:
        if top_adapt.startswith('Tru'):
            rev_adapt = 'TruR'
        elif top_adapt.startswith('MBL'):
            rev_adapt = 'MBLR'
        else:
            rev_adapt = top_adapt
        if opts.verbose: sys.stdout.write("Parallel Adaptor Trimming %s (%s) %s (%s) ... "%(opts.input, top_adapt, opts.rev_input, rev_adapt))
        cmd_set = [cmd_str, "cutadapt -O 10 -f %s -b %s -o %s %s"%(opts.format, map_adapt[rev_adapt], opts.rev_output, opts.rev_input)]
        ppool   = Pool(processes=2)
        log_txt = ppool.map(trim_fastq, cmd_set, 1)
    else:
        if opts.verbose: sys.stdout.write("Adaptor Trimming %s (%s) ... "%(opts.input, top_adapt))
        log_txt = [ trim_fastq(cmd_str) ]
    if opts.verbose:
        sys.stdout.write("Done\n")
        for log in log_txt:
            sys.stdout.write(log)
    
    # cleanup
    os.remove(blatf)
    if in_seqs != opts.input:
        os.remove(in_seqs)
    return 0
    

if __name__ == "__main__":
    sys.exit(main(sys.argv))
