RECCALC  START  0                                                       00030000
RECCALC  AMODE 24                                                       00040000
RECCALC  RMODE 24                                                       00050000
         COPY  EQUATES                                                  00060000
         SAVE  (14,12),,'RECCALC &SYSDATE &SYSTIME'                     00061000
         USING RECCALC,R12                                              00062000
         LR    R12,R15                                                  00063000
         ST    R13,SAVEAREA+4                                           00064000
         LR    R14,R13                                                  00065000
         LA    R13,SAVEAREA                                             00066000
         ST    R14,8(R13)                                               00067000
         USING SAVEAREA,R13                                             00068000
** CHECK FOR APPROX PARAMETER, THIS SUPPRESSES THE READ TO GET THE      00068176
** NUMBER OF RECORDS IN THE LAST BLOCK.                                 00068275
         L     R1,0(R1)                 R1->PARMS                       00068377
         CLC   =C'APPROX',2(R1)         IF PARM = 'APPROX'              00068477
         JNE   NO_APPROX                THEN DO                         00068575
         OI    OPTIONS,APPROX            APPROX = TRUE                  00068675
NO_APPROX DS   0H                       END                             00068775
** INITIALISE BSAMGET WORK AREA FOR REQUEST ID IN                       00069061
         TM    OPTIONS,APPROX           IF NOT APPROX                   00069175
         JO    NO_OPEN                  THEN DO                         00069276
         BSAMGET INIT,IN                 INITIALISE INSTANCE            00070075
         OPEN  (IN_DCB)                  OPEN FILE                      00071070
NO_OPEN  DS    0H                       END                             00071175
**                                                                      00071275
NEXTVOL  DS    0H                       DO WHILE VOLS ¬= SPACES         00071323
** GET THE FIRST/NEXT VOLUME SERIAL NUMBER FOR DDNAME IN                00071425
         CALL  GETVOLS,(DSNAME,VOL),MF=(E,GETVOLS_PARMS)                00071519
         CLC   VOL,=CL6' '               IF VOL = SPACES                00071637
         JE    LEAVEVOL                  THEN LEAVE                     00071723
** CALL  GETDSCB  TO READ THE FORMAT-1 DSCB AND EXTRACT THE LAST        00071800
** USED TRACK ADDRESS (TTR).                                            00072000
         CALL  GETDSCB,(DSNAME,VOL,DSCB1),                             X00073020
               MF=(E,GETDSCB_PARMS)                                     00074000
         LTR   R15,R15                   IF R15 ¬= 0                    00075023
         JZ    GETDSCB_OK                THEN DO                        00076023
         TPUT  GETDSCB_ERR,L'GETDSCB_ERR  DISPLAY MESSAGE               00077023
         J     EXIT                       RETURN                        00078054
GETDSCB_OK DS  0H                        END                            00079023
** FORCE END OF VOLUME SO THAT AT THE END WE WILL BE POSITIONED ON      00079172
** THE LAST VOLUME. THE EODAD ROUTINE WILL BE INVOKED ON THE LAST       00079272
** VOLUME, BUT WE JUST CONTINUE AT THE NEXT SEQUENTIAL INSTRUCTION.     00079372
         FEOV  IN_DCB                    FORCE END OF VOLUME            00079472
EODAD    DS    0H                                                       00079572
         MVC   TTR_TTR,PD1LSTAR          GET LAST USED TTR              00079672
         LH    R0,PD1BLKL                GET BLKSIZE                    00079872
         STH   R0,DD                                                    00079972
         CVZ   R0,NUMPRECL                                              00080072
FIRST1   JNOP  NOT_FIRST                 IF FIRST TIME                  00080172
*                                        THEN DO                        00080272
         MVI   FIRST1+1,X'F4'             INDICATE NOT FIRST            00080372
*                                         FIND DEVICE TYPE FROM UCB     00080472
         LA    R5,UCBAREA                                               00080572
         USING UCB,R5                                                   00080672
         UCBSCAN COPY,WORKAREA=UCBWORK,UCBAREA=UCBOB,VOLSER=VOL         00080772
*                                         DISPLAY DEVICE TYPE MESSAGE   00080872
         XR    R3,R3                      CLEAR R3                      00081033
         IC    R3,UCBUNTYP                R3 = UCBUNTYP                 00082033
         SLL   R3,2                       MULTIPLY BY 4                 00083033
         LA    R3,UNIT_TYPES(R3)          R3-> UNIT_TYPES (UCBUNTYP)    00084033
         MVC   UNIT_DISP,0(R3)                                          00085033
