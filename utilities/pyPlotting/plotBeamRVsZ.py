# Copyright (c) 2012-2018, University of Strathclyde
# Authors: Lawrence T. Campbell
# License: BSD-3-Clause

"""
This produces a plot of the average rms standard deviation of the electron beam from 
the Puffin integrated datafiles, against distance through the undulator z. 
"""

import sys, glob, os
import numpy as np
from numpy import arange
import matplotlib.pyplot as plt
import tables
from retrieve import getIntData
from puffdata import fdata
from puffdata import puffData

iTemporal = 0
iPeriodic = 1


##################################################################
#
##


def getFileSlices(baseName):
  """ getTimeSlices(baseName) gets a list of files

  That will be used down the line...
  """
  filelist=glob.glob(os.getcwd()+os.sep+baseName+'_integrated_*.h5')
  
  dumpStepNos=[]
  for thisFile in filelist:
    thisDump=int(thisFile.split(os.sep)[-1].split('.')[0].split('_')[-1])
    dumpStepNos.append(thisDump)

  for i in range(len(dumpStepNos)):
    filelist[i]=baseName+'_integrated_'+str(sorted(dumpStepNos)[i])+'.h5'
  return filelist



def getZData(fname):
    h5f = tables.open_file(fname, mode='r')
    zD = h5f.root.runInfo._v_attrs.zTotal
    h5f.close()
    return zD


def plotBeamRVsZ(basename):


    filelist = getFileSlices(basename)
    #print filelist

    mdata = fdata(filelist[0])

    sampleFreq = 1.0 / mdata.vars.dz2

    lenz2 = (mdata.vars.nz2-1) * mdata.vars.dz2
    z2axis = (np.arange(0,mdata.vars.nz2)) * mdata.vars.dz2
    
    xaxis = (np.arange(0,mdata.vars.nx)) * mdata.vars.dxbar
    yaxis = (np.arange(0,mdata.vars.ny)) * mdata.vars.dybar

    fcount = 0
    
    radx = np.zeros(len(filelist))
    rady = np.zeros(len(filelist))
    zData = np.zeros(len(filelist))

    gAv = 1

    for ij in filelist:
        radx[fcount] = getIntData(ij, 'sigmaXSI', irtype = gAv)
        rady[fcount] = getIntData(ij, 'sigmaYSI', irtype = gAv)
        zData[fcount] = getZData(ij)
        fcount += 1



#    plotLab = 'SI Power'
#    axLab = 'Power (W)'

    plotLab = r'$\sigma_x$'
    axLab = r'$\sigma_x, \sigma_y (\mu m)$'

    ax1 = plt.subplot(111)
    plt.plot(zData, radx * 1.e6, label=r'$\sigma_x$')
    plt.plot(zData, rady * 1.e6, label=r'$\sigma_y$')
    #ax1.set_title(axLab)
    plt.xlabel('z (m)')
    plt.ylabel(axLab)

    plt.legend()

    plt.tight_layout()

    opname = basename + "-beamRadiusVsZ.png"

    plt.savefig(opname)
#    plt.show()


#    plt.show(block=False)
#    h5f.close()


if __name__ == '__main__':

    basename = sys.argv[1]
    plotBeamRVsZ(basename)
