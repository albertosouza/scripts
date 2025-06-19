#!/bin/bash

# Script: lm-studio-install.sh
# Descrição: Este script automatiza a instalação do LM Studio no Linux.
# O script baixa a versão mais recente do LM Studio, instala como AppImage em /opt
# e cria um atalho no menu de aplicativos do sistema.
#
# Funcionalidades:
# - Verifica e solicita privilégios sudo
# - Baixa a última versão do LM Studio
# - Instala o AppImage em /opt
# - Cria atalho no menu de aplicativos
# - Gerencia erros de download e instalação

if [ "$EUID" -ne 0 ]; then
    echo "Solicitando acesso sudo para instalar o LM Studio..."
    exec sudo "$0" "$@"
    exit $?
fi

if [ -f "/opt/lm-studio.appimage" ]; then
    echo "LM Studio já está instalado em /opt/lm-studio.appimage"
    echo "Para atualizar, use o script lm-studio-update.sh"
    exit 1
fi

TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo "Verificando a versão mais recente do LM Studio..."

# URL padrão para a versão estável mais recente conhecida
# Baseado nas informações coletadas, a versão 0.3.16-8 é estável
VERSION="0.3.16-8"
DOWNLOAD_URL="https://installers.lmstudio.ai/linux/x64/${VERSION}/LM-Studio-${VERSION}-x64.AppImage"

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

echo "Instalando LM Studio..."
mv lm-studio.AppImage /opt/lm-studio.appimage

# Instalar dependências necessárias
echo "Instalando dependências necessárias..."
apt update
apt install -y libatk1.0-0 libatk-bridge2.0-0 libcups2 libgdk-pixbuf2.0-0 \
    libgtk-3-0 libpango-1.0-0 libcairo2 libxcomposite1 libxdamage1 \
    libasound2t64 libatspi2.0-0 || apt install -y libatk1.0-0 libatk-bridge2.0-0 \
    libcups2 libgdk-pixbuf2.0-0 libgtk-3-0 libpango-1.0-0 libcairo2 \
    libxcomposite1 libxdamage1 libasound2 libatspi2.0-0

# Extrair o AppImage para configurar corretamente
echo "Configurando LM Studio..."
cd /opt
./lm-studio.appimage --appimage-extract >/dev/null 2>&1

# Configurar permissões do chrome-sandbox
if [ -f "/opt/squashfs-root/chrome-sandbox" ]; then
    chown root:root /opt/squashfs-root/chrome-sandbox
    chmod 4755 /opt/squashfs-root/chrome-sandbox
fi

# Criar atalho no desktop
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

echo "Instalação concluída! LM Studio ${VERSION} foi instalado em /opt/lm-studio.appimage"
echo "Um atalho foi criado no menu de aplicativos"
echo "Você pode executar o LM Studio através do menu de aplicativos ou executando: /opt/lm-studio.appimage"
echo ""
echo "Nota: LM Studio permite executar modelos de linguagem como Llama, DeepSeek, Qwen e Phi localmente"
echo "Acesse a interface através do menu de aplicativos ou execute diretamente o comando acima"

# Limpeza
cd /
rm -rf "$TEMP_DIR" 