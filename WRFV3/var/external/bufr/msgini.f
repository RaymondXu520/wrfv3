      SUBROUTINE MSGINI(LUN)

C$$$  SUBPROGRAM DOCUMENTATION BLOCK
C
C SUBPROGRAM:    MSGINI
C   PRGMMR: WOOLLEN          ORG: NP20       DATE: 1994-01-06
C
C ABSTRACT: THIS SUBROUTINE INITIALIZES, WITHIN THE INTERNAL ARRAYS, A
C   NEW BUFR MESSAGE FOR OUTPUT.  ARRAYS ARE FILLED IN COMMON BLOCKS
C   /MSGPTR/, /MSGCWD/ AND /BITBUF/.
C
C PROGRAM HISTORY LOG:
C 1994-01-06  J. WOOLLEN -- ORIGINAL AUTHOR
C 1996-12-11  J. WOOLLEN -- MODIFIED TO ALLOW INCLUSION OF MINUTES IN
C                           WRITING THE MESSAGE DATE INTO A BUFR
C                           MESSAGE
C 1997-07-29  J. WOOLLEN -- MODIFIED TO UPDATE THE CURRENT BUFR VERSION
C                           WRITTEN IN SECTION 0 FROM 2 TO 3
C 1998-07-08  J. WOOLLEN -- REPLACED CALL TO CRAY LIBRARY ROUTINE
C                           "ABORT" WITH CALL TO NEW INTERNAL BUFRLIB
C                           ROUTINE "BORT"; MODIFIED TO MAKE Y2K
C                           COMPLIANT
C 1999-11-18  J. WOOLLEN -- THE NUMBER OF BUFR FILES WHICH CAN BE
C                           OPENED AT ONE TIME INCREASED FROM 10 TO 32
C                           (NECESSARY IN ORDER TO PROCESS MULTIPLE
C                           BUFR FILES UNDER THE MPI)
C 2000-09-19  J. WOOLLEN -- MAXIMUM MESSAGE LENGTH INCREASED FROM
C                           10,000 TO 20,000 BYTES
C 2002-05-14  J. WOOLLEN -- REMOVED ENTRY POINT MINIMG (IT BECAME A
C                           SEPARATE ROUTINE IN THE BUFRLIB TO
C                           INCREASE PORTABILITY TO OTHER PLATFORMS)
C 2003-11-04  J. ATOR    -- ADDED DOCUMENTATION
C 2003-11-04  S. BENDER  -- ADDED REMARKS/BUFRLIB ROUTINE
C                           INTERDEPENDENCIES
C 2003-11-04  D. KEYSER  -- MAXJL (MAXIMUM NUMBER OF JUMP/LINK ENTRIES)
C                           INCREASED FROM 15000 TO 16000 (WAS IN
C                           VERIFICATION VERSION); UNIFIED/PORTABLE FOR
C                           WRF; ADDED HISTORY DOCUMENTATION; OUTPUTS
C                           MORE COMPLETE DIAGNOSTIC INFO WHEN ROUTINE
C                           TERMINATES ABNORMALLY
C 2004-08-09  J. ATOR    -- MAXIMUM MESSAGE LENGTH INCREASED FROM
C                           20,000 TO 50,000 BYTES
C 2005-11-29  J. ATOR    -- CHANGED DEFAULT MASTER TABLE VERSION TO 12
C
C USAGE:    CALL MSGINI (LUN)
C   INPUT ARGUMENT LIST:
C     LUN      - INTEGER: I/O STREAM INDEX INTO INTERNAL MEMORY ARRAYS
C
C REMARKS:
C    THIS ROUTINE CALLS:        BORT     NEMTAB   NEMTBA   PKB
C                               PKC
C    THIS ROUTINE IS CALLED BY: CPYUPD   MSGUPD   OPENMB   OPENMG
C                               SUBUPD
C                               Normally not called by any application
C                               programs.
C
C ATTRIBUTES:
C   LANGUAGE: FORTRAN 77
C   MACHINE:  PORTABLE TO ALL PLATFORMS
C
C$$$

      INCLUDE 'bufrlib.prm'

      COMMON /PADESC/ IBCT,IPD1,IPD2,IPD3,IPD4
      COMMON /MSGPTR/ NBY0,NBY1,NBY2,NBY3,NBY4,NBY5
      COMMON /MSGCWD/ NMSG(NFILES),NSUB(NFILES),MSUB(NFILES),
     .                INODE(NFILES),IDATE(NFILES)
      COMMON /BITBUF/ MAXBYT,IBIT,IBAY(MXMSGLD4),MBYT(NFILES),
     .                MBAY(MXMSGLD4,NFILES)
      COMMON /BTABLES/ MAXTAB,NTAB,TAG(MAXJL),TYP(MAXJL),KNT(MAXJL),
     .                JUMP(MAXJL),LINK(MAXJL),JMPB(MAXJL),
     .                IBT(MAXJL),IRF(MAXJL),ISC(MAXJL),
     .                ITP(MAXJL),VALI(MAXJL),KNTI(MAXJL),
     .                ISEQ(MAXJL,2),JSEQ(MAXJL)

      CHARACTER*128 BORT_STR
      CHARACTER*10  TAG
      CHARACTER*8   SUBTAG
      CHARACTER*4   BUFR,SEVN
      CHARACTER*3   TYP
      CHARACTER*1   TAB

      DATA BUFR/'BUFR'/
      DATA SEVN/'7777'/

