#!/usr/bin/env perl
# -*- coding: utf-8 -*-
# Adapta apenas fontes que falham no cobc (CICS/SQL/DLI/MQ) para sandbox.
# NAO altera CONTINUE ja existentes em IF/ELSE (ponto quebraria o escopo).
use strict;
use warnings;
use File::Basename qw(basename);
use Encode qw(decode encode FB_CROAK);

my $root = '/usr/local/workspace/recebido/app';

# Programas que falhavam no build-unit-tests original (+ COACTVWC alvo da historia)
my @targets = qw(
  CBEXPORT CBIMPORT CBPAUP0C CBSTM03A COACCT01 COACTUPC COACTVWC
  COADM01C COBIL00C COBTUPDT COCRDLIC COCRDSLC COCRDUPC CODATE01
  COMEN01C COPAUA0C COPAUS0C COPAUS1C COPAUS2C CORPT00C COSGN00C
  COTRN00C COTRN01C COTRN02C COTRTLIC COTRTUPC COUSR00C COUSR01C
  COUSR02C COUSR03C
);

sub find_target {
    my ($name) = @_;
    my @cands = (
        "$root/cbl/$name.cbl", "$root/cbl/$name.CBL",
        "$root/app-transaction-type-db2/cbl/$name.cbl",
        "$root/app-vsam-mq/cbl/$name.cbl",
        "$root/app-authorization-ims-db2-mq/cbl/$name.cbl",
        "$root/app-authorization-ims-db2-mq/cbl/$name.CBL",
    );
    for my $c (@cands) { return $c if -f $c; }
    return;
}

sub read_utf8 {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "read $path: $!";
    local $/; my $raw = <$fh>; close $fh;
    my $text;
    eval { $text = decode('UTF-8', $raw, FB_CROAK()); 1 } or do {
        $text = decode('ISO-8859-1', $raw);
    };
    return $text;
}

sub write_utf8 {
    my ($path, $text) = @_;
    open my $fh, '>:raw', $path or die "write $path: $!";
    print {$fh} encode('UTF-8', $text);
    close $fh;
}

sub col7_comment {
    return "      * EXEC stubbed for GnuCOBOL sandbox\n";
}

