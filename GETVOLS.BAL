GETVOLS  START  0                                                       00010000
GETVOLS  AMODE 24                                                       00020000
GETVOLS  RMODE 24                                                       00030000
         COPY  EQUATES                                                  00040000
         SAVE  (14,12),,'GETVOLS &SYSDATE &SYSTIME'                     00050000
         USING GETVOLS,R12                                              00060000
         LR    R12,R15                                                  00061000
         ST    R13,SAVEAREA+4                                           00062000
         LR    R14,R13                                                  00063000
         LA    R13,SAVEAREA                                             00064000
         ST    R14,8(R13)                                               00065000
         USING SAVEAREA,R13                                             00066000
         LR    R2,R1                    R1-> PARMS                      00066100
         USING PARMS,R2                                                 00066200
** FIRST TIME CONSTRUCTOR CALL                                          00066300
         ICM   R3,B'1111',VOL_IDX       IF FIRST TIME                   00067000
         JNZ   NOT_FIRST                THEN DO                         00068000
         RDJFCB IN_DCB,MF=(E,RD1)        READ JOB FILE CONTROL BLOCK    00071000
         L     R5,A#DSNAME               R5 -> RETURN_VALUE.DSNAME      00071103
         USING DSNAME,R5                                                00071203
         MVC   DSNAME,JFCBDSNM           RETURN_VALUE.DSNAME = DSNAME   00071301
         DROP  R5                                                       00071403
NOT_FIRST DS   0H                       END                             00071502
         LA    R3,1(R3)                 INCREMENT VOL_IDX               00071600
         ST    R3,VOL_IDX                                               00071704
         CHI   R3,5                     IF VOL_IDX <= 5                 00071810
         BH    USE_EXT                  THEN DO                         00071900
         BCTR  R3,0                      REDUCE BY 1                    00072000
         MHI   R3,6                      GET OFFSET                     00072110
         LA    R3,JFCBVOLS(R3)           R3 -> NEXT VOLUME              00073000
         B     VOL_FND                  END                             00074004
USE_EXT  DS    0H                       ELSE DO                         00350004
         L     R5,JFCBEXTL               R5 = 1 BYTE LEN + ADDR OF EXT  00350104
         LA    R5,16(R5)                 DSECT IS MISSING 16 BYTES      00350209
         USING JFCBX,R5                                                 00350306
         AHI   R3,-6                     CONVERT R3 TO OFFSET           00350611
*                                        NB NO SHI SO ADD NEGATIVE      00350711
         MHI   R3,6                                                     00350810
         LA    R3,JFCBXVOL(R3)           R3 -> NEXT VOLUME              00350906
         LA    R7,JFCBXVOL+(15*6)-1      R7 -> END OF LIST              00351007
         CLR   R3,R7                     IF R3 >= R7                    00351106
         JL    IN_RANGE                  THEN DO                        00351206
         LA    R3,BLANK_VOL               R3 -> BLANKS                  00351306
IN_RANGE DS    0H                        END                            00351406
VOL_FND  DS    0H                       END                             00351506
         L     R5,A#RET_VOL             R5 -> RETURN_VALUE.VOLSER       00351606
         USING RET_VOL,R5                                               00351706
         MVC   RET_VOL,0(R3)            RETURN_VALUE.VOLSER = NEXT VOL  00351806
         DROP  R5                                                       00351906
EXIT     DS    0H                                                       00352000
         L     R13,SAVEAREA+4                                           00360000
         RETURN (14,12),,RC=(15)                                        00370000
         DS    0D                                                       00380000
SAVEAREA DC    18F'0'                                                   00390000
DWORD    DC    PL8'0'                                                   00400000
VOL_IDX  DC    F'0'                                                     00410000
BLANK_VOL DC   CL6' '                                                   00420004
         PUSH  PRINT                                                    00780500
         PRINT NOGEN                                                    00780600
IN_DCB   DCB   DDNAME=IN,MACRF=(RP),DSORG=PS,EXLST=EX1                  00780700
         POP   PRINT                                                    00780800
RD1      RDJFCB IN_DCB,MF=L                                             00780900
AREA     DS    0D                                                       00781000
         IEFJFCBN LIST=YES                                              00782000
EX1      DS    0F                                                       00790000
         DC    X'87',AL3(AREA)                                          00800000
PARMS    DSECT ,                                                        00801000
A#DSNAME DS    A                        ADDRESS OF RETURN DSNAME        00802001
A#RET_VOL DS   A                        ADDRESS OF RETURN VOLUME        00802102
PARM1    DSECT ,                                                        00803000
DSNAME   DS    CL44                     RETURN DSNAME                   00804001
PARM2    DSECT ,                                                        00805001
RET_VOL  DS    CL6                      RETURN VOLUME                   00806002
JFCBX    DSECT ,                                                        00807006
         IEFJFCBX                                                       00808006
         END   GETVOLS                                                  00810000
