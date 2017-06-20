#!/usr/bin/env python

import unittest
import subprocess 
from subprocess import Popen, PIPE
import sys
import os

# do something get script dir  smart and set path relative to CWL dir

debug = 0

testDir = os.path.abspath( os.path.dirname( __file__ )  )
baselineDir = testDir + "/../Data/Baseline/"
toolDir     = testDir + "/../Tools/"
workflowDir = testDir + "/../Workflows/"
inputDir    = testDir + "/../Data/Inputs/"
outputDir   = testDir + "/../Data/Outputs/"

class TestCWL(unittest.TestCase):
 
    def setUp(self):
        """Setup test, get path to script and version"""
        # output = subprocess.call(['cwl-runner' , '--version'] , stdout=PIPE, stderr=PIPE)
        session = subprocess.Popen(['cwl-runner' , '--version'] , stdout=PIPE, stderr=PIPE)
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
 
class TestDrisee(unittest.TestCase):
 
    def setUp(self):
      pass
    
    def tearDown(self):
      pass
      
    def test_cwl_drisee(self):
      """Is receipt for drisee identical to baseline receipt"""
   
     
      if debug :
        print "\nDEBUG:"
        print "ToolDir: " + toolDir
        print "OutputDir: " + outputDir
        print ['cwl-runner' , '--outdir ' + outputDir, toolDir + 'drisee.tool.cwl' , toolDir + 'drisee.job.yaml'] 
     
      session = subprocess.Popen(['cwl-runner' , '--outdir' , outputDir, toolDir + 'drisee.tool.cwl' , toolDir + 'drisee.job.yaml'] , stdin=None , stdout=PIPE, stderr=PIPE , shell=False)
      stdout, stderr = session.communicate()
       
      if stderr and debug :
          print 'ERROR:'
          print stderr
      
      # Test here    
      compFile = open( baselineDir + "/" + "drisee.receipt" , 'r')
      baseline = compFile.read()
    
      if debug :
          print 'Baseline:'
          print baseline
          print 'Output:' + stdout
      self.assertTrue( baseline == stdout )
      
class TestKmerTool(unittest.TestCase):      
  
  def setUp(self):
    pass
    
  def tearDown(self):
    pass  
  
  def test_cwl_kmer_tool(self):
    """Is receipt for kmer-tool identical to baseline receipt"""
    
    if debug :
      print "\nDEBUG:"
      print "ToolDir: " + toolDir
      print "OutputDir: " + outputDir
      print ['cwl-runner' , '--outdir ' + outputDir, toolDir + 'kmer-tool.tool.cwl' , toolDir + 'kmer-tool.job.yaml'] 
   
    session = subprocess.Popen(['cwl-runner' , '--outdir' , outputDir, toolDir + 'kmer-tool.tool.cwl' , toolDir + 'kmer-tool.job.yaml'] , stdin=None , stdout=PIPE, stderr=PIPE , shell=False)
    stdout, stderr = session.communicate()
       
    if stderr and debug :
        print 'ERROR:'
        print stderr
    
    # Test here    
    compFile = open( baselineDir + "/" + "kmer-tool.receipt" , 'r')
    baseline = compFile.read()
  
    self.assertTrue( baseline == stdout )
    
if __name__ == '__main__':
    unittest.main()