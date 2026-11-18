      ******************************************************************
      * AUTHFRDS - declaracao COBOL (sem EXEC SQL) para sandbox cobc
      ******************************************************************
       01  DCLAUTHFRDS.
           10 CARD-NUM             PIC X(16).
           10 AUTH-TS              PIC X(26).
           10 AUTH-TYPE            PIC X(4).
           10 CARD-EXPIRY-DATE     PIC X(4).
           10 MESSAGE-TYPE         PIC X(6).
           10 MESSAGE-SOURCE       PIC X(6).
           10 AUTH-ID-CODE         PIC X(6).
           10 AUTH-RESP-CODE       PIC X(2).
           10 AUTH-RESP-REASON     PIC X(4).
           10 PROCESSING-CODE      PIC X(6).
           10 TRANSACTION-AMT      PIC S9(10)V9(2) USAGE COMP-3.
           10 APPROVED-AMT         PIC S9(10)V9(2) USAGE COMP-3.
           10 MERCHANT-CATAGORY-CODE
              PIC X(4).
           10 ACQR-COUNTRY-CODE    PIC X(3).
           10 POS-ENTRY-MODE       PIC S9(4) USAGE COMP.
           10 MERCHANT-ID          PIC X(15).
           10 MERCHANT-NAME.
              49 MERCHANT-NAME-LEN
                 PIC S9(4) USAGE COMP.
              49 MERCHANT-NAME-TEXT
                 PIC X(22).
           10 MERCHANT-CITY        PIC X(13).
           10 MERCHANT-STATE       PIC X(2).
           10 MERCHANT-ZIP         PIC X(9).
           10 TRANSACTION-ID       PIC X(15).
           10 MATCH-STATUS         PIC X(1).
           10 AUTH-FRAUD           PIC X(1).
           10 FRAUD-RPT-DATE       PIC X(10).
           10 ACCT-ID              PIC S9(11)V USAGE COMP-3.
           10 CUST-ID              PIC S9(9)V USAGE COMP-3.
      *
