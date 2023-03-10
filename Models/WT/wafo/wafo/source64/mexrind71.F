#include "fintrf.h"
* The preprocessor finterf.h was added by Georg Lindgren, February 7, 2011, 
* to allow compilation for 32- and 64-bit platforms
* The extension  .F  should not be altered when preprocessor is used.
* 
* This is a MEX-file for MATLAB.
* This file contains a mex-interface to RIND a subroutine
* for computing multivariate normal expectations.
* The file is self contained and should compile without errors on (Fortran90) 
* standard Fortran compilers.

*
* The mex-interface was written by
*			Per Andreas Brodtkorb
*			Norwegian Defence Research Establishment
*			P.O. Box 115
*			N-3191 Horten
*			Norway
*			Email: Per.Brodtkorb@ffi.no
* 
* This file was modified by Georg Lindgren, 2009-10-21, and successfully 
* compiled by Intel Visual Fortran compiler 10.1 - changed mxCreateFull to
* mxCreateDoubleMatrix in order to comply with Matlab2009a.
*
* MEXRIND Computes multivariate normal expectations
*
*  E[Jacobian*Indicator|Condition ]*f_{Xc}(xc(:,ix)) 
*  where
*      "Indicator" = I{ H_lo(i) < X(i) < H_up(i), i=1:N_t+N_d }
*      "Jacobian"  = J(X(Nt+1),...,X(Nt+Nd+Nc)), special case is 
*      "Jacobian"  = |X(Nt+1)*...*X(Nt+Nd)|=|Xd(1)*Xd(2)..Xd(Nd)|
*      "condition" = Xc=xc(:,ix),  ix=1,...,Nx.
*      X = [Xt; Xd; Xc], a stochastic vector of Multivariate Gaussian 
*          variables where Xt,Xd and Xc have the length Nt, Nd and Nc,
*          respectively. (Recommended limitations Nx,Nt<=100, Nd<=6 and Nc<=10) 
* 
*  CALL: value = mexrind71(S,m,xc,Nt,NIT,speed,indI,Blo,Bup,seed,XcScale);
*
*
*    VALUE  = estimated value for the expectation as explained above size 1 x Nx
* 
*         S = Covariance matrix of X=[Xt;Xd;Xc] size Ntdc x Ntdc (Ntdc=Nt+Nd+Nc)
*         m = the expectation of X=[Xt;Xd;Xc]   size N x 1
*        xc = values to condition on            size Nc x Nx
*        Nt = size of Xt
*       NIT = 0,1,2..., dimension of numerical integration (default NIT=1)
*                -1 Integrate all by SADAPT for Ndim<9 and by KRBVRC otherwise 
*                -2 Integrate by SADAPT for Ndim<20 and by KRBVRC otherwise 
*                -3 Integrate by KRBVRC by Genz (1993) (Fast Ndim<101) 
*                -4 Integrate by KROBOV by Genz (1992) (Fast Ndim<101)
*                -5 Integrate by RCRUDE by Genz (1992) (Slow Ndim<1001)
*                -6 Integrate by SOBNIED               (Fast Ndim<1041)
*                -7 Integrate by DKBVRC by Genz (2003) (Fast Ndim<1001)
*     speed = defines accuraccy of calculations by choosing different 
*                parameters, possible values: 1,2...,9 (9 fastest, default 4).
*      indI = vector of indices to the different barriers in the  
*            indicator function,  length NI, where   NI = Nb+1 
*             (NB! restriction  indI(1)=0, indI(NI)=Nt+Nd )
* B_lo,B_up = Lower and upper barriers used to compute the integration 
*             limits, H_lo and H_up, respectively. size  Mb x Nb 
*
*    ABSEPS = REAL absolute error tolerance.
*    RELEPS = REAL relative error tolerance.
*    MAXPTS = INTEGER, maximum number of function values allowed. This 
*            parameter can be used to limit the time. A sensible 
*            strategy is to start with MAXPTS = 1000*N, and then
*            increase MAXPTS if ERROR is too large.
*
*   This routine also uses global data to transport the inputs:  
*   NB!  INITDATA may be called  before calling RIND
*   to initialize some global data
* 
*   If  Mb<Nc+1 then B_lo(Mb+1:Nc+1,:) is assumed to be zero. The relation 
*  to the integration limits  are as follows
* 
*               H_lo(i)=B_lo(1,j)+B_lo(2:Nc+1,j).'*xc(:,ix), 
*               H_up(i)=B_up(1,j)+B_up(2:Nc+1,j).'*xc(:,ix), 
* 
*   where i=indI(j-1)+1:indI(j), j=2:NI, ix=1:Nx