*                                         CALCULATE TRACK CAPACITY      00090033
         CNOP  0,4                                                      00091059
STAR     EQU   *+4                                                      00100057
         TRKCALC FUNCTN=TRKCAP,TYPE=UCBUNTYP,RKDD=RKDD                  00450057
         DROP  R5                                                       00450136
         ST    R0,BLKS_PER_TRK                                          00451007
         LTR   R15,R15                    IF RC = ZERO                  00460033
         JNZ   NONEFIT                    THEN DO                       00470033
         CVZ   R0,NUMRECS                  PUT BLKS_PER_TRK IN MESSAGE  00490033
         MH    R0,DD                                                    00520000
         CVZ   R0,NUMBLKSZ                 PUT BLOCK SIZE IN MESSAGE    00530033
         LH    R0,PD1LRECL                 PUT LRECL IN MESSAGE         00540045
         CVZ   R0,NUMLRECL                                              00550045
         USING STARSECT,R5                                              00551056
         LA    R5,STAR                                                  00552056
         XR    R0,R0                                                    00552158
         ICM   R0,B'0011',STARBAL          PUT INITIAL BALANCE IN MSG   00553058
         CVZ   R0,INITBAL                                               00554056
         DROP  R5                                                       00555056
         TPUT  MSG1,L'MSG1                 DISPLAY MESSAGE              00560044
         J     TRKC_DONE                  END                           00570033
NONEFIT  DS    0H                         ELSE DO                       00580033
         TPUT  TOOBIG,L'TOOBIG             DISPLAY NONE FIT MESSAGE     00590033
TRKC_DONE DS   0H                         END                           00600033
         XR    R4,R4                                                    00600141
         LH    R5,PD1BLKL                                               00600241
         LH    R6,PD1LRECL                                              00600341
         DR    R4,R6                      R5 = BLOCKING FACTOR          00600441
         ST    R5,BLOCK_FACTOR                                          00600641
         CVZ   R5,MSG_FACTOR              PUT IN MESSAGE                00600741
*                                                                       00600841
         TPUT  MSG3,L'MSG3                DISPLAY MESSAGE               00600941
* GETMAIN A BUFFER                                                      00601061
         LH    R0,PD1BLKL                 SIZE TO GETMAIN               00601261
         GETMAIN RU,LV=(0),LOC=BELOW      GETMAIN A NEW BUFFER          00601461
         ST    R1,INBUFF                  SAVE ADDRESS                  00601561
NOT_FIRST DS   0H                        END                            00601633
         MVC   MSG_VOL,VOL               PUT VOLSER IN MESSAGE          00601740
         XR    R2,R2                     R3 = BLOCK COUNT               00601823
         L     R3,BLKS_PER_TRK                                          00601912
         XR    R4,R4                                                    00602030
         ICM   R4,B'0011',TTR_TT         R4 = LAST USED TTR (UNSIGNED)  00602130
         MR    R2,R4                                                    00602212
         XR    R4,R4                                                    00602312
         IC    R4,TTR_R                                                 00602412
         AR    R3,R4                                                    00602512
         CVZ   R3,BLOCK_COUNT                                           00602612
*                                                                       00602712
         L     R5,BLOCK_FACTOR                                          00602841
         MR    R2,R5                     R2 = NUM OF RECS               00602923
         CVD   R3,DWORD                                                 00603045
         MVC   NUM_OF_RECS,EDMASK                                       00603145
         ED    NUM_OF_RECS,DWORD+2                                      00603249
*                                                                       00603345
         XR    R5,R5                                                    00603453
         ICM   R5,B'0011',PD1TRBAL       R5 = TRACK BALANCE             00603553
         CVZ   R5,MSG_TRBAL              PUT IN MESSAGE                 00603650
*                                                                       00603750
         TPUT  MSG2,L'MSG2               DISPLAY MESSAGE                00603850
*                                                                       00603950
         A     R3,TOT_RECS               TOT_RECS = TOT_RECS + R3       00604050
         ST    R3,TOT_RECS               TOT_RECS = TOT_RECS + R3       00604150
         J     NEXTVOL                                                  00604250
