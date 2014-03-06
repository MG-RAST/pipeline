#!/usr/bin/env python

import os
import sys
import json
from optparse import OptionParser
from collections import defaultdict

# declare a blank dictionary, keys are the term_ids
terms = {}

def getTerm(stream):
    block = []
    for line in stream:
        if line.strip() == "[Term]" or line.strip() == "[Typedef]":
            break
        else:
            if line.strip() != "":
                block.append(line.strip())
    return block

def parseTagValue(term):
    data = defaultdict(list)
    for line in term:
        tag = line.split(': ',1)[0]
        value = line.split(': ',1)[1]
        if tag == 'relationship':
            tag = value.split(' ', 1)[0]
            value = value.split(' ', 1)[1]
        data[tag].append(value)
    return data

def getDescendents(tid):
    recursiveArray = []
    if terms.has_key(tid):
        recursiveArray = [(terms[tid]['name'], tid)]
        children = terms[tid]['c']
        if len(children) > 0:
            for child in children:
                recursiveArray.extend(getDescendents(child))
    return list(set(recursiveArray))

def getAncestors(tid):
    recursiveArray = []
    if terms.has_key(tid):
        recursiveArray = [(terms[tid]['name'], tid)]
        parents = terms[tid]['p']
        if len(parents) > 0:
            for parent in parents:
                recursiveArray.extend(getAncestors(parent))
    return list(set(recursiveArray))

def getChildren(tid):
    children = []
    if terms.has_key(tid):
        for c in terms[tid]['c']:
            children.append((terms[c]['name'], c))
    return list(set(children))

def getParents(tid):
    parents = []
    if terms.has_key(tid):
        for p in terms[tid]['p']:
            parents.append((terms[p]['name'], p))
    return list(set(parents))

def main(args):
    global terms
    parser = OptionParser(usage="usage: %prog [options] -i <input file> -o <output file>")
    parser.add_option("-i", "--input", dest="input", default=None, help="input .obo file")
    parser.add_option("-o", "--output", dest="output", default=None, help="output .json file")
    parser.add_option("-g", "--get", dest="get", default='all', help="output to get: all, ancestors, parents, children, descendents. 'all' if no term_id")
    parser.add_option("-t", "--term_id", dest="term_id", default=None, help="term id if doing relationship lookup")
    parser.add_option("-r", "--relations", dest="relations", default='is_a,part_of', help="comma seperated list of relations to use, default is 'is_a,part_of'")
    (opts, args) = parser.parse_args()
    if not (opts.input and os.path.isfile(opts.input)):
        parser.error("missing input")
    if not opts.relations:
        parser.error("missing relations")
    if not opts.term_id:
        opts.get = 'all'
    
    oboFile = open(opts.input, 'r')
    relations = opts.relations.split(',')
    
    # skip the file header lines
    getTerm(oboFile)

    # infinite loop to go through the obo file.
    # breaks when the term returned is empty, indicating end of file
    while 1:
        # get the term using the two parsing functions
        term = parseTagValue(getTerm(oboFile))
        if len(term) != 0:
            termID = term['id'][0]
            termName = term['name'][0]
        
            # only add to the structure if the term has a relation tag
            # the relation value contains ID and term definition, we only want ID
            termParents = []
            for rel in relations:
                if term.has_key(rel):
                    termParents.extend([p.split()[0] for p in term[rel]])
        
            # each ID will have two arrays of parents and children
            if not terms.has_key(termID):
                terms[termID] = {'p':[],'c':[]}
            terms[termID]['name'] = termName
        
            # append parents of the current term
            terms[termID]['p'] = termParents
        
            # for every parent term, add this current term as children
            for termParent in termParents:
                if not terms.has_key(termParent):
                    terms[termParent] = {'p':[],'c':[]}
                terms[termParent]['c'].append(termID)
        else:
            break
    
    # output
    data = None
    if opts.get == 'ancestors':
        data = getAncestors(opts.term_id)
    elif opts.get == 'parents':
        data = getParents(opts.term_id)
    elif opts.get == 'children':
        data = getChildren(opts.term_id)
    elif opts.get == 'descendents':
        data = getDescendents(opts.term_id)
    else:
        data = terms
        
    if opts.output:
        json.dump(data, open(opts.output, 'w'))
    else:
        print json.dumps(data, sort_keys=True, indent=4)

if __name__ == "__main__":
    sys.exit(main(sys.argv))
