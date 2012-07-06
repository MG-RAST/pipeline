#!/usr/bin/env python

import sys, os, array, random, subprocess
from optparse import OptionParser
from Bio import SeqIO

a = array.array('L')
c = array.array('L')
g = array.array('L')
t = array.array('L')
n = array.array('L')

def countseqs(infile, type):
  if type == 'fasta':
    cmd = ['grep', '-c', '^>', infile]
  elif type == 'fastq':
    cmd = ['wc', '-l', infile]
  else:
    sys.stderr.write("%s is invalid %s file\n"%(infile, type))
    exit(1)
  proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  stdout, stderr = proc.communicate()
  if proc.returncode != 0:
    raise IOError("%s\n%s"%(" ".join(cmd), stderr))
  slen = stdout.strip()
  if not slen:
    sys.stderr.write("%s is invalid %s file\n"%(infile, type))
    exit(1)
  slenNum = int(slen)
  if type == 'fastq':
    slenNum = slenNum / 4  
  return slenNum

def initialize(Nmax):
  for i in range(0, Nmax):
    a.append(0)
    c.append(0)
    g.append(0)
    t.append(0)
    n.append(0)

def populate(infile, type, Nmax, Sratio):
  """puts nucleotide data into matrix."""
  seqnum = 0
  for i, rec in enumerate(SeqIO.parse(infile, type)):
    if Sratio < random.random():
      continue
    seqnum += 1
    try:
      sequence=rec.seq.upper()
    except IndexError:
      sequence=""
    for i in range(0, min(len(sequence), Nmax)):
      if sequence[i] == "A":
        a[i] += 1
      elif sequence[i] == "G":
        c[i] += 1
      elif sequence[i] == "C":
        g[i] += 1
      elif sequence[i] == "T":
        t[i] += 1
      elif sequence[i] == "N":
        n[i] += 1
  return seqnum

def printtable(outfile, Nmax):
  outhdl = open(outfile, 'w')
  outhdl.write("\t".join(['#', 'A', 'C', 'G', 'T', 'N', 'total'])+"\n")
  for i in range(0, Nmax):
    outhdl.write("\t".join(map(str,[i, a[i], c[i], g[i], t[i], n[i], (a[i]+c[i]+g[i]+t[i]+n[i])]))+"\n")
  outhdl.close()
  

if __name__ == '__main__':
  usage  = "usage: %prog -i <input sequence file> -o <output file>"
  parser = OptionParser(usage)
  parser.add_option("-i", "--input", dest="input", default=None, help="Input sequence file.")
  parser.add_option("-o", "--output", dest="output", default=None, help="Output file.")
  parser.add_option("-t", "--type", dest="type", default='fasta', help="file type: fasta, fastq [default 'fasta']")
  parser.add_option("-b", "--bp_max", dest="bp_max", default=100, type="int", help="max number of bps to process [default 100]")
  parser.add_option("-s", "--seq_max", dest="seq_max", default=100000, type="int", help="max number of seqs to process [default 100000]")
  parser.add_option("-v", "--verbose", dest="verbose", action="store_true", default=False, help="Wordy [default off]")
  
  (opts, args) = parser.parse_args()
  if not (opts.input and os.path.isfile(opts.input) and opts.output):
    parser.error("Missing input/output files")

  if opts.verbose: sys.stdout.write("Counting sequences in %s ... "%opts.input)
  seqnum = countseqs(opts.input, opts.type)
  seqper = (opts.seq_max * 1.0) / seqnum
  if opts.verbose: sys.stdout.write("Done: %d seqs found, %f %% of sequences will be processed\n"%(seqnum, (seqper*100)))

  if opts.verbose: sys.stdout.write("Populating bp matrixes ... ")
  initialize(opts.bp_max)
  seqs = populate(opts.input, opts.type, opts.bp_max, seqper)
  printtable(opts.output, opts.bp_max)
  if opts.verbose: sys.stdout.write("Done: %d of %d sequences processed\n"%(seqs, seqnum))
