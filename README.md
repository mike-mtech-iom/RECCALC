#RECCALC

zOS  Record count calculator


This code calculates the number of records in a zOS dataset. It works best with RECFM=FB, for VB it will only give an approximation. 

It can give improper results if the dataset is compressed or has been written to with DISP=MOD.

It displays the number of records on each volume occupied by the dataset plus the total.

RECCALC.BAL - the main routine
GETVOLS.BAL - called to get each of the volume serials in order
GETDSCB.BAL - called to get the format 1 DSCB for the current volume
BSAMGET.BAL- an interface to BSAM which returns individual records rather than blocks
BSAMGET.MAC - a macro to call the above in an object oriented way
EQUATES.CPY - a copybook used in all my code to equate the register numbers to symbols