LEAVEVOL DS    0H                       END                             00604350
*                                       GET SIZE OF LAST BLOCK          00604461
         LTR   R3,R3                    IF TOT_RECS > 0                 00604567
         JNP   NO_FIXUP                 THEN DO                         00604665
         TM    OPTIONS,APPROX            IF NOT APPROX                  00604775
         JO    NO_READ                   THEN DO                        00604876
         BSAMGET READ,IN,TTR=TTR_TTR      READ LAST BLOCK               00604975
         CLOSE IN_DCB                     CLOSE FILE                    00605075
         S     R3,BLOCK_FACTOR            REDUCE TOT_RECS BY ONE BLOCK  00605175
         XR    R4,R4                      R4 = ZERO                     00605275
         L     R5,INLBLK                  R5 = L(LAST BLOCK)            00605375
         LH    R6,PD1LRECL                R6 = LRECL                    00605475
         DR    R4,R6                      DIVIDE BLKLEN BY LRECL        00605575
         AR    R3,R5                      R3 = TOT_RECS + RECS IN LAST  00605675
         CVZ   R5,MSGBLK                  PUT IN MESSAGE                00605775
         TPUT  MSG5,L'MSG5                DISPLAY MESSAGE               00605875
NO_READ  DS    0H                        END                            00605975
NO_FIXUP DS    0H                       END                             00606075
*                                                                       00606175
         CVD   R3,DWORD                 DISPLAY TOT_RECS                00606275
         MVC   TOT_DISP,EDMASK                                          00606375
         ED    TOT_DISP,DWORD+2                                         00606475
*                                       CALCULATE SIZE IN BYTES         00606575
         LH    R6,PD1LRECL                                              00606675
         CVD   R6,LRECL_PACKED                                          00606775
         MP    DWORD,LRECL_PACKED+5(3)                                  00606875
         MVC   SIZE_DISP,EDMASK                                         00606975
         ED    SIZE_DISP,DWORD+2                                        00607075
*                                       SHOW AS MEGABYTES               00607175
         DP    DWORD,=PL4'1048576'                                      00607275
         UNPK  MEGS_DISP,DWORD(4)                                       00607375
         OI    MEGS_DISP+L'MEGS_DISP-1,X'F0'                            00607475
         TPUT  MSG4,L'MSG4                                              00607575
*                                                                       00607675
EXIT     DS    0H                                                       00607775
         L     R13,SAVEAREA+4                                           00608064
         RETURN (14,12),,RC=(15)                                        00610000
         DS    0D                                                       00620000
SAVEAREA DC    18F'0'                                                   00621001
DWORD    DC    PL8'0'                                                   00630000
LRECL_PACKED DC PL8'0'                                                  00630146
TOT_RECS DC    F'0'                                                     00631024
BLOCK_FACTOR DC F'0'                                                    00631142
OPTIONS  DC    X'00'                                                    00631275
APPROX   EQU   X'80'                                                    00631375
EDMASK   DC    X'4020206B2020206B2020206B202120'                        00632048
MSG1S    EQU   *                                                        00633043
         DC    C'LRECL='                                                00633145
NUMLRECL DC    ZL5'0'                                                   00633245
         DC    C' BLKSIZE='                                             00633345
NUMPRECL DC    ZL5'0'                                                   00633445
         DC    C' BLOCKS PER TRACK='                                    00634043
NUMRECS  DC    ZL5'0'                                                   00640043
MSG1E    EQU   *                                                        00671043
         ORG   MSG1S                                                    00680043
MSG1     DS    CL(MSG1E-MSG1S)                                          00690043
MSG2S    EQU   *                                                        00691007
MSG_VOL  DC    CL6' '                                                   00692040
         DC    C' BLOCKS USED='                                         00693074
BLOCK_COUNT DC ZL8'0'                                                   00693110
         DC    C' RECORD COUNT='                                        00693474
