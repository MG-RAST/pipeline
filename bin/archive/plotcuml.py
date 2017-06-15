#!/usr/bin/env python

import sys, os
import numpy as np
import matplotlib.pyplot as plt
from optparse import OptionParser

lab=[]

def makecumsum(inf, outf):
  d = np.loadtxt(inf)
  x = d[:,0]
  y = np.flipud(np.flipud(d[:,1]).cumsum())
  plt.loglog(x, y, '.-', hold=True)
  lab.append(inf)
  z = np.vstack((x,y)).T
  np.savetxt(outf, z, "%.1d", delimiter="\t")


if __name__ == '__main__':
  usage = "usage: %prog -i <input sequence file> -o <output file>"
  parser = OptionParser(usage)
  parser.add_option("-i", "--input", dest="input", default=None, help="Input sequence file.")
  parser.add_option("-o", "--output", dest="output", default=None, help="Output file.")
  (opts, args) = parser.parse_args()
  if not (opts.input and os.path.isfile(opts.input) and opts.output):
    parser.error("Missing input/output files")
  
  if os.path.isfile(opts.input):
    makecumsum(opts.input, opts.output)
  else:
    sys.stderr.write("File "+opts.input+" not found!")
  
  plt.legend(lab)
  plt.show()

