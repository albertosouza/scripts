#!/bin/bash

# Script: cursor-install.sh
# Descrição: Este script automatiza a instalação do editor Cursor no Linux.
# O script baixa a versão mais recente do Cursor, instala como AppImage em /opt
# e cria um atalho no menu de aplicativos do sistema.
#
# Funcionalidades:
# - Verifica e solicita privilégios sudo
# - Baixa a última versão do Cursor
# - Instala o AppImage em /opt
# - Cria atalho no menu de aplicativos
# - Gerencia erros de download e instalação

if [ "$EUID" -ne 0 ]; then
    echo "Solicitando acesso sudo para instalar o Cursor..."
    exec sudo "$0" "$@"
    exit $?
fi

if [ -f "/opt/cursor.appimage" ]; then
    echo "Cursor já está instalado em /opt/cursor.appimage"
    echo "Para atualizar, use o script cursor-update.sh"
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

echo "Instalando Cursor..."
mv cursor.AppImage /opt/cursor.appimage

# Criar atalho no desktop
cat > /usr/share/applications/cursor.desktop << EOL
[Desktop Entry]
Name=Cursor
Exec=/opt/cursor.appimage
Icon=cursor
Type=Application
Categories=Development;IDE;
Comment=AI-first code editor
EOL

echo "Instalação concluída! Cursor ${VERSION} foi instalado em /opt/cursor.appimage"
echo "Um atalho foi criado no menu de aplicativos"
echo "Você pode executar o Cursor através do menu de aplicativos ou executando: /opt/cursor.appimage"

# Limpeza
cd /
rm -rf "$TEMP_DIR"