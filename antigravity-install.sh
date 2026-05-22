#!/bin/bash

# Script: antigravity-install.sh
# Descrição: Instala e configura o Google Antigravity (Hub e IDE) no Ubuntu.
# Autor: Antigravity AI Assistant
# Data: 2026-05-21

# Cores para saída formatada
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Função para exibir o cabeçalho
show_header() {
    clear
    echo -e "${BLUE}${BOLD}================================================================${NC}"
    echo -e "${CYAN}${BOLD}       Instalador e Configurador do Google Antigravity          ${NC}"
    echo -e "${BLUE}${BOLD}================================================================${NC}"
    echo ""
}

# Verificar privilégios de root
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Solicitando acesso sudo para instalar o Google Antigravity...${NC}"
    exec sudo "$0" "$@"
    exit $?
fi

# Obter o usuário real e seu diretório home
REAL_USER=$SUDO_USER
if [ -z "$REAL_USER" ]; then
    REAL_USER=$(whoami)
fi
USER_HOME=$(eval echo ~$REAL_USER)

show_header

# 1. Verificar dependências necessárias
echo -e "${BLUE}[1/5] Verificando dependências do sistema...${NC}"
for cmd in curl jq tar; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${YELLOW}Instalando dependência ausente: $cmd...${NC}"
        apt-get update -y && apt-get install -y $cmd
    else
        echo -e "  [${GREEN}✓${NC}] $cmd está instalado."
    fi
done
echo ""

# 2. Detectar arquitetura
echo -e "${BLUE}[2/5] Detectando arquitetura do processador...${NC}"
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    PLATFORM_HUB="linux-x64"
    PLATFORM_IDE="linux-x64"
    echo -e "  [${GREEN}✓${NC}] Arquitetura detectada: x86_64 (Linux x64)"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    PLATFORM_HUB="linux-arm"
    PLATFORM_IDE="linux-arm"
    echo -e "  [${GREEN}✓${NC}] Arquitetura detectada: ARM64 (Linux ARM64)"
else
    echo -e "  [${RED}✗${NC}] Arquitetura não suportada: $ARCH"
    exit 1
fi
echo ""

# 3. Consultar versões mais recentes
echo -e "${BLUE}[3/5] Consultando versões estáveis mais recentes...${NC}"

# Buscar dados do Antigravity Hub
HUB_RELEASE_INFO=$(curl -s "https://antigravity-auto-updater-974169037036.us-central1.run.app/releases")
HUB_VERSION=$(echo "$HUB_RELEASE_INFO" | jq -r '.[0].version')
HUB_EXEC_ID=$(echo "$HUB_RELEASE_INFO" | jq -r '.[0].execution_id')

# Buscar dados do Antigravity IDE
IDE_RELEASE_INFO=$(curl -s "https://antigravity-ide-auto-updater-974169037036.us-central1.run.app/releases")
IDE_VERSION=$(echo "$IDE_RELEASE_INFO" | jq -r '.[0].version')
IDE_EXEC_ID=$(echo "$IDE_RELEASE_INFO" | jq -r '.[0].execution_id')

if [ -z "$HUB_VERSION" ] || [ -z "$IDE_VERSION" ]; then
    echo -e "  [${RED}✗${NC}] Erro ao buscar informações de versão. Verifique sua conexão com a internet."
    exit 1
fi

echo -e "  [${GREEN}✓${NC}] Antigravity Hub (CLI): versão ${GREEN}$HUB_VERSION${NC} disponível."
echo -e "  [${GREEN}✓${NC}] Antigravity IDE: versão ${GREEN}$IDE_VERSION${NC} disponível."
echo ""

# 4. Perguntar o que instalar
echo -e "${BLUE}[4/5] Selecione o que deseja instalar:${NC}"
echo -e "  ${BOLD}1)${NC} Google Antigravity Hub (Desktop App / CLI Core)"
echo -e "  ${BOLD}2)${NC} Google Antigravity IDE"
echo -e "  ${BOLD}3)${NC} Ambos (Recomendado)"
echo -e "  ${BOLD}4)${NC} Cancelar"
echo -n "Escolha uma opção [1-4]: "
read -r OPTION