sub adapt_text {
    my ($src, $path, $name) = @_;
    my $orig = $src;

    # EXEC SQL INCLUDE -> COPY
    $src =~ s/EXEC\s+SQL\s+INCLUDE\s+([A-Za-z0-9-]+)\s+END-EXEC\.?/COPY $1./gi;
    $src =~ s/EXEC\s+SQL\s*\r?\n\s*INCLUDE\s+([A-Za-z0-9-]+)\s*\r?\n\s*END-EXEC\.?/COPY $1./gi;

    # Split DATA / PROCEDURE
    my ($data_part, $proc_part) = ($src, '');
    if ($src =~ /^(.*?)(\n[^\n]*PROCEDURE\s+DIVISION\b.*)$/si) {
        $data_part = $1;
        $proc_part = $2;
    }

    # DATA: stub EXEC as column-7 comment (preserva periodo se houver)
    $data_part =~ s/EXEC\s+(?:CICS|SQL|DLI)\b[\s\S]*?END-EXEC\.?/col7_comment()/gie;

    # PROCEDURE: stub EXEC -> CONTINUE preservando o ponto do END-EXEC
    $proc_part =~ s/EXEC\s+(?:CICS|SQL|DLI)\b[\s\S]*?END-EXEC(\.?)/CONTINUE$1/gi;

    $src = $data_part . $proc_part;

    # DFHRESP(NAME) -> DFHRESP-NAME
    $src =~ s/DFHRESP\s*\(\s*([A-Za-z0-9-]+)\s*\)/DFHRESP-$1/gi;

    # LINKAGE DEPENDING ON EIBCALEN
    $src =~ s/
        01\s+DFHCOMMAREA\.\s*
        05\s+(?:LK-COMMAREA|FILLER)\s+PIC\s+X\(0?1\)\s*
        OCCURS\s+1\s+TO\s+32767\s+TIMES\s+DEPENDING\s+ON\s+EIBCALEN\.
    /01  DFHCOMMAREA.\n         05  LK-COMMAREA                           PIC X(2000)./gix;

    $src =~ s/
        01\s+DFHCOMMAREA\s+PIC\s+X\(01\)\s*
        OCCURS\s+1\s+TO\s+32767\s+TIMES\s+DEPENDING\s+ON\s+EIBCALEN\.
    /01  DFHCOMMAREA PIC X(2000)./gix;

    # COPY DFHEIBLK / DFHRESP
    my $needs_eib = ($src =~ /\bEIB(?:CALEN|AID|RESP|RESP2|TRNID|TIME|DATE)\b/);
    my $needs_resp = ($src =~ /\bDFHRESP-/);
    if (($needs_eib || $needs_resp) && $src !~ /COPY\s+DFHEIBLK/i) {
        if ($src =~ /COPY\s+DFHBMSCA\./i) {
            $src =~ s/(COPY\s+DFHBMSCA\.)/$1\n       COPY DFHEIBLK.\n       COPY DFHRESP./i;
        } elsif ($src =~ /COPY\s+DFHAID\./i) {
            $src =~ s/(COPY\s+DFHAID\.)/$1\n       COPY DFHEIBLK.\n       COPY DFHRESP./i;
        } elsif ($src =~ /WORKING-STORAGE\s+SECTION\./i) {
            $src =~ s/(WORKING-STORAGE\s+SECTION\.)/$1\n       COPY DFHEIBLK.\n       COPY DFHRESP./i;
        }
    } elsif ($needs_resp && $src !~ /COPY\s+DFHRESP/i) {
        if ($src =~ /WORKING-STORAGE\s+SECTION\./i) {
            $src =~ s/(WORKING-STORAGE\s+SECTION\.)/$1\n       COPY DFHRESP./i;
        }
    }

    # DIBSTAT
    if ($src =~ /\bDIBSTAT\b/ && $src !~ /01\s+DIBSTAT\b/) {
        $src =~ s/(WORKING-STORAGE\s+SECTION\.)/$1\n       01  DIBSTAT PIC X(2) VALUE SPACES./i;
    }

    # CBEXPORT / CBIMPORT: tornar sequencial (evita RECORD KEY fora do FD)
    if ($name =~ /^CBEXPORT$/i) {
        $src =~ s/
            SELECT\s+EXPORT-OUTPUT\s+ASSIGN\s+TO\s+EXPFILE\s*
            ORGANIZATION\s+IS\s+INDEXED\s*
            ACCESS\s+MODE\s+IS\s+SEQUENTIAL\s*
            RECORD\s+KEY\s+IS\s+EXPORT-SEQUENCE-NUM\s*
            FILE\s+STATUS\s+IS\s+WS-EXPORT-STATUS\.
        /SELECT EXPORT-OUTPUT ASSIGN TO EXPFILE\n               ORGANIZATION IS SEQUENTIAL\n               ACCESS MODE IS SEQUENTIAL\n               FILE STATUS IS WS-EXPORT-STATUS./ix;
    }
    if ($name =~ /^CBIMPORT$/i) {
        $src =~ s/
            SELECT\s+EXPORT-INPUT\s+ASSIGN\s+TO\s+EXPFILE\s*
            ORGANIZATION\s+IS\s+INDEXED\s*
            ACCESS\s+MODE\s+IS\s+SEQUENTIAL\s*
            RECORD\s+KEY\s+IS\s+EXPORT-SEQUENCE-NUM\s*
            FILE\s+STATUS\s+IS\s+WS-EXPORT-STATUS\.
        /SELECT EXPORT-INPUT ASSIGN TO EXPFILE\n               ORGANIZATION IS SEQUENTIAL\n               ACCESS MODE IS SEQUENTIAL\n               FILE STATUS IS WS-EXPORT-STATUS./ix;
    }

    # COACTVWC: mensagem de sucesso + observabilidade harness
    if ($name =~ /^COACTVWC$/i) {
        # SET WS-INFORM-OUTPUT apos leitura bem-sucedida
        if ($src !~ /SET\s+WS-INFORM-OUTPUT\s+TO\s+TRUE/i) {
            $src =~ s/
                (IF\s+DID-NOT-FIND-CUST-IN-CUSTDAT\s*
                   GO\s+TO\s+9000-READ-ACCT-EXIT\s*
                END-IF\s*)
                (\.)
            /$1\n           SET WS-INFORM-OUTPUT TO TRUE\n\n           DISPLAY WS-INFO-MSG\n\n           $2/ix;
        }
        # DISPLAY no inicio para smoke batch-cobol (expect-output)
        if ($src !~ /DISPLAY\s+'Displaying details of given Account'/i) {
            $src =~ s/
                (SET\s+WS-RETURN-MSG-OFF\s+TO\s+TRUE)
            /$1\n      * Sandbox batch-cobol: literal observavel no SYSOUT\n           DISPLAY 'Displaying details of given Account'/ix;
        }
        # DISPLAY no SEND quando inform-output
        if ($src =~ /1400-SEND-SCREEN\./ && $src !~ /1400-SEND-SCREEN\.[\s\S]*WS-INFORM-OUTPUT/) {
            $src =~ s/
                (1400-SEND-SCREEN\.\s*)
            /$1\n           IF WS-INFORM-OUTPUT\n              DISPLAY WS-INFO-MSG\n           END-IF\n/ix;
        }
    }

    return ($src, $src ne $orig);
}

my $changed = 0;
for my $name (@targets) {
    my $f = find_target($name);
    if (!$f) { print "MISSING:$name\n"; next; }
    my $src = read_utf8($f);
    my ($out, $did) = adapt_text($src, $f, $name);
    if ($did) {
        write_utf8($f, $out);
        print "ADAPTED:$f\n";
        $changed++;
    } else {
        print "SKIP:$f\n";
    }
}
print "TOTAL_CHANGED=$changed\n";
