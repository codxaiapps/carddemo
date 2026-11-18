#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# Validacao local US-20261118-001: COACTVWC no sandbox GnuCOBOL
# - compilacao cobc -std=ibm
# - presença de SET WS-INFORM-OUTPUT no sucesso de 9000-READ-ACCT
# - SYSOUT contem "Displaying details of given Account"
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CBL="$ROOT/app/cbl/COACTVWC.cbl"
CPY="$ROOT/app/cpy"
CPYBMS="$ROOT/app/cpy-bms"
OUTDIR="${TMPDIR:-/tmp}/coactvwc-sandbox-test"
MSG='Displaying details of given Account'

mkdir -p "$OUTDIR"

echo "== Fonte contem SET WS-INFORM-OUTPUT =="
grep -n "SET WS-INFORM-OUTPUT TO TRUE" "$CBL"

echo "== Compilacao cobc =="
cobc -std=ibm -I "$CPY" -I "$CPYBMS" -m -o "$OUTDIR/COACTVWC.so" "$CBL"

echo "== Execucao cobcrun =="
export COB_LIBRARY_PATH="$OUTDIR"
OUT="$(cobcrun COACTVWC 2>&1 || true)"
printf '%s\n' "$OUT"

echo "== Assercao expect-output =="
printf '%s\n' "$OUT" | grep -F "$MSG" >/dev/null
echo "OK: saida contem literal esperado"
echo "PASSED"