C-----------------------------------------------------------------------
C-----------------------------------------------------------------------

C  GET THE MESSAGE TAG AND TYPE, AND BREAK UP THE DATE
C  ---------------------------------------------------

      SUBTAG = TAG(INODE(LUN))
c  .... Given SUBSET, NEMTBA returns MTYP,MSBT,INOD
      CALL NEMTBA(LUN,SUBTAG,MTYP,MSBT,INOD)
      IF(INODE(LUN).NE.INOD) GOTO 900
      CALL NEMTAB(LUN,SUBTAG,ISUB,TAB,IRET)
      IF(IRET.EQ.0) GOTO 901

C  DATE CAN BE YYMMDDHH OR YYYYMMDDHH
C  ----------------------------------

      MCEN = MOD(IDATE(LUN)/10**8,100)+1
      MEAR = MOD(IDATE(LUN)/10**6,100)
      MMON = MOD(IDATE(LUN)/10**4,100)
      MDAY = MOD(IDATE(LUN)/10**2,100)
      MOUR = MOD(IDATE(LUN)      ,100)
      MMIN = 0

c  .... DK: Can this happen?? (investigate)
      IF(MCEN.EQ.1) GOTO 902

      IF(MEAR.EQ.0) MCEN = MCEN-1
      IF(MEAR.EQ.0) MEAR = 100

C  INITIALIZE THE MESSAGE
C  ----------------------

      MBIT = 0
      NBY0 = 8
      NBY1 = 18
      NBY2 = 0
      NBY3 = 20
      NBY4 = 4
      NBY5 = 4
      NBYT = NBY0+NBY1+NBY2+NBY3+NBY4+NBY5

C  SECTION 0
C  ---------

      CALL PKC(BUFR ,  4 , MBAY(1,LUN),MBIT)
      CALL PKB(NBYT , 24 , MBAY(1,LUN),MBIT)
      CALL PKB(   3 ,  8 , MBAY(1,LUN),MBIT)

