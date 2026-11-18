      ******************************************************************
      * DFHEIBLK - Campos EIB minimos para sandbox GnuCOBOL (sem CICS)
      * EIBCALEN/EIBAID referenciados por COACTVWC e CSSTRPFY
      ******************************************************************
       01  DFHEIBLK-AREA.
           05  EIBTIME                   PIC S9(7) COMP-3 VALUE ZERO.
           05  EIBDATE                   PIC S9(7) COMP-3 VALUE ZERO.
           05  EIBTRNID                  PIC X(4)  VALUE SPACES.
           05  EIBTASKN                  PIC S9(7) COMP-3 VALUE ZERO.
           05  EIBTRMID                  PIC X(4)  VALUE SPACES.
           05  EIBCALEN                  PIC S9(4) COMP VALUE ZERO.
           05  EIBAID                    PIC X VALUE SPACES.
           05  EIBFN                     PIC X(2) VALUE SPACES.
           05  EIBRCODE                  PIC X(6) VALUE SPACES.
           05  EIBRESP                   PIC S9(8) COMP VALUE ZERO.
           05  EIBRESP2                  PIC S9(8) COMP VALUE ZERO.
      *