NUM_OF_RECS DC CL(L'EDMASK)' '                                          00693545
         DC    C' TRACK BALANCE='                                       00693674
MSG_TRBAL DC ZL8'0'                                                     00693752
MSG2E    EQU   *                                                        00694007
         ORG   MSG2S                                                    00695007
MSG2     DS    CL(MSG2E-MSG2S)                                          00696010
MSG3S    EQU   *                                                        00697017
         DC    C'DEVICE TYPE='                                          00698074
UNIT_DISP DC   CL4' '                                                   00699017
         DC    C' BLOCK FACTOR='                                        00699174
MSG_FACTOR DC ZL8'0'                                                    00699241
         DC    C' SPACE UTILISED='                                      00699374
NUMBLKSZ DC    ZL5'0'                                                   00699473
         DC    C' INIT BAL='                                            00699574
INITBAL  DC    ZL5'0'                                                   00699673
MSG3E    EQU   *                                                        00699717
         ORG   MSG3S                                                    00699817
MSG3     DS    CL(MSG3E-MSG3S)                                          00699917
MSG4S    EQU   *                                                        00700024
         DC    C'TOTAL RECORDS='                                        00700174
TOT_DISP DC    CL(L'EDMASK)' '                                          00700228
         DC    C' SIZE IN BYTES='                                       00700374
SIZE_DISP DC   CL(L'EDMASK)' '                                          00700446
         DC    C' '                                                     00700560
MEGS_DISP DC   ZL8'0'                                                   00700660
         DC    C' MEG'                                                  00700766
MSG4E    EQU   *                                                        00701024
         ORG   MSG4S                                                    00702024
MSG4     DS    CL(MSG4E-MSG4S)                                          00703065
MSG5S    EQU   *                                                        00704065
         DC    C'RECORDS IN LAST BLOCK='                                00709274
MSGBLK   DC    ZL5'0'                                                   00709365
MSG5E    EQU   *                                                        00709465
         ORG   MSG5S                                                    00709565
MSG5     DS    CL(MSG5E-MSG5S)                                          00709665
TOOBIG   DC    C'NO RECORDS OF THAT SIZE WILL FIT'                      00710024
GETDSCB_ERR  DC C'FAILURE READING FORMAT-1 DSCB'                        00731000
BLKS_PER_TRK DS F                                                       00732007
TTR      DS    0F                                                       00732107
TTR_TTR  DS    0XL3                                                     00733001
TTR_TT   DC    H'-1'                                                    00734007
TTR_R    DC    XL1'FF'                                                  00735001
         DC    XL1'00'                                                  00736001
RKDD     DS    0F                                                       00750000
R        DC    X'01'                                                    00760000
K        DC    X'00'                                                    00770000
DD       DC    H'00'                                                    00780000
UNIT_TYPES DS  16CL4                                                    00780117
         ORG   UNIT_TYPES                                               00780217
         DC    14CL4'????'             00 - 0D                          00780317
         DC    CL4'3380'               0E                               00780417
         DC    CL4'3390'               0F                               00780517
DSNAME   DC    CL44' '                                                  00780619
VOL      DC    CL6' '                                                   00780719
GETVOLS_PARMS DS 2F                    WKAREA FOR CALL TO GETVOLS       00781019
GETDSCB_PARMS DS 3F                    WKAREA FOR CALL TO GETDSCB       00782019
         PUSH  PRINT                                                    00790000
         PRINT NOGEN                                                    00800000
         BSAMGET DEFINE,IN,DCB=IN_DCB                                   00800161
IN_DCB   DCB   DDNAME=IN,MACRF=(RP),DSORG=PS,EODAD=EODAD                00800271
AREA     DS    0D                                                       00801029
         IEFJFCBN LIST=YES                                              00802029
** N.B. IECPDSCB OVERLAYS IEFJFCBN SO ENSURE LENGTHS ARE OK             00810029
**      WHEN THE DSCB IS RETURNED THE DSN IS OMITTED, SO THE            00820029
**      DATA BEGINS WITH PD1FMTID.                                      00830029
DSCB1    EQU   PD1FMTID                                                 00840029
         IECPDSCB                        DSCB FORMAT1                   00850029
L#DSCB   EQU   *-DSCB1                                                  00860029
         DS    CL(140-L#DSCB)            ENSURE AT LEAST 140 BYTES      00870029
UCBWORK  DS    CL100                     WORK AREA FOR UCBSCAN          00870134
UCBAREA  DS    CL48                      AREA MAPPED BY UCB             00870239
UCB      DSECT ,                                                        00870336
         IEFUCBOB                        UNIT CONTROL BLOCK             00871033
L#UCB    EQU   *-UCBOB                                                  00872036
         PRINT GEN                                                      00873056
STARSECT DSECT ,                         TRKCALC PARM OVERLAY           00874056
         TRKCALC MF=D                                                   00875056
         END   RECCALC                                                  00880000