BSAMGET  START 0
         COPY  EQUATES
         SAVE  (14,12),,'BSAMGET &SYSDATE &SYSTIME'
         USING BSAMGET,R12
         LR    R12,R15
         ST    R13,SAVEAREA+4
         LR    R14,R13
         LA    R13,SAVEAREA
         ST    R14,8(R13)
         USING SAVEAREA,R13
         SPACE 1
** ADDRESS THE PARM LIST
         L     R5,0(R1)                  R5 -> PARM LIST
         USING PARMS,R5
** ADDRESS THE DCB
         USING IHADCB,R2
         L     R2,A#DCB                  R2 -> DCB
** IF THIS IS A DIRECT READ, THEN GET THE BLOCK
         OC    A#TTR,A#TTR              IF A#TTR ¬= ZERO
         BZ    SEQL                     THEN DO
         L     R3,A#TTR                  R3 -> TTR
         POINT (R2),(R3),TYPE=REL         LOCATE BLOCK
         LTR   R15,R15                   IF RC ¬= ZERO
         BZ    PT_OK                     THEN DO
         XC    A#RECORD,A#RECORD          INDICATE NO RECORD
         XC    L#BLK,L#BLK                RETURNED BLKSIZE = ZERO
         B     EXIT                       RETURN
PT_OK    DS    0H                        END
         BAL   R14,READ                  READ BLOCK
         CLI   FOUNDIT,0                 IF RC ¬= ZERO
         BE    READ_OK                   THEN DO
         XC    A#RECORD,A#RECORD          INDICATE NO RECORD
         XC    L#BLK,L#BLK                RETURNED BLKSIZE = ZERO
         B     EXIT                       RETURN
READ_OK  DS    0H                        END
         L     R9,DECB1+16               R9 -> IOB
         LH    R10,DCBBLKSI              R10 = L(BLOCK)
         SH    R10,14(R9)                SUBTRACT UNUSED SPACE IN BLK
         ST    R10,L#BLK                 PUBLISH IN RESPONSE
         ST    R2,A#RECORD               PASS BACK ADDRESS OF BLOCK
         B     EXIT                      RETURN
SEQL     DS    0H                       END
** READ THE BLOCK
         ICM   R3,B'1111',A#CURRENT      IF CURRENT POS = ZERO
         BZ    READ                      OR
         C     R3,A#EOBUFF               CURRENT POS >= END OF BUFFER
         BL    NO_READ                   THEN DO
         BAL   R14,READ                   CALL READ
         SPACE 1
         CLI   FOUNDIT,0                  IF RC ¬= ZERO
         BE    FOUND                      THEN DO
         XC    A#RECORD,A#RECORD           INDICATE NO RECORD
         B     EXIT                        RETURN
FOUND    DS    0H                         END
         SPACE 1
         TM    DCBRECFM,DCBRECF           IF FIXED LENGTH
         BZ    REC_V_1                    THEN DO
         LH    R7,DCBBLKSI                 R7 = L(BLOCK)
         B     SET_EOB                    END
REC_V_1  DS    0H                         ELSE DO .. VARIABLE LENGTH ..
         LH    R7,0(R3)                    R7 = L(BLOCK)
         SH    R7,=H'4'                    REDUCE BY LENGTH OF BDW
         LA    R3,4(R3)                    R3 -> BEYOND BDW
SET_EOB  DS    0H                         END
         A     R7,A#BUFF                  R7 -> END OF BLOCK
         ST    R7,A#EOBUFF                RESET A#EOBUFF
         ST    R3,A#CURRENT               RESET A#CURRENT
NO_READ  DS    0H                        END
**
         ST    R3,A#RECORD
         TM    DCBRECFM,DCBRECF          IF FIXED LENGTH
         BZ    REC_V_2                   THEN DO
         LH    R9,DCBLRECL                R9 = LRECL FROM DCB
         B     REC_GOT                   END
REC_V_2  DS    0H                        ELSE DO .. VARIABLE LENGTH ..
         LH    R9,0(R3)                   R9 = LRECL FROM RDW
REC_GOT  DS    0H                        END
         LA    R15,0(R9,R3)              R15 -> NEXT RECORD
         ST    R15,A#CURRENT             RESET CURRENT POSITION
*
         ST    R9,L#RECORD
EXIT     DS    0H
         L     R13,SAVEAREA+4
         RETURN (14,12)
         EJECT
SYNAD_AND_EOF_RTN DS 0H
         MVI   FOUNDIT,4               INDICATE SYNAD OCCURRED
         BR    R14                     RETURN TO CHECK MACRO
READ     DS    0H
         ST    R14,READRETN               SAVE RETURN ADDRESS
         MVI   FOUNDIT,0                  PRIME FOUND FLAG
         LA    R14,SYNAD_AND_EOF_RTN      SET ADDRESS OF SYNAD AND EOF
         STCM R14,B'0111',DCBSYNAD+1
         STCM R14,B'0111',DCBEODAD+1
         L     R3,A#BUFF                  R3 -> INPUT BUFFER
         READ  DECB1,SF,(R2),(R3),'S'     READ NEXT BLOCK
         CHECK DECB1                      CHECK I/O COMPLETION
         L     R14,READRETN               LOAD RETURN ADDRESS
         BR    R14                        RETURN
         EJECT
SAVEAREA DC    18F'0'
*
READRETN DS    A                       RETURN ADDRESS FOR READ SUBRTN
FOUNDIT  DC    XL1'0'
PARMS    DSECT
A#DCB    DS    A                       A(DCB)
A#BUFF   DS    A                       A(INPUT BUFFER)
A#CURRENT DS   A                       A(CURRENT BUFFER POSITION)
A#EOBUFF DS    A                       A(END OF BUFFER)
A#RECORD DS    A                       A(RECORD READ)
L#RECORD DS    F                       L(RECORD READ)
L#BLK    DS    F                       L(BLOCK READ)
A#TTR    DS    A                       A(TTR TO READ)
         EJECT
         PRINT NOGEN
         DCBD  DSORG=PS                DCB DSECT
         END