#!/usr/bin/env python

import unittest
import subprocess
from subprocess import Popen, PIPE
import sys
import os
import glob
import re
import json

# do something get script dir  smart and set path relative to CWL dir


debug =  int(os.environ.get('DEBUG', 0))
# print("DEBUG: " + str(debug))

disable_docker = 0

testDir     = os.path.abspath(os.path.dirname(__file__))
baselineDir = testDir + "/../Data/Baseline/"
toolDir     = testDir + "/../Tools/"
workflowDir = testDir + "/../Workflows/"
inputDir    = testDir + "/../Data/Inputs/"
outputDir   = testDir + "/../Data/Outputs/"
docker      = "--strict"
cwlTool     = "cwltool" # "cwl-runner"

if disable_docker:
    docker = "--no-container"


def generate_check_exists_tool(tool, name, path):
    def test(self):
        """Does tool exists"""
        self.assertTrue(os.path.exists(path))
    return test

def generate_check_exists_job(tool, name, path):
    def test(self):
        """Does job exists"""
        job_file = toolDir + name + ".job.yaml"
        # self.longMessage = True
        msg = "Missing job " + toolDir + name + ".job.yaml"
        self.assertTrue(os.path.exists(job_file), msg=msg)
    return test

def generate_check_exists_baseline(tool, name, path):
    def test(self):
        """Does baseline data exist"""
        baseline_file = baselineDir + name + ".receipt"
        # self.longMessage = True
        msg = "Missing baseline for " + name + ": " + baseline_file
        self.assertTrue(os.path.exists(baseline_file), msg=msg)
    return test

def generate_check_tool_output(tool, name, path):
    def test(self):
        """Compare baseline"""

        # set job
        job = toolDir + name + ".job.yaml"

        if debug:
            print("\nDEBUG:")
            print("ToolDir: " + toolDir)
            print("OutputDir: " + outputDir)
            print("Tool: " + tool)
            print([tool, name, path])
            print(['cwl-runner', '--outdir ' + outputDir, docker, toolDir + tool, job])



      # execute tool
        session = subprocess.Popen([cwlTool, '--outdir', outputDir, docker, toolDir + tool, job], stdin=None, stdout=PIPE, stderr=PIPE, shell=False)
        stdout, stderr = session.communicate()

        if stderr and debug:
            print('ERROR:')
            print(stderr)

        # Test here
        compFile = open(baselineDir + "/" + name + ".receipt", 'r')
        baseline = compFile.read()

        if debug:
            print('Baseline:')
            print(baseline)
            print('Output:' + stdout)
        self.assertTrue(cmp_cwl_receipts(baseline, stdout), msg=" ".join(['cwl-runner', '--outdir ' + outputDir, docker, toolDir + tool, job, "\n", stderr]))

        return test

def cmp_cwl_receipts(json_a, json_b):

    identical = 1
    assert type(json_a) is str
    assert type(json_b) is str
  
    try:
        a = json.loads(json_a)
        b = json.loads(json_b)
    except Exception as e:
        sys.stderr.write("Can't parse json strings ... " + repr(e)  + " ... ")
        identical = 0
        return
    for k, v in a.iteritems():
        if 'format' in v:
            if debug:
                sys.stderr.write('Found \'format\' key.\n')
            if re.search("json", v['format']) is  None:
                if v['checksum'] != b[k]["checksum"]:
                    identical = 0
                    sys.stderr.write('Checksum not identical for ' + v['basename'] + "\n")
            else:
                if debug:
                    sys.stderr.write('Found \'json\' value. Not comparing checksum for ' + v['basename'] + "\n")
        if 'checksum' in v:
            if  v['checksum'] != b[k]["checksum"]:
                identical = 0
                sys.stderr.write('Checksum not identical for ' + k + "(" + v['basename'] + ")\n")
        if 'basename' in v:
            if v['basename'] != b[k]["basename"]:
                identical = 0
                sys.stderr.write('Basename not identical for ' + k +  "\n")
        if 'size' in v:
            if v['size'] != b[k]["size"]:
                identical = 0
                sys.stderr.write('Size not identical for ' + k +  "\n")
  
    return identical

    # "summary": {
    #     "checksum": "sha1$e1f54b727983be4d5f28136fdd5a0f9a02cb6b30",
    #     "basename": "drisee.log",
    #     "http://commonwl.org/cwltool#generation": 0,
    #     "location": "file:///pipeline/CWL/Data/Outputs/drisee.log",
    #     "path": "/pipeline/CWL/Data/Outputs/drisee.log",
    #     "class": "File",
    #     "size": 436
    # },
    # "stats": {
    #     "checksum": "sha1$da39a3ee5e6b4b0d3255bfef95601890afd80709",
    #     "basename": "drisee.stats",
    #     "http://commonwl.org/cwltool#generation": 0,
    #     "location": "file:///pipeline/CWL/Data/Outputs/drisee.stats",
    #     "path": "/pipeline/CWL/Data/Outputs/drisee.stats",
    #     "class": "File",
    #     "size": 0
    # },
    # "error": {
    #     "checksum": "sha1$da39a3ee5e6b4b0d3255bfef95601890afd80709",
    #     "basename": "drisee.error",
    #     "http://commonwl.org/cwltool#generation": 0,
    #     "location": "file:///pipeline/CWL/Data/Outputs/drisee.error",
    #     "path": "/pipeline/CWL/Data/Outputs/drisee.error",
    #     "class": "File",
    #     "size": 0
    # }


