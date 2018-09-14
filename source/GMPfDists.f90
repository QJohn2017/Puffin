! Copyright 2012-2018, University of Strathclyde
! Authors: Lawrence T. Campbell
! License: BSD-3-Clause

module gMPsFromDists

use paratype
use readDists
use MacrosGenNew
use parallelInfoType
use Globals
use typesAndConstants
use parBeam
use grids
use gtop2
use initConds
use remLow
use addNoise
use pseqs
use scale

implicit none

contains


subroutine getMPs(fname, nbeams, sZ, qNoise, sEThresh, nMPDims)


! This subroutine  loops around the beams, reading in each
! particle file, and calling genMacros to generate the 
! macroparticles in each. Then the MP's with the lowest 
! chi weights are removed, and placed into the global
! arrays.


!           ARGUMENTS

  character(*), intent(in) :: fname(:)
  integer(kind=ip), intent(in) :: nbeams
  real(kind=wp), intent(in) :: sZ, sEThresh
  logical, intent(in) :: qNoise
  integer(kind=ip), intent(in) :: nMPDims(:,:)

!           local args


  real(kind=wp), allocatable :: x(:), y(:), &
                                z2(:), px(:), &
                                py(:), pz2(:), gamma(:), &
                                z2m(:), gm(:), gsig(:), &
                                xm(:), ym(:), pxm(:), pym(:), &
                                Ne(:), pxsig(:), pysig(:), &
                                xsig(:), ysig(:), &
                                chi(:), chi_b(:)


  real(kind=wp), allocatable :: dz2(:)
  integer(kind=ip), allocatable :: nZ2(:), nZ2G(:)
  integer(kind=ip) :: ib
  real(kind=wp) :: ls, le, npk, sgx1D, sgy1D

  integer(kind=ipl), allocatable :: totMPs_b(:), b_sts(:), b_ends(:)
  integer(kind=ipl) :: tnms

  integer :: error


  qRndEj_G(:) = .false.
  npk = npk_bar_G
! nZ2 is local, nZ2G is full

  allocate(dz2(nbeams), nZ2G(nbeams), nZ2(nbeams))

  call getHeaders(fname, dz2, nZ2G, sgx1D, sgy1D)

!  if (qOneD_G) then
!    nMPDims(:, iX_CG) = 1
!    nMPDims(:, iY_CG) = 1
!    nMPDims(:, iPX_CG) = 1
!    nMPDims(:, iPY_CG) = 1
!  else
!    nMPDims(:, iX_CG) = 7
!    nMPDims(:, iY_CG) = 7
!    nMPDims(:, iPX_CG) = 7
!    nMPDims(:, iPY_CG) = 7
!  end if



  do ib = 1, nbeams

    call splitBeam(nZ2G(ib), (nZ2G(ib)-1)*dz2(ib), tProcInfo_G%size, &
                   tProcInfo_G%rank, nZ2(ib), ls, le)

  end do



  

  tnms   = sum(int(nZ2(:),kind=ipl) * int((nMPDims(:,iGam_CG)),kind=ipl))



!!!!    temp

  allocate(totMPs_b(nbeams), b_sts(nbeams), b_ends(nbeams))



!  getTotalMPS(for each beam)



  if (qEquiXY_G) then

    totMPs_b(:) = int(nZ2(:),kind=ipl) * int(nMPDims(:,iGam_CG),kind=ipl) * &  ! no of mps in z2 times num in gamma
                  int(nMPDims(:,iX_CG),kind=ipl) * int(nMPDims(:,iPX_CG),kind=ipl) * &
                  int(nMPDims(:,iY_CG),kind=ipl) * int(nMPDims(:,iPY_CG),kind=ipl)

  else

    totMPs_b(:) = int(nZ2(:),kind=ipl) * nseqparts_G

  end if

  tnms   = sum(totMPs_b)    ! Sum of totMPs is the total number of 
                            ! MPs in the entire system

  call getStEnd(nbeams, totMPs_b, b_sts, b_ends)

  allocate(x(tnms), y(tnms), px(tnms), py(tnms), z2(tnms), gamma(tnms), &
           chi_b(tnms), chi(tnms))