INSTALL_HUB=false
INSTALL_IDE=false

case $OPTION in
    1)
        INSTALL_HUB=true
        ;;
    2)
        INSTALL_IDE=true
        ;;
    3)
        INSTALL_HUB=true
        INSTALL_IDE=true
        ;;
    *)
        echo -e "${YELLOW}Instalação cancelada pelo usuário.${NC}"
        exit 0
        ;;
esac

echo ""
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR" || exit 1

# Função para instalar o Hub
install_hub() {
    local url="https://storage.googleapis.com/antigravity-public/antigravity-hub/${HUB_VERSION}-${HUB_EXEC_ID}/${PLATFORM_HUB}/Antigravity.tar.gz"
    echo -e "${CYAN}Baixando Google Antigravity Hub (${HUB_VERSION})...${NC}"
    
    if ! curl -L "$url" -o antigravity-hub.tar.gz; then
        echo -e "${RED}Erro ao baixar Antigravity Hub de: $url${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Extraindo Antigravity Hub...${NC}"
    tar -xzf antigravity-hub.tar.gz
    
    # Antigravity-x64 ou correspondente de acordo com a arquitetura
    local folder_name="Antigravity-x64"
    if [ "$PLATFORM_HUB" = "linux-arm" ]; then
        folder_name="Antigravity-arm" # ou similar, mas no tar é extraído de acordo
    fi
    
    # Se a pasta extraída tiver outro nome, localizamos dinamicamente
    if [ ! -d "$folder_name" ]; then
        folder_name=$(find . -maxdepth 1 -type d -name "Antigravity*" | head -n 1)
        folder_name=${folder_name#./}
    fi
    
    echo -e "${CYAN}Instalando em /opt/antigravity...${NC}"
    rm -rf /opt/antigravity
    mv "$folder_name" /opt/antigravity
    
    # Configurar sandbox do chrome
    if [ -f "/opt/antigravity/chrome-sandbox" ]; then
        chown root:root /opt/antigravity/chrome-sandbox
        chmod 4755 /opt/antigravity/chrome-sandbox
    fi
    
    # Criar link simbólico
    echo -e "${CYAN}Criando link simbólico em /usr/local/bin/antigravity...${NC}"
    ln -sf /opt/antigravity/antigravity /usr/local/bin/antigravity
    
    # Baixar ícone
    echo -e "${CYAN}Configurando ícone do aplicativo...${NC}"
    mkdir -p /usr/share/pixmaps
    curl -sL "https://antigravity.google/assets/image/antigravity-logo.png" -o /usr/share/pixmaps/antigravity.png
    
    # Criar atalho Desktop (.desktop)
    echo -e "${CYAN}Criando atalho no menu do sistema...${NC}"
    cat > /usr/share/applications/antigravity.desktop << EOL
[Desktop Entry]
Name=Google Antigravity Hub
Comment=Google Antigravity Agent Platform
Exec=/opt/antigravity/antigravity %U
Icon=/usr/share/pixmaps/antigravity.png
Terminal=false
Type=Application
Categories=Development;IDE;
StartupWMClass=antigravity
EOL

    echo -e "${GREEN}✓ Google Antigravity Hub instalado com sucesso!${NC}"
}

# Função para instalar a IDE
install_ide() {
    local url="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/${IDE_VERSION}-${IDE_EXEC_ID}/${PLATFORM_IDE}/Antigravity%20IDE.tar.gz"
    echo -e "${CYAN}Baixando Google Antigravity IDE (${IDE_VERSION})...${NC}"
    
    if ! curl -L "$url" -o antigravity-ide.tar.gz; then
        echo -e "${RED}Erro ao baixar Antigravity IDE de: $url${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Extraindo Antigravity IDE...${NC}"
    tar -xzf antigravity-ide.tar.gz
    
    # Antigravity IDE ou correspondente de acordo com a arquitetura
    local folder_name="Antigravity IDE"
    if [ ! -d "$folder_name" ]; then
        folder_name=$(find . -maxdepth 1 -type d -name "Antigravity*IDE*" -o -name "*IDE" | head -n 1)
        folder_name=${folder_name#./}
    fi
    
    echo -e "${CYAN}Instalando em /opt/antigravity-ide...${NC}"
    rm -rf /opt/antigravity-ide
    mv "$folder_name" /opt/antigravity-ide
    
    # Configurar sandbox do chrome
    if [ -f "/opt/antigravity-ide/chrome-sandbox" ]; then
        chown root:root /opt/antigravity-ide/chrome-sandbox
        chmod 4755 /opt/antigravity-ide/chrome-sandbox
    fi
    
    # Criar link simbólico
    echo -e "${CYAN}Criando link simbólico em /usr/local/bin/antigravity-ide...${NC}"
    ln -sf "/opt/antigravity-ide/antigravity-ide" /usr/local/bin/antigravity-ide
    
    # Baixar ícone
    echo -e "${CYAN}Configurando ícone do aplicativo...${NC}"
    mkdir -p /usr/share/pixmaps
    curl -sL "https://antigravity.google/assets/image/antigravity-logo.png" -o /usr/share/pixmaps/antigravity-ide.png
    
    # Criar atalho Desktop (.desktop)
    echo -e "${CYAN}Criando atalho no menu do sistema...${NC}"
    cat > /usr/share/applications/antigravity-ide.desktop << EOL
[Desktop Entry]
Name=Google Antigravity IDE
Comment=Google Antigravity Agent-First IDE
Exec="/opt/antigravity-ide/antigravity-ide" %U
Icon=/usr/share/pixmaps/antigravity-ide.png
Terminal=false
Type=Application
Categories=Development;IDE;
StartupWMClass=antigravity-ide
EOL

    echo -e "${GREEN}✓ Google Antigravity IDE instalado com sucesso!${NC}"
}

# Executar instalações selecionadas
if [ "$INSTALL_HUB" = true ]; then
    install_hub
fi

if [ "$INSTALL_IDE" = true ]; then
    echo ""
    install_ide
fi

# 5. Configurações Finais
echo ""
echo -e "${BLUE}[5/5] Executando configurações finais de ambiente...${NC}"

# Criar pastas de configuração do usuário real se não existirem e ajustar permissões
if [ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ]; then
    echo -e "${CYAN}Configurando pastas do usuário local ($REAL_USER)...${NC}"
    mkdir -p "$USER_HOME/.antigravity" "$USER_HOME/.antigravity-ide" "$USER_HOME/.antigravitycli"
    chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.antigravity" "$USER_HOME/.antigravity-ide" "$USER_HOME/.antigravitycli"
    echo -e "  [${GREEN}✓${NC}] Pastas de perfil criadas e permissões ajustadas."
fi

# Limpeza do diretório temporário
cd /
rm -rf "$TEMP_DIR"

echo ""
echo -e "${GREEN}${BOLD}================================================================${NC}"
echo -e "${GREEN}${BOLD}             Configuração concluída com sucesso!                ${NC}"
echo -e "${GREEN}${BOLD}================================================================${NC}"
echo ""
if [ "$INSTALL_HUB" = true ]; then
    echo -e "  * Para iniciar o Antigravity Hub pelo terminal, digite: ${CYAN}antigravity${NC}"
fi
if [ "$INSTALL_IDE" = true ]; then
    echo -e "  * Para iniciar o Antigravity IDE pelo terminal, digite: ${CYAN}antigravity-ide${NC}"
fi
echo -e "  * Ambos também estão disponíveis no menu de aplicativos do sistema."
echo ""