class TestCWL(unittest.TestCase):

    def setUp(self):
        """Setup test, get path to script and version"""

        session = subprocess.Popen([cwlTool, '--version'], stdout=PIPE, stderr=PIPE)
        stdout, stderr = session.communicate()

        if stderr:
            raise Exception("Error "+str(stderr))

        (script, version) = stdout.split(" ")
        self.script = script
        self.version = version


    def test_cwl_runner_version(self):
        """Is cwl-runner version greater or equal 1.0.20170525215327"""
        # output = subprocess.call(['cwl-runner', '--version'], stdout=PIPE, stderr=PIPE)

        (main, subversion, revision) = self.version.split(".")

        self.assertTrue(int(main) >= 1)
        self.assertTrue(int(revision) >= 20170525215327)

class TestDrisee(unittest.TestCase):

    def setUp(self):
        pass

    def tearDown(self):
        pass

    def test_cwl_drisee(self):
      	"""Is receipt for drisee identical to baseline receipt"""


        if debug:
            print("\nDEBUG:")
            print("ToolDir: " + toolDir)
            print("OutputDir: " + outputDir)
            print(['cwl-runner', '--outdir ' + outputDir, docker, toolDir + 'drisee.tool.cwl', toolDir + 'drisee.job.yaml'])
  
        session = subprocess.Popen([cwlTool, '--outdir', outputDir, docker, toolDir + 'drisee.tool.cwl', toolDir + 'drisee.job.yaml'], stdin=None, stdout=PIPE, stderr=PIPE, shell=False)
        stdout, stderr = session.communicate()
  
        if stderr and debug:
            print('ERROR:')
            print(stderr)
  
        # Test here
        compFile = open(baselineDir + "/" + "drisee.receipt", 'r')
        baseline = compFile.read()
  
        if debug:
            print('Baseline:')
            print(baseline)
            print('Output:' + stdout)
        self.assertTrue(cmp_cwl_receipts(baseline, stdout))

class TestKmerTool(unittest.TestCase):

    def setUp(self):
        pass
  
    def tearDown(self):
        pass
  
    def test_cwl_kmer_tool(self):
        """Is receipt for kmer-tool identical to baseline receipt"""
    
        if debug:
            print("\nDEBUG:")
            print("ToolDir: " + toolDir)
            print("OutputDir: " + outputDir)
            print([cwlTool, '--outdir ' + outputDir, docker, toolDir + 'kmer-tool.tool.cwl', toolDir + 'kmer-tool.job.yaml'])
    
        session = subprocess.Popen([cwlTool, '--outdir', outputDir, docker, toolDir + 'kmer-tool.tool.cwl', toolDir + 'kmer-tool.job.yaml'], stdin=None, stdout=PIPE, stderr=PIPE, shell=False)
        stdout, stderr = session.communicate()
    
        if stderr and debug:
            print('ERROR:')
            print(stderr)
    
        # Test here
        compFile = open(baselineDir + "/" + "kmer-tool.receipt", 'r')
        baseline = compFile.read()
    
        self.assertTrue(cmp_cwl_receipts(baseline, stdout))

class TestCwlTool(unittest.TestCase): pass


if __name__ == '__main__':

    # Create tests for every tool in the tool directory
    # A cwl tool has the suffix *.tool.cwl, e.g. drisee.too.cwl.
    # A job file for testing has to be present next to the tool,
    # the job file for the tool has the tool name as prefix
    # and *.job.yaml as suffix, e.g. drisee.job.yaml.
    # Baseline file names are created from the tool name
    # as prefix and .receipt as suffix, eg. drisee.receipts.

    files = glob.glob(toolDir + "/*.tool.cwl")

    for f in files:

        # split up file and path for later use, e.g. test name creation or inferring file name for job
        m = re.split("/", f)
        tool = m.pop()
        [name, cwl_type, suffix] = tool.split(".")

        # test tool exists - should be always true for obvious reasons
        test_name = 'test_cwl_tool_%s' % name
        test = generate_check_exists_tool(tool, name, f)
        setattr(TestCwlTool, test_name, test)

        # check for job
        test_name = 'test_cwl_job_%s' % name
        test = generate_check_exists_job(tool, name, f)
        setattr(TestCwlTool, test_name, test)

        # check baseline exists for tool
        test_name = 'test_cwl_baseline_%s' % name
        test = generate_check_exists_baseline(tool, name, f)
        setattr(TestCwlTool, test_name, test)

        # baseline test
        test_name = 'test_cwl_compare_baseline_%s' % name
        test = generate_check_tool_output(tool, name, f)
        setattr(TestCwlTool, test_name, test)

    unittest.main()