C     
C     mex -O -output mexrind71 intmodule.f  jacobmod.f rind71.f mexrind71.f
C
C
* Compiled by Intel Visual Fortran 11.1 with MS Visual Studio 2008, SP1, pro, February 2011

      SUBROUTINE mexFunction(nlhs, plhs, nrhs, prhs)
      USE GLOBALDATA, only: SCIS,NIT,Nt
      USE RIND
	IMPLICIT NONE
C-----------------------------------------------------------------------
C     The preprocessor  fintrf.h  (on top) will replace the mwpointer declarations 
C     to the appropriate values integer*4 or integer*8 for 32-bit and 64-bit platforms 
C
      mwpointer :: plhs(*), prhs(*)
      mwpointer :: mxCreateDoubleMatrix, mxGetPr
      mwpointer :: S_pr, Ex_pr, Xc_pr, IN_pr, BL_pr, BU_pr, V_pr
C-----------------------------------------------------------------------
C
      INTEGER :: nlhs, nrhs
      INTEGER :: mxGetM, mxGetN, mxIsNumeric
      REAL*8  :: mxGetScalar
      INTEGER :: Nx,Nj,Nc,Ntd,Nd,Ntdc,Ni,Nb,Mb,K,I
C	DOUBLE PRECISION :: ABSEPS, RELEPS, VAL, ERR
      INTEGER :: speed1, seed1
      DOUBLE PRECISION, ALLOCATABLE :: BIG(:,:),Xc(:,:)
      DOUBLE PRECISION, ALLOCATABLE :: Blo(:,:),Bup(:,:)
      DOUBLE PRECISION, ALLOCATABLE ::Ex(:),VALS(:),rINDI(:)
      DOUBLE PRECISION :: SQ0, XcScale, dREPS,dEPSS,dEPS2,dXc
      integer :: dNINT,dMAXPTS
      INTEGER, ALLOCATABLE  :: IndI(:) !,INFIN(:)
      INTEGER, ALLOCATABLE  :: seed(:)
      INTEGER               :: seed_size,INFA,INFB
C     Check for proper number of arguments. 
      IF(nrhs .LT. 11) THEN
         CALL mexErrMsgTxt('11 inputs required.')
      ELSEIF(nlhs .ne. 1) then
         CALL mexErrMsgTxt('1 outputs required.')
      ENDIF
C     Check to ensure the array is numeric (not strings).
	DO K=1,11
           IF(mxIsNumeric(prhs(K)) .EQ. 0 ) THEN
              CALL mexErrMsgTxt('Inputs must be numeric !')
           ENDIF
	END DO
C     Get the size of the input array.
      Ntdc = mxGetM(prhs(1))
	IF (Ntdc .NE. mxGetN(prhs(1)) .OR.
     &	 Ntdc .NE. mxGetN(prhs(2))*mxGetM(prhs(2)) ) THEN
		CALL mexErrMsgTxt('Inconsistent size of Big and Ex!')
	ENDIF

	Nc = mxGetM(prhs(3))
	Nx = mxGetN(prhs(3))
	IF (Nx.LT.1) THEN
		Nx = 1;	
	ENDIF
	Ni = mxGetM(prhs(7))*mxGetN(prhs(7))
	Mb = mxGetM(prhs(8))
	Nb = mxGetN(prhs(8))
	IF (Nb+1.NE. Ni) THEN
		call mexErrMsgTxt('Nb+1 must equal Ni!')
	ENDIF
	IF (Mb .NE. mxGetM(prhs(9)) .or.
     &	 Nb .NE. mxGetN(prhs(9))) THEN
		call mexErrMsgTxt('Size of Blo and Bup must be the same!')
	ENDIF
	Nt     = mxGetScalar(prhs(4))
	NIT    = mxGetScalar(prhs(5))
	speed1 = mxGetScalar(prhs(6))
	seed1  = mxGetScalar(prhs(10))
      XcScale = mxGetScalar(prhs(11))
	ALLOCATE(VALS(Nx))
	ALLOCATE(BIG(Ntdc,Ntdc))
	ALLOCATE(Ex(Ntdc))
	ALLOCATE(Xc(Nc,Nx))
	ALLOCATE(INDI(Ni))
	ALLOCATE(rINDI(Ni))
	ALLOCATE(Blo(Mb,Nb))
	ALLOCATE(Bup(Mb,Nb))
