# CardDemo — aplicação COBOL/CICS/VSAM/JCL (mainframe)
# Emulador: Hercules via imagem da família adesutherland/vm-370
# (publicada no Docker Hub como adriansutherland/vm370).
#
# Contexto de build: raiz de recebido/
# Porta principal: 3270 (terminal tn3270)
# TIPO_APLICACAO: COBOL

FROM adriansutherland/vm370:latest

LABEL org.opencontainers.image.title="CardDemo" \
      org.opencontainers.image.description="CardDemo COBOL/CICS com emulador Hercules (VM/370)" \
      org.opencontainers.image.source="recebido/" \
      org.opencontainers.image.vendor="CardDemo"

# A imagem base VM/370 opera com o usuário do entrypoint original (tipicamente root
# para IPL do Hercules). Mantemos esse modelo para não quebrar o start_vm370.sh.

# Fontes, dados de amostra, JCL, BMS, CSD e scripts do CardDemo
COPY app/ /opt/carddemo/app/
COPY samples/ /opt/carddemo/samples/
COPY scripts/ /opt/carddemo/scripts/
COPY diagrams/ /opt/carddemo/diagrams/
COPY README.md LICENSE NOTICE CODE_OF_CONDUCT.md CONTRIBUTING.md /opt/carddemo/

COPY docker/entrypoint.sh /usr/local/bin/carddemo-entrypoint.sh

RUN chmod +x /usr/local/bin/carddemo-entrypoint.sh \
    && mkdir -p /opt/carddemo

ENV CARDDEMO_ROOT=/opt/carddemo \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Terminal 3270 (tn3270). A imagem base também pode expor 8038 (console HTTP) e 3505.
EXPOSE 3270

WORKDIR /opt/hercules/vm370

ENTRYPOINT ["/usr/local/bin/carddemo-entrypoint.sh"]