GETVOLS  START  0                                                       00010000
GETVOLS  AMODE 24                                                       00020000
GETVOLS  RMODE 24                                                       00030000
         COPY  EQUATES                                                  00040000
         SAVE  (14,12),,'GETVOLS &SYSDATE &SYSTIME'                     00050000
         USING GETVOLS,R12                                              00060000
         LR    R12,R15                                                  00061000
         ST    R13,SAVEAREA+4                                           00062000
         LR    R14,R13                                                  00063000
         LA    R13,SAVEAREA                                             00064000
         ST    R14,8(R13)                                               00065000
         USING SAVEAREA,R13                                             00066000
         LR    R2,R1                    R1-> PARMS                      00066100
         USING PARMS,R2                                                 00066200
** FIRST TIME CONSTRUCTOR CALL                                          00066300
         ICM   R3,B'1111',VOL_IDX       IF FIRST TIME                   00067000
         JNZ   NOT_FIRST                THEN DO                         00068000
         RDJFCB IN_DCB,MF=(E,RD1)        READ JOB FILE CONTROL BLOCK    00071000
         L     R5,A#DSNAME               R5 -> RETURN_VALUE.DSNAME      00071103
         USING DSNAME,R5                                                00071203
         MVC   DSNAME,JFCBDSNM           RETURN_VALUE.DSNAME = DSNAME   00071301
         DROP  R5                                                       00071403
NOT_FIRST DS   0H                       END                             00071502
         LA    R3,1(R3)                 INCREMENT VOL_IDX               00071600
         ST    R3,VOL_IDX                                               00071704
         CHI   R3,5                     IF VOL_IDX <= 5                 00071810
         BH    USE_EXT                  THEN DO                         00071900
         BCTR  R3,0                      REDUCE BY 1                    00072000
         MHI   R3,6                      GET OFFSET                     00072110
         LA    R3,JFCBVOLS(R3)           R3 -> NEXT VOLUME              00073000
         B     VOL_FND                  END                             00074004
USE_EXT  DS    0H                       ELSE DO                         00350004
         L     R5,JFCBEXTL               R5 = 1 BYTE LEN + ADDR OF EXT  00350104
         LA    R5,16(R5)                 DSECT IS MISSING 16 BYTES      00350209
         USING JFCBX,R5                                                 00350306
         AHI   R3,-6                     CONVERT R3 TO OFFSET           00350611
*                                        NB NO SHI SO ADD NEGATIVE      00350711
         MHI   R3,6                                                     00350810
         LA    R3,JFCBXVOL(R3)           R3 -> NEXT VOLUME              00350906
         LA    R7,JFCBXVOL+(15*6)-1      R7 -> END OF LIST              00351007
         CLR   R3,R7                     IF R3 >= R7                    00351106
         JL    IN_RANGE                  THEN DO                        00351206
         LA    R3,BLANK_VOL               R3 -> BLANKS                  00351306
IN_RANGE DS    0H                        END                            00351406
VOL_FND  DS    0H                       END                             00351506
         L     R5,A#RET_VOL             R5 -> RETURN_VALUE.VOLSER       00351606
         USING RET_VOL,R5                                               00351706
         MVC   RET_VOL,0(R3)            RETURN_VALUE.VOLSER = NEXT VOL  00351806
         DROP  R5                                                       00351906
EXIT     DS    0H                                                       00352000
         L     R13,SAVEAREA+4                                           00360000
         RETURN (14,12),,RC=(15)                                        00370000
         DS    0D                                                       00380000
SAVEAREA DC    18F'0'                                                   00390000
DWORD    DC    PL8'0'                                                   00400000
VOL_IDX  DC    F'0'                                                     00410000
BLANK_VOL DC   CL6' '                                                   00420004
         PUSH  PRINT                                                    00780500
         PRINT NOGEN                                                    00780600
IN_DCB   DCB   DDNAME=IN,MACRF=(RP),DSORG=PS,EXLST=EX1                  00780700
         POP   PRINT                                                    00780800
RD1      RDJFCB IN_DCB,MF=L                                             00780900
AREA     DS    0D                                                       00781000
         IEFJFCBN LIST=YES                                              00782000
EX1      DS    0F                                                       00790000
         DC    X'87',AL3(AREA)                                          00800000
PARMS    DSECT ,                                                        00801000
A#DSNAME DS    A                        ADDRESS OF RETURN DSNAME        00802001
A#RET_VOL DS   A                        ADDRESS OF RETURN VOLUME        00802102
PARM1    DSECT ,                                                        00803000
DSNAME   DS    CL44                     RETURN DSNAME                   00804001
PARM2    DSECT ,                                                        00805001
RET_VOL  DS    CL6                      RETURN VOLUME                   00806002
JFCBX    DSECT ,                                                        00807006
         IEFJFCBX                                                       00808006
         END   GETVOLS                                                  00810000