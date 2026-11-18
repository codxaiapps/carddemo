      ******************************************************************
      * DCLTRCAT - declaracao COBOL (sem EXEC SQL) para sandbox cobc
      ******************************************************************
       01  DCLTRANSACTION-TYPE-CATEGORY.
           10 DCL-TRC-TYPE-CODE    PIC X(2).
           10 DCL-TRC-TYPE-CATEGORY
              PIC X(4).
           10 DCL-TRC-CAT-DATA.
              49 DCL-TRC-CAT-DATA-LEN
                 PIC S9(4) USAGE COMP.
              49 DCL-TRC-CAT-DATA-TEXT
                 PIC X(50).
      *
