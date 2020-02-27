#!/usr/bin/env python
import sys
import os
import shutil
import subprocess

pathname = os.path.dirname(sys.argv[0])        
scriptpath = os.path.abspath(pathname) 

skipmerge = False
version = sys.argv[1]                                # ifort version number
fprname = os.path.join(scriptpath,sys.argv[2])       # name of the file with the projectlist
slndir  = scriptpath        # path to the solution

env_ifortdir = "IFORT_COMPILER"+version
try:
    ifortdir = os.environ[env_ifortdir]
except:
    sys.stderr.write("Are you absolutely sure you have Intel Fortran %s ??!!\n\n"%version)
    sys.exit()

ja64 = True
if (ja64):
    codecovtool = os.path.join(ifortdir,"bin","intel64","codecov.exe") 
    profmergetool = os.path.join(ifortdir,"bin","intel64","profmerge.exe") 
else:
    codecovtool = os.path.join(ifortdir,"bin","intel64_ia32","codecov.exe") 
    profmergetool = os.path.join(ifortdir,"bin","intel64_ia32","profmerge.exe") 

# execute the profmerge tool
if not skipmerge:
    cmd = profmergetool
    proc_rtn = subprocess.Popen(cmd).wait()    # proc_rtn!=0 in case of an error

fpr = open(fprname,'r') 
prlist = fpr.readlines()
fpr.close()

cov_results = 'cov_results'
if os.path.isdir(cov_results):
    shutil.rmtree(cov_results)
os.mkdir(cov_results)
os.chdir(cov_results)

mwd = os.getcwd()
for entry in prlist:
    spi_file = entry.rstrip()
    pad, file = os.path.split(spi_file)
    prname = os.path.split(pad.rstrip())[1]
    os.mkdir(prname)
    os.chdir(prname)
    cmd = codecovtool + ' -dpi ..\..\pgopti.dpi -spi ' +os.path.join(slndir,spi_file) \
	                  +' -xmlbcvrgfull code_coverage.xml' +' -txtbcvrgfull code_coverage.txt'
    print (cmd)
    proc_rtn = subprocess.Popen(cmd).wait()    # proc_rtn!=0 in case of an error
    print (prname)
    os.chdir(mwd)