!	ALLOCATE(INFIN(Nb))

	IF (NIT.LT.0) THEN
           SCIS = ABS(NIT)
	ENDIF
	IF (SCIS.gt.0) THEN
           CALL random_seed(SIZE=seed_size) 
           ALLOCATE(seed(seed_size))
                                !print *,'rindinterface seed', seed1
           CALL random_seed(GET=seed(1:seed_size)) ! get current state
           seed(1:seed_size)=seed1 ! change seed
           CALL random_seed(PUT=seed(1:seed_size)) 
           CALL random_seed(GET=seed(1:seed_size)) ! get current state
                                !print *,'rindinterface seed', seed
           DEALLOCATE(seed)
      ENDIF

      Ntd = Ntdc - Nc;
!	Nd  = Ntd - Nt
	
      !print *,'Nt,Nd,Nc,NI,Mb,Nx',Nt,Nd,Nc,NI,Mb,Nx
      !print *,'Speed,NIT',speed,NIT
      !print *,'rind_intNj',Nj
      if (speed1.gt.0) then
	   CALL INITDATA(speed1)
	else
	 
         dEPSS  = mxGetScalar(prhs(12))
         dEPS2  = mxGetScalar(prhs(13))
         dXc    = mxGetScalar(prhs(14))
         dREPS  = mxGetScalar(prhs(15))
         dNINT  = mxGetScalar(prhs(16))
         dMAXPTS = mxGetScalar(prhs(17))
         
         CALL SETDATA (dREPS,dEPSS,dEPS2,dXc,dNINT,dMAXPTS)
	end if

C     Create matrix for the return argument.
      plhs(1) = mxCreateDoubleMatrix(1,Nx,0)
      V_pr    = mxGetPr(plhs(1))


	S_pr  = mxGetPr(prhs(1))
	Ex_pr = mxGetPr(prhs(2))
	Xc_pr = mxGetPr(prhs(3))
	IN_pr = mxGetPr(prhs(7))
	Bl_pr = mxGetPr(prhs(8))
	Bu_pr = mxGetPr(prhs(9))
      call mxCopyPtrToReal8(S_pr,BIG,Ntdc*Ntdc)
	call mxCopyPtrToReal8(Ex_pr,Ex,Ntdc)
	call mxCopyPtrToReal8(Xc_pr,Xc,Nc*Nx)
	call mxCopyPtrToReal8(Bl_pr,Blo,Mb*Nb)
	call mxCopyPtrToReal8(Bu_pr,Bup,Mb*Nb)
	call mxCopyPtrToReal8(IN_pr,rINDI,Ni)	
	DO K=1,Ni
		INDI(K) = NINT(rINDI(K))
	END DO
	IF (Ntd.EQ.INDI(NI)) THEN	
!		DO K=1,Nb
!			INFA = 0
!			INFB = 0
!	      I = INDI(K)+1
!			SQ0 = SQRT(BIG(I,I))
!			IF (Blo(1,K).GT.-10.d0*SQ0) infa=1
!			IF (Bup(1,K).LT.10.d0*SQ0) infb=1
!			INFIN(K)=2*INFA+INFB-1
!		ENDDO
C     Call the computational subroutine.
           CALL RINDD(VALS,Big,Ex,Xc,INDI,Blo,Bup,XcScale)
	ELSE
           CALL mexErrMsgTxt('INDI(Ni) must equal Nt+Nd !')
	ENDIF
      
C     Load the data into V_pr, which is the output to MATLAB
      CALL mxCopyReal8ToPtr(VALS,V_pr,Nx)     
	
	DEALLOCATE(VALS)
	DEALLOCATE(BIG)
	DEALLOCATE(Ex)
	DEALLOCATE(Xc)
	DEALLOCATE(INDI)
	DEALLOCATE(rINDI)
	DEALLOCATE(Blo)
	DEALLOCATE(Bup)
!	DEALLOCATE(INFIN)

      RETURN
      END SUBROUTINE MEXFUNCTION

