      ******************************************************************
      * CMQMDV - Message Descriptor MQ stub (05-level)
      ******************************************************************
           05  MQMD-MSGTYPE               PIC S9(9) BINARY VALUE 0.
           05  MQMD-EXPIRY                PIC S9(9) BINARY VALUE -1.
           05  MQMD-PERSISTENCE           PIC S9(9) BINARY VALUE 0.
           05  MQMD-MSGID                 PIC X(24) VALUE LOW-VALUES.
           05  MQMD-CORRELID              PIC X(24) VALUE LOW-VALUES.
           05  MQMD-FORMAT                PIC X(8) VALUE SPACES.
           05  MQMD-CODEDCHARSETID        PIC S9(9) BINARY VALUE 0.
           05  MQMD-REPLYTOQ              PIC X(48) VALUE SPACES.
           05  MQMD-REPLYTOQMGR           PIC X(48) VALUE SPACES.
      *
