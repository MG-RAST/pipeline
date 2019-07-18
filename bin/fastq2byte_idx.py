#!/usr/bin/env python

import os
import re
import sys
import statistics as s
from struct import *
from Bio import SeqIO
from Bio.Seq import Seq
from Bio.Alphabet import generic_dna
from Bio.SeqIO.QualityIO import FastqGeneralIterator
from pprint import pprint

from optparse import OptionParser

usage  = "usage: %prog [options] -i <input file> -o <output file>"
parser = OptionParser(usage)
parser.add_option("-i", "--input", dest="input", default=None, help="Input mapping file.")
parser.add_option("-o", "--index", dest="output", default="tmp.idx", help="Output binary index file")
parser.add_option("-r", "--record", dest="record", default="tmp.rec", help="Output record index file")
parser.add_option("--id2rec" , dest="id" , default="tmp.id2rec" , help="Output id file")


(opts, args) = parser.parse_args()

if opts.input and os.path.isfile(opts.input) :
    print("# Processing " + opts.input)
else :
    print("Missing input file")
    sys.exit(1)

fastq_file_handle   = open(opts.input , "r")
pointer             = open(opts.input , "r") 
index               = open(opts.output , "wb")
record              = open(opts.record , "w")
id2rec              = open(opts.id , "w")

record_counter = 0
offset = pointer.tell() 

llist = []

# for fastq
for rec in FastqGeneralIterator(fastq_file_handle) :
    record_counter += 1
    head, seq, qual = ( rec[0].split()[0], rec[1].upper(), rec[2] )

    line_nr = 0
    while line_nr < 10 :
            line = pointer.readline()
            line_nr += 1
            if (qual + "\n") == line :
                # print("Found" , line_nr , pointer.tell() )
                break
            else:
                pass

    

    # Write index    
    length = pointer.tell() - offset    
    index.write( pack('<QQ' , int(offset) , int(length) ) ) 
    record.write( "\t".join( [ str(record_counter) , str(offset) , str( pointer.tell() - offset )] ) + "\n"  )
    id2rec.write( "\t".join( [ head , str(record_counter) , str(offset) , str( pointer.tell() - offset )] ) + "\n" ) 

    # keep for stats
    llist.append( length )
    
    # New offset 
    offset = pointer.tell()


record.close()
index.close()

mean = s.mean(llist)

print( "Records:\t" + str( len(llist)))
print( "Mean:\t" + str( mean ) ) 
print( "Median:\t" + str( s.median(llist) ) )
print( "Variance:\t" + str ( s.pvariance( llist, mu=mean) ) )
print( "Stdev:\t" + str( s.pstdev(llist , mu=mean ) ) ) 