C  SECTION 1
C  ---------

      CALL PKB(NBY1 , 24 , MBAY(1,LUN),MBIT)
      CALL PKB(   0 ,  8 , MBAY(1,LUN),MBIT)
      CALL PKB(   3 ,  8 , MBAY(1,LUN),MBIT)
      CALL PKB(   7 ,  8 , MBAY(1,LUN),MBIT)
      CALL PKB(   0 ,  8 , MBAY(1,LUN),MBIT)
      CALL PKB(   0 ,  8 , MBAY(1,LUN),MBIT)
      CALL PKB(MTYP ,  8 , MBAY(1,LUN),MBIT)
      CALL PKB(MSBT ,  8 , MBAY(1,LUN),MBIT)
      CALL PKB(  12 ,  8 , MBAY(1,LUN),MBIT)
      CALL PKB(   0 ,  8 , MBAY(1,LUN),MBIT)
      CALL PKB(MEAR ,  8 , MBAY(1,LUN),MBIT)
      CALL PKB(MMON ,  8 , MBAY(1,LUN),MBIT)
      CALL PKB(MDAY ,  8 , MBAY(1,LUN),MBIT)
      CALL PKB(MOUR ,  8 , MBAY(1,LUN),MBIT)
      CALL PKB(MMIN ,  8 , MBAY(1,LUN),MBIT)
      CALL PKB(MCEN ,  8 , MBAY(1,LUN),MBIT)

C  SECTION 3
C  ---------

      CALL PKB(NBY3 , 24 , MBAY(1,LUN),MBIT)
      CALL PKB(   0 ,  8 , MBAY(1,LUN),MBIT)
      CALL PKB(   0 , 16 , MBAY(1,LUN),MBIT)
      CALL PKB(2**7 ,  8 , MBAY(1,LUN),MBIT)
      CALL PKB(IBCT , 16 , MBAY(1,LUN),MBIT)
      CALL PKB(ISUB , 16 , MBAY(1,LUN),MBIT)
      CALL PKB(IPD1 , 16 , MBAY(1,LUN),MBIT)
      CALL PKB(IPD2 , 16 , MBAY(1,LUN),MBIT)
      CALL PKB(IPD3 , 16 , MBAY(1,LUN),MBIT)
      CALL PKB(IPD4 , 16 , MBAY(1,LUN),MBIT)
      CALL PKB(   0 ,  8 , MBAY(1,LUN),MBIT)

C  SECTION 4
C  ---------

      CALL PKB(NBY4 , 24 , MBAY(1,LUN),MBIT)
      CALL PKB(   0 ,  8 , MBAY(1,LUN),MBIT)

C  SECTION 5
C  ---------

      CALL PKC(SEVN ,  4 , MBAY(1,LUN),MBIT)

C  DOUBLE CHECK INITIAL MESSAGE LENGTH
C  -----------------------------------

      IF(MOD(MBIT,8).NE.0) GOTO 903
      IF(MBIT/8.NE.NBYT  ) GOTO 904

      NMSG(LUN) = NMSG(LUN)+1
      NSUB(LUN) = 0
      MBYT(LUN) = NBYT

C  EXITS
C  -----

      RETURN
900   WRITE(BORT_STR,'("BUFRLIB: MSGINI - MISMATCH BETWEEN INODE (=",   
     & I7,") & POSITIONAL INDEX, INOD (",I7,") OF SUBTAG (",A,") IN 
     & DICTIONARY")') INODE(LUN),INOD,SUBTAG
      CALL BORT(BORT_STR)
901   WRITE(BORT_STR,'("BUFRLIB: MSGINI - TABLE A MESSAGE TYPE    
     & MNEMONIC ",A," NOT FOUND IN INTERNAL TABLE D ARRAYS")') SUBTAG
      CALL BORT(BORT_STR)
902   CALL BORT
     & ('BUFRLIB: MSGINI - BUFR MESSAGE DATE (IDATE) is 0000000000')
903   CALL BORT('BUFRLIB: MSGINI - INITIALIZED MESSAGE DOES NOT END  
     & ON A BYTE BOUNDARY')
904   WRITE(BORT_STR,'("BUFRLIB: MSGINI - NUMBER OF BYTES STORED FOR  
     & INITIALIZED MESSAGE (",I6,") IS NOT THE SAME AS FIRST  
     & CALCULATED, NBYT (",I6)') MBIT/8,NBYT
      CALL BORT(BORT_STR)
      END
