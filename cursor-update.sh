#!/bin/bash

# Script: cursor-update.sh
# Descrição: Este script atualiza uma instalação existente do editor Cursor no Linux.
# O script baixa a versão mais recente do Cursor, faz backup da versão anterior
# e atualiza a instalação em /opt.
#
# Funcionalidades:
# - Verifica e solicita privilégios sudo
# - Verifica se o Cursor está instalado
# - Baixa a última versão do Cursor
# - Faz backup da versão anterior
# - Atualiza a instalação mantendo o mesmo local

# Check if jq is installed
if ! command -v jq &> /dev/null
then
    echo "jq could not be found. Please install it (e.g., sudo apt install jq)."
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo "Solicitando acesso sudo para atualizar o Cursor..."
    exec sudo "$0" "$@"
    exit $?
fi

if [ ! -f "/opt/cursor.appimage" ]; then
    echo "Erro: Cursor não está instalado em /opt/cursor.appimage"
    echo "Por favor, use o script de instalação primeiro"
    exit 1
fi

TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo "Verificando a versão mais recente do Cursor..."
if ! DOWNLOAD_INFO=$(curl -s \
    -H "Accept: */*" \
    -H "Accept-Language: pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7" \
    -H "Priority: u=1, i" \
    -H "Sec-Ch-Ua: \"Not)A;Brand\";v=\"8\", \"Chromium\";v=\"138\", \"Google Chrome\";v=\"138\"" \
    -H "Sec-Ch-Ua-Arch: \"x86\"" \
    -H "Sec-Ch-Ua-Bitness: \"64\"" \
    -H "Sec-Ch-Ua-Mobile: ?0" \
    -H "Sec-Ch-Ua-Platform: \"Linux\"" \
    -H "Sec-Ch-Ua-Platform-Version: \"6.14.0\"" \
    -H "Sec-Fetch-Dest: empty" \
    -H "Sec-Fetch-Mode: cors" \
    -H "Sec-Fetch-Site: same-origin" \
    -H "Referer: https://cursor.com/downloads" \
    -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
    "https://cursor.com/api/download?platform=linux-x64&releaseTrack=stable"); then
    echo "Erro: Falha ao obter informações de download"
    exit 1
fi

echo "Download Info: $DOWNLOAD_INFO"
DOWNLOAD_URL=$(echo "$DOWNLOAD_INFO" | jq -r '.downloadUrl')
VERSION=$(echo "$DOWNLOAD_INFO" | jq -r '.version')

if [ -z "$DOWNLOAD_URL" ] || [ -z "$VERSION" ]; then
    echo "Erro: Falha ao analisar informações de download"
    exit 1
fi

echo "Baixando Cursor versão ${VERSION}..."
if ! curl -L -o cursor.AppImage "$DOWNLOAD_URL"; then
    echo "Erro: Falha ao baixar o Cursor AppImage"
    exit 1
fi

chmod +x cursor.AppImage

echo "Atualizando Cursor..."
mv /opt/cursor.appimage /opt/cursor.appimage.bak

mv cursor.AppImage /opt/cursor.appimage

echo "Atualização concluída! A versão anterior foi copiada para /opt/cursor.appimage.bak"
echo "Você já pode executar a versão atualizada do Cursor (versão ${VERSION})"

# Limpeza
cd /
rm -rf "$TEMP_DIR"