      ******************************************************************
      * DCLTRTYP - declaracao COBOL (sem EXEC SQL) para sandbox cobc
      * Origem: app-transaction-type-db2/dcl/DCLTRTYP.dcl
      ******************************************************************
       01  DCLTRANSACTION-TYPE.
           10 DCL-TR-TYPE          PIC X(2).
           10 DCL-TR-DESCRIPTION.
              49 DCL-TR-DESCRIPTION-LEN
                 PIC S9(4) USAGE COMP.
              49 DCL-TR-DESCRIPTION-TEXT
                 PIC X(50).
      *
