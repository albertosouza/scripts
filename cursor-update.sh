#!/bin/bash

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
if ! DOWNLOAD_INFO=$(curl -s -H "sec-ch-ua: \"Google Chrome\";v=\"135\", \"Not-A.Brand\";v=\"8\", \"Chromium\";v=\"135\"" \
    -H "sec-ch-ua-mobile: ?0" \
    -H "sec-ch-ua-platform: \"Linux\"" \
    "https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=stable"); then
    echo "Erro: Falha ao obter informações de download"
    exit 1
fi

DOWNLOAD_URL=$(echo "$DOWNLOAD_INFO" | grep -o '"downloadUrl":"[^"]*"' | cut -d'"' -f4)
VERSION=$(echo "$DOWNLOAD_INFO" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)

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