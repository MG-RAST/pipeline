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


debug =  int(os.environ.get('DEBUG' , 0))
CREATE_BASELINE = int(os.environ.get('CREATE_BASELINE' , 0))
CHECK_BASELINE = int(os.environ.get('CREATE_BASELINE' , 0))
# print "DEBUG: " + str(debug)

disable_docker = 1

testDir     = os.path.abspath( os.path.dirname( __file__ )  )
baselineDir = testDir + "/../Data/Baseline/"
toolDir     = testDir + "/../Tools/"
workflowDir = testDir + "/../Workflows/"
inputDir    = testDir + "/../Data/Inputs/"
outputDir   = testDir + "/../Data/Outputs/"
docker      = None
cwlTool     = "cwltool" # "cwl-runner"

if disable_docker :
  docker = "--no-container"


def generate_check_exists_tool(tool , name, path):
    def test(self):
        """Does tool exists"""
        self.assertTrue(os.path.exists(path))
    return test

def generate_check_exists_job(tool , name, path) :
  def test(self):
      """Does job exists"""
      job_file = workflowDir + name + ".job.yaml"
      # self.longMessage = True
      msg = "Missing job " + toolDir + name + ".job.yaml"
      self.assertTrue(os.path.exists(job_file) , msg= msg)
  return test
  
def generate_check_exists_baseline(tool , name, path) :
  def test(self):
      """Does baseline data exists"""
      baseline_file = baselineDir + name + ".receipt"
      # self.longMessage = True
      msg = "Missing baseline for " + name + ": " + baseline_file
      self.assertTrue(os.path.exists(baseline_file) , msg= msg)
  return test  

def generate_check_tool_output(tool, name , path) :
  def test(self):
      """Run tool or workflow and compare output to baseline"""
      
      # set job  
      job = workflowDir + name + ".job.yaml"
       
      if debug :
        print("\nDEBUG:")
        print("workflowDir: " + workflowDir)
        print("OutputDir: " + outputDir)
        print("Tool: " + tool)
        print [tool , name , path]
        print ['cwl-runner' , '--outdir ' + outputDir, docker , workflowDir + tool  , job] 
   
      # execute tool
      session = subprocess.Popen([ cwlTool , '--outdir' , outputDir, docker , workflowDir + tool , job ] , stdin=None , stdout=PIPE, stderr=PIPE , shell=False)
      stdout, stderr = session.communicate()
      setattr(self , name , stdout)

      success = re.search( "Final process status is success" , stderr )

      if debug :
        if re.search("permanentFail" , stderr) :
          print("Regex permantFail worked")
          print stderr
        else:
          print stderr[-40:]  

      if CREATE_BASELINE and success : 
        if not os.path.exists( baselineDir):
           sys.stderr.write('No baseline dir :' + baselineDir)
           sys.exit()
        if not os.path.exists( baselineDir + "/" + name + ".receipt" ) :
          print ("Creating baseline file for " + name )
          compFile = open( baselineDir + "/" + name + ".receipt" , 'w')
          compFile.write(stdout)
          compFile.close()
        else:
          print ("Baseline already exists, no overwrite option")

     
      self.assertTrue( success	, msg= " ".join(['cwl-runner' , '--outdir ' + outputDir, docker , workflowDir + tool  , job , "\n" , stderr ]) )

      if success and CHECK_BASELINE :
        compFile = open( baselineDir + "/" + name + ".receipt" , 'r')
        baseline = compFile.read()
        compFile.close()
        print("Testing against baseline")
        self.assertTrue( cmp_cwl_receipts(baseline , stdout) , msg= "Receipt not identical with baseline receipt for " + tool )   
    
  return test

def cmp_cwl_receipts(json_a , json_b) :
  
  identical = 1
  
  try:
    a = json.loads(json_a)
    b = json.loads(json_b)
  except Exception as e :
    print(repr(e))
    sys.stderr.write("Can't parse json strings ... " + repr(e)  + " ... " + "a=" + str(type(json_a)) + " b=" + str(type(json_b)) + " ...") 

  try:  
    for k, v in a.iteritems():
      if 'format' in v :
        if debug:
          sys.stderr.write('Found \'format\' key.\n')
        if re.search("json" , v['format']) is  None :
          if v['checksum'] != b[k]["checksum"] :
            identical = 0
            sys.stderr.write('Checksum not identical for ' + v['basename'] + "\n")
        else:
            if debug:
              sys.stderr.write('Found \'json\' value. Not comparing checksum for ' + v['basename'] + "\n")
      elif  v['checksum'] != b[k]["checksum"] :
        identical = 0
        sys.stderr.write('Checksum not identical for ' + k + "(" + v['basename'] + ")\n")
      if v['basename'] != b[k]["basename"] :
        identical = 0
        sys.stderr.write('Basename not identical for ' + k +  "\n")
      if v['size'] != b[k]["size"] :
        identical = 0 
        sys.stderr.write('Size not identical for ' + k +  "\n") 
        
  except Exception as e :
    print("error in second try")
    print(repr(e))
    sys.stderr.write("Error comparing dicts ... " + repr(e) + " ... ") 
    identical = 0
  
  return identical   


class TestCWL(unittest.TestCase):
 
    def setUp(self):
        """Setup test, get path to script and version"""
      
        session = subprocess.Popen([ cwlTool , '--version'] , stdout=PIPE, stderr=PIPE)
        stdout, stderr = session.communicate()

        if stderr:
            raise Exception("Error "+str(stderr))
            
        (script , version) = stdout.split(" ")
        self.script = script
        self.version = version
        
 
    def test_cwl_runner_version(self):
        """Is cwl-runner version greater or equal 1.0.20170525215327"""
        # output = subprocess.call(['cwl-runner' , '--version'] , stdout=PIPE, stderr=PIPE)
        
        (main , subversion , revision) = self.version.split(".")
       
        self.assertTrue( int(main) >= 1)
        self.assertTrue( int(revision) >= 20170525215327 )
 

      

    
class TestCwlTool(unittest.TestCase): pass   
    
    
if __name__ == '__main__':
  
    # Create tests for every tool in the tool directory
    # A cwl tool has the suffix *.tool.cwl, e.g. drisee.too.cwl.
    # A job file for testing has to be present next to the tool,
    # the job file for the tool has the tool name as prefix 
    # and *.job.yaml as suffix , e.g. drisee.job.yaml.
    # Baseline file names are created from the tool name 
    # as prefix and .receipt as suffix , eg. drisee.receipts.
    
    files = glob.glob(workflowDir + "/*.workflow.cwl")

    workflowsToCheck = [
        "amplicon-fasta.workflow.cwl" ,
        "amplicon-fastq.workflow.cwl" ,
        "assembled.workflow.cwl" ,
        "metabarcode-fasta.workflow.cwl" ,
        "metabarcode-fastq.workflow.cwl" ,
        "wgs-fasta.workflow.cwl"  ,
        "wgs-fastq.workflow.cwl" ,
        "wgs-noscreen-fasta.workflow.cwl" ,
        "wgs-noscreen-fastq.workflow.cwl" 
    ]
 
    positiveList = set(workflowsToCheck)

    for f in files:
      
        if not os.path.basename(f) in positiveList :
           continue
            

        print ("Setting up tests for " + os.path.basename(f) )

        # split up file and path for later use, e.g. test name creation or inferring file name for job
        m = re.split("/" , f)
        tool = m.pop()
        [name , cwl_type , suffix] = tool.split(".")
        
        # test tool exists - should be always true for obvious reasons
        test_name = 'test_cwl_tool_%s' % name
        test = generate_check_exists_tool(tool , name, f)
        setattr(TestCwlTool, test_name, test)
        
        # check for job
        test_name = 'test_cwl_job_%s' % name
        test = generate_check_exists_job(tool , name, f)
        setattr(TestCwlTool, test_name, test)
        
        # check baseline exists for tool
        test_name = 'test_cwl_baseline_%s' % name
        test = generate_check_exists_baseline(tool , name, f)
        setattr(TestCwlTool, test_name, test)
        
        # run tool/workflow test and compare to workflow
        test_name = 'test_cwl_execute_%s' % name
        test = generate_check_tool_output(tool , name, f)
        setattr(TestCwlTool, test_name, test)

        # # compare to baseline
        # test_name = 'test_cwl_compare_baseline_%s' % name
        # test = generate_compare_to_baseline(tool , name , f)
        # setattr(TestCwlTool, test_name, test)
  
    unittest.main()