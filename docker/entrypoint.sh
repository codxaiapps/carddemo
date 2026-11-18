#!/bin/sh
# -*- coding: utf-8 -*-
# Ponto de entrada do container CardDemo + Hercules (VM/370).
# Mantém o entrypoint original da imagem base quando disponível.

set -eu

CARDDEMO_ROOT="${CARDDEMO_ROOT:-/opt/carddemo}"

echo "============================================================"
echo " CardDemo — emulador Hercules (VM/370) + fontes COBOL/CICS"
echo "============================================================"
echo " Fontes montados em: ${CARDDEMO_ROOT}"
echo " Terminal 3270 (tn3270): porta 3270 deste container"
echo " Transação de signon (quando CICS estiver disponível): CC00"
echo " Programa de signon: COSGN00C (mapa BMS COSGN00)"
echo "============================================================"

# Preferir o script de start da imagem adesutherland/vm-370 / adriansutherland/vm370
if [ -x /opt/hercules/vm370/start_vm370.sh ]; then
  exec /opt/hercules/vm370/start_vm370.sh "$@"
fi

# Fallbacks comuns em imagens Hercules / VM/370
if [ -f /opt/hercules/vm370/hercules.conf ]; then
  cd /opt/hercules/vm370
  exec hercules -f hercules.conf "$@"
fi

if [ -f /home/hercules/sixpack.conf ]; then
  cd /home/hercules
  exec hercules -f sixpack.conf "$@"
fi

if [ -f /opt/system/hercules.cnf ]; then
  cd /opt/system
  exec hercules -f hercules.cnf "$@"
fi

echo "ERRO: não foi encontrado script/configuração Hercules na imagem base." >&2
echo "Verifique a imagem (adriansutherland/vm370 / adesutherland/vm-370)." >&2
exit 1
