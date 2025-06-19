#!/bin/bash

# Script: lm-studio-update.sh
# Descrição: Este script atualiza uma instalação existente do LM Studio no Linux.
# O script baixa a versão mais recente do LM Studio, faz backup da versão anterior
# e atualiza a instalação em /opt.
#
# Funcionalidades:
# - Verifica e solicita privilégios sudo
# - Verifica se o LM Studio está instalado
# - Baixa a última versão do LM Studio
# - Faz backup da versão anterior
# - Atualiza a instalação mantendo o mesmo local

if [ "$EUID" -ne 0 ]; then
    echo "Solicitando acesso sudo para atualizar o LM Studio..."
    exec sudo "$0" "$@"
    exit $?
fi

if [ ! -f "/opt/lm-studio.appimage" ]; then
    echo "Erro: LM Studio não está instalado em /opt/lm-studio.appimage"
    echo "Por favor, use o script de instalação primeiro"
    exit 1
fi

TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo "Verificando a versão mais recente do LM Studio..."

# Tentar obter a versão mais recente da API ou usar uma versão conhecida
# Como LM Studio não tem uma API pública como o Cursor, vamos usar a versão estável mais recente
VERSION="0.3.16-8"
DOWNLOAD_URL="https://installers.lmstudio.ai/linux/x64/${VERSION}/LM-Studio-${VERSION}-x64.AppImage"

# Verificar se há uma versão mais nova disponível (opcional)
echo "Tentando verificar versões mais recentes..."
if LATEST_VERSION=$(curl -s "https://lmstudio.ai/beta-releases" | grep -o "0\.[0-9]\+\.[0-9]\+-[0-9]\+" | head -1); then
    if [ ! -z "$LATEST_VERSION" ] && [ "$LATEST_VERSION" != "$VERSION" ]; then
        echo "Versão beta disponível: $LATEST_VERSION"
        echo "Deseja atualizar para a versão beta? (y/N)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            VERSION="$LATEST_VERSION"
            DOWNLOAD_URL="https://installers.lmstudio.ai/linux/x64/${VERSION}/LM-Studio-${VERSION}-x64.AppImage"
        fi
    fi
fi

echo "Baixando LM Studio versão ${VERSION}..."
if ! curl -L -o lm-studio.AppImage "$DOWNLOAD_URL"; then
    echo "Erro: Falha ao baixar o LM Studio AppImage"
    echo "URL tentada: $DOWNLOAD_URL"
    exit 1
fi

# Verificar se o arquivo foi baixado corretamente
if [ ! -f "lm-studio.AppImage" ] || [ ! -s "lm-studio.AppImage" ]; then
    echo "Erro: Arquivo AppImage não foi baixado corretamente"
    exit 1
fi

chmod +x lm-studio.AppImage

echo "Atualizando LM Studio..."
# Fazer backup da versão anterior
mv /opt/lm-studio.appimage /opt/lm-studio.appimage.bak

# Instalar a nova versão
mv lm-studio.AppImage /opt/lm-studio.appimage

# Remover extração anterior se existir
if [ -d "/opt/squashfs-root" ]; then
    rm -rf /opt/squashfs-root
fi

# Extrair o AppImage para configurar corretamente
echo "Configurando nova versão do LM Studio..."
cd /opt
./lm-studio.appimage --appimage-extract >/dev/null 2>&1

# Configurar permissões do chrome-sandbox
if [ -f "/opt/squashfs-root/chrome-sandbox" ]; then
    chown root:root /opt/squashfs-root/chrome-sandbox
    chmod 4755 /opt/squashfs-root/chrome-sandbox
fi

# Atualizar atalho no desktop (caso tenha mudanças)
cat > /usr/share/applications/lm-studio.desktop << EOL
[Desktop Entry]
Name=LM Studio
Exec=/opt/lm-studio.appimage
Icon=lm-studio
Type=Application
Categories=Development;IDE;Science;
Comment=Run Large Language Models locally on your computer
StartupWMClass=LM Studio
EOL

echo "Atualização concluída! A versão anterior foi copiada para /opt/lm-studio.appimage.bak"
echo "Você já pode executar a versão atualizada do LM Studio (versão ${VERSION})"
echo ""
echo "Para remover o backup da versão anterior, execute:"
echo "sudo rm /opt/lm-studio.appimage.bak"

# Limpeza
cd /
rm -rf "$TEMP_DIR" 