!     Loop around beams, reading in dist files for each beam.

  do ib = 1, nbeams    !  Loop over beams



!     Allocate dist arrays for this beam

    allocate(z2m(nZ2(ib)), gm(nZ2(ib)), gsig(nZ2(ib)), &
             xm(nZ2(ib)), ym(nZ2(ib)), pxm(nZ2(ib)), &
             pym(nZ2(ib)), Ne(nZ2(ib)), pxsig(nZ2(ib)), &
             pysig(nZ2(ib)), xsig(nZ2(ib)), ysig(nZ2(ib)))

!     Read in dist file for this beam

    call getLocalDists(fname(ib), z2m, gm, &
                       xm, ym, pxm, pym, gsig, xsig, ysig, & 
                       pxsig, pysig, nz2(ib), nz2G(ib), &
                       Ne)

!     get Macroparticles in this beam

    call getMPsFDists(z2m, gm, gsig, xm, xsig, ym, ysig, pxm, pxsig, pym, pysig, dz2(ib), Ne, npk, &
                      qnoise, x(b_sts(ib):b_ends(ib)), y(b_sts(ib):b_ends(ib)), &
                      px(b_sts(ib):b_ends(ib)), py(b_sts(ib):b_ends(ib)), &
                      z2(b_sts(ib):b_ends(ib)), gamma(b_sts(ib):b_ends(ib)), &   ! ....BOUNDS.... !
                      chi_b(b_sts(ib):b_ends(ib)), chi(b_sts(ib):b_ends(ib)),sZ,nMPDims(ib,iGam_CG), &
                      nMPDims(ib,iX_CG), nMPDims(ib,iY_CG), nMPDims(ib,iPX_CG), nMPDims(ib,iPY_CG), sgx1D, sgy1D)

    deallocate(z2m, gm, gsig, xm, ym, pxm, pym, Ne, pxsig, pysig, xsig, ysig)

  end do 

!     Remove MP's with chi weights below the threshold value.

  call removeLowNC(chi_b, chi, b_sts, b_ends, sEThresh, npk_bar_G, &
                   nbeams, x, y, z2, px,&
                   py, gamma, totMPs_b)

!  if (qEquiXY_G)  npk_bar_G = npk

  deallocate(totMPs_b, b_sts, b_ends)

  deallocate(x, y, px, py, z2, gamma, chi_b, chi)

  deallocate(dz2, nZ2G, nZ2)

end subroutine getMPs

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine getLocalDists(fname, z2ml, gam_ml, xml, yml, pxml, &
                         pyml, gam_dl, xdl, ydl, pxdl, pydl, nz2, nz2g, Nel)


  character(*), intent(in) :: fname

  real(kind=wp), intent(inout) :: z2ml(:), & 
                               pxml(:), pyml(:), xml(:), yml(:), &
                               gam_ml(:), gam_dl(:), xdl(:), ydl(:), pxdl(:), pydl(:), &
                               Nel(:)

  integer(kind=ip), intent(inout) :: nz2, nz2g

!                 Local args

  real(kind=wp), allocatable :: z2m(:), & 
                   pxm(:), pym(:), xm(:), ym(:), &
                   gam_m(:), gam_d(:), pxd(:), pyd(:), &
                   xd(:), yd(:), Ne(:)

!     Allocate arrays

  allocate(z2m(nz2g), pxm(nz2g), pym(nz2g), xm(nz2g), ym(nz2g), &
           gam_m(nz2g), gam_d(nz2g), pxd(nz2g), pyd(nz2g), Ne(nz2g), &
           xd(nz2g), yd(nz2g))

!     Read in file

  if (tProcInfo_G%qRoot) then

    call readPartDists(fname, z2m, gam_m, xm, ym, pxm, pym, &
                       gam_d, xd, yd, pxd, pyd, Ne, nz2G)

  end if

!     Send to local arrays

  call scdists(xml, yml, z2ml, pxml, pyml, gam_ml, Nel, &
               xm, ym, z2m, pxm, pym, gam_m, xdl, ydl, &
               pxdl, pydl, gam_dl, pxd, pyd, xd, yd, gam_d, Ne, &
               nz2, nz2g)


  if (.not. qscaled_G) then

    ! scale beam coordinates

    call scaleT(z2ml, Lc_G)
    call scaleX(xml, Lg_G, Lc_G)
    call scaleX(xdl, Lg_G, Lc_G)
    call scaleX(yml, Lg_G, Lc_G)
    call scaleX(ydl, Lg_G, Lc_G)
    call scalePX(pxml, sGammaR_G * gam_ml, saw_G)
    call scalePX(pxdl, sGammaR_G * gam_ml, saw_G)
    call scalePX(pyml, sGammaR_G * gam_ml, saw_G)
    call scalePX(pydl, sGammaR_G * gam_ml, saw_G)


  end if

!     deallocate arrays

  deallocate(z2m, pxm, pym, xm, ym, &
             gam_m, gam_d, pxd, pyd, Ne)

end subroutine getLocalDists


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine scdists(xml, yml, z2ml, pxml, pyml, gam_ml, Nel, &
                   xm, ym, z2m, pxm, pym, gam_m, xdl, ydl, &
                   pxdl, pydl, gam_dl, pxd, pyd, xd, yd, gam_d, Ne, &
                   nz2, nz2g)


  real(kind=wp), intent(inout), dimension(:) :: xml, yml, z2ml, pxml, &
                                                pyml, gam_ml, pxdl, pydl, &
                                                gam_dl, Nel, xdl, ydl

  real(kind=wp), intent(inout), dimension(:) :: xm, ym, z2m, pxm, pym, &
                                             gam_m, pxd, pyd, gam_d, Ne, xd, yd 

  integer(kind=ip), intent(in) :: nz2, nz2g

  integer(kind=ip), allocatable :: recvs(:), displs(:)


  allocate(recvs(tProcInfo_G%size), displs(tProcInfo_G%size))

  call getGathArrs(nz2,recvs,displs)


!     Scatter mean positions to local processes

  call scatterE2Loc(z2ml,z2m,nz2,nz2g,recvs,displs,0)

  call scatterE2Loc(xml,xm,nz2,nz2g,recvs,displs,0)

  call scatterE2Loc(yml,ym,nz2,nz2g,recvs,displs,0)

  call scatterE2Loc(pxml,pxm,nz2,nz2g,recvs,displs,0)

  call scatterE2Loc(pyml,pym,nz2,nz2g,recvs,displs,0)

  call scatterE2Loc(gam_ml,gam_m,nz2,nz2g,recvs,displs,0)


!     Scatter dists to local processes

  call scatterE2Loc(xdl,xd,nz2,nz2g,recvs,displs,0)

  call scatterE2Loc(ydl,yd,nz2,nz2g,recvs,displs,0)

  call scatterE2Loc(pxdl,pxd,nz2,nz2g,recvs,displs,0)

  call scatterE2Loc(pydl,pyd,nz2,nz2g,recvs,displs,0)

  call scatterE2Loc(gam_dl,gam_d,nz2,nz2g,recvs,displs,0)

!     Scatter the num of electrons for each Z2 slice to 
!     local processes

  call scatterE2Loc(Nel,Ne,nz2,nz2g,recvs,displs,0)

  deallocate(recvs,displs)


end subroutine scdists

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine getMPsFDists(z2m,gm,gsig,xm,xsig,ym,ysig,pxm,pxsig,pym,pysig, &
                        dz2,Ne,npk,qnoise, &
                        x, y, px, py, z2, gamma, chi_b, chi, sZ, iNMPG, &
                        iNMPX, iNMPY, iNMPPX, iNMPPY, sgx1D, sgy1D) 


! This routine creates the macroparticles according to the beam dists 
! read in from the dist file.

!     Distribute Ne over gamma
!  call getGrid(aye,inputs) ! get gamma grid - equispaced in gamma
!  call getIntegrals(aye, mair inputs)
!     Just genGrid in one dimension for 1D (technically 2D) case


!     Inputting gammagrid, mean z2, Nk, and qnoise, getting out Vk,
!     and z2 and gamma positions of macroparticles, with noise added

!  call newGenMacros(grid,z2m,Nk,Vk,qNoise)   ! We will ignore vk for now

!  dV = dZ2

!     Should now have Ne for each macroparticle (WITH noise added)
!     IGNORE Vk output by genMacros



! so.......

  real(kind=wp), intent(in) :: z2m(:), gm(:), gsig(:), xm(:), xsig(:), &
                               ym(:), ysig(:), pxm(:), pxsig(:), pym(:), &
                               pysig(:), dz2, Ne(:), npk, sZ, sgx1D, sgy1D

  integer(kind=ip), intent(in) :: iNMPG, iNMPX, iNMPY, iNMPPX, iNMPPY

  logical, intent(in) :: qnoise

  real(kind=wp), intent(inout) :: x(:), y(:), px(:), py(:), &
                                  z2(:), gamma(:), chi_b(:), chi(:)

  integer(kind=ip) :: i, intTypeG, nMPs, NMZ2  ! Num MPs in gamma

  integer(kind=ipl) :: istart, iend, k, xin

  real(kind=wp) :: z2grid(2_IP), &
                   z2int(1_IP), px0, py0, x0, y0, npk_num, ndens_num, npk_numl

  integer(kind=ip), allocatable :: arrbs(:)

  real(kind=wp), allocatable :: Nk(:), Vk(:), ggrid(:), gint(:), &
                                xgrid(:), xint(:), ygrid(:), yint(:), &
                                pxgrid(:), pxint(:), pygrid(:), pyint(:), &
                                xseq(:), yseq(:), pxseq(:), pyseq(:), gamseq(:), &
                                z2seq(:), &
                                xseqb(:), yseqb(:), pxseqb(:), pyseqb(:), gamseqb(:), &
                                z2seqb(:)

  real(kind=wp) :: sigxpr, sigpxpr, sigypr, sigpypr, siggampr

  logical :: qOKL, error

!     Using 11 mp's and a gaussian distribution in p2 (gamma) 

  allocate(ggrid(iNMPG+1), gint(iNMPG))
  allocate(xgrid(iNMPX+1), xint(iNMPX))
  allocate(ygrid(iNMPY+1), yint(iNMPY))
  allocate(pxgrid(iNMPPX+1), pxint(iNMPPX))
  allocate(pygrid(iNMPPY+1), pyint(iNMPPY))

  intTypeG = iGaussianDistribution_CG  ! iTopHatDistribution_CG

  NMZ2 = size(z2m)

  z2int(:) = 1_WP

  if (qEquiXY_G) then

    nMPs = int(NMZ2,kind=ipl) * int(iNMPG,kind=ipl) * int(iNMPX,kind=ipl) * &
           int(iNMPY,kind=ipl) * int(iNMPPX,kind=ipl) * int(iNMPPY,kind=ipl)

  else

    nMPs = int(NMZ2,kind=ipl) * nseqparts_G
    
  end if

  allocate(arrbs(iNMPG))
  allocate(Nk(nMPs))
  allocate(Vk(nMPs))
  

  if (.not. qEquiXY_G) then
    allocate(xseq(nseqparts_G), yseq(nseqparts_G), &
             pxseq(nseqparts_G), pyseq(nseqparts_G), &
             gamseq(nseqparts_G), z2seq(nseqparts_G))
    allocate(xseqb(nseqparts_G), yseqb(nseqparts_G), &
         pxseqb(nseqparts_G), pyseqb(nseqparts_G), &
         gamseqb(nseqparts_G), z2seqb(nseqparts_G))
    call getSeqs(xseqb, yseqb, pxseqb, pyseqb, gamseqb, z2seqb, &
             (/1.0_wp, 1.0_wp, 1.0_wp, 1.0_wp, 1.0_wp, 1.0_wp/), TrLdMeth_G)
             
    z2seqb = (z2seqb - 0.5_wp) * dz2
    !sigxpr = 1.0_wp
    !sigpxpr = 1.0_wp
    !sigypr = 1.0_wp
    !sigpypr = 1.0_wp
    !siggampr = 1.0_wp
  end if

  iend = 0
  iStart = 0

  npk_num = 0
  ndens_num = 0

  call init_random_seed()

  do k = 1, NMZ2

    !    arrbs = linspace( (k-1) * iNMPG + 1,  k * (iNMPG-1) + 1, iNMPG )    !  calarrayboundsfrom k, nx, ny, npx, npy, ngamma 

    z2grid = (/ z2m(k) - ( dz2 / 2.0_WP) , z2m(k) + ( dz2 / 2.0_WP) /)

! what should the length of the grid in gamma be?
! since we have a different sigGam for each?.....

    if (qEquiXY_G) then

      if (qOneD_G) then

        if (iNMPG == 1_ip) then

          istart = iend + 1
          iend = iStart

          call genMacrosNew(i_total_electrons  =   Ne(k), &
                            q_noise            =   qnoise,  & 
                            x_1_grid           =   z2grid,  &
                            x_1_integral       =   z2int, & 
                            s_number_macro     =   Nk(istart:iend),  &
                            s_vol_element      =   Vk(istart:iend),  &
                            max_av             =   ndens_num,   &
                            x_1_coord          =   z2(istart:iend))

          gamma(k) = gm(k)
          px(istart:iend) = 0    !  In 1D giving no deviation in px
          py(istart:iend) = 0    !  or py
          x(istart:iend)  = 0    ! ??    x = getXR(xm,xr)
          y(istart:iend)  = 0  

        else

          istart = iend + 1
          iend = iStart + iNMPG - 1

          arrbs = (/ ( (k-1) * iNMPG + 1 + i,    i=0, (iNMPG-1) ) /)

          call genGrid(1_ip, intTypeG, iLinear_CG, gm(k), &         
                       gsig(k), 6.0_WP*gsig(k), iNMPG, iNMPG, &
                       ggrid, gint, .FALSE., &
                       qOKL) 

          call genMacrosNew(i_total_electrons  =   Ne(k), &
                            q_noise            =   qnoise,  & 
                            x_1_grid           =   z2grid,  &
                            x_1_integral       =   z2int, & 
                            p_3_grid           =   ggrid,  &
                            p_3_integral       =   gint,  &
                            s_number_macro     =   Nk(istart:iend),  &
                            s_vol_element      =   Vk(istart:iend),  &
                            max_av             =   ndens_num,   &
                            x_1_coord          =   z2(istart:iend),  &
                            p_3_vector         =   gamma(istart:iend) )


          px(istart:iend) = 0    !  In 1D giving no deviation in px
          py(istart:iend) = 0    !  or py
          x(istart:iend)  = 0    ! ??    x = getXR(xm,xr)
          y(istart:iend)  = 0  

        end if

!      Vk(iStart:iEnd) = dz2

      else

        istart = iend + 1
        iend = iStart + iNMPG * iNMPX * iNMPY * iNMPPX * iNMPPY - 1

        call genGrid(1_ip, intTypeG, iLinear_CG, xm(k), &         
                     xsig(k), 6.0_WP*xsig(k), iNMPX, iNMPX, &
                     xgrid, xint, .FALSE., &
                     qOKL)
  
        call genGrid(1_ip, intTypeG, iLinear_CG, ym(k), &         
                     ysig(k), 6.0_WP*ysig(k), iNMPY, iNMPY, &
                     ygrid, yint, .FALSE., &
                     qOKL)
  
        call genGrid(1_ip, intTypeG, iLinear_CG, pxm(k), &         
                     pxsig(k), 6.0_WP*pxsig(k), iNMPPX, iNMPPX, &
                     pxgrid, pxint, .FALSE., &
                     qOKL)
  
        call genGrid(1_ip, intTypeG, iLinear_CG, pym(k), &         
                     pysig(k), 6.0_WP*pysig(k), iNMPPY, iNMPPY, &
                     pygrid, pyint, .FALSE., &
                     qOKL)

      !call mpi_barrier(tProcInfo_G%comm, error)
      !if (tProcInfo_G%qRoot) print*, 'ghend grids!!'

        call genMacrosnew(i_total_electrons  =   Ne(k), &
                          q_noise            =   qnoise,  & 
                          x_1_grid           =   z2grid,  &
                          x_1_integral       =   z2int, & 
                          x_2_grid           =   xgrid,  &
                          x_2_integral       =   xint, & 
                          x_3_grid           =   ygrid,  &
                          x_3_integral       =   yint, &
                          p_1_grid           =   pxgrid,  &
                          p_1_integral       =   pxint,  &
                          p_2_grid           =   pygrid,  &
                          p_2_integral       =   pyint,  & 
                          p_3_grid           =   ggrid,  &
                          p_3_integral       =   gint,  &
                          s_number_macro     =   Nk(istart:iend),  &
                          s_vol_element      =   Vk(istart:iend),  &
                          max_av             =   ndens_num,   &
                          x_1_coord          =   z2(istart:iend),  &
                          x_2_coord          =   x(iStart:iend), &
                          x_3_coord          =   y(istart:iend), &
                          p_1_vector         =   px(istart:iend), &
                          p_2_vector         =   py(istart:iend), &
                          p_3_vector         =   gamma(istart:iend) )
 
        if (ndens_num > npk_num) npk_numl = ndens_num

      end if


