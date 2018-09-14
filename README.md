# Puffin

Puffin (Parallel Unaveraged Fel INtegrator) simulates a Free Electron
Laser (FEL). Puffin is a massively parallel numerical solver for an
unaveraged, 3D FEL system of equations, and is written mostly in
Fortran 90, using MPI and OpenMP.

The initial publication describing the first version of the code is:-

LT Campbell and BWJ McNeil, Physics of Plasmas 19, 093119 (2012)

The code has undergone many improvements and extended its functionality
since then. It no longer uses an external linear solver package, and the
only external packages now required are FFTW (version 3.3 onwards), and
parallel HDF5 libraries. 

Please note Puffin is currently under active development. An 'official'
release will be tagged soon. Documentation is being developed 
[here](https://ukfels.github.io/puffinDocs/).

## Features

Puffin is a so-called 'unaveraged' FEL code - meaning it is absent of the
slowly varying envelope approximation (SVEA) and wiggler period averaging
approximations. It does not utilize a 'slicing' model of the beam phase space
and radiation field, and instead utilizes an algorithm which is much more
similar to a Particle-In-Cell (PIC) code methodology.

In addition, some accelerator components are included for simulation of the
'realistic' undulator line, and together with the lack of restrictions,
means it may model:
  - The full, broad bandwidth frequency spectrum, limited only by the Nyquist frequency of the mesh
  - Full electron beam transport
  - Transport of large energy spread beams through the undulator, and the radiation emitted from these beams
  - Tapered undulators
  - Fully 3D undulators, including modelling of the wiggler entries/exits and natural focusing
  - Interleaved undulator-chicane lattices
  - Variably polarized undulators
  - Tuning of each undulator module

It presently does not include the effects of space charge, and ignores emission
of the backwards wave from the e-beam.


## Release Notes

1.9.0
  - Added periodic mesh mode
  - 1D runs now read in the transverse beam radii to give proper SI power

1.8.0
  - Can now input with the Puffin HDF5 output format
  - More metadata in the output files
  - Can now resume from previous runs using HDF5 Puffin dumps
  - Twiss parameters can be used with the simple beam input
  - Communication time reduced in reorganisation stage of the parallel field algorithm
  - Using doxygen for dev documentation
  - The example auto-plotting python scripts for Visit have been refactored and can be called separately
  - Added python script (powPrep.py) to collect the power data together
  - Better point transforms for quads, now including energy dependence
  - Fixed bug of extra half-period diffraction per undulator module
  - HDF5 output is now the default data output format
  - Can now specify specific writing steps for data dumps using a 'write file'
  - Can now choose to use estimated or measured FFTW plans from input file

1.6.0:
  - Revamped the form of the lattice file, both to include more components, and to
    enhance the flexibility. Multiple undulator types with different polarizations,
    tunings, and tapers can now be used in the one run. Quads, drifts, and better
    chicane modelling (with proper diffraction of the radiation field) are now
    included.
  - Now uses FFTW v3.3 onwards. FFTW 2.1.5 support removed.
  - Supplying the radiation seed file is now optional.

1.5.1:
  - Added use of inner mesh to the parallel model to reduce communication between MPI nodes.
  - Initial python script to auto-gen plots using Visit from HDF5 files.

1.5.0
  - Re-wrote parallel algorithm to distribute the field mesh amongst MPI nodes.