!   Gen'ing particle by random sequences in otehr 5 dimensions
    else

      istart = iend + 1
      iend = iStart + nseqparts_G - 1

      !sigxpr = 1.0_wp
      !sigpxpr = 1.0_wp
      !sigypr = 1.0_wp
      !sigpypr = 1.0_wp
      !siggampr = 1.0_wp

!     Modify random sequences to new rms sigma and mean

      xseq = xseqb * xsig(k) + xm(k)
      yseq = yseqb * ysig(k) + ym(k)
      pxseq = pxseqb * pxsig(k) + pxm(k)
      pyseq = pyseqb * pysig(k) + pym(k)
      gamseq = gamseqb * gsig(k) + gm(k)
      z2seq = z2seqb + z2m(k)



!     Save rms sigma for next iteration

        !sigxpr = xsig(k)
        !sigpxpr = pxsig(k)
        !sigypr = ysig(k)
        !sigpypr = pysig(k)
        !siggampr = gsig(k)



!     Distribute charge equally amongst processes, and set
!     positions

      Nk(istart:iend) = Ne(k) / real(nseqparts_G,kind=wp)
      z2(istart:iend) = z2seq !z2m(k) ! z2seq
      gamma(istart:iend) = gamseq
      x(iStart:iend) = xseq
      y(istart:iend) = yseq
      px(istart:iend) = pxseq
      py(istart:iend) = pyseq


    end if

 
  end do 


  if (.not. qEquiXY_G) then

    if (minval(z2) < 0) print*, 'WARNING. B4 noise z2<0'

    call applyNoise(z2, dz2, Nk)  ! add noise in z2

    if (minval(z2) < 0) print*, 'WARNING. AFTER noise z2<0'

    deallocate(xseq, yseq, pxseq, pyseq, gamseq, z2seq)
    deallocate(xseqb, yseqb, pxseqb, pyseqb, gamseqb, z2seqb)
  end if





  if (qEquiXY_G) then

    if (qOneD_G) then

      !call getChi(Nk, Vk, npk, chi_b, chi)
      call getChi(Nk, Vk, npk_bar_G, chi_b, chi)

      ata_G = 2.0_wp * pi * sgx1D * sgy1D
      fillFact_G = 1.0_wp
      !print*, 'YYYOOO', ata_G
      chi_b = chi_b / ata_G * fillFact_G

    else 


      !call getGlobalnpk(npk_num, npk_numl)

      call getChi(Nk, Vk, npk_bar_G, chi_b, chi)

    end if

  else

    chi_b = Nk / npk_bar_G
    chi = 1.0_wp
    Vk = 1.0_wp
    
    if (qOneD_G) then
      ata_G = 2.0_wp * pi * sgx1D * sgy1D
      fillFact_G = 1.0_wp
      chi_b = chi_b / ata_G * fillFact_G
    end if

  end if

  deallocate(Nk, Vk)

  deallocate(ggrid, xgrid, ygrid, pxgrid, pygrid, &
             gint, xint, yint, pxint, pyint)


end subroutine getMPsFDists

end module gMPsFromDists